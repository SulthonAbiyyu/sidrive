import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverLocationService {
  static final DriverLocationService _instance = DriverLocationService._internal();
  factory DriverLocationService() => _instance;
  DriverLocationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _locationTimer;
  String? _currentDriverId;
  String? _currentOrderId;
  String? _currentStatus;
  bool _isTracking = false;
  Position? _lastPosition;

  // ⭐ START TRACKING - Dipanggil saat driver mulai pengiriman
  Future<bool> startTracking({
    required String driverId,
    required String orderId,
    required String initialStatus,
  }) async {
    print('🚗 ========== START DRIVER TRACKING ==========');
    print('🚗 Driver ID: $driverId');
    print('🚗 Order ID: $orderId');
    print('🚗 Initial Status: $initialStatus');
    
    if (_isTracking) {
      print('⚠️ Already tracking! Stopping previous tracking...');
      stopTracking();
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

    _currentDriverId = driverId;
    _currentOrderId = orderId;
    _currentStatus = initialStatus;
    _isTracking = true;

    // 3️⃣ KIRIM LOKASI PERTAMA KALI (LANGSUNG)
    await _updateLocationAndNotify();

    // 4️⃣ START TIMER - UPDATE SETIAP 5 DETIK
    _locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _updateLocationAndNotify();
    });

    print('✅ Tracking started! Updating every 5 seconds');
    print('=============================================');
    return true;
  }

  // ⭐ UPDATE STATUS - Dipanggil saat driver ubah status (tapi tetap tracking)
  void updateStatus(String newStatus) {
    print('📊 Updating tracking status: $_currentStatus → $newStatus');
    _currentStatus = newStatus;
    
    // Langsung kirim notif dengan status baru
    if (_isTracking) {
      _updateLocationAndNotify();
    }
  }

  // ⭐ STOP TRACKING - Dipanggil saat driver selesai pengiriman
  void stopTracking() {
    print('🛑 ========== STOP DRIVER TRACKING ==========');
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    _currentDriverId = null;
    _currentOrderId = null;
    _currentStatus = null;
    _lastPosition = null;
    print('✅ Tracking stopped');
    print('============================================');
  }

  // 🔐 MINTA PERMISSION GPS
  Future<bool> _requestLocationPermission() async {
    print('🔐 Requesting location permission...');
    
    var status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      print('❌ Location permission permanently denied!');
      await openAppSettings();
      return false;
    }
    
    // Request background location (Android 10+)
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }
    
    print('✅ Location permission granted');
    return status.isGranted;
  }

  // 🚀 AMBIL GPS, UPDATE SUPABASE, & TRIGGER NOTIFICATION
  Future<void> _updateLocationAndNotify() async {
    if (_currentDriverId == null || _currentOrderId == null) {
      print('⚠️ Missing driver/order ID, skipping update');
      return;
    }

    try {
      // 1️⃣ AMBIL KOORDINAT GPS DARI HP
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      // 2️⃣ CEK APAKAH LOKASI BERUBAH SIGNIFIKAN (minimal 5 meter)
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          lat,
          lng,
        );
        
        if (distance < 5) {
          print('⏭️ Location change < 5m, skipping update');
          return;
        }
      }

      _lastPosition = position;

      print('📍 ========== LOCATION UPDATE ==========');
      print('📍 Time: ${DateTime.now()}');
      print('📍 Latitude: $lat');
      print('📍 Longitude: $lng');
      print('📍 Accuracy: ${position.accuracy}m');
      print('📍 Status: $_currentStatus');

      // 3️⃣ FORMAT KE POSTGIS POINT
      final pointStr = 'POINT($lng $lat)';

      // 4️⃣ UPDATE LOCATION DI DATABASE
      await _supabase.rpc('update_driver_location', params: {
        'driver_id': _currentDriverId,
        'new_location': pointStr,
      });

      print('✅ Location updated in database');

      // 5️⃣ KIRIM NOTIFICATION VIA EDGE FUNCTION
      await _sendTrackingNotification(lat, lng);

      print('========================================');

    } catch (e, stackTrace) {
      print('❌ ========== ERROR UPDATE LOCATION ==========');
      print('❌ Error: $e');
      print('❌ Stack: $stackTrace');
      print('==============================================');
    }
  }

  // 📲 KIRIM TRACKING NOTIFICATION VIA EDGE FUNCTION
  Future<void> _sendTrackingNotification(double lat, double lng) async {
    try {
      // 1️⃣ GET CUSTOMER USER ID FROM ORDER
      final orderData = await _supabase
          .from('pesanan')
          .select('id_user')
          .eq('id_pesanan', _currentOrderId!)
          .single();

      final customerId = orderData['id_user'] as String;

      // 2️⃣ GET DRIVER NAME
      final driverData = await _supabase
          .from('driver')
          .select('nama')
          .eq('id_driver', _currentDriverId!)
          .single();

      final driverName = driverData['nama'] as String;

      // 3️⃣ CALL EDGE FUNCTION
      final response = await _supabase.functions.invoke(
        'send-tracking-notification',
        body: {
          'orderId': _currentOrderId,
          'userId': customerId,
          'driverName': driverName,
          'status': _currentStatus,
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (response.status == 200) {
        print('📲 Notification sent successfully');
      } else {
        print('⚠️ Notification failed: ${response.status}');
      }

    } catch (e) {
      print('⚠️ Error sending notification: $e');
      // Don't throw - notification failure shouldn't stop tracking
    }
  }

  // 📊 GETTER - CEK STATUS TRACKING
  bool get isTracking => _isTracking;
  String? get currentDriverId => _currentDriverId;
  String? get currentOrderId => _currentOrderId;
  String? get currentStatus => _currentStatus;
  Position? get lastPosition => _lastPosition;
}