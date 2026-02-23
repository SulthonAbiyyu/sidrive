import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/core/theme/app_theme.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/providers/theme_provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/providers/notifikasi_provider.dart';
import 'package:sidrive/services/storage_service.dart';
import 'package:sidrive/core/widgets/connectivity_wrapper.dart'; 
import 'package:sidrive/providers/cart_provider.dart';

// Client Screens
import 'package:sidrive/screens/splash_screen.dart';
import 'package:sidrive/screens/onboarding_screen.dart';
import 'package:sidrive/screens/welcome_screen.dart';
import 'package:sidrive/screens/auth/login_screen.dart';
import 'package:sidrive/screens/auth/register_form_screen.dart';
import 'package:sidrive/screens/auth/success_screen.dart';
import 'package:sidrive/screens/customer/dashboard_customer.dart';
import 'package:sidrive/screens/driver/dashboard_driver.dart';
import 'package:sidrive/screens/umkm/dashboard_umkm.dart';
import 'package:sidrive/screens/customer/pages/order_ojek_screen_osm.dart';
import 'package:sidrive/screens/auth/role_selection_multi_screen.dart';
import 'package:sidrive/screens/auth/nim_verification_screen.dart';
import 'package:sidrive/screens/auth/request_driver_role_screen.dart';
import 'package:sidrive/screens/auth/request_umkm_role_screen.dart';
import 'package:sidrive/screens/profile/profile_tab.dart';
import 'package:sidrive/screens/notifikasi/notifikasi_page.dart';
import 'package:sidrive/screens/customer/pages/refund_history_page.dart';
import 'package:sidrive/screens/common/withdrawal_history_screen.dart';
import 'package:sidrive/screens/umkm/pages/profile_toko_screen.dart';
import 'package:sidrive/screens/umkm/pages/produk_umkm.dart';
import 'package:sidrive/screens/umkm/pages/add_edit_produk_screen.dart';
import 'package:sidrive/screens/umkm/pages/pendapatan_umkm_page.dart';
import 'package:sidrive/screens/umkm/pages/pesanan_umkm_page.dart';

// Admin Screens
import 'package:sidrive/screens/admin/admin_login_screen.dart';
import 'package:sidrive/screens/admin/admin_dashboard.dart';

// Flavors
import 'package:sidrive/app_config.dart';

// ============================================================================
// INITIALIZE APP
// ============================================================================
Future<void> initializeApp() async {
  await StorageService.init();
  
  runApp(const MyApp());
}

// Global Navigator Key untuk navigation dari FCM
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔥 APP FLAVOR: ${AppConfig.flavor}');
    debugPrint('🔥 IS ADMIN: ${AppConfig.isAdmin}');
    debugPrint('🔥 APP NAME: ${AppConfig.appName}');
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotifikasiProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()..loadCart()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return ConnectivityWrapper(
                child: MaterialApp(
                  navigatorKey: navigatorKey,
                  title: AppConfig.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeProvider.themeMode,
                  initialRoute: '/',
                  routes: {
                    // ╔══════════════════════════════════════════════════════════════╗
                    // SHARED ROUTES
                    // ╚══════════════════════════════════════════════════════════════╝
                    '/': (context) => const SplashScreen(),
                    
                    // ╔══════════════════════════════════════════════════════════════╗
                    // CLIENT ROUTES
                    // ╚══════════════════════════════════════════════════════════════╝
                    '/onboarding': (context) => const OnboardingScreen(),
                    '/welcome': (context) => const WelcomeScreen(),
                    '/login': (context) => const LoginScreen(),
                    '/customer/dashboard': (context) => const DashboardCustomer(),
                    '/driver/dashboard': (context) => const DashboardDriver(),
                    '/umkm/dashboard': (context) => const DashboardUmkm(),
                    '/umkm/profil-toko': (context) => const ProfilTokoScreen(),
                    '/umkm/produk': (context) => const ProdukUmkm(),
                    '/umkm/add-produk': (context) => const AddEditProdukScreen(),
                    '/umkm/pendapatan': (context) => const PendapatanUmkmPage(),
                    '/umkm/pesanan': (context) => const PesananUmkmPage(),
                    '/profile': (context) => const ProfileTab(),
                    '/pending': (context) => const PlaceholderPending(),
                    '/register/role-multi': (context) => RoleSelectionScreenMulti(),
                    '/request/driver': (context) => RequestDriverRoleScreen(),
                    '/request/umkm': (context) => RequestUmkmRoleScreen(),
                    '/order/ojek/motor': (context) => const OrderOjekScreenOsm(jenisKendaraan: 'motor'),
                    '/order/ojek/mobil': (context) => const OrderOjekScreenOsm(jenisKendaraan: 'mobil'),
                    '/notifikasi': (context) => const NotifikasiPage(),
                    '/refund-history': (context) => const RefundHistoryPage(),
                    '/wallet/history': (context) => const WithdrawalHistoryScreen(),

                    
                    
                    // ╔══════════════════════════════════════════════════════════════╗
                    // ADMIN ROUTES (Integrated - No separate page routes)
                    // ╚══════════════════════════════════════════════════════════════╝
                    '/admin/login': (context) => const AdminLoginScreen(),
                    '/admin/dashboard': (context) => const AdminDashboard(),
                  },
                  onGenerateRoute: (settings) {
                    debugPrint('🔍 Navigating to: ${settings.name}');
                    
                    // Client Routes with Arguments
                    if (settings.name == '/register/nim-multi') {
                      final roles = settings.arguments as List<String>;
                      return MaterialPageRoute(
                        builder: (context) => NimVerificationMultiScreen(roles: roles),
                      );
                    }
                    
                    if (settings.name == '/register/form-multi') {
                      final roles = settings.arguments as List<String>;
                      return MaterialPageRoute(
                        builder: (context) => RegisterFormScreen(roles: roles),
                      );
                    }
                    
                    if (settings.name == '/register/success-multi') {
                      final roles = settings.arguments as List<String>;
                      return MaterialPageRoute(
                        builder: (context) => SuccessScreen(roles: roles),
                      );
                    }
                    
                    if (settings.name == '/order/ojek') {
                      final jenis = settings.arguments as String;
                      return MaterialPageRoute(
                        builder: (context) => OrderOjekScreenOsm(jenisKendaraan: jenis),
                      );
                    }
                    
                    return null;
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// PLACEHOLDER PENDING SCREEN
// ============================================================================
class PlaceholderPending extends StatelessWidget {
  const PlaceholderPending({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 100, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Menunggu Verifikasi Admin',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Akun Anda sedang diverifikasi. Silakan cek kembali dalam 1x24 jam.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/welcome',
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025