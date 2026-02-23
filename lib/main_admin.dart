// ============================================================================
// MAIN ADMIN - Entry Point for Admin App 
// Build command: flutter run --flavor admin -t lib/main_admin.dart -d web-server
// ============================================================================

import 'package:flutter/material.dart';
import 'package:sidrive/app_config.dart';
import 'package:sidrive/app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:sidrive/config/constants.dart'; 
import 'package:sidrive/services/storage_service.dart';
import 'package:sidrive/services/connectivity_service.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/user_provider.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('🔥 ========================================');
    debugPrint('🔥 Initializing Admin App Services...');
    debugPrint('🔥 ========================================');

    // 1. SET FLAVOR
    AppConfig.setFlavor(AppFlavor.admin);
    debugPrint('   ✅ Flavor set: ${AppConfig.flavor}');
    debugPrint('   ✅ Is Admin: ${AppConfig.isAdmin}');

    // 2. Initialize locale data for date formatting
    await initializeDateFormatting('id_ID', null);
    debugPrint('   ✅ Locale initialized');

    // 3. SUPABASE - CRITICAL! Harus diinit sebelum app jalan
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    debugPrint('   ✅ Supabase initialized');

    // 4. STORAGE
    await StorageService.init();
    debugPrint('   ✅ Storage initialized');

    await ConnectivityService().initialize();
    debugPrint('   ✅ Connectivity Service ready');

    debugPrint('🔥 All Admin Services Initialized!');
    debugPrint('🔥 ========================================');

  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR during admin initialization:');
    debugPrint('❌ Error: $e');
    debugPrint('❌ Stack: $stackTrace');
    // Tetap jalankan app meskipun ada error
  }


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // ... existing providers lain kalau ada
      ],
      child: const MyApp(),
    ),
  );
}


// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025