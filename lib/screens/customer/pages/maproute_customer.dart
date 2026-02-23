import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

class MapRouteCustomer extends StatefulWidget {
  final String idPesanan;
  final Map<String, dynamic> pesananData;
  final String currentStatus;
  final LatLng? driverLocation;
  final LatLng? customerLocation;
  final Function(List<LatLng>)? onRouteUpdate;

  const MapRouteCustomer({
    Key? key,
    required this.idPesanan,
    required this.pesananData,
    required this.currentStatus,
    this.driverLocation,
    this.customerLocation,
    this.onRouteUpdate,
  }) : super(key: key);

  @override
  State<MapRouteCustomer> createState() => MapRouteCustomerState();
}

class MapRouteCustomerState extends State<MapRouteCustomer> {
  final MapController _mapController = MapController();
  final supabase = Supabase.instance.client;
  
  List<LatLng> _routePoints = [];
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  bool _isUpdating = false;
  int _retryCount = 0;
  
  Timer? _debounceTimer;
  DateTime? _lastRouteUpdate;
  int _routeRequestId = 0;
  
  bool _isFollowingDriver = true;
  StreamSubscription<MapEvent>? _mapEventSubscription;

  void toggleFollowMode() {
    _toggleFollowMode();
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _listenMapEvents();
  }

  void _listenMapEvents() {
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove && event.source == MapEventSource.onDrag) {
        if (_isFollowingDriver) {
          setState(() {
            _isFollowingDriver = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapEventSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapRouteCustomer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    bool statusChanged = oldWidget.currentStatus != widget.currentStatus;
    bool locationChangedSignificantly = false;
    
    if (oldWidget.driverLocation != null && widget.driverLocation != null) {
      final distance = _calculateDistance(
        oldWidget.driverLocation!.latitude,
        oldWidget.driverLocation!.longitude,
        widget.driverLocation!.latitude,
        widget.driverLocation!.longitude,
      );
      
      locationChangedSignificantly = distance > 50;
    }
    
    if (statusChanged) {
      print('📍 Status changed: ${oldWidget.currentStatus} → ${widget.currentStatus}');
      _fetchRoute();
      if (_isFollowingDriver) {
        _centerToDriver();
      }
    } else if (locationChangedSignificantly) {
      final now = DateTime.now();
      if (_lastRouteUpdate == null || 
          now.difference(_lastRouteUpdate!) > Duration(seconds: 5)) {
        _lastRouteUpdate = now;
        print('📍 Driver moved significantly, updating route...');
        _fetchRoute();
      } else {
        print('⏸️ Route update skipped (debounced)');
      }
    }
    
    if (_isFollowingDriver && widget.driverLocation != null) {
      _centerToDriver();
    }
  }

  Future<void> _initializeMap() async {
    print('🗺️ ========== INIT CUSTOMER MAP ==========');
    
    try {
      final response = await supabase.rpc(
        'get_pesanan_coordinates',
        params: {'pesanan_id': widget.idPesanan},
      ).single();
      
      print('✅ Coordinates fetched: $response');
      
      if (mounted) {
        setState(() {
          if (response['lat_asal'] != null && response['lng_asal'] != null) {
            _pickupLocation = LatLng(
              response['lat_asal'] as double,
              response['lng_asal'] as double,
            );
            print('✅ Pickup Location set: $_pickupLocation');
          }
          
          if (response['lat_tujuan'] != null && response['lng_tujuan'] != null) {
            _destinationLocation = LatLng(
              response['lat_tujuan'] as double,
              response['lng_tujuan'] as double,
            );
            print('✅ Destination set: $_destinationLocation');
          }
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error init map: $e');
      print('❌ Stack: $stackTrace');
    }

    if (widget.driverLocation != null && _destinationLocation != null) {
      await _fetchRoute();
      if (_isFollowingDriver) {
        _centerToDriver();
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) * 
        cos(_degreesToRadians(lat2)) * 
        sin(dLon / 2) * 
        sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _fetchRoute() async {
    if (!mounted) return;
    
    if (widget.driverLocation == null) {
      print('⚠️ Missing driver location');
      return;
    }
    
    if (_isUpdating) {
      print('⏸️ Skipping route fetch - previous still running');
      return;
    }
    
    _isUpdating = true;
    final currentRequestId = ++_routeRequestId;
    
    try {
      List<String> coordinates = [];
      String routeMode = '';

      if (widget.currentStatus == 'diterima' || 
          widget.currentStatus == 'menuju_pickup' || 
          widget.currentStatus == 'sampai_pickup') {
        
        if (_pickupLocation != null) {
          coordinates = [
            '${widget.driverLocation!.longitude},${widget.driverLocation!.latitude}',
            '${_pickupLocation!.longitude},${_pickupLocation!.latitude}',
          ];
          routeMode = 'Driver → Pickup Location';
          print('🗺️ Route mode: $routeMode');
        } else {
          print('⚠️ Pickup location is NULL, cannot draw route');
          _isUpdating = false;
          return;
        }
      } 
      else if (widget.currentStatus == 'customer_naik' || 
               widget.currentStatus == 'perjalanan' || 
               widget.currentStatus == 'sampai_tujuan') {
        
        if (_destinationLocation != null) {
          coordinates = [
            '${widget.driverLocation!.longitude},${widget.driverLocation!.latitude}',
            '${_destinationLocation!.longitude},${_destinationLocation!.latitude}',
          ];
          routeMode = 'Driver → Destination';
          print('🗺️ Route mode: $routeMode');
        } else {
          print('⚠️ Destination location is NULL, cannot draw route');
          _isUpdating = false;
          return;
        }
      } 
      else {
        print('⚠️ Unknown status: ${widget.currentStatus}, skipping route');
        _isUpdating = false;
        return;
      }
      
      if (coordinates.isEmpty) {
        print('⚠️ No valid coordinates for route');
        _isUpdating = false;
        return;
      }
      
      final coordString = coordinates.join(';');
      final url = 'https://router.project-osrm.org/route/v1/driving/$coordString'
          '?overview=full&geometries=geojson';

      print('🌐 Fetching route from OSRM...');
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('OSRM request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          
          if (mounted && currentRequestId == _routeRequestId) {
            setState(() {
              _routePoints = geometry
                  .map((coord) => LatLng(coord[1] as double, coord[0] as double))
                  .toList();
            });
            
            print('✅ Route loaded: ${_routePoints.length} points ($routeMode)');
            _retryCount = 0;

            if (widget.onRouteUpdate != null) {
              widget.onRouteUpdate!(_routePoints);
            }
            
            if (_isFollowingDriver) {
              _centerToDriver();
            }
          } else {
            print('⚠️ Stale route response ignored');
          }
        } else {
          print('⚠️ No routes found in response');
        }
      } else {
        print('⚠️ OSRM HTTP error: ${response.statusCode}');
        _retryFetchRoute();
      }
    } catch (e) {
      print('❌ Error fetching route: $e');
      
      if (_retryCount >= 3) {
        if (mounted) {
          setState(() {
            _routePoints = [];
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Gagal memuat rute. Periksa koneksi internet.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        _retryCount = 0;
        _isUpdating = false;
        return;
      }
      
      _retryFetchRoute();
    } finally {
      _isUpdating = false;
    }
  }

  void _retryFetchRoute() {
    if (!mounted) {
      _retryCount = 0;
      return;
    }
    
    if (_retryCount >= 3) {
      print('❌ Max retry reached for route fetch');
      if (mounted) {
        setState(() {
          _routePoints = [];
        });
      }
      _retryCount = 0;
      return;
    }
    
    _retryCount++;
    final delaySeconds = _retryCount * 2;
    
    print('🔄 Retrying route fetch in ${delaySeconds}s (attempt $_retryCount/3)');
    
    Future.delayed(Duration(seconds: delaySeconds), () {
      if (mounted && widget.driverLocation != null && _destinationLocation != null) {
        _fetchRoute();
      }
    });
  }

  void _centerToDriver() {
    if (widget.driverLocation == null) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(widget.driverLocation!, 17.0);
        print('📍 Map centered to driver: zoom 17');
      }
    });
  }

  void _toggleFollowMode() {
    setState(() {
      _isFollowingDriver = !_isFollowingDriver;
    });
    
    if (_isFollowingDriver) {
      _centerToDriver();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Mengikuti lokasi driver'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> updateRoute() async {
    await _fetchRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.driverLocation ?? const LatLng(-7.5, 112.7),
            initialZoom: 17.0,
            maxZoom: 18.0,
            minZoom: 10.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.sidrive',
            ),
            
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: Colors.blue,
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.blue.shade900,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                // ✅ HIDE customer marker for UMKM orders with driver
                // Show only for: ojek OR ambil_sendiri
                if (widget.customerLocation != null && 
                    !(widget.pesananData['jenis'] == 'umkm' && 
                      widget.pesananData['metode_pengiriman'] == 'driver'))
                  Marker(
                    point: widget.customerLocation!,
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
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                
                if (widget.driverLocation != null)
                  Marker(
                    point: widget.driverLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.two_wheeler, color: Colors.white, size: 20),
                    ),
                  ),
                
                if (_pickupLocation != null && 
                    (widget.currentStatus == 'diterima' || 
                    widget.currentStatus == 'menuju_pickup' || 
                    widget.currentStatus == 'sampai_pickup'))
                  Marker(
                    point: _pickupLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        // ✅ Orange background for UMKM store
                        color: widget.pesananData['jenis'] == 'umkm' 
                            ? Colors.orange 
                            : null,
                        shape: BoxShape.circle,
                        border: widget.pesananData['jenis'] == 'umkm'
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      // ✅ Store icon for UMKM, location_on for regular
                      child: Icon(
                        widget.pesananData['jenis'] == 'umkm' 
                            ? Icons.store 
                            : Icons.location_on, 
                        color: widget.pesananData['jenis'] == 'umkm' 
                            ? Colors.white 
                            : Colors.green, 
                        size: widget.pesananData['jenis'] == 'umkm' ? 22 : 40,
                      ),
                    ),
                  ),
                
                if (_destinationLocation != null)
                  Marker(
                    point: _destinationLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on, 
                        color: Colors.red, 
                        size: 40,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}