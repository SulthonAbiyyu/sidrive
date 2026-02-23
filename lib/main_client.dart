import 'package:flutter/material.dart';
import 'package:sidrive/app_config.dart';
import 'package:sidrive/app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sidrive/services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sidrive/services/order_timer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/config/constants.dart';
import 'package:sidrive/services/storage_service.dart';
import 'package:sidrive/services/connectivity_service.dart'; 
import 'package:sidrive/services/session_service.dart';
import 'package:sidrive/services/app_lifecycle_manager.dart';
import 'dart:typed_data';


// ============================================================================
// ✅ GLOBAL NOTIFICATION PLUGIN (untuk background handler)
// ============================================================================
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ============================================================================
// ✅ BACKGROUND HANDLER - RECEIVES ALL NOTIFICATIONS WHEN APP KILLED/BACKGROUND
// ============================================================================
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print('📢 ========================================');
  print('📢 [BACKGROUND] FCM Message Received');
  print('📢 ========================================');
  
  await Firebase.initializeApp();
  
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  print('   Type: ${message.data['type']}');
  
  final type = message.data['type'] ?? 'tracking_update';
  
  if (type == 'new_order') {
    await _showBackgroundNewOrderNotification(message);
  } else {
    await _showBackgroundNotification(message);
  }
  
  print('📢 Background handler DONE');
}

// ============================================================================
// ✅ SHOW BACKGROUND NOTIFICATION
// ============================================================================
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  try {
    print('📲 Initializing background notification...');
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('👆 Background notification tapped: ${details.payload}');
      },
    );
    
    const channel = AndroidNotificationChannel(
      'tracking_channel',
      'Live Tracking',
      description: 'Notifikasi tracking pesanan real-time',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );
    
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      print('✅ Background channel created');
    } else {
      print('⚠️ Android plugin is null in background!');
    }
    
    final notification = message.notification;
    final data = message.data;
    
    final title = notification?.title ?? data['title'] ?? 'SiDrive';
    final body = notification?.body ?? data['body'] ?? 'Update pesanan';
    final status = data['status'] ?? 'diterima';
    final orderId = data['orderId'] ?? '';
    final timestamp = data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final progress = _calculateProgressBackground(status);
    final progressPercent = (progress * 100).toInt();
    
    print('   Progress: $progressPercent%');
    print('   Status: $status');
    print('   OrderID: $orderId');
    
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
      color: const Color(0xFF4CAF50),
      
      playSound: true,
      enableVibration: true,
      sound: null,
      
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        summaryText: '$progressPercent% Selesai',
      ),
      
      ongoing: status != 'selesai',
      autoCancel: status == 'selesai',
      showWhen: true,
      when: int.tryParse(timestamp) ?? DateTime.now().millisecondsSinceEpoch,
      
      tag: 'order_$orderId',
      
      category: AndroidNotificationCategory.transport,
      visibility: NotificationVisibility.public,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );
    
    final notificationId = orderId.hashCode.abs();
    
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: orderId,
    );
    
    print('✅ Background notification shown: $progressPercent% (ID: $notificationId)');
    
  } catch (e, stackTrace) {
    print('❌ Background notification error: $e');
    print('Stack: $stackTrace');
  }
}

Future<void> _showBackgroundNewOrderNotification(RemoteMessage message) async {
  try {
    print('🔔 Showing background NEW ORDER notification...');
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('👆 Background notification tapped: ${details.payload}');
      },
    );
    
    const channel = AndroidNotificationChannel(
      'new_order_channel',
      'Pesanan Baru',
      description: 'Notifikasi pesanan masuk untuk driver',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );
    
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      print('✅ Background new order channel created');
    }
    
    final notification = message.notification;
    final data = message.data;
    
    final title = notification?.title ?? data['title'] ?? 'SiDrive';
    final body = notification?.body ?? data['body'] ?? 'Pesanan baru';
    final orderId = data['orderId'] ?? '';
    final jenisKendaraan = data['jenisKendaraan'] ?? 'motor';
    final jarak = data['jarak'] ?? '0';
    final ongkir = data['ongkir'] ?? '0';
    
    print('   Vehicle: $jenisKendaraan');
    print('   Distance: $jarak km');
    print('   Price: Rp $ongkir');
    
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
    );
    
    final notificationId = orderId.hashCode.abs();
    
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'new_order:$orderId',
    );
    
    print('✅ Background new order notification shown! (ID: $notificationId)');
    
  } catch (e, stackTrace) {
    print('❌ Background new order notification error: $e');
    print('Stack: $stackTrace');
  }
}

// ============================================================================
// ✅ CALCULATE PROGRESS
// ============================================================================
double _calculateProgressBackground(String status) {
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

// ============================================================================
// ✅ MAIN FUNCTION - URUTAN YANG BENAR!
// ============================================================================
void main() async {
  // 0. BINDING FLUTTER
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  try {
    debugPrint('🎮 ========================================');
    debugPrint('🎮 Initializing Client App Services...');
    debugPrint('🎮 ========================================');

    // ⚡ CRITICAL: BACKGROUND HANDLER HARUS DULU!
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    debugPrint('   ✅ Background handler registered FIRST');

    // 1. FIREBASE INIT
    await Firebase.initializeApp();
    debugPrint('   ✅ Firebase initialized');

    // 2. SUPABASE
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    debugPrint('   ✅ Supabase initialized');

    // 2.5. SESSION RESTORE ⬅️ TAMBAHAN BARU!
    await SessionService.restoreSession();
    debugPrint('   ✅ Session restored (if available)');

    // 3. STORAGE
    await StorageService.init();
    debugPrint('   ✅ Storage initialized');

    // 4. FCM SERVICE
    await FCMService.initialize();
    debugPrint('   ✅ FCM Service ready');
    
    final token = FCMService.fcmToken;
    if (token != null) {
      debugPrint('   🔑 FCM Token: ${token.substring(0, 30)}...');
    } else {
      debugPrint('   ⚠️ FCM Token is NULL!');
    }

    // 5. ORDER TIMER
    OrderTimerService();
    debugPrint('   ✅ Order Timer Service ready');

    await ConnectivityService().initialize();
    debugPrint('   ✅ Connectivity Service ready');

    // 6. LIFECYCLE MANAGER ⬅️ TAMBAHAN BARU!
    AppLifecycleManager().initialize();
    AppLifecycleManager().setOnAppResumed(() async {
      debugPrint('🔄 App resumed - refreshing session...');
      await SessionService.refreshSessionIfNeeded();
    });
    debugPrint('   ✅ Lifecycle Manager ready');
    
    debugPrint('🎮 All Services Initialized!');
    debugPrint('🎮 ========================================');
    
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR during initialization:');
    debugPrint('❌ Error: $e');
    debugPrint('❌ Stack: $stackTrace');
  }

  // 7. SET FLAVOR & RUN APP
  AppConfig.setFlavor(AppFlavor.client);
  runApp(const MyApp());
}


// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025