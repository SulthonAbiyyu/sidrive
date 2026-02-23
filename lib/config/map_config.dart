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
import 'dart:ui' as ui;
import 'dart:typed_data';

// ============================================================================
// ✅ GLOBAL NOTIFICATION PLUGIN
// ============================================================================
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ============================================================================
// 🎨 BACKGROUND HANDLER - BEAUTIFUL NOTIFICATIONS EVEN IN BACKGROUND!
// ============================================================================
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print('🎨 ========================================');
  print('🎨 [BACKGROUND] Beautiful Notification Incoming!');
  print('🎨 ========================================');
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
  // Show BEAUTIFUL notification
  await _showBeautifulBackgroundNotification(message);
  print('✅ Beautiful background notification sent!');
}

// ============================================================================
// 🎨 SHOW BEAUTIFUL BACKGROUND NOTIFICATION with Custom Canvas
// ============================================================================
Future<void> _showBeautifulBackgroundNotification(RemoteMessage message) async {
  try {
    print('🎨 Creating beautiful background notification...');
    
    // Initialize
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
    
    // Create channel
    const channel = AndroidNotificationChannel(
      'sidrive_tracking',
      '🚗 SiDrive Live Tracking',
      description: 'Real-time order tracking dengan visual menarik',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color(0xFF4CAF50),
    );
    
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      print('✅ Background channel created');
    }
    
    // Extract data
    final data = message.data;
    final notification = message.notification;
    
    final title = notification?.title ?? data['title'] ?? 'SiDrive';
    final body = notification?.body ?? data['body'] ?? 'Update pesanan';
    final status = data['status'] ?? 'diterima';
    final orderId = data['orderId'] ?? '';
    final driverName = data['driverName'] ?? 'Driver';
    
    print('📊 Status: $status');
    print('👤 Driver: $driverName');
    
    // 🎨 Generate beautiful custom image
    final customImage = await _generateBeautifulNotificationImage(
      status: status,
      driverName: driverName,
      body: body,
    );
    
    if (customImage == null) {
      print('⚠️ Failed to generate image, using standard');
      await _showStandardBackgroundNotification(message);
      return;
    }
    
    print('✅ Beautiful image generated!');
    
    // Build BEAUTIFUL notification
    final androidDetails = AndroidNotificationDetails(
      'sidrive_tracking',
      '🚗 SiDrive Live Tracking',
      channelDescription: 'Real-time order tracking',
      importance: Importance.high,
      priority: Priority.high,
      
      // 🎨 CUSTOM BEAUTIFUL IMAGE
      styleInformation: BigPictureStyleInformation(
        ByteArrayAndroidBitmap(customImage),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        contentTitle: title,
        summaryText: _getStatusEmoji(status) + ' ' + _getStatusText(status),
        htmlFormatContentTitle: true,
        htmlFormatSummaryText: true,
      ),
      
      // Colorful
      color: _getStatusColor(status),
      colorized: true,
      
      // Sound & vibration
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      
      // Behavior
      ongoing: status != 'selesai',
      autoCancel: status == 'selesai',
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      
      tag: 'order_$orderId',
      category: AndroidNotificationCategory.transport,
      visibility: NotificationVisibility.public,
      
      // Actions
      actions: _getNotificationActions(status),
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
    
    print('✅ Beautiful background notification shown! 🎉');
    
  } catch (e, stackTrace) {
    print('❌ Background notification error: $e');
    print('Stack: $stackTrace');
    await _showStandardBackgroundNotification(message);
  }
}

// ============================================================================
// 🎨 GENERATE BEAUTIFUL NOTIFICATION IMAGE with Canvas
// ============================================================================
Future<Uint8List?> _generateBeautifulNotificationImage({
  required String status,
  required String driverName,
  required String body,
}) async {
  try {
    const width = 1024.0;
    const height = 450.0;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    
    // 🎨 BACKGROUND GRADIENT
    final bgGradient = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(0, height),
      [
        _getStatusColor(status).withOpacity(0.15),
        Colors.white,
      ],
    );
    
    final bgPaint = Paint()..shader = bgGradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);
    
    // 🚗 CAR ICON
    _drawCarIcon(canvas, 40, 40);
    
    // 📊 BEAUTIFUL PROGRESS BAR with MARKER & GLOW
    final progress = _calculateProgress(status);
    _drawBeautifulProgressBar(canvas, width, height, progress, status);
    
    // 📝 DRIVER NAME (bold)
    _drawText(
      canvas: canvas,
      text: '🚗 $driverName',
      x: 140,
      y: 50,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    
    // 📝 STATUS TEXT (colorful)
    _drawText(
      canvas: canvas,
      text: _getStatusText(status),
      x: 140,
      y: 95,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: _getStatusColor(status),
    );
    
    // 📝 BODY TEXT
    _drawText(
      canvas: canvas,
      text: body,
      x: 60,
      y: height - 100,
      fontSize: 24,
      color: Colors.black54,
    );
    
    // 🎯 PERCENTAGE (big & bold)
    final percentage = (progress * 100).toInt();
    _drawText(
      canvas: canvas,
      text: '$percentage%',
      x: width - 120,
      y: 50,
      fontSize: 42,
      fontWeight: FontWeight.bold,
      color: _getStatusColor(status),
    );
    
    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData?.buffer.asUint8List();
    
  } catch (e) {
    print('❌ Error generating beautiful image: $e');
    return null;
  }
}

// ============================================================================
// 🚗 DRAW CAR ICON
// ============================================================================
void _drawCarIcon(Canvas canvas, double x, double y) {
  final carPaint = Paint()
    ..color = const Color(0xFF4CAF50)
    ..style = PaintingStyle.fill;
  
  // Car body
  final carPath = Path()
    ..moveTo(x, y + 30)
    ..lineTo(x + 20, y + 10)
    ..lineTo(x + 50, y + 10)
    ..lineTo(x + 70, y + 30)
    ..lineTo(x + 70, y + 50)
    ..lineTo(x, y + 50)
    ..close();
  
  canvas.drawPath(carPath, carPaint);
  
  // Wheels
  final wheelPaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(Offset(x + 15, y + 50), 8, wheelPaint);
  canvas.drawCircle(Offset(x + 55, y + 50), 8, wheelPaint);
  
  // Window
  final windowPaint = Paint()
    ..color = Colors.white.withOpacity(0.7)
    ..style = PaintingStyle.fill;
  
  final windowPath = Path()
    ..moveTo(x + 25, y + 15)
    ..lineTo(x + 45, y + 15)
    ..lineTo(x + 50, y + 25)
    ..lineTo(x + 20, y + 25)
    ..close();
  
  canvas.drawPath(windowPath, windowPaint);
}

// ============================================================================
// 📊 DRAW BEAUTIFUL PROGRESS BAR with MARKER
// ============================================================================
void _drawBeautifulProgressBar(
  Canvas canvas,
  double width,
  double height,
  double progress,
  String status,
) {
  const barY = 200.0;
  const barHeight = 20.0;
  const margin = 60.0;
  final barWidth = width - (margin * 2);
  
  // Background track (gray with shadow)
  final bgShadow = Paint()
    ..color = Colors.black.withOpacity(0.1)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  
  final bgShadowRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(margin, barY + 3, barWidth, barHeight),
    const Radius.circular(10),
  );
  canvas.drawRRect(bgShadowRect, bgShadow);
  
  final bgPaint = Paint()
    ..color = Colors.grey.shade300
    ..style = PaintingStyle.fill;
  
  final bgRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(margin, barY, barWidth, barHeight),
    const Radius.circular(10),
  );
  canvas.drawRRect(bgRect, bgPaint);
  
  // Progress fill (beautiful gradient)
  final progressWidth = barWidth * progress;
  final progressGradient = ui.Gradient.linear(
    Offset(margin, barY),
    Offset(margin + progressWidth, barY),
    [
      _getStatusColor(status),
      _getStatusColor(status).withOpacity(0.7),
      _getStatusColor(status),
    ],
    [0.0, 0.5, 1.0],
  );
  
  final progressPaint = Paint()
    ..shader = progressGradient
    ..style = PaintingStyle.fill;
  
  final progressRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(margin, barY, progressWidth, barHeight),
    const Radius.circular(10),
  );
  canvas.drawRRect(progressRect, progressPaint);
  
  // 🎯 MARKER with GLOW EFFECT (like inDrive!)
  final markerX = margin + (barWidth * progress);
  final markerY = barY + barHeight / 2;
  
  // Outer glow (largest)
  final outerGlow = Paint()
    ..color = _getStatusColor(status).withOpacity(0.15)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
  canvas.drawCircle(Offset(markerX, markerY), 30, outerGlow);
  
  // Middle glow
  final middleGlow = Paint()
    ..color = _getStatusColor(status).withOpacity(0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  canvas.drawCircle(Offset(markerX, markerY), 20, middleGlow);
  
  // Inner glow
  final innerGlow = Paint()
    ..color = _getStatusColor(status).withOpacity(0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  canvas.drawCircle(Offset(markerX, markerY), 15, innerGlow);
  
  // Main marker (solid color)
  final markerPaint = Paint()
    ..color = _getStatusColor(status)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(markerX, markerY), 15, markerPaint);
  
  // White border
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  canvas.drawCircle(Offset(markerX, markerY), 15, borderPaint);
  
  // Inner white circle
  final innerPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(markerX, markerY), 8, innerPaint);
  
  // Inner dot (colored)
  final dotPaint = Paint()
    ..color = _getStatusColor(status)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(markerX, markerY), 4, dotPaint);
  
  // START & END MARKERS
  _drawText(
    canvas: canvas,
    text: '📍',
    x: margin - 20,
    y: barY - 20,
    fontSize: 32,
  );
  
  _drawText(
    canvas: canvas,
    text: '🎯',
    x: margin + barWidth - 10,
    y: barY - 20,
    fontSize: 32,
  );
  
  // Labels
  _drawText(
    canvas: canvas,
    text: 'Start',
    x: margin - 15,
    y: barY + 30,
    fontSize: 18,
    color: Colors.black54,
  );
  
  _drawText(
    canvas: canvas,
    text: 'Finish',
    x: margin + barWidth - 30,
    y: barY + 30,
    fontSize: 18,
    color: Colors.black54,
  );
}

// ============================================================================
// 📝 DRAW TEXT on Canvas
// ============================================================================
void _drawText({
  required Canvas canvas,
  required String text,
  required double x,
  required double y,
  double fontSize = 24,
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  final textSpan = TextSpan(
    text: text,
    style: TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Roboto',
    ),
  );
  
  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(canvas, Offset(x, y));
}

// ============================================================================
// 🎨 HELPER FUNCTIONS
// ============================================================================
Color _getStatusColor(String status) {
  switch (status) {
    case 'diterima': return const Color(0xFF2196F3);
    case 'menuju_pickup': return const Color(0xFFFF9800);
    case 'sampai_pickup': return const Color(0xFFFF5722);
    case 'customer_naik': return const Color(0xFF9C27B0);
    case 'perjalanan': return const Color(0xFF4CAF50);
    case 'sampai_tujuan': return const Color(0xFF00BCD4);
    case 'selesai': return const Color(0xFF8BC34A);
    default: return const Color(0xFF9E9E9E);
  }
}

String _getStatusText(String status) {
  switch (status) {
    case 'diterima': return 'Pesanan Diterima';
    case 'menuju_pickup': return 'Menuju Lokasi Anda';
    case 'sampai_pickup': return 'Driver Sudah Tiba';
    case 'customer_naik': return 'Perjalanan Dimulai';
    case 'perjalanan': return 'Dalam Perjalanan';
    case 'sampai_tujuan': return 'Sampai di Tujuan';
    case 'selesai': return 'Pesanan Selesai';
    default: return 'Update Pesanan';
  }
}

String _getStatusEmoji(String status) {
  switch (status) {
    case 'diterima': return '✅';
    case 'menuju_pickup': return '🚗';
    case 'sampai_pickup': return '📍';
    case 'customer_naik': return '👤';
    case 'perjalanan': return '🛣️';
    case 'sampai_tujuan': return '🎯';
    case 'selesai': return '🎉';
    default: return '📦';
  }
}

List<AndroidNotificationAction> _getNotificationActions(String status) {
  if (status == 'selesai') {
    return [
      const AndroidNotificationAction(
        'rate',
        '⭐ Beri Rating',
        showsUserInterface: true,
      ),
    ];
  }
  return [
    const AndroidNotificationAction(
      'view',
      '👁️ Lihat Detail',
      showsUserInterface: true,
    ),
  ];
}

double _calculateProgress(String status) {
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
// 📢 FALLBACK: Standard Notification
// ============================================================================
Future<void> _showStandardBackgroundNotification(RemoteMessage message) async {
  try {
    final data = message.data;
    final notification = message.notification;
    
    final title = notification?.title ?? data['title'] ?? 'SiDrive';
    final body = notification?.body ?? data['body'] ?? 'Update pesanan';
    final status = data['status'] ?? 'diterima';
    final orderId = data['orderId'] ?? '';
    
    final progress = _calculateProgress(status);
    final progressPercent = (progress * 100).toInt();
    
    final androidDetails = AndroidNotificationDetails(
      'sidrive_tracking',
      '🚗 SiDrive Live Tracking',
      importance: Importance.high,
      priority: Priority.high,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      color: _getStatusColor(status),
      playSound: true,
      enableVibration: true,
      tag: 'order_$orderId',
    );
    
    await flutterLocalNotificationsPlugin.show(
      orderId.hashCode.abs(),
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: orderId,
    );
  } catch (e) {
    print('❌ Standard notification error: $e');
  }
}

// ============================================================================
// 🎮 MAIN FUNCTION
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  try {
    debugPrint('🎮 ========================================');
    debugPrint('🎮 Initializing Client App Services...');
    debugPrint('🎮 ========================================');

    // ⚡ CRITICAL: Background handler FIRST!
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    debugPrint('   ✅ Beautiful background handler registered');

    // 1. Firebase
    await Firebase.initializeApp();
    debugPrint('   ✅ Firebase initialized');

    // 2. Supabase
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    debugPrint('   ✅ Supabase initialized');

    // 3. Storage
    await StorageService.init();
    debugPrint('   ✅ Storage initialized');

    // 4. FCM Service
    await FCMService.initialize();
    debugPrint('   ✅ FCM Service ready');
    
    final token = FCMService.fcmToken;
    if (token != null) {
      debugPrint('   🔑 FCM Token: ${token.substring(0, 30)}...');
    } else {
      debugPrint('   ⚠️ FCM Token is NULL!');
    }

    // 5. Order Timer
    OrderTimerService();
    debugPrint('   ✅ Order Timer Service ready');
    
    debugPrint('🎮 All Services Initialized with BEAUTIFUL Notifications! 🎨');
    debugPrint('🎮 ========================================');
    
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR during initialization:');
    debugPrint('❌ Error: $e');
    debugPrint('❌ Stack: $stackTrace');
  }

  AppConfig.setFlavor(AppFlavor.client);
  runApp(const MyApp());
}