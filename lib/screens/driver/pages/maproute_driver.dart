import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MapRouteDriver extends StatefulWidget {
  final Map<String, dynamic> pesananData;
  final String currentStatus;
  final Function(LatLng, List<LatLng>, String?, double?)? onRouteUpdate;

  const MapRouteDriver({
    Key? key,
    required this.pesananData,
    required this.currentStatus,
    this.onRouteUpdate,
  }) : super(key: key);

  @override
  State<MapRouteDriver> createState() => MapRouteDriverState();
}

class MapRouteDriverState extends State<MapRouteDriver> {
  final MapController _mapController = MapController();
  
  List<LatLng> _routePoints = [];
  LatLng? _lokasiJemput;
  LatLng? _lokasiTujuan;
  LatLng? _lokasiDriver;
  String? _estimasiWaktu;
  double? _totalJarak;
  bool _isUpdating = false;
  int _retryCount = 0;
  Timer? _mapUpdateTimer;
  
  // ✅ GPS FOLLOW MODE
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

  // ✅ Listen map events untuk detect manual move
  void _listenMapEvents() {
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove && event.source == MapEventSource.onDrag) {
        // User sedang drag map, matikan auto-follow
        if (_isFollowingDriver) {
          setState(() {
            _isFollowingDriver = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(MapRouteDriver oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentStatus != widget.currentStatus) {
      print('📍 Status changed: ${oldWidget.currentStatus} -> ${widget.currentStatus}');
      _fetchRoute();
    }
  }

  Future<void> _initializeMap() async {
    print('🗺️ ========== INIT MAP ==========');
    
    try {
      final response = await Supabase.instance.client.rpc(
        'get_pesanan_coordinates',
        params: {'pesanan_id': widget.pesananData['id_pesanan']},
      ).single();
    
      print('✅ Coordinates fetched: $response');
      
      if (mounted) {
        setState(() {
          if (response['lat_asal'] != null && response['lng_asal'] != null) {
            _lokasiJemput = LatLng(
              response['lat_asal'] as double,
              response['lng_asal'] as double,
            );
            print('✅ Lokasi Jemput: $_lokasiJemput');
          }
          
          if (response['lat_tujuan'] != null && response['lng_tujuan'] != null) {
            _lokasiTujuan = LatLng(
              response['lat_tujuan'] as double,
              response['lng_tujuan'] as double,
            );
            print('✅ Lokasi Tujuan: $_lokasiTujuan');
          }
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error init map: $e');
      print('❌ Stack: $stackTrace');
    }

    await updateDriverLocation();

    if (_lokasiDriver != null && _lokasiJemput != null && _lokasiTujuan != null) {
      await _fetchRoute();
    }

    _startMapRealTimeUpdate();
  }

  Future<void> updateDriverLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _lokasiDriver = LatLng(position.latitude, position.longitude);
        });
        print('🚗 Driver location updated: $_lokasiDriver');
        
        // ✅ AUTO-FOLLOW driver jika mode aktif
        if (_isFollowingDriver && _lokasiDriver != null) {
          _centerToDriver();
        }
      }
    } catch (e) {
      print('❌ Error getting driver location: $e');
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

  void _startMapRealTimeUpdate() {
    _mapUpdateTimer?.cancel();
    
    LatLng? _lastDriverLocation;
    
    _mapUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_isUpdating) {
        print('⏸️ Skipping update - previous still running');
        return;
      }
      
      _isUpdating = true;
      
      try {
        await updateDriverLocation();
        
        bool shouldUpdateRoute = false;
        
        if (_lastDriverLocation == null) {
          shouldUpdateRoute = true;
        } else if (_lokasiDriver != null) {
          final distance = _calculateDistance(
            _lastDriverLocation!.latitude,
            _lastDriverLocation!.longitude,
            _lokasiDriver!.latitude,
            _lokasiDriver!.longitude,
          );
          
          if (distance > 30) {
            shouldUpdateRoute = true;
            print('🚀 Driver moved ${distance.toStringAsFixed(0)}m, updating route');
          }
        }
        
        if (shouldUpdateRoute && _lokasiDriver != null && _lokasiJemput != null && _lokasiTujuan != null) {
          _lastDriverLocation = _lokasiDriver;
          await _fetchRoute();
        } else {
          print('📍 Driver location updated but no route fetch needed');
        }
      } catch (e) {
        print('❌ Error in map update: $e');
      } finally {
        _isUpdating = false;
      }
    });
  }

  void _retryFetchRoute() {
    if (_retryCount >= 3) {
      print('❌ Max retry reached, giving up');
      _retryCount = 0;
      return;
    }
    
    _retryCount++;
    final delaySeconds = _retryCount * 2;
    
    print('🔄 Retrying route fetch in ${delaySeconds}s (attempt $_retryCount/3)');
    
    Future.delayed(Duration(seconds: delaySeconds), () {
      if (mounted && _lokasiDriver != null && _lokasiJemput != null && _lokasiTujuan != null) {
        _fetchRoute();
      }
    });
  }

  Future<void> _fetchRoute() async {
    if (!mounted) return;
    
    try {
      List<String> coordinates = [];
      
      if (widget.currentStatus == 'diterima' || 
          widget.currentStatus == 'menuju_pickup' || 
          widget.currentStatus == 'sampai_pickup') {
        
        if (_lokasiDriver != null && _lokasiJemput != null) {
          coordinates = [
            '${_lokasiDriver!.longitude},${_lokasiDriver!.latitude}',
            '${_lokasiJemput!.longitude},${_lokasiJemput!.latitude}',
          ];
          print('🗺️ Route mode: Driver → Pickup Location');
        } else {
          print('⚠️ Missing location for pickup route');
          return;
        }
      } 
      else if (widget.currentStatus == 'customer_naik' || 
               widget.currentStatus == 'perjalanan' || 
               widget.currentStatus == 'sampai_tujuan') {
        
        if (_lokasiDriver != null && _lokasiTujuan != null) {
          coordinates = [
            '${_lokasiDriver!.longitude},${_lokasiDriver!.latitude}',
            '${_lokasiTujuan!.longitude},${_lokasiTujuan!.latitude}',
          ];
          print('🗺️ Route mode: Driver → Destination');
        } else {
          print('⚠️ Missing location for destination route');
          return;
        }
      } else {
        print('⚠️ Unknown status: ${widget.currentStatus}, skipping route');
        return;
      }
      
      if (coordinates.isEmpty) {
        print('⚠️ No valid coordinates for route');
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
          
          if (mounted) {
            setState(() {
              _routePoints = geometry
                  .map((coord) => LatLng(coord[1] as double, coord[0] as double))
                  .toList();
              
              final duration = route['duration'] as num;
              _estimasiWaktu = '${(duration / 60).round()} menit';
              
              final distance = route['distance'] as num;
              _totalJarak = distance / 1000;
            });

            print('✅ Route updated: ${_routePoints.length} points');
            print('✅ Distance: ${_totalJarak?.toStringAsFixed(2)} km');
            print('✅ Duration: $_estimasiWaktu');
            _retryCount = 0;

            if (widget.onRouteUpdate != null && _lokasiDriver != null) {
              widget.onRouteUpdate!(
                _lokasiDriver!,
                _routePoints,
                _estimasiWaktu,
                _totalJarak,
              );
            }

            // ✅ AUTO-ZOOM jika follow mode aktif
            if (_isFollowingDriver) {
              _centerToDriver();
            }
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
            _estimasiWaktu = 'Tidak tersedia';
            _totalJarak = null;
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
        return;
      }
      
      _retryFetchRoute();
    }
  }

  // ✅ CENTER TO DRIVER dengan zoom dekat (17)
  void _centerToDriver() {
    if (_lokasiDriver == null) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(_lokasiDriver!, 17.0); // Zoom dekat
        print('📍 Map centered to driver: zoom 17');
      }
    });
  }

  // ✅ TOGGLE GPS FOLLOW MODE
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

  Future<void> _openNavigation() async {
    LatLng? destination;
    String destinationName = '';
    
    if (widget.currentStatus == 'diterima' || 
        widget.currentStatus == 'menuju_pickup' || 
        widget.currentStatus == 'sampai_pickup') {
      destination = _lokasiJemput;
      destinationName = 'Lokasi Jemput';
    } else {
      destination = _lokasiTujuan;
      destinationName = 'Lokasi Tujuan';
    }
    
    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Lokasi tujuan tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Aplikasi Navigasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.map, color: Colors.green, size: 28),
              ),
              title: Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(destinationName),
              onTap: () async {
                Navigator.pop(context);
                final url = 'https://www.google.com/maps/dir/?api=1&destination=${destination!.latitude},${destination.longitude}&travelmode=driving';
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗺️ Buka Google Maps'),
                    action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ),
                );
                print('📍 Google Maps URL: $url');
              },
            ),
            
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.navigation, color: Colors.blue, size: 28),
              ),
              title: Text('Waze', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(destinationName),
              onTap: () async {
                Navigator.pop(context);
                final url = 'https://waze.com/ul?ll=${destination!.latitude},${destination.longitude}&navigate=yes';
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🧭 Buka Waze'),
                    action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ),
                );
                print('📍 Waze URL: $url');
              },
            ),
            
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapUpdateTimer?.cancel();
    _mapEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _lokasiDriver ?? _lokasiJemput ?? const LatLng(-7.5, 112.7),
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
                if (_lokasiDriver != null)
                  Marker(
                    point: _lokasiDriver!,
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
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
                          child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),

                if (_lokasiJemput != null &&
                    (widget.currentStatus == 'diterima' || 
                    widget.currentStatus == 'menuju_pickup' || 
                    widget.currentStatus == 'sampai_pickup'))
                  Marker(
                    point: _lokasiJemput!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        // ✅ Orange for UMKM store, green for regular pickup
                        color: widget.pesananData['jenis'] == 'umkm' 
                            ? Colors.orange 
                            : Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      // ✅ Store icon for UMKM, person icon for regular
                      child: Icon(
                        widget.pesananData['jenis'] == 'umkm' 
                            ? Icons.store 
                            : Icons.person_pin_circle, 
                        color: Colors.white, 
                        size: 22,
                      ),
                    ),
                  ),
                
                if (_lokasiTujuan != null)
                  Marker(
                    point: _lokasiTujuan!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 22),
                    ),
                  ),
              ],
            ),
          ],
        ),

        if (_totalJarak != null && _estimasiWaktu != null)
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: _openNavigation,
                    icon: Icon(Icons.navigation, size: 20),
                    label: Text(
                      'Buka Navigasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMapInfoItem(
                        icon: Icons.straighten,
                        value: '${_totalJarak!.toStringAsFixed(1)} km',
                      ),
                      Container(
                        width: 1,
                        height: 25,
                        color: Colors.grey.shade300,
                      ),
                      _buildMapInfoItem(
                        icon: Icons.access_time,
                        value: _estimasiWaktu!,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMapInfoItem({required IconData icon, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}