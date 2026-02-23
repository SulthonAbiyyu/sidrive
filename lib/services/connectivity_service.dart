// ============================================================================
// CONNECTIVITY SERVICE - GLOBAL INTERNET MONITORING
// File: lib/services/connectivity_service.dart
// ============================================================================

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream controller untuk broadcast connectivity status
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  // Current status
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Connectivity plugin
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZE - Call once di main
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> initialize() async {
    debugPrint('🌐 [ConnectivityService] Initializing...');

    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _isConnected = _isConnectionActive(result);
    debugPrint('🌐 [ConnectivityService] Initial status: ${_isConnected ? "CONNECTED" : "DISCONNECTED"}');

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
      onError: (error) {
        debugPrint('❌ [ConnectivityService] Error: $error');
      },
    );

    debugPrint('✅ [ConnectivityService] Initialized!');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HANDLE CONNECTIVITY CHANGE
  // ═══════════════════════════════════════════════════════════════════════════
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = _isConnectionActive(results);

    debugPrint('🌐 [ConnectivityService] Connectivity changed:');
    debugPrint('   Previous: ${wasConnected ? "CONNECTED" : "DISCONNECTED"}');
    debugPrint('   Current: ${_isConnected ? "CONNECTED" : "DISCONNECTED"}');
    debugPrint('   Results: $results');

    // Only broadcast if status actually changed
    if (wasConnected != _isConnected) {
      debugPrint('🔔 [ConnectivityService] Broadcasting change: $_isConnected');
      _connectivityController.add(_isConnected);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK IF CONNECTION IS ACTIVE
  // ═══════════════════════════════════════════════════════════════════════════
  bool _isConnectionActive(List<ConnectivityResult> results) {
    // If any result is not "none", consider as connected
    return results.any((result) => 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════════════════════════════════════
  void dispose() {
    debugPrint('🌐 [ConnectivityService] Disposing...');
    _subscription?.cancel();
    _connectivityController.close();
  }
}