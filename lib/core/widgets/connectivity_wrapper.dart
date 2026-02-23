// ============================================================================
// CONNECTIVITY WRAPPER - GLOBAL UI FOR CONNECTIVITY STATUS
// File: lib/widgets/connectivity_wrapper.dart
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sidrive/services/connectivity_service.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  
  bool _isConnected = true;
  bool _showBanner = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INIT CONNECTIVITY
  // ═══════════════════════════════════════════════════════════════════════════
  void _initConnectivity() {
    // Set initial state
    _isConnected = _connectivityService.isConnected;
    
    // Listen to changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        debugPrint('🔔 [ConnectivityWrapper] Received: $isConnected');
        setState(() {
          _isConnected = isConnected;
          _showBanner = true;
        });

        // Auto-hide banner after 3 seconds if connected
        if (isConnected) {
          _hideTimer?.cancel();
          _hideTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showBanner = false;
              });
            }
          });
        } else {
          // Keep showing if disconnected
          _hideTimer?.cancel();
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD BANNER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBanner() {
    if (!_showBanner) return const SizedBox.shrink();

    final isConnected = _isConnected;
    final bgColor = isConnected ? Colors.green : Colors.red;
    final icon = isConnected ? Icons.wifi : Icons.wifi_off;
    final message = isConnected 
        ? '✅ Koneksi Internet Terhubung' 
        : '❌ Tidak Ada Koneksi Internet';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isConnected)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  setState(() {
                    _showBanner = false;
                  });
                  _hideTimer?.cancel();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBanner(),
        Expanded(child: widget.child),
      ],
    );
  }
}