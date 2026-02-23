import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/screens/customer/pages/customer_tracking_constants.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/models/chat_models.dart';
import 'package:sidrive/screens/chat/chat_room_page.dart';
import 'package:sidrive/services/customer_location_service.dart';
import 'package:sidrive/services/driver_tracking_service.dart';
import 'package:http/http.dart' as http;

class CustomerUmkmTracking extends StatefulWidget {
  final String idPesanan;
  final Map<String, dynamic> pesananData;

  const CustomerUmkmTracking({
    Key? key,
    required this.idPesanan,
    required this.pesananData,
  }) : super(key: key);

  @override
  State<CustomerUmkmTracking> createState() => _CustomerUmkmTrackingState();
}

class _CustomerUmkmTrackingState extends State<CustomerUmkmTracking> {
  final MapController _mapController = MapController();
  final _supabase = Supabase.instance.client;
  final _chatService = ChatService();
  
  // ✅ SERVICES
  final _customerLocationService = CustomerLocationService();
  final _trackingService = DriverTrackingService();

  StreamSubscription? _pengirimanStream;
  StreamSubscription? _pesananStream;
  Timer? _locationUpdateTimer;
  Timer? _mapRefreshTimer;
  Timer? _routeUpdateTimer; // ✅ NEW: Timer untuk update route

  Map<String, dynamic>? _pengirimanData;
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _umkmData;
  
  LatLng? _driverLocation;
  LatLng? _pickupLocation;  // Lokasi toko UMKM
  LatLng? _destinationLocation; // Lokasi customer (input user)
  LatLng? _customerLocation; // Lokasi real-time customer (GPS)
  
  // ✅ NEW: OSRM Route data
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  
  String _currentStatus = 'diterima';
  String _cachedDriverId = '';
  bool _isLoading = true;
  bool _isPanelMinimized = false;
  bool _hasDriver = false;
  bool _isFollowMode = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startMapRefreshTimer();
  }

  void _startMapRefreshTimer() {
    _mapRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {});
        if (_isFollowMode) {
          _fitBoundsAfterLoad();
        }
      }
    });
  }

  // ✅ NEW: Fetch OSRM route
  Future<void> _fetchOSRMRoute() async {
    if (_isLoadingRoute) return;

    print('🗺️ ========== FETCHING ROUTE ==========');
    print('   Has Driver: $_hasDriver');
    print('   Current Status: $_currentStatus');
    print('   Driver Location: ${_driverLocation != null ? "✅" : "❌"}');
    print('   Pickup Location: ${_pickupLocation != null ? "✅" : "❌"}');
    print('   Destination Location: ${_destinationLocation != null ? "✅" : "❌"}');
    print('   Customer Location: ${_customerLocation != null ? "✅" : "❌"}');

    List<LatLng> waypoints = [];
    
    // Tentukan waypoints berdasarkan mode DAN status
    if (_hasDriver) {
      // ✅ DELIVERY MODE
      // Cek status untuk tentukan routing:
      // - SEBELUM customer_naik: Driver → Toko
      // - SETELAH customer_naik: Driver → Customer (titik pengiriman yang dipilih)
      
      final beforePickup = ['diterima', 'menuju_pickup', 'sampai_pickup'].contains(_currentStatus);
      
      if (beforePickup) {
        // ✅ PHASE 1: Driver → Toko (sebelum ambil barang)
        if (_driverLocation != null && _pickupLocation != null) {
          waypoints = [_driverLocation!, _pickupLocation!];
          print('📍 Route mode: Driver → Toko (PHASE 1)');
          print('   From: ${_driverLocation!.latitude}, ${_driverLocation!.longitude}');
          print('   To: ${_pickupLocation!.latitude}, ${_pickupLocation!.longitude}');
        } else {
          print('⚠️ Missing location data for Driver → Toko route');
        }
      } else {
        // ✅ PHASE 2: Driver → Customer Destination (setelah ambil barang)
        if (_driverLocation != null && _destinationLocation != null) {
          waypoints = [_driverLocation!, _destinationLocation!];
          print('📍 Route mode: Driver → Customer Destination (PHASE 2)');
          print('   From: ${_driverLocation!.latitude}, ${_driverLocation!.longitude}');
          print('   To: ${_destinationLocation!.latitude}, ${_destinationLocation!.longitude}');
        } else {
          print('⚠️ Missing location data for Driver → Customer route');
        }
      }
    } else {
      // ✅ PICKUP MODE: Customer GPS → Toko (tidak pakai driver)
      if (_customerLocation != null && _pickupLocation != null) {
        waypoints = [_customerLocation!, _pickupLocation!];
        print('📍 Route mode: Customer GPS → Toko (PICKUP MODE)');
        print('   From: ${_customerLocation!.latitude}, ${_customerLocation!.longitude}');
        print('   To: ${_pickupLocation!.latitude}, ${_pickupLocation!.longitude}');
      } else {
        print('⚠️ Missing location data for Customer → Toko route');
      }
    }

    if (waypoints.length < 2) {
      print('⚠️ Not enough waypoints for routing - skipping');
      print('======================================');
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      // Build OSRM coordinates string: "lng,lat;lng,lat;..."
      final coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      final url = 'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson';
      
      print('🗺️ Fetching OSRM route...');
      print('   Waypoints: ${waypoints.length}');
      print('   URL: $url');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          // Parse GeoJSON coordinates
          final List<dynamic> coords = geometry['coordinates'];
          final List<LatLng> points = coords
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();

          // Get distance and duration
          final distance = route['distance'] as num; // meters
          final duration = route['duration'] as num; // seconds

          setState(() {
            _routePoints = points;
            _routeDistance = '${(distance / 1000).toStringAsFixed(1)} km';
            _routeDuration = '${(duration / 60).ceil()} menit';
            _isLoadingRoute = false;
          });

          print('✅ OSRM route loaded: ${points.length} points, $_routeDistance, $_routeDuration');
        } else {
          throw Exception('Invalid OSRM response');
        }
      } else {
        throw Exception('OSRM API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching OSRM route: $e');
      // Fallback to straight line
      setState(() {
        _routePoints = waypoints;
        _routeDistance = null;
        _routeDuration = null;
        _isLoadingRoute = false;
      });
    }
  }

  // ✅ NEW: Auto-update route ketika lokasi berubah
  void _startRouteUpdateTimer() {
    _routeUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchOSRMRoute();
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      print('📦 ========== UMKM TRACKING INIT ==========');
      print('📦 Pesanan ID: ${widget.idPesanan}');
      
      final statusPesanan = widget.pesananData['status_pesanan'] ?? 'menunggu_konfirmasi';
      print('   Status Pesanan: $statusPesanan');

      _hasDriver = widget.pesananData['delivery_option'] == 'delivery';
      print('   Has Driver: $_hasDriver');

      // 1️⃣ LOAD DATA UMKM
      print('🏪 Loading UMKM data...');
      
      try {
        final umkmRpc = await _supabase.rpc(
          'get_umkm_with_location',
          params: {'umkm_id': widget.pesananData['id_umkm']},
        ).maybeSingle();

        if (umkmRpc != null) {
          _umkmData = umkmRpc;
          print('✅ UMKM loaded via RPC: ${umkmRpc['nama_toko']}');
          print('🗺️  Latitude: ${umkmRpc['lokasi_toko_lat']}');
          print('🗺️  Longitude: ${umkmRpc['lokasi_toko_lng']}');
        } else {
          throw Exception('UMKM not found via RPC');
        }
      } catch (rpcError) {
        print('⚠️ RPC method failed: $rpcError');
        print('🔄 Trying fallback method...');
        
        final umkm = await _supabase
            .from('umkm')
            .select()
            .eq('id_umkm', widget.pesananData['id_umkm'])
            .single();

        _umkmData = umkm;
        print('✅ UMKM loaded via fallback: ${umkm['nama_toko']}');
      }

      // 2️⃣ CEK PENGIRIMAN (untuk delivery)
      // ✅ FIX: Cek pengiriman jika hasDriver = true, tidak peduli statusPesanan
      // karena status_pesanan bisa 'dalam_pengiriman', 'mencari_driver', atau 'siap_kirim'
      if (_hasDriver) {
        try {
          final pengiriman = await _supabase
              .from('pengiriman')
              .select()
              .eq('id_pesanan', widget.idPesanan)
              .maybeSingle();

          if (pengiriman != null) {
            _pengirimanData = pengiriman;
            _currentStatus = pengiriman['status_pengiriman'] ?? 'diterima';
            _cachedDriverId = pengiriman['id_driver'] ?? '';
            
            print('✅ Pengiriman loaded');
            print('   Status Pengiriman: $_currentStatus');
            print('   Driver ID: $_cachedDriverId');
            
            // ✅ Load driver info jika sudah ada driver
            if (_cachedDriverId.isNotEmpty) {
              await _loadDriverInfo(_cachedDriverId);
            } else {
              print('⚠️ Pengiriman exists but driver not assigned yet');
            }
          } else {
            print('⚠️ No pengiriman record found yet (driver not assigned)');
          }
        } catch (e) {
          print('⚠️ Error loading pengiriman: $e');
        }
      }

      // 3️⃣ PARSE LOKASI
      _parseLocations();
      
      print('🔍 ========== LOCATION VERIFICATION ==========');
      print('   Toko: ${_pickupLocation != null ? "✅ ${_pickupLocation!.latitude}, ${_pickupLocation!.longitude}" : "❌ NULL"}');
      print('   Customer Dest: ${_destinationLocation != null ? "✅" : "⚠️ NULL"}');
      print('   Driver: ${_driverLocation != null ? "✅" : "ℹ️ NULL"}');
      print('=============================================');

      // 4️⃣ START TRACKING
      if (_cachedDriverId.isNotEmpty && _hasDriver) {
        _startDriverLocationUpdates();
        
        if (_pengirimanData != null) {
          _trackingService.startTracking(
            idPengiriman: _pengirimanData!['id_pengiriman'],
            idDriver: _cachedDriverId,
          );
        }
      }
      
      if (!_hasDriver) {
        await _startCustomerLocationTracking();
      }

      // 5️⃣ LISTEN TO UPDATES
      // ✅ FIX: Selalu listen pengiriman updates jika hasDriver, meskipun pengirimanData null
      // karena driver bisa di-assign setelah halaman dibuka
      if (_hasDriver) {
        _listenPengirimanUpdates();
      }
      _listenPesananUpdates();

      setState(() => _isLoading = false);

      // 6️⃣ FETCH OSRM ROUTE & START AUTO-UPDATE
      await Future.delayed(const Duration(milliseconds: 500));
      await _fetchOSRMRoute();
      _startRouteUpdateTimer();
      
      Future.delayed(const Duration(milliseconds: 800), () {
        _fitBoundsAfterLoad();
      });

    } catch (e, stackTrace) {
      print('❌ [UmkmTracking] Error: $e');
      print('Stack: $stackTrace');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDriverInfo(String idDriver) async {
    print('👤 Loading driver info: $idDriver');
    
    try {
      final driver = await _supabase
          .from('drivers')
          .select('rating_driver, total_rating, id_user, current_location')
          .eq('id_driver', idDriver)
          .single();
      
      final user = await _supabase
          .from('users')
          .select('nama, foto_profil, no_telp')
          .eq('id_user', driver['id_user'])
          .single();
      
      final vehicleList = await _supabase
          .from('driver_vehicles')
          .select('plat_nomor, merk_kendaraan, is_active, status_verifikasi')
          .eq('id_driver', idDriver);

      final approvedVehicles = vehicleList.where((v) =>
        v['is_active'] == true && 
        v['status_verifikasi'] == 'approved'
      ).toList();

      Map<String, dynamic>? vehicle;
      if (approvedVehicles.isNotEmpty) {
        vehicle = approvedVehicles.first;
      }
      
      final combinedData = {
        ...driver,
        ...user,
        'plat_nomor': vehicle?['plat_nomor'] ?? '-',
        'merk_kendaraan': vehicle?['merk_kendaraan'] ?? '-',
      };

      setState(() {
        _driverData = combinedData;
      });

      if (driver['current_location'] != null) {
        try {
          final locationData = await _supabase.rpc(
            'get_driver_location',
            params: {'driver_id': idDriver},
          ).single();

          if (locationData['lat'] != null && locationData['lng'] != null) {
            setState(() {
              _driverLocation = LatLng(
                locationData['lat'] as double,
                locationData['lng'] as double,
              );
            });
          }
        } catch (e) {
          print('⚠️ Failed to parse driver location: $e');
        }
      }
      
    } catch (e) {
      print('❌ Error loading driver info: $e');
    }
  }

  void _startDriverLocationUpdates() {
    if (_cachedDriverId.isEmpty) return;
    
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_cachedDriverId.isEmpty) {
        timer.cancel();
        return;
      }
      
      try {
        final driver = await _supabase.rpc(
          'get_driver_location',
          params: {'driver_id': _cachedDriverId},
        ).maybeSingle();
        
        if (driver != null && driver['lat'] != null && driver['lng'] != null) {
          setState(() {
            _driverLocation = LatLng(
              driver['lat'] as double,
              driver['lng'] as double,
            );
          });
          
          // Update route when driver moves
          _fetchOSRMRoute();
        }
      } catch (e) {
        print('❌ Error updating driver location: $e');
      }
    });
  }

  Future<void> _startCustomerLocationTracking() async {
    print('👤 Starting customer location tracking...');
    
    final customerId = widget.pesananData['id_user'];
    final pesananId = widget.idPesanan;
    
    final success = await _customerLocationService.startTracking(
      customerId: customerId,
      pesananId: pesananId,
      onUpdate: (lat, lng) {
        if (mounted) {
          setState(() {
            _customerLocation = LatLng(lat, lng);
          });
          
          // Update route when customer moves (pickup mode only)
          if (!_hasDriver) {
            _fetchOSRMRoute();
          }
        }
      },
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS gagal diaktifkan. Pastikan GPS aktif dan izin diberikan.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _parseLocations() {
    print('🗺️ ========== PARSING LOCATIONS ==========');
    
    // Parse driver location
    if (_pengirimanData?['last_driver_location'] != null) {
      final driverLoc = _pengirimanData!['last_driver_location'];
      final regex = RegExp(r'POINT\(([^ ]+) ([^ ]+)\)');
      final match = regex.firstMatch(driverLoc);
      
      if (match != null) {
        final lng = double.parse(match.group(1)!);
        final lat = double.parse(match.group(2)!);
        _driverLocation = LatLng(lat, lng);
      }
    }

    // Parse pickup location (toko UMKM)
    if (_umkmData != null) {
      if (_umkmData!.containsKey('lokasi_toko_lat') && 
          _umkmData!.containsKey('lokasi_toko_lng') &&
          _umkmData!['lokasi_toko_lat'] != null &&
          _umkmData!['lokasi_toko_lng'] != null) {
        
        final lat = _umkmData!['lokasi_toko_lat'] as double;
        final lng = _umkmData!['lokasi_toko_lng'] as double;
        _pickupLocation = LatLng(lat, lng);
        print('✅ Store location from RPC: $lat, $lng');
      } 
      else if (_umkmData!.containsKey('lokasi_toko_text') && 
               _umkmData!['lokasi_toko_text'] != null) {
        
        final tokoLoc = _umkmData!['lokasi_toko_text'] as String;
        final regex = RegExp(r'POINT\(([^ ]+) ([^ ]+)\)');
        final match = regex.firstMatch(tokoLoc);
        
        if (match != null) {
          final lng = double.parse(match.group(1)!);
          final lat = double.parse(match.group(2)!);
          _pickupLocation = LatLng(lat, lng);
        }
      }
      else if (_umkmData!.containsKey('lokasi_toko') && 
               _umkmData!['lokasi_toko'] != null) {
        
        final tokoLoc = _umkmData!['lokasi_toko'].toString();
        
        try {
          final regex = RegExp(r'POINT\(([^ ]+) ([^ ]+)\)');
          final match = regex.firstMatch(tokoLoc);
          
          if (match != null) {
            final lng = double.parse(match.group(1)!);
            final lat = double.parse(match.group(2)!);
            _pickupLocation = LatLng(lat, lng);
          }
        } catch (e) {
          print('❌ Error parsing store location: $e');
        }
      }
    }

    // Parse destination
    if (widget.pesananData['lokasi_tujuan'] != null) {
      final destLoc = widget.pesananData['lokasi_tujuan'];
      final regex = RegExp(r'POINT\(([^ ]+) ([^ ]+)\)');
      final match = regex.firstMatch(destLoc);
      
      if (match != null) {
        final lng = double.parse(match.group(1)!);
        final lat = double.parse(match.group(2)!);
        _destinationLocation = LatLng(lat, lng);
      }
    }

    print('========================================');
  }

  void _listenPengirimanUpdates() {
    // ✅ FIX: Listen by id_pesanan, bukan id_pengiriman
    // karena pengiriman bisa dibuat setelah halaman dibuka
    _pengirimanStream = _supabase
        .from('pengiriman')
        .stream(primaryKey: ['id_pengiriman'])
        .eq('id_pesanan', widget.idPesanan)
        .listen((data) async {
      if (data.isNotEmpty && mounted) {
        final newData = data.first;
        final newStatus = newData['status_pengiriman'] ?? 'diterima';
        final newDriverId = newData['id_driver'] ?? '';
        
        print('📡 ========== PENGIRIMAN UPDATE ==========');
        print('   Old Status: $_currentStatus');
        print('   New Status: $newStatus');
        print('   Old Driver: $_cachedDriverId');
        print('   New Driver: $newDriverId');
        print('=========================================');
        
        setState(() {
          _pengirimanData = newData;
          _currentStatus = newStatus;
        });
        
        // ✅ Handle driver assignment (ketika driver baru di-assign)
        if (newDriverId.isNotEmpty && newDriverId != _cachedDriverId) {
          print('🚗 New driver assigned! Loading driver info...');
          _cachedDriverId = newDriverId;
          
          await _loadDriverInfo(newDriverId);
          
          // Start tracking services
          _startDriverLocationUpdates();
          _trackingService.startTracking(
            idPengiriman: newData['id_pengiriman'],
            idDriver: newDriverId,
          );
          
          // Fetch new route
          await _fetchOSRMRoute();
        }
      }
    }, onError: (error) {
      print('❌ Pengiriman stream error: $error');
    });
  }

  void _listenPesananUpdates() {
    _pesananStream = _supabase
        .from('pesanan')
        .stream(primaryKey: ['id_pesanan'])
        .eq('id_pesanan', widget.idPesanan)
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        final newStatus = data.first['status_pesanan'];
        
        if (newStatus == 'dibatalkan') {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan telah dibatalkan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _fitBoundsAfterLoad() {
    List<LatLng> allPoints = [];
    
    if (_hasDriver) {
      if (_driverLocation != null) allPoints.add(_driverLocation!);
      if (_pickupLocation != null) allPoints.add(_pickupLocation!);
      if (_destinationLocation != null) allPoints.add(_destinationLocation!);
    } else {
      if (_customerLocation != null) allPoints.add(_customerLocation!);
      if (_pickupLocation != null) allPoints.add(_pickupLocation!);
    }

    if (allPoints.isEmpty) return;

    if (allPoints.length == 1) {
      _mapController.move(allPoints.first, 15);
      return;
    }

    try {
      final bounds = LatLngBounds.fromPoints(allPoints);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(80),
        ),
      );
    } catch (e) {
      print('⚠️ Error fitting bounds: $e');
    }
  }

  void _toggleFollowMode() {
    setState(() {
      _isFollowMode = !_isFollowMode;
    });

    if (_isFollowMode) {
      _fitBoundsAfterLoad();
    }
  }

  Future<void> _openChat() async {
    if (_driverData == null) return;

    try {
      // Create or get chat room
      final room = await _chatService.createOrGetRoom(
        context: ChatContext.customerDriver,
        participantIds: [widget.pesananData['id_user'], _cachedDriverId],
        participantRoles: {
          widget.pesananData['id_user']: 'customer',
          _cachedDriverId: 'driver',
        },
        orderId: widget.idPesanan,
      );

      if (room != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              roomId: room.id,
              room: room,
              currentUserId: widget.pesananData['id_user'],
              currentUserRole: 'customer',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka chat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pengirimanStream?.cancel();
    _pesananStream?.cancel();
    _locationUpdateTimer?.cancel();
    _mapRefreshTimer?.cancel();
    _routeUpdateTimer?.cancel(); // ✅ NEW
    _customerLocationService.stopTracking();
    _trackingService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data...'),
                ],
              ),
            )
          : Stack(
              children: [
                // MAP
                _buildMap(),
                
                // BACK BUTTON
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                
                // ✅ NEW: ROUTE INFO CARD (TOP CENTER)
                if (_routeDistance != null && _routeDuration != null && !_isPanelMinimized)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 70,
                    right: 70,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route, color: Colors.blue, size: 18),
                          SizedBox(width: 6),
                          Text(
                            '$_routeDistance • $_routeDuration',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // BOTTOM PANEL
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 5 && !_isPanelMinimized) {
                        setState(() => _isPanelMinimized = true);
                      }
                      else if (details.primaryDelta! < -5 && _isPanelMinimized) {
                        setState(() => _isPanelMinimized = false);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _isPanelMinimized 
                          ? 120.0 
                          : (screenHeight * 0.5).clamp(120.0, screenHeight * 0.65),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // DRAG HANDLE
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPanelMinimized = !_isPanelMinimized;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          
                          // CONTENT
                          Flexible(
                            child: _isPanelMinimized
                                ? _buildMinimizedContent()
                                : _buildFullContent(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // CHAT BUTTON
                if (_hasDriver && _driverData != null)
                  Positioned(
                    bottom: (_isPanelMinimized ? 120 : screenHeight * 0.5) + 80,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: const Color(0xFFFF6B9D),
                      heroTag: 'chat_button',
                      onPressed: _openChat,
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                // FOLLOW BUTTON
                Positioned(
                  bottom: (_isPanelMinimized ? 120 : screenHeight * 0.5) + 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: _isFollowMode ? Colors.blue : Colors.white,
                    heroTag: 'follow_button',
                    onPressed: _toggleFollowMode,
                    child: Icon(
                      Icons.my_location,
                      color: _isFollowMode ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMap() {
    List<Marker> markers = [];

    // SCENARIO 1: DELIVERY
    if (_hasDriver) {
      // Driver marker
      if (_driverLocation != null) {
        markers.add(
          Marker(
            point: _driverLocation!,
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.two_wheeler,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      }

      // Store marker
      if (_pickupLocation != null) {
        markers.add(
          Marker(
            point: _pickupLocation!,
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.store,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      }

      // Destination marker
      if (_destinationLocation != null) {
        markers.add(
          Marker(
            point: _destinationLocation!,
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      }
    } 
    // SCENARIO 2: PICKUP
    else {
      // Customer marker (GPS)
      if (_customerLocation != null) {
        markers.add(
          Marker(
            point: _customerLocation!,
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_pin,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      }

      // Store marker
      if (_pickupLocation != null) {
        markers.add(
          Marker(
            point: _pickupLocation!,
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.store,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      }
    }

    // Default center
    LatLng center = _pickupLocation ?? 
                    _customerLocation ?? 
                    _driverLocation ?? 
                    LatLng(-7.5568, 110.8281);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sidrive.app',
        ),
        
        // ✅ OSRM ROUTE LINE
        if (_routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 5.0,
                color: Colors.blue,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white,
              ),
            ],
          ),

        // MARKERS
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildMinimizedContent() {
    if (!_hasDriver) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.store, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ambil di Toko',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tunjukkan kode pesanan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade400, size: 24),
          ],
        ),
      );
    }

    // Minimized for delivery
    // ✅ FIX: Handle case when driver not yet assigned
    if (_driverData == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.search, color: Colors.grey, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mencari Driver...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Mohon tunggu sebentar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade400, size: 24),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: _driverData!['foto_profil'] != null
                ? NetworkImage(_driverData!['foto_profil'])
                : null,
            child: _driverData!['foto_profil'] == null
                ? const Icon(Icons.person, size: 24)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _driverData!['nama'] ?? 'Driver',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CustomerTrackingConstants.getStatusLabel(_currentStatus, isUmkm: true),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade400, size: 24),
        ],
      ),
    );
  }

  Widget _buildFullContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ NEW: ORDER CODE CARD (PROMINENT)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF6B9D).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'KODE PESANAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${widget.idPesanan.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                          text: widget.idPesanan.substring(0, 8).toUpperCase(),
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Kode berhasil disalin'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Tunjukkan kode ini di toko',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // DRIVER INFO (if delivery AND driver assigned)
          if (_hasDriver && _driverData != null)
            _buildDriverInfo(),
          
          // ✅ NEW: Show "Mencari Driver" if delivery but no driver yet
          if (_hasDriver && _driverData == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mencari Driver',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mohon tunggu, kami sedang mencarikan driver terdekat untuk Anda',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          if (_hasDriver && _driverData != null)
            const SizedBox(height: 16),
          
          // STATUS PROGRESS
          _buildStatusProgress(),
          
          const SizedBox(height: 16),
          
          // ORDER DETAIL
          _buildOrderDetail(),
        ],
      ),
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: _driverData!['foto_profil'] != null
                ? NetworkImage(_driverData!['foto_profil'])
                : null,
            child: _driverData!['foto_profil'] == null
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverData!['nama'] ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${_driverData!['merk_kendaraan'] ?? 'MOTOR'} • ${_driverData!['plat_nomor'] ?? '-'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (_driverData!['rating_driver'] != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text(
                        _driverData!['rating_driver'].toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFF6B9D).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _openChat,
              icon: Icon(
                Icons.chat_bubble_rounded,
                color: Color(0xFFFF6B9D),
                size: 20,
              ),
              padding: EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgress() {
    if (!_hasDriver) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Status Pesanan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambil di Toko',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _umkmData?['nama_toko'] ?? 'Nama Toko',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Progress for delivery
    final steps = CustomerTrackingConstants.getUmkmDeliverySteps();
    final currentIndex = steps.indexWhere((s) => s['status'] == _currentStatus);
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Status Pengiriman',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(steps.length, (index) {
                final step = steps[index];
                final isCompleted = index <= safeIndex;
                final isActive = index == safeIndex;
                final isLast = index == steps.length - 1;

                return Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: isCompleted
                                ? LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isCompleted ? null : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            boxShadow: isActive ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ] : null,
                          ),
                          child: Icon(
                            step['icon'],
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 85,
                          child: Text(
                            step['label'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isCompleted ? Colors.black87 : Colors.grey.shade500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Container(
                        width: 32,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 28),
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? LinearGradient(
                                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                                )
                              : null,
                          color: isCompleted ? null : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetail() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: Colors.grey.shade700),
              SizedBox(width: 8),
              Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Toko', _umkmData?['nama_toko'] ?? '-'),
          if (_hasDriver)
            _buildDetailRow(
              'Ongkir',
              CurrencyFormatter.formatRupiahWithPrefix(widget.pesananData['ongkir'] ?? 0),
            ),
          _buildDetailRow(
            'Total',
            CurrencyFormatter.formatRupiahWithPrefix(widget.pesananData['total_harga'] ?? 0),
          ),
          _buildDetailRow(
            'Pembayaran',
            widget.pesananData['payment_method'] == 'cash' ? '💵 Tunai' : '💳 Transfer',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025