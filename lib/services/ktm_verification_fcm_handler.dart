// ============================================================================
// KTM_VERIFICATION_FCM_HANDLER.DART
// Handler untuk FCM notification terkait KTM verification
// ============================================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sidrive/app.dart' show navigatorKey;

class KtmVerificationFcmHandler {
  
  /// Handle notification untuk KTM verification approval/rejection
  static void handleKtmVerificationNotification(RemoteMessage message) {
    debugPrint('📨 [KTM_FCM] Handling KTM verification notification');
    debugPrint('   Data: ${message.data}');
    
    final type = message.data['type'] as String?;
    final status = message.data['status'] as String?;
    
    if (type != 'ktm_verification') {
      debugPrint('⚠️ [KTM_FCM] Not a KTM verification notification');
      return;
    }
    
    if (status == 'approved') {
      _handleApproval(message);
    } else if (status == 'rejected') {
      _handleRejection(message);
    }
  }
  
  /// Handle approval notification
  static void _handleApproval(RemoteMessage message) {
    debugPrint('✅ [KTM_FCM] KTM Verification APPROVED');
    
    // Auto redirect ke register form
    if (navigatorKey.currentState != null) {
      // Get roles dari notification data (format: "customer,driver")
      final rolesString = message.data['roles'] as String? ?? 'customer';
      final roles = rolesString.split(',');
      
      navigatorKey.currentState?.pushReplacementNamed(
        '/register/form-multi',
        arguments: roles,
      );
    } else {
      debugPrint('⚠️ [KTM_FCM] Navigator not ready');
    }
  }
  
  /// Handle rejection notification
  static void _handleRejection(RemoteMessage message) {
    debugPrint('❌ [KTM_FCM] KTM Verification REJECTED');
    
    final reason = message.data['reason'] as String? ?? 'Foto KTM tidak valid';
    
    // Show dialog
    if (navigatorKey.currentState != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text('Verifikasi KTM Ditolak'),
          content: Text(
            'Alasan penolakan:\n\n$reason\n\n'
            'Silakan upload foto KTM yang lebih jelas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                navigatorKey.currentState?.pushNamed('/nim-verification');
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
  }
  
  /// Check if notification is KTM verification type
  static bool isKtmVerificationNotification(Map<String, dynamic> data) {
    return data['type'] == 'ktm_verification';
  }
}

