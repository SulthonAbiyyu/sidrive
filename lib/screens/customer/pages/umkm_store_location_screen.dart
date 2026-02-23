// ============================================================================
// UMKM STORE LOCATION SCREEN
// Halaman untuk customer melihat lokasi toko UMKM
// Features:
// - Maps dengan zoom dekat ke lokasi toko
// - Rute dari lokasi customer ke toko
// - Estimasi jarak dan waktu tempuh
// - Marker toko dan customer
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sidrive/core/utils/error_dialog_utils.dart';

class UmkmStoreLocationScreen extends StatefulWidget {
  final LatLng tokoLocation;
  final String tokoName;
  final String tokoAddress;
  final String jamBuka;
  final String jamTutup;

  const UmkmStoreLocationScreen({
    Key? key,
    required this.tokoLocation,
    required this.tokoName,
    required this.tokoAddress,
    required this.jamBuka,
    required this.jamTutup,
  }) : super(key: key);

  @override
  State<UmkmStoreLocationScreen> createState() => _UmkmStoreLocationScreenState();
}

class _UmkmStoreLocationScreenState extends State<UmkmStoreLocationScreen> {
  final MapController _mapController = MapController();
  
  // Location state
  LatLng? _customerLocation;
  bool _isLoadingLocation = false;
  bool _isLoadingRoute = false;
  
  // Route state
  List<LatLng> _routePoints = [];
  double _distanceKm = 0.0;
  int _durationMinutes = 0;
  String _routeInfo = '';
  
  // Map state
  bool _followCustomer = false;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  /// Initialize customer location and calculate route
  Future<void> _initializeLocation() async {
    await _getCurrentLocation();
    if (_customerLocation != null) {
      await _calculateRoute();
    }
  }

  /// Get customer's current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location service is enabled
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS tidak aktif. Mohon aktifkan GPS Anda.');
      }

      // Check permission
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Mohon aktifkan di pengaturan.');
      }

      // Get position
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _customerLocation = LatLng(position.latitude, position.longitude);
        });

        // Start location updates
        _startLocationUpdates();
        
        // Fit bounds to show both markers
        _fitBoundsToMarkers();
      }

    } catch (e) {
      print('❌ Error get location: $e');
      
      if (mounted) {
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Error Lokasi',
          message: e.toString(),
        );
        
        // Fallback: center on store
        _mapController.move(widget.tokoLocation, 16.0);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  /// Start periodic location updates
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
        );

        if (mounted) {
          final newLocation = LatLng(position.latitude, position.longitude);
          
          // Only update if location changed significantly (>10 meters)
          if (_customerLocation == null || 
              _calculateDistance(_customerLocation!, newLocation) > 0.01) {
            
            setState(() {
              _customerLocation = newLocation;
            });

            // Recalculate route if moved significantly
            if (_calculateDistance(_customerLocation!, newLocation) > 0.05) {
              await _calculateRoute();
            }

            // Follow customer if enabled
            if (_followCustomer) {
              _mapController.move(_customerLocation!, _mapController.camera.zoom);
            }
          }
        }
      } catch (e) {
        print('❌ Error update location: $e');
      }
    });
  }

  /// Calculate route using OSRM
  Future<void> _calculateRoute() async {
    if (_customerLocation == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final start = _customerLocation!;
      final end = widget.tokoLocation;

      // OSRM API call
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson&steps=true';

      print('🗺️ Requesting route from OSRM...');
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          
          // Convert coordinates to LatLng
          final routePoints = geometry.map((coord) {
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();

          // Get distance and duration
          final distance = (route['distance'] as num) / 1000; // meters to km
          final duration = (route['duration'] as num) / 60; // seconds to minutes

          if (mounted) {
            setState(() {
              _routePoints = routePoints;
              _distanceKm = distance.toDouble();
              _durationMinutes = duration.ceil();
              _routeInfo = _formatRouteInfo();
            });
          }

          print('✅ Route calculated: ${_distanceKm.toStringAsFixed(2)} km, $_durationMinutes min');
        }
      } else {
        throw Exception('Failed to get route: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Error calculate route: $e');
      
      // Fallback: calculate straight-line distance
      if (_customerLocation != null) {
        final distance = _calculateDistance(_customerLocation!, widget.tokoLocation);
        
        if (mounted) {
          setState(() {
            _distanceKm = distance;
            _durationMinutes = (distance * 3).ceil(); // Assume 20 km/h average
            _routeInfo = _formatRouteInfo();
            _routePoints = []; // No route line
          });
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghitung rute. Menampilkan jarak langsung.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  /// Calculate straight-line distance between two points (in km)
  double _calculateDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, from, to);
  }

  /// Format route information string
  String _formatRouteInfo() {
    if (_durationMinutes < 60) {
      return '${_distanceKm.toStringAsFixed(2)} km • $_durationMinutes menit';
    } else {
      final hours = _durationMinutes ~/ 60;
      final minutes = _durationMinutes % 60;
      return '${_distanceKm.toStringAsFixed(2)} km • ${hours}h ${minutes}m';
    }
  }

  /// Fit map bounds to show both customer and store markers
  void _fitBoundsToMarkers() {
    if (_customerLocation == null) return;

    final bounds = LatLngBounds.fromPoints([
      _customerLocation!,
      widget.tokoLocation,
    ]);

    // Add padding
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  /// Toggle follow customer mode
  void _toggleFollowMode() {
    setState(() {
      _followCustomer = !_followCustomer;
    });

    if (_followCustomer && _customerLocation != null) {
      _mapController.move(_customerLocation!, 17.0);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_followCustomer 
          ? 'Mode ikuti lokasi diaktifkan' 
          : 'Mode ikuti lokasi dinonaktifkan'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Recenter to store location
  void _recenterToStore() {
    _mapController.move(widget.tokoLocation, 18.0);
    setState(() => _followCustomer = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lokasi ${widget.tokoName}'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.tokoLocation,
              initialZoom: 16.0,
              minZoom: 10.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sidrive.app',
                maxZoom: 19,
              ),

              // Route Polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF2563EB),
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Store Marker
                  Marker(
                    point: widget.tokoLocation,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: _recenterToStore,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Color(0xFF2563EB),
                          size: 30,
                        ),
                      ),
                    ),
                  ),

                  // Customer Marker
                  if (_customerLocation != null)
                    Marker(
                      point: _customerLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Loading Indicator
          if (_isLoadingLocation || _isLoadingRoute)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLoadingLocation 
                          ? 'Mendapatkan lokasi...' 
                          : 'Menghitung rute...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Store Info Card (Top)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Store Name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tokoName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.jamBuka} - ${widget.jamTutup}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 16),
                    
                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.tokoAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Route Info Card (Bottom)
          if (_customerLocation != null && _routeInfo.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Route Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _routeInfo,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      
                      if (_routePoints.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Jarak garis lurus',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Action Buttons
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter to Store Button
                FloatingActionButton(
                  heroTag: 'recenter_store',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _recenterToStore,
                  child: const Icon(
                    Icons.store,
                    color: Color(0xFF2563EB),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Follow Customer Button
                if (_customerLocation != null)
                  FloatingActionButton(
                    heroTag: 'follow_customer',
                    mini: true,
                    backgroundColor: _followCustomer 
                      ? const Color(0xFF2563EB) 
                      : Colors.white,
                    onPressed: _toggleFollowMode,
                    child: Icon(
                      Icons.my_location,
                      color: _followCustomer ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Refresh Route Button
                if (_customerLocation != null)
                  FloatingActionButton(
                    heroTag: 'refresh_route',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _isLoadingRoute ? null : _calculateRoute,
                    child: _isLoadingRoute
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        )
                      : const Icon(
                          Icons.refresh,
                          color: Color(0xFF2563EB),
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}