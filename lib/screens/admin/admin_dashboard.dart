import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/screens/admin/modern_sidebar.dart';
import 'package:sidrive/screens/admin/navbar_admin.dart';
import 'package:sidrive/screens/admin/contents/verify_driver_content.dart';
import 'package:sidrive/screens/admin/contents/verify_umkm_content.dart';
import 'package:sidrive/screens/admin/contents/penarikan_saldo_content.dart';
import 'package:sidrive/screens/admin/contents/statistik_content.dart';
import 'package:sidrive/screens/admin/contents/pengaturan_content.dart';
import 'package:sidrive/screens/admin/contents/kelola_mahasiswa_content.dart'; 
import 'package:sidrive/screens/admin/contents/kelola_admin_content.dart';
import 'package:sidrive/screens/admin/contents/refund_management_content.dart';
import 'package:sidrive/screens/admin/contents/cash_settlement_content.dart';
import 'package:sidrive/screens/admin/contents/kelola_user_content.dart';
import 'package:sidrive/screens/admin/contents/ktm_verification_admin_content.dart';
import 'package:sidrive/screens/admin/contents/kelola_tarif_content.dart';
import 'package:sidrive/screens/admin/contents/cs_chat_admin_content.dart'; // ✅ NEW


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedMenuIndex = 0;
  final ValueNotifier<double> _sidebarWidthNotifier = ValueNotifier<double>(80);

  // ✅ Flag agar startRealtimeBadges + startCsChatRealtime hanya dipanggil SEKALI
  // Tidak boleh restart setiap kali user klik balik ke menu Statistik
  bool _realtimeInitialized = false;

  // Detail state management
  String? _selectedDriverId;
  String? _selectedUmkmId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _sidebarWidthNotifier.dispose();
    // ✅ Reset flag saat widget di-dispose (misal logout) agar session baru bisa init ulang
    _realtimeInitialized = false;
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final adminProvider = context.read<AdminProvider>();
    
    try {
      // ── Index berdasarkan selectedMenuIndex (setelah Chat di index 1) ──────
      switch (_selectedMenuIndex) {
        case 0: // Statistik
          await adminProvider.refreshDashboard();
          // ✅ Hanya panggil sekali selama session - jangan restart setiap balik ke Statistik
          if (!_realtimeInitialized) {
            adminProvider.startRealtimeBadges();
            adminProvider.startCsChatRealtime();
            _realtimeInitialized = true;
          }
          break;
        case 1: // Live Chat CS
          // CsChatAdminContent handle data loading sendiri via initState
          break;
        case 2: // Admin (super_admin only)
          // No initial load needed
          break;
        case 3: // Mahasiswa
          // No initial load needed (handled in content)
          break;
        case 4: // Kelola User
          // No initial load needed (handled in content)
          break;
        case 5: // Kelola Tarif
          await adminProvider.loadTarifConfigs();
          break;
        case 6: // KTM Verification
          await adminProvider.loadPendingKtmVerifications();
          break;
        case 7: // Driver
          await adminProvider.loadPendingDrivers();
          break;
        case 8: // UMKM
          await adminProvider.loadPendingUmkm();
          break;
        case 9: // Penarikan
          await adminProvider.loadPendingPenarikan();
          break;
        case 10: // Settlement
          // No initial load needed
          break;
        case 11: // Refund
          await adminProvider.loadPendingRefundCount();
          break;
        case 12: // Pengaturan
          // No initial load needed
          break;
      }
    } catch (e) {
      debugPrint('❌ Error loading initial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // Main Content (Animated position berdasarkan sidebar width)
          ValueListenableBuilder<double>(
            valueListenable: _sidebarWidthNotifier,
            builder: (context, sidebarWidth, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                left: sidebarWidth + 56, // Sidebar width + margin
                right: 0,
                top: 0,
                bottom: 0,
                child: _buildMainContent(context, adminProvider),
              );
            },
          ),

          // Floating Sidebar (Always on top)
          ModernSidebar(
            selectedIndex: _selectedMenuIndex,
            onMenuTap: _onMenuTap,
            adminName: adminProvider.currentAdmin?.nama ?? 'Super Admin',
            adminAvatar: null,
            sidebarWidthNotifier: _sidebarWidthNotifier,
          ),
        ],
      ),
    );
  }

  /// Handle menu tap - switch content tanpa Navigator
  void _onMenuTap(int index) {
    if (_selectedMenuIndex == index) return; // Jangan reload jika menu sama

    setState(() {
      _selectedMenuIndex = index;
      // Reset detail state ketika pindah menu
      _selectedDriverId = null;
      _selectedUmkmId = null;
    });

    // Load data untuk menu baru
    _loadInitialData();
  }

  /// Build main content area
  Widget _buildMainContent(BuildContext context, AdminProvider provider) {
    return Column(
      children: [
        // Navbar
        const NavbarAdmin(),
        
        const SizedBox(height: 16),
        
        // Content Area (Expanded untuk fill remaining space)
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.02, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildContentByIndex(),
          ),
        ),
      ],
    );
  }

  Widget _buildContentByIndex() {
    final adminProvider = context.watch<AdminProvider>();
    final isSuperAdmin = adminProvider.currentAdmin?.level == 'super_admin';
    
    // Key untuk AnimatedSwitcher
    final key = ValueKey<int>(_selectedMenuIndex);

    // ── Adjustment logic ──────────────────────────────────────────────────────
    // Chat (index 1) tersedia untuk SEMUA role, jadi adjustment hanya berlaku
    // mulai index >= 2 (untuk melewati menu Admin yang hanya super_admin).
    // Super_admin: tidak ada adjustment (adjustedIndex = selectedMenuIndex)
    // Regular admin: jika selectedMenuIndex >= 2, +1 untuk skip case Admin (2)
    // ─────────────────────────────────────────────────────────────────────────
    int adjustedIndex = _selectedMenuIndex;
    if (!isSuperAdmin && _selectedMenuIndex >= 2) {
      adjustedIndex = _selectedMenuIndex + 1;
    }

    switch (adjustedIndex) {
      case 0: // Statistik
        return StatistikContent(key: key);

      case 1: // Live Chat CS (semua role)
        return CsChatAdminContent(key: key);
      
      case 2: // Admin (HANYA SUPER_ADMIN)
        return isSuperAdmin 
            ? KelolaAdminContent(key: key)
            : StatistikContent(key: key);
      
      case 3: // Mahasiswa
        return KelolaMahasiswaContent(key: key);
      
      case 4: // Kelola User
        return KelolaUserContent(key: key);
      
      case 5: // Kelola Tarif
        return KelolaTarifContent(key: key);
      
      case 6: // KTM Verification
        return KtmVerificationAdminContent(key: key);
      
      case 7: // Driver
        return VerifyDriverContent(
          key: key,
          selectedDriverId: _selectedDriverId,
          onDriverSelected: (driverId) {
            setState(() => _selectedDriverId = driverId);
          },
          onBackToList: () {
            setState(() => _selectedDriverId = null);
          },
        );
      
      case 8: // UMKM
        return VerifyUmkmContent(
          key: key,
          selectedUmkmId: _selectedUmkmId,
          onUmkmSelected: (umkmId) {
            setState(() => _selectedUmkmId = umkmId);
          },
          onBackToList: () {
            setState(() => _selectedUmkmId = null);
          },
        );
      
      case 9: // Penarikan
        return PenarikanSaldoContent(key: key);

      case 10: // Settlement
        return CashSettlementContent(key: key);
      
      case 11: // Refund
        return RefundManagementContent(key: key);
      
      case 12: // Pengaturan
        return PengaturanContent(key: key);
      
      default:
        return StatistikContent(key: key);
    }
  }
}