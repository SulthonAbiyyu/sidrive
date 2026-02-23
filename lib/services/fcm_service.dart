import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/app.dart' show navigatorKey;
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:sidrive/services/ktm_verification_fcm_handler.dart'; 

/// 🔥 FCM Service - PRODUCTION READY VERSION
class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  static bool _isInitialized = false;
  static String? _pendingPayload;
  
  /// ✅ Initialize FCM
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ FCM already initialized');
      return;
    }
    
    print('🔥 ========================================');
    print('🔥 [FCM] Initializing...');
    print('🔥 ========================================');
    
    try {
      // 1. Request permission FIRST
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print('❌ Notification permission DENIED');
      }
      
      // 2. Initialize local notifications BEFORE anything else
      await _initializeLocalNotifications();
      
      // 3. Get FCM token DENGAN RETRY
      await _getTokenWithRetry();
      
      // 4. Save token to Supabase
      if (_fcmToken != null) {
        await _saveFCMTokenToSupabase(_fcmToken!);
      } else {
        print('⚠️ FCM Token is NULL after retry! User won\'t receive notifications!');
      }
      
      // 5. Token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _saveFCMTokenToSupabase(newToken);
      });
      
      // 6. Foreground messages - SHOW NOTIFICATION
      FirebaseMessaging.onMessage.listen((message) {
        print('📨 [FOREGROUND] Message received');
        print('   Title: ${message.notification?.title}');
        print('   Body: ${message.notification?.body}');
        print('   Data: ${message.data}');
        if (KtmVerificationFcmHandler.isKtmVerificationNotification(message.data)) {
            KtmVerificationFcmHandler.handleKtmVerificationNotification(message);
          } else {
            _showLocalNotification(message);
          }
        });
      
      // 7. Notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print('👆 [BACKGROUND TAP] Opening app');
        if (KtmVerificationFcmHandler.isKtmVerificationNotification(message.data)) {
            KtmVerificationFcmHandler.handleKtmVerificationNotification(message);
          } else {
            _handleNotificationTap(message);
          }
        });
      
      // 8. Check if app opened from terminated state
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('👆 [TERMINATED TAP] Opening app from notification');
        _handleNotificationTap(initialMessage);
      }
      
      // 9. Process pending payload
      if (_pendingPayload != null && navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushNamed(
          '/order/tracking',
          arguments: {'id_pesanan': _pendingPayload},
        );
        _pendingPayload = null;
      }
      
      _isInitialized = true;
      print('✅ [FCM] Initialization complete');
      
    } catch (e, stackTrace) {
      print('❌ [FCM] Initialization error: $e');
      print('Stack: $stackTrace');
    }
  }
  
  /// 🔄 Get FCM Token dengan RETRY mechanism
  static Future<void> _getTokenWithRetry() async {
    print('🔑 Getting FCM token...');
    
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        _fcmToken = await _firebaseMessaging.getToken();
        
        if (_fcmToken != null && _fcmToken!.isNotEmpty) {
          print('✅ FCM Token obtained (attempt $attempt): $_fcmToken');
          return;
        }
        
        print('⚠️ FCM Token is null/empty, retrying... (attempt $attempt/3)');
        
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: 2 * attempt));
        }
        
      } catch (e) {
        print('❌ Error getting token (attempt $attempt): $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }
    
    print('❌ CRITICAL: Failed to get FCM token after 3 attempts!');
    print('❌ User will NOT receive push notifications!');
  }
  
  /// 🔔 Request notification permission
  static Future<NotificationSettings> _requestPermission() async {
    print('🔔 Requesting notification permission...');
    
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission GRANTED');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Notification permission PROVISIONAL');
    } else {
      print('❌ Notification permission DENIED');
    }
    
    return settings;
  }
  
  /// 🔧 Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    print('🔧 Initializing local notifications...');
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('📲 Local notification tapped: ${details.payload}');
        
        if (details.payload != null) {
          final type = details.payload!.split(':')[0];
          final orderId = details.payload!.split(':')[1];
          
          if (navigatorKey.currentState != null) {
            if (type == 'new_order') {
              navigatorKey.currentState?.pushNamed('/pesanan');
            } else {
              navigatorKey.currentState?.pushNamed(
                '/order/tracking',
                arguments: {'id_pesanan': orderId},
              );
            }
          } else {
            print('⚠️ Navigator not ready, saving payload for later');
            _pendingPayload = details.payload;
          }
        }
      },
    );
    
    const trackingChannel = AndroidNotificationChannel(
      'tracking_channel',
      'Live Tracking',
      description: 'Notifikasi tracking pesanan real-time',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );
    
    // CREATE NEW ORDER CHANNEL - DENGAN SOUND & VIBRATION LEBIH KUAT
    const newOrderChannel = AndroidNotificationChannel(
      'new_order_channel',
      'Pesanan Baru',
      description: 'Notifikasi pesanan masuk untuk driver',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color(0xFFFF6B9D),
    );
    
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      try {
        await androidPlugin.deleteNotificationChannel('tracking_channel');
        await androidPlugin.deleteNotificationChannel('new_order_channel');
        print('🗑️ Old channels deleted');
      } catch (e) {
        // Channel belum ada, skip
      }
      
      await androidPlugin.createNotificationChannel(trackingChannel);
      await androidPlugin.createNotificationChannel(newOrderChannel);
      print('✅ Android notification channels created');
      
      try {
        final canSchedule = await androidPlugin.requestExactAlarmsPermission();
        if (canSchedule == true) {
          print('✅ Exact alarms permission GRANTED');
        } else {
          print('⚠️ Exact alarms permission DENIED (not critical)');
        }
      } catch (e) {
        print('⚠️ Exact alarm permission not available (Android < 13)');
      }
      
    } else {
      print('❌ Android plugin is NULL!');
      print('⚠️ Notifications may not work properly on this device!'); 
    }
    
    print('✅ Local notifications initialized');
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    print('📢 ========================================');
    print('📢 Showing local notification');
    print('📢 ========================================');
    
    try {
      final notification = message.notification;
      final data = message.data;
      
      if (notification == null && data.isEmpty) {
        print('⚠️ No notification payload AND no data, skipping');
        return;
      }
      
      final type = data['type'] ?? 'tracking_update';
      final title = notification?.title ?? data['title'] ?? 'SiDrive';
      final body = notification?.body ?? data['body'] ?? 'Update pesanan';
      final orderId = data['orderId'] ?? '';
      
      print('   Type: $type');
      print('   Title: $title');
      print('   Body: $body');
      print('   OrderId: $orderId');
      
      // ✅ FIX: PASTIKAN NOTIFICATION MUNCUL
      if (type == 'new_order') {
        print('🔔 NEW ORDER NOTIFICATION - FORCING SHOW');
        await _showNewOrderNotification(title, body, data);
      } else {
        await _showTrackingNotification(title, body, data);
      }
      
      print('========================================');
      
    } catch (e, stackTrace) {
      print('❌ Error showing notification: $e');
      print('Stack: $stackTrace');
    }
  }

  static Future<void> _showNewOrderNotification(
    String title, 
    String body, 
    Map<String, dynamic> data
  ) async {
    final orderId = data['orderId'] ?? '';
    final jenisKendaraan = data['jenisKendaraan'] ?? 'motor';
    final jarak = data['jarak'] ?? '0';
    final ongkir = data['ongkir'] ?? '0';
    
    final androidDetails = AndroidNotificationDetails(
      'new_order_channel',
      'Pesanan Baru',
      channelDescription: 'Notifikasi pesanan masuk untuk driver',
      importance: Importance.max,
      priority: Priority.max,
      
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFFFF6B9D),
      
      playSound: true,
      enableVibration: true,
      sound: null,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        summaryText: '$jarak km • Rp $ongkir',
      ),
      
      ongoing: false,
      autoCancel: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      
      tag: 'new_order_$orderId',
      
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      
      ledColor: const Color(0xFFFF6B9D),
      ledOnMs: 1000,
      ledOffMs: 500,
      
      ticker: 'Pesanan $jenisKendaraan baru masuk',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
      sound: 'default',
    );
    
    final notificationId = orderId.hashCode.abs();
    
    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'new_order:$orderId',
    );
    
    print('✅ New order notification shown! (ID: $notificationId)');
  }

  static Future<void> _showTrackingNotification(
    String title, 
    String body, 
    Map<String, dynamic> data
  ) async {
    final status = data['status'] ?? 'diterima';
    final orderId = data['orderId'] ?? '';
    final timestamp = data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final progress = _calculateProgress(status);
    final progressPercent = (progress * 100).toInt();
    
    print('   Progress: $progressPercent%');
    
    final androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'Live Tracking',
      channelDescription: 'Notifikasi tracking pesanan real-time',
      importance: Importance.high,
      priority: Priority.high,
      
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      
      playSound: true,
      enableVibration: true,
      sound: null,
      
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        summaryText: '$progressPercent% Selesai',
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
      
      ongoing: status != 'selesai',
      autoCancel: status == 'selesai',
      showWhen: true,
      when: int.tryParse(timestamp) ?? DateTime.now().millisecondsSinceEpoch,
      
      category: AndroidNotificationCategory.transport,
      visibility: NotificationVisibility.public,
      
      tag: 'order_$orderId',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );
    
    final notificationId = orderId.hashCode.abs();
    
    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'tracking:$orderId',
    );
    
    print('✅ Tracking notification shown! (ID: $notificationId)');
  }
// ✅ COPAS SAMPAI SINI
  
  /// 📊 Calculate progress based on status
  static double _calculateProgress(String status) {
    switch (status) {
      case 'diterima': return 0.15;
      case 'menuju_pickup': return 0.35;
      case 'sampai_pickup': return 0.50;
      case 'customer_naik': return 0.60;
      case 'perjalanan': return 0.80;
      case 'sampai_tujuan': return 0.95;
      case 'selesai': return 1.0;
      default: return 0.0;
    }
  }
  
  /// 👆 Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 [FCM] Notification tapped');
    print('   Data: ${message.data}');
    
    final orderId = message.data['orderId'];
    if (orderId != null && orderId.isNotEmpty) {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushNamed(
          '/order/tracking',
          arguments: {'id_pesanan': orderId},
        );
      } else {
        print('⚠️ Navigator not ready, saving payload');
        _pendingPayload = orderId;
      }
    }
  }
  
  /// 💾 Save FCM token to Supabase
  static Future<void> _saveFCMTokenToSupabase(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        print('⚠️ User not logged in, skip saving FCM token');
        return;
      }
      
      await supabase.from('users').update({
        'fcm_token': token,
        'fcm_token_updated_at': DateTime.now().toIso8601String(),
      }).eq('id_user', userId);
      
      print('✅ FCM token saved to Supabase');
      
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }
  
  /// 📤 Get current FCM token
  static String? get fcmToken => _fcmToken;
  
  /// 🔄 Refresh FCM token
  static Future<void> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      await _getTokenWithRetry();
      
      if (_fcmToken != null) {
        await _saveFCMTokenToSupabase(_fcmToken!);
        print('✅ FCM token refreshed: $_fcmToken');
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
    }
  }

  /// 🧪 Test notification (untuk debugging)
  static Future<void> testNotification() async {
    print('🧪 Testing notification...');
    
    await _showNewOrderNotification(
      'Test Pesanan Baru',
      'Ini adalah test notifikasi • 5.0 km • Rp 15.000',
      {
        'orderId': 'TEST-123',
        'jenisKendaraan': 'motor',
        'jarak': '5.0',
        'ongkir': '15000',
      },
    );
    
    print('✅ Test notification sent');
  }
}