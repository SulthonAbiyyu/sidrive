// lib/config/constants.dart
// ============================================================================
// CONSTANTS.DART - UPDATED WITH HOMEPAGE BACKGROUNDS
// ============================================================================

/// ===========================================================================
/// APP CONSTANTS - Informasi global aplikasi
/// ============================================================================
class AppConstants {
  static const String appName = 'SiDrive';
  static const String appTagline = 'Connecting UMSIDA Community';
  static const String appVersion = '1.0.0';

  // Supabase credentials
  static const String supabaseUrl = 'https://jwexcqljpcnyfislcxrh.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3ZXhjcWxqcGNueWZpc2xjeHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzNTAxNjAsImV4cCI6MjA3NzkyNjE2MH0.D78VqXZAh3ne2jaZk4ztsqQzYFGkVY5I7ecpCzp9a7w';

  // Email domain otomatis
  static const String emailDomain = '@umsida.internal';

  // Durasi Animasi (ms)
  static const int splashDuration = 2000;
  static const int animationDuration = 300;
  static const int longAnimationDuration = 500;

  // Validasi panjang input
  static const int nimLength = 12;
  static const int passwordMinLength = 8;
  static const int phoneMinLength = 10;
  static const int phoneMaxLength = 13;
}

/// ===========================================================================
/// RESPONSIVE BREAKPOINTS
/// ============================================================================
class Breakpoints {
  static const double mobileSmall = 360.0;
  static const double mobile = 414.0;
  static const double mobileLarge = 480.0;
  static const double tablet = 600.0;
  static const double tabletLarge = 900.0;
  static const double desktop = 1200.0;
}

/// ===========================================================================
/// ASSET PATHS - UPDATED WITH HOMEPAGE BACKGROUNDS
/// ============================================================================
class AssetPaths {
  // Logo
  static const String logo = 'assets/images/logo4.png';

  // ========================================================================
  // WELCOME SCREEN BACKGROUND
  // ========================================================================
  static const String welcomeBackground = 'assets/images/welcome_screen/welcomescreen2.png';

  // ========================================================================
  // ONBOARDING BACKGROUNDS
  // ========================================================================
  static const String onboarding1Video = 'assets/images/onboarding/onboarding1.mp4';
  static const String onboarding2Image = 'assets/images/onboarding/onboarding2.png';
  static const String onboarding3Video = 'assets/images/onboarding/onboarding3.mp4';

  // ========================================================================
  // LOGIN & REGISTER BACKGROUNDS
  // ========================================================================
  static const String loginBackground = 'assets/images/loginpage/loginscreen.png';
  static const String registerBackground = 'assets/images/loginpage/registerscreen.png';

  // ========================================================================
  // LOGIN ADMIN
  // ========================================================================
  static const String loginAdmin = 'assets/images/loginadmin/bglanding2.gif';
  static const String loginAdminBackground = 'assets/images/loginadmin/backgroundbelakang.jpg';

  // ========================================================================
  // CEK NIM BACKGROUND
  // ========================================================================
  static const String cekNimBackground = 'assets/images/ceknim/ceknimscreen.png';

  // ========================================================================
  // PILIH ROLE BACKGROUND
  // ========================================================================
  static const String pilihRoleBackground = 'assets/images/pilihrole/pilihrole.png';

  // ========================================================================
  // OLD ONBOARDING (KEEP FOR BACKWARD COMPATIBILITY)
  // ========================================================================
  static const String onboardingOjek = 'assets/images/onboarding/ojek.png';
  static const String onboardingUmkm = 'assets/images/onboarding/umkm.png';
  static const String onboardingSecure = 'assets/images/onboarding/secure.png';

  // Placeholder
  static const String placeholderUser = 'assets/images/placeholder/user.png';
  static const String placeholderProduct = 'assets/images/placeholder/product.png';
}

/// ===========================================================================
/// REGEX PATTERNS
/// ============================================================================
class RegexPatterns {
  static final RegExp email =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp phone = RegExp(r'^(08)[0-9]{8,11}$');
  static final RegExp nim = RegExp(r'^[0-9]{12}$');
  static final RegExp password =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$');
  static final RegExp name = RegExp(r'^[a-zA-Z\s]+$');
}

/// ===========================================================================
/// API ENDPOINTS (Supabase Table Name)
/// ============================================================================
class ApiEndpoints {
  static const String users = 'users';
  static const String mahasiswaAktif = 'mahasiswa_aktif';
  static const String drivers = 'drivers';
  static const String umkm = 'umkm';
  static const String pesanan = 'pesanan';
  static const String produk = 'produk';
  static const String tarifSettings = 'tarif_settings';
  static const String komisiSettings = 'komisi_settings';
}

/// ===========================================================================
/// STORAGE KEYS (SharedPreferences)
/// ============================================================================
class StorageKeys {
  static const String isFirstTime = 'is_first_time';
  static const String themeMode = 'theme_mode';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String rememberMe = 'remember_me';
  static const String lastNim = 'last_nim';
}

// constants.dart (buat file baru)
class OrderStatus {
  // Customer side
  static const mencariDriver = 'mencari_driver';
  
  // Driver side
  static const diterimaDriver = 'diterima_driver';
  static const menujuPickup = 'menuju_pickup';
  static const sampaiPickup = 'sampai_pickup';
  static const sedangAntar = 'sedang_antar';
  static const selesai = 'selesai';
  
  // Cancelled
  static const dibatalkan = 'dibatalkan';
}