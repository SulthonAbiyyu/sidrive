// ============================================================================
// APP CONFIG - FLAVOR CONFIGURATION ✅
// ============================================================================

enum AppFlavor {
  client,
  admin,
}

class AppConfig {
  static AppFlavor? _flavor;
  
  static void setFlavor(AppFlavor flavor) {
    _flavor = flavor;
  }
  
  static AppFlavor get flavor => _flavor ?? AppFlavor.client;
  
  static bool get isClient => _flavor == AppFlavor.client;
  static bool get isAdmin => _flavor == AppFlavor.admin;
  
  static String get appName {
    switch (_flavor) {
      case AppFlavor.client:
        return 'SiDrive';
      case AppFlavor.admin:
        return 'SiDrive Admin';
      default:
        return 'SiDrive';
    }
  }
  
  static String get packageSuffix {
    switch (_flavor) {
      case AppFlavor.client:
        return '.client';
      case AppFlavor.admin:
        return '.admin';
      default:
        return '';
    }
  }
}
