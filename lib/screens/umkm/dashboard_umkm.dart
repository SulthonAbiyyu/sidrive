import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ TAMBAHAN BARU
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/screens/umkm/pages/homepage.dart';
import 'package:sidrive/screens/umkm/pages/produk_umkm.dart';
import 'package:sidrive/screens/profile/profile_tab.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/widgets/custom_bottom_nav.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sidrive/providers/notifikasi_provider.dart';
import 'package:sidrive/screens/umkm/pages/pendapatan_umkm_page.dart';



class DashboardUmkm extends StatefulWidget {
  const DashboardUmkm({super.key});

  @override
  State<DashboardUmkm> createState() => _DashboardUmkmState();
}

class _DashboardUmkmState extends State<DashboardUmkm> with WidgetsBindingObserver {
  int _selectedIndex = 2; // Default: Home (center button)

  late final List<Widget> _pages;
  
  // ✅ TAMBAHAN BARU: Untuk fitur tekan back 2x keluar
  DateTime? _lastBackPressed;

  // =========================================================================
  // CONNECTIVITY & LIFECYCLE
  // =========================================================================
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _hasShownOfflineSnackbar = false;
  bool _hasShownOnlineSnackbar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    debugPrint('🪙 [UMKM_DASHBOARD] ========================================');
    debugPrint('🪙 [UMKM_DASHBOARD] Dashboard initialized');
    debugPrint('🪙 [UMKM_DASHBOARD] ========================================');
    
    _initializePages();
    _checkInitialConnectivity();
    _setupConnectivityListener();
    _initializeNotifikasi();
    
    // ✅ FIX: Better timing - wait for build to complete
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('🔥 [UMKM_DASHBOARD] 🔍 Post-frame callback triggered');
      
      // ✅ Wait for next frame instead of arbitrary delay
      await Future.delayed(Duration.zero);
      
      if (!mounted) {
        debugPrint('🔥 [UMKM_DASHBOARD] ⚠️ Widget not mounted after delay');
        return;
      }
      
      // ✅ Ensure provider is ready
      final authProvider = context.read<AuthProvider>();
      debugPrint('🔥 [UMKM_DASHBOARD] AuthProvider loaded');
      debugPrint('🔥 [UMKM_DASHBOARD] Current user: ${authProvider.currentUser?.nama}');
      
      if (authProvider.currentUser != null) {
        debugPrint('🔥 [UMKM_DASHBOARD] _checkTokoSetup() completed');
      } else {
        debugPrint('🔥 [UMKM_DASHBOARD] ⚠️ No user found, skipping setup check');
        setState(() {


        });
      }
    });
  }

  @override
  void dispose() {
    debugPrint('🪙 [UMKM_DASHBOARD] Disposing dashboard...');
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    
    // Stop notifikasi listener
    if (mounted) {
      context.read<NotifikasiProvider>().stopListening();
    }
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('🪙 [UMKM_DASHBOARD] App lifecycle changed: $state');
    
    if (state == AppLifecycleState.resumed) {
      debugPrint('🪙 [UMKM_DASHBOARD] App resumed - checking connectivity');
      _checkInitialConnectivity();
    }
  }

 
  // =========================================================================
  // INITIALIZATION
  // =========================================================================
  void _initializePages() {
    debugPrint('🪙 [UMKM_DASHBOARD] Initializing pages...');
    
    try {
      _pages = [
        const ProdukUmkm(),                                                     
        const PendapatanUmkmPage(),
        const HomeUmkm(),                                                       
        const PlaceholderPage(title: 'Chat', icon: Icons.chat_bubble),         
        const ProfileTab(isInsideTab: true),                                    
      ];
      
      debugPrint('✅ [UMKM_DASHBOARD] Pages initialized successfully (${_pages.length} pages)');
    } catch (e, stackTrace) {
      debugPrint('❌ [UMKM_DASHBOARD] Error initializing pages: $e');
      debugPrint('📚 [UMKM_DASHBOARD] Stack trace: $stackTrace');
    }
  }

  // =========================================================================
  // CONNECTIVITY MANAGEMENT
  // =========================================================================
  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _updateConnectivityStatus(connectivityResult);
    } catch (e) {
      debugPrint('❌ [UMKM_DASHBOARD] Error checking connectivity: $e');
    }
  }

  void _setupConnectivityListener() {
    debugPrint('🪙 [UMKM_DASHBOARD] Setting up connectivity listener...');
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.isNotEmpty) {
          _updateConnectivityStatus(results);
        }
      },
      onError: (error) {
        debugPrint('❌ [UMKM_DASHBOARD] Connectivity listener error: $error');
      },
    );
  }

  // =========================================================================
  // NOTIFIKASI INITIALIZATION
  // =========================================================================
  void _initializeNotifikasi() {
    debugPrint('🔔 [UMKM_DASHBOARD] Initializing notifications...');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId != null) {
        context.read<NotifikasiProvider>().loadNotifikasi(userId);
        context.read<NotifikasiProvider>().startListening(userId);
        
        debugPrint('✅ [UMKM_DASHBOARD] Notifications initialized');
      }
    });
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    if (!mounted) return;
    
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);
    
    debugPrint('🌐 [UMKM_DASHBOARD] Connectivity changed: ${results.first.name}');
    debugPrint('🌐 [UMKM_DASHBOARD] Status: ${_isOnline ? "ONLINE ✅" : "OFFLINE ❌"}');
    
    if (wasOnline != _isOnline) {
      if (!_isOnline && !_hasShownOfflineSnackbar) {
        _showConnectivitySnackbar(false);
        _hasShownOfflineSnackbar = true;
        _hasShownOnlineSnackbar = false;
      } else if (_isOnline && !_hasShownOnlineSnackbar) {
        _showConnectivitySnackbar(true);
        _hasShownOnlineSnackbar = true;
        _hasShownOfflineSnackbar = false;
      }
    }
    
    setState(() {});
  }

  void _showConnectivitySnackbar(bool isOnline) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: ResponsiveMobile.scaledFont(20),
            ),
            ResponsiveMobile.hSpace(12),
            Expanded(
              child: Text(
                isOnline 
                    ? 'Koneksi internet terhubung' 
                    : 'Tidak ada koneksi internet',
                style: TextStyle(
                  fontSize: ResponsiveMobile.captionSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isOnline ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isOnline ? 2 : 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        ),
        margin: EdgeInsets.only(
          bottom: ResponsiveMobile.scaledH(80),
          left: ResponsiveMobile.scaledW(16),
          right: ResponsiveMobile.scaledW(16),
        ),
      ),
    );
  }

  // =========================================================================
  // BUILD METHOD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    debugPrint('🪙 [UMKM_DASHBOARD] Building dashboard (selectedIndex: $_selectedIndex)');
    
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // ✅ SAFETY CHECK: User validation
    if (user == null) {
      debugPrint('⚠️ [UMKM_DASHBOARD] User is null - showing loading');
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    debugPrint('👤 [UMKM_DASHBOARD] User loaded: ${user.nama} (ID: ${user.idUser})');

    // ✅ ROLE VALIDATION
    final roleDetails = authProvider.getRoleDetails('umkm');
    final isPending = roleDetails?.status == 'pending_verification';
    
    debugPrint('📋 [UMKM_DASHBOARD] Role status: ${roleDetails?.status ?? "unknown"}');
    debugPrint('📋 [UMKM_DASHBOARD] Is pending: $isPending');

    // ✅ TAMBAHAN BARU: PopScope untuk fitur tekan back 2x keluar
    // Cara kerja: tekan back pertama → muncul snackbar "tekan lagi untuk keluar"
    // Tekan back kedua dalam 2 detik → keluar aplikasi
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          // Tekan pertama → simpan waktu & tampilkan snackbar
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tekan sekali lagi untuk keluar'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          // Tekan kedua dalam 2 detik → keluar aplikasi
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Stack(
          children: [
            // Main content
            IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
            
            // ✅ CONNECTIVITY INDICATOR (Top Bar)
            if (!_isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.red.shade600,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveMobile.scaledH(8),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          color: Colors.white,
                          size: ResponsiveMobile.scaledFont(16),
                        ),
                        ResponsiveMobile.hSpace(8),
                        Text(
                          'Tidak ada koneksi internet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveMobile.captionSize(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // =========================================================================
  // BOTTOM NAVIGATION
  // =========================================================================
  Widget _buildBottomNav() {
    return CustomBottomNav(
      selectedIndex: _selectedIndex,
      onTap: (index) {
        debugPrint('🪙 [UMKM_DASHBOARD] Bottom nav tapped: $index');
        
        // ✅ VALIDATION: Prevent invalid index
        if (index < 0 || index >= _pages.length) {
          debugPrint('⚠️ [UMKM_DASHBOARD] Invalid index: $index (max: ${_pages.length - 1})');
          return;
        }
        
        setState(() => _selectedIndex = index);
      },
      role: 'umkm',
    );
  }
}

// ============================================================================
// PLACEHOLDER PAGE
// ============================================================================
class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🪙 [PLACEHOLDER] Building placeholder: $title');
    
    return Center(
      child: Padding(
        padding: ResponsiveMobile.horizontalPadding(context, 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: ResponsiveMobile.allScaledPadding(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                size: ResponsiveMobile.scaledFont(64), 
                color: Colors.grey.shade400,
              ),
            ),
            
            ResponsiveMobile.vSpace(24),
            
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveMobile.titleSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            ResponsiveMobile.vSpace(12),
            
            Text(
              'Fitur ini sedang dalam pengembangan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context),
                color: Colors.grey.shade600,
              ),
            ),
            
            ResponsiveMobile.vSpace(32),
            
            Container(
              padding: ResponsiveMobile.allScaledPadding(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  ResponsiveMobile.hSpace(12),
                  Expanded(
                    child: Text(
                      'Fitur $title akan segera hadir dalam update berikutnya!',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context),
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}