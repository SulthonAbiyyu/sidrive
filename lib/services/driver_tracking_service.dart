import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class DriverTrackingService {
  final _supabase = Supabase.instance.client;
  Timer? _trackingTimer;
  Position? _lastPosition;
  DateTime? _lastMovementTime;

  /// Start tracking driver location during delivery
  void startTracking({
    required String idPengiriman,
    required String idDriver,
  }) {
    print('📍 Starting driver tracking for pengiriman: $idPengiriman');

    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _updateDriverLocation(idPengiriman, idDriver);
    });
  }

  /// Stop tracking
  void stopTracking() {
    print('🛑 Stopping driver tracking');
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _lastPosition = null;
    _lastMovementTime = null;
  }

  /// Update driver location and check movement
  Future<void> _updateDriverLocation(String idPengiriman, String idDriver) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      bool hasMoved = false;
      double distanceMoved = 0;

      if (_lastPosition != null) {
        distanceMoved = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        hasMoved = distanceMoved > 10; // 10 meters threshold
      } else {
        hasMoved = true;
      }

      final now = DateTime.now();
      final locationWKT = 'POINT(${position.longitude} ${position.latitude})';

      await _supabase.from('pengiriman').update({
        'last_driver_location': locationWKT,
        'last_movement_time': hasMoved ? now.toIso8601String() : _lastMovementTime?.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id_pengiriman', idPengiriman);

      await _supabase.from('drivers').update({
        'current_location': locationWKT,
        'last_location_update': now.toIso8601String(),
      }).eq('id_driver', idDriver);

      if (hasMoved) {
        _lastMovementTime = now;
        print('✅ Driver moved ${distanceMoved.toStringAsFixed(1)}m');
      }

      _lastPosition = position;
    } catch (e) {
      print('❌ Error update driver location: $e');
    }
  }

  /// Calculate total distance traveled by driver   
  Future<double> calculateTotalDistanceTraveled({
    required String idPengiriman,
    String? pickupLocationWKT,
  }) async {
    try {
      final pengiriman = await _supabase
          .from('pengiriman')
          .select('last_driver_location')
          .eq('id_pengiriman', idPengiriman)
          .single();

      final currentLocationWKT = pengiriman['last_driver_location'] as String?;
      
      if (currentLocationWKT == null || pickupLocationWKT == null) {
        return 0.0;
      }

      final currentCoords = _parsePointWKT(currentLocationWKT);
      final pickupCoords = _parsePointWKT(pickupLocationWKT);

      if (currentCoords == null || pickupCoords == null) {
        return 0.0;
      }

      final distanceMeters = Geolocator.distanceBetween(
        pickupCoords['lat']!,
        pickupCoords['lng']!,
        currentCoords['lat']!,
        currentCoords['lng']!,
      );

      return distanceMeters / 1000;
    } catch (e) {
      print('❌ Error calculate distance: $e');
      return 0.0;
    }
  }

  Map<String, double>? _parsePointWKT(String wkt) {
    try {
      final regex = RegExp(r'POINT\(([^ ]+) ([^ ]+)\)');
      final match = regex.firstMatch(wkt);

      if (match != null) {
        return {
          'lng': double.parse(match.group(1)!),
          'lat': double.parse(match.group(2)!),
        };
      }
    } catch (e) {
      print('❌ Error parsing WKT: $e');
    }
    return null;
  }
}