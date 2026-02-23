import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';


class CustomerLocationService {
  static final CustomerLocationService _instance = CustomerLocationService._internal();
  factory CustomerLocationService() => _instance;
  CustomerLocationService._internal();

  Timer? _locationTimer;
  String? _currentCustomerId;
  String? _currentPesananId;
  bool _isTracking = false;
  
  // ⭐ CALLBACK untuk kirim lokasi ke UI
  Function(double lat, double lng)? onLocationUpdate;

  // ⭐ START TRACKING - Dipanggil saat customer mulai tracking pesanan
  Future<bool> startTracking({
    required String customerId,
    required String pesananId,
    required Function(double lat, double lng) onUpdate,
  }) async {
    print('👤 ========== START CUSTOMER TRACKING ==========');
    print('👤 Customer ID: $customerId');
    print('👤 Pesanan ID: $pesananId');
    
    if (_isTracking) {
      print('⚠️ Already tracking!');
      return true;
    }

    // 1️⃣ CEK & MINTA PERMISSION GPS
    final hasPermission = await _requestLocationPermission();
    if (!hasPermission) {
      print('❌ Location permission denied!');
      return false;
    }

    // 2️⃣ CEK APAKAH GPS AKTIF
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      print('❌ GPS is turned off!');
      return false;
    }

    _currentCustomerId = customerId;
    _currentPesananId = pesananId;
    _isTracking = true;
    onLocationUpdate = onUpdate; // ⭐ Set callback

    // 3️⃣ KIRIM LOKASI PERTAMA KALI (LANGSUNG)
    await _updateLocation();

    // 4️⃣ START TIMER - UPDATE SETIAP 5 DETIK
    _locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _updateLocation();
    });

    print('✅ Customer tracking started! Updating every 5 seconds');
    print('==================================================');
    return true;
  }

  // ⭐ STOP TRACKING - Dipanggil saat pesanan selesai
  void stopTracking() {
    print('🛑 ========== STOP CUSTOMER TRACKING ==========');
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    _currentCustomerId = null;
    _currentPesananId = null;
    onLocationUpdate = null; // ⭐ Clear callback
    print('✅ Customer tracking stopped');
    print('==============================================');
  }

  // 📍 MINTA PERMISSION GPS
  Future<bool> _requestLocationPermission() async {
    print('📍 Requesting location permission...');
    
    var status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      print('❌ Location permission permanently denied!');
      await openAppSettings();
      return false;
    }
    
    print('✅ Location permission granted');
    return status.isGranted;
  }

  // 📍 AMBIL GPS & KIRIM KE UI + BACKGROUND SERVICE
  Future<void> _updateLocation() async {
    try {
      // 1️⃣ AMBIL KOORDINAT GPS DARI HP
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = position.latitude;
      final lng = position.longitude;

      print('📍 ========== CUSTOMER LOCATION UPDATE ==========');
      print('📍 Time: ${DateTime.now()}');
      print('📍 Latitude: $lat');
      print('📍 Longitude: $lng');
      print('📍 Accuracy: ${position.accuracy}m');

      // 2️⃣ KIRIM KE UI VIA CALLBACK
      if (onLocationUpdate != null) {
        onLocationUpdate!(lat, lng);
        print('✅ Location sent to UI (monitoring only)');
      }

      // ✅ CATATAN PENTING:
      // Customer GPS TIDAK disimpan ke database karena:
      // - Lokasi jemput = lokasi yang diinput user saat pesan (STATIC)
      // - GPS customer hanya untuk monitoring di UI customer saja
      // - Driver menggunakan lokasi jemput dari input user, bukan GPS real-time customer

      print('==================================================');

    } catch (e, stackTrace) {
      print('❌ ========== ERROR UPDATE CUSTOMER LOCATION ==========');
      print('❌ Error: $e');
      print('❌ Stack: $stackTrace');
      print('========================================================');
    }
  }

  // 📍 GET CURRENT POSITION (single shot, tanpa tracking)
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('📍 Got current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting current position: $e');
      return null;
    }
  }

  // 📊 GETTER - CEK STATUS TRACKING
  bool get isTracking => _isTracking;
  String? get currentCustomerId => _currentCustomerId;
  String? get currentPesananId => _currentPesananId;
}