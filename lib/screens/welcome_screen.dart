// lib/screens/welcome/welcome_screen.dart
// ✅ FIX CRITICAL: Scan database untuk detect pending verifications
// ✅ TIDAK RELY HANYA pada localStorage
// ✅ FIX: Populate verifiedMahasiswa sebelum navigate ke register form

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ TAMBAHAN: Import Provider
import 'package:sidrive/config/constants.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/services/ktm_verification_service.dart';
import 'package:sidrive/services/storage_service.dart';
import 'package:sidrive/providers/auth_provider.dart'; // ✅ TAMBAHAN: Import AuthProvider
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  // ✅ Static reference agar layar lain bisa trigger re-check tanpa restart
  static _WelcomeScreenState? _activeState;

  /// Dipanggil dari nim_verification_screen setelah submit KTM manual
  /// agar welcome screen langsung re-check status tanpa perlu restart app
  static void triggerStatusRefresh() {
    _activeState?._checkKtmVerificationStatus();
    debugPrint('🔄 [WELCOME] triggerStatusRefresh called');
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _hoverRegister = false;
  bool _hoverLogin = false;
  bool _pressRegister = false;
  bool _pressLogin = false;

  String _ktmStatus = 'none'; // 'none' | 'pending' | 'approved' | 'rejected'
  String? _storedNim;
  bool _isCheckingStatus = true;

  final _ktmService = KtmVerificationService();

  @override
  void initState() {
    super.initState();
    // ✅ Daftarkan state ini agar bisa di-trigger dari luar
    WelcomeScreen._activeState = this;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkKtmVerificationStatus();
    });
  }

  @override
  void dispose() {
    // ✅ Bersihkan reference saat widget di-dispose
    if (WelcomeScreen._activeState == this) {
      WelcomeScreen._activeState = null;
    }
    super.dispose();
  }

  // ============================================================================
  // ✅ FIX: AUTO DELETE STALE VERIFICATIONS (> 7 hari & belum di-link ke user)
  // ============================================================================
  Future<void> _deleteStaleVerifications() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      await Supabase.instance.client
          .from('ktm_verification_requests')
          .delete()
          .isFilter('id_user', null)
          .lt('created_at', sevenDaysAgo.toIso8601String());
      
      debugPrint('🗑️ [WELCOME] Deleted stale verifications older than 7 days');
    } catch (e) {
      debugPrint('❌ [WELCOME] Error deleting stale verifications: $e');
    }
  }

  // ============================================================================
  // CHECK KTM STATUS - STRATEGI BARU: SCAN DATABASE DULU!
  // ✅ FIX: Tambah validasi NIM availability & auto-cleanup
  // ============================================================================
  Future<void> _checkKtmVerificationStatus() async {
    try {
      // ✅ Reset state agar UI loading saat re-check (misal dipanggil triggerStatusRefresh)
      if (mounted) {
        setState(() {
          _isCheckingStatus = true;
          _ktmStatus = 'none';
        });
      }

      debugPrint('🔍 [WELCOME] ================================');
      debugPrint('🔍 [WELCOME] Checking KTM status...');
      
      // ✅ FIX: Auto-cleanup stale verifications dulu
      await _deleteStaleVerifications();
      
      // Step 1: Cek localStorage dulu (fast path)
      final storedNim = StorageService.getString('pending_ktm_nim');
      debugPrint('📌 [WELCOME] Stored NIM in localStorage: $storedNim');

      String targetNim = storedNim ?? '';
      
      // Step 2: Jika tidak ada di localStorage, SCAN DATABASE untuk pending verifications
      if (targetNim.isEmpty) {
        debugPrint('🔍 [WELCOME] No NIM in storage, scanning database for ANY pending verifications...');
        
        // Query database untuk cari pending verification tanpa id_user (pre-registration)
        final response = await Supabase.instance.client
            .from('ktm_verification_requests')
            .select('nim, status, rejection_reason, created_at')
            .isFilter('id_user', null)  // ✅ FIX: isFilter instead of is_
            .order('created_at', ascending: false)
            .limit(10);  // Ambil 10 terbaru
        
        debugPrint('📊 [WELCOME] Found ${response.length} pre-registration verifications');
        
        if (response.isEmpty) {
          debugPrint('ℹ️ [WELCOME] No pre-registration verifications found');
          setState(() { _ktmStatus = 'none'; _isCheckingStatus = false; });
          return;
        }
        
        // Cari yang approved atau rejected dulu (prioritas)
        final approved = response.where((r) => r['status'] == 'approved').toList();
        final rejected = response.where((r) => r['status'] == 'rejected').toList();
        final pending = response.where((r) => r['status'] == 'pending').toList();
        
        Map<String, dynamic>? targetRecord;
        
        if (approved.isNotEmpty) {
          targetRecord = approved.first;
          debugPrint('✅ [WELCOME] Found APPROVED verification!');
        } else if (rejected.isNotEmpty) {
          // ✅ FIX: Cek apakah user sudah acknowledge rejection ini
          // (RLS bisa block delete, jadi record tetap ada di DB meskipun sudah ditangani)
          final rejectedNim = rejected.first['nim'] as String;
          final ackedNim = StorageService.getString('ktm_rejection_acked');
          
          if (ackedNim == rejectedNim) {
            // User sudah tap "Upload Ulang" sebelumnya → skip rejected ini
            debugPrint('⏭️ [WELCOME] Rejection for NIM $rejectedNim already acknowledged, skipping...');
            
            // Kalau ada pending baru → tampilkan pending
            if (pending.isNotEmpty) {
              targetRecord = pending.first;
              debugPrint('⏳ [WELCOME] Found PENDING verification (after acked rejection)!');
            } else {
              // Tidak ada pending → status none (user sedang proses upload ulang)
              setState(() { _ktmStatus = 'none'; _isCheckingStatus = false; });
              return;
            }
          } else {
            targetRecord = rejected.first;
            debugPrint('❌ [WELCOME] Found REJECTED verification!');
          }
        } else if (pending.isNotEmpty) {
          targetRecord = pending.first;
          debugPrint('⏳ [WELCOME] Found PENDING verification!');
        }
        
        if (targetRecord != null) {
          targetNim = targetRecord['nim'] as String;
          debugPrint('🎯 [WELCOME] Target NIM from database: $targetNim');
          
          // Save ke localStorage untuk next time
          await StorageService.setString('pending_ktm_nim', targetNim);
          debugPrint('💾 [WELCOME] Saved NIM to localStorage');
        } else {
          debugPrint('ℹ️ [WELCOME] No relevant verification found');
          setState(() { _ktmStatus = 'none'; _isCheckingStatus = false; });
          return;
        }
      }

      // ✅ VALIDASI: targetNim harus ada sebelum lanjut
      if (targetNim.isEmpty) {
        debugPrint('⚠️ [WELCOME] targetNim is null after all checks');
        setState(() { _ktmStatus = 'none'; _isCheckingStatus = false; });
        return;
      }

      // ✅ FIX KRITIS: CEK APAKAH NIM SUDAH TERDAFTAR DI USERS
      // Jika sudah, berarti user sudah register tapi ktm_verification_requests belum di-cleanup
      final nimCheckResponse = await Supabase.instance.client
          .from('users')
          .select('nim')
          .eq('nim', targetNim)
          .maybeSingle();
      
      if (nimCheckResponse != null) {
        debugPrint('⚠️ [WELCOME] NIM $targetNim ALREADY REGISTERED! Auto-cleanup...');
        
        // Auto-cleanup
        await Supabase.instance.client
            .from('ktm_verification_requests')
            .delete()
            .eq('nim', targetNim);
        
        await StorageService.remove('pending_ktm_nim');
        await StorageService.remove('pending_ktm_roles');
        
        debugPrint('✅ [WELCOME] Cleanup completed, resetting status');
        setState(() { _ktmStatus = 'none'; _isCheckingStatus = false; });
        return;
      }

      // Step 3: Sekarang kita punya targetNim, query detail dari database
      setState(() => _storedNim = targetNim);

      final status = await _ktmService.checkStatusByNim(targetNim);
      debugPrint('📊 [WELCOME] Status from DB: ${status?['status']}');
      debugPrint('📊 [WELCOME] Rejection reason: ${status?['rejection_reason']}');

      if (!mounted) return;

      if (status == null) {
        debugPrint('⚠️ [WELCOME] No verification data found, clearing storage');
        await StorageService.remove('pending_ktm_nim');
        await StorageService.remove('pending_ktm_roles');
        setState(() { _ktmStatus = 'none'; _isCheckingStatus = false; });
        return;
      }

      setState(() {
        _ktmStatus = status['status'] ?? 'none';
        _isCheckingStatus = false;
      });

      debugPrint('✅ [WELCOME] Status set to: $_ktmStatus');

      // Delay 500ms sebelum show popup
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;

      // ✅ VALIDASI FINAL: targetNim sudah pasti tidak null di sini
      if (_ktmStatus == 'approved') {
        debugPrint('✅ [WELCOME] Showing APPROVED popup');
        _showApprovedPopup(targetNim); // ✅ Safe: sudah divalidasi
      } else if (_ktmStatus == 'rejected') {
        // ✅ FIX KRITIS: Cek acked flag di sini juga!
        // Masalah: fast path (Step 1) langsung ke sini tanpa lewat acked check di Step 2.
        // Skenario: user klik "Upload Ulang" → nim_verification_screen set pending_ktm_nim lagi
        // → fast path aktif → checkStatusByNim → dapat record rejected (RLS block delete)
        // → spam popup terus! Fix: cek acked di sini juga.
        final ackedNim = StorageService.getString('ktm_rejection_acked');
        if (ackedNim == targetNim) {
          debugPrint('⏭️ [WELCOME] Rejection for NIM $targetNim already acked (fast-path gap fix), ignoring...');
          // Clear pending_ktm_nim agar scan path aktif next time (detect pending baru)
          await StorageService.remove('pending_ktm_nim');
          if (!mounted) return;
          setState(() { _ktmStatus = 'none'; _isCheckingStatus = false; });
          return;
        }
        debugPrint('❌ [WELCOME] Showing REJECTED popup');
        _showRejectedPopup(targetNim, status['rejection_reason'] ?? 'Foto KTM tidak valid'); // ✅ Safe
      } else if (_ktmStatus == 'pending') {
        debugPrint('⏳ [WELCOME] Status is PENDING, register button disabled');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [WELCOME] Error: $e');
      debugPrint('Stack: $stackTrace');
      setState(() => _isCheckingStatus = false);
    }
  }

  // ============================================================================
  // HANDLER TOMBOL DAFTAR
  // ============================================================================
  Future<void> _onRegisterTap() async {
    if (_isCheckingStatus) {
      debugPrint('⏳ [WELCOME] Still checking status, please wait...');
      return;
    }

    if (_ktmStatus == 'pending') {
      debugPrint('⏳ [WELCOME] Status PENDING, showing popup');
      _showPendingPopup();
      return;
    }
    
    if (_ktmStatus == 'approved' && _storedNim != null) {
      debugPrint('✅ [WELCOME] Status APPROVED, showing popup');
      _showApprovedPopup(_storedNim!);
      return;
    }
    
    if (_ktmStatus == 'rejected' && _storedNim != null) {
      debugPrint('❌ [WELCOME] Status REJECTED, showing popup');
      final status = await _ktmService.checkStatusByNim(_storedNim!);
      _showRejectedPopup(_storedNim!, status?['rejection_reason'] ?? 'Foto KTM tidak valid');
      return;
    }

    // USER BARU - LANGSUNG KE ROLE SELECTION DULU!
    if (!mounted) return;
    debugPrint('➡️ [WELCOME] New user, go to role selection first');
    Navigator.pushNamed(context, '/register/role-multi');
  }

  // ============================================================================
  // 🔥 FIX: POPUP APPROVED - POPULATE verifiedMahasiswa SEBELUM NAVIGATE!
  // ============================================================================
  void _showApprovedPopup(String nim) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 50),
              ),
              const SizedBox(height: 20),
              const Text('KTM Terverifikasi!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 12),
              Text(
                'Admin telah menyetujui KTM kamu (NIM: $nim).\n\nSilakan lanjutkan pendaftaran akun.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    debugPrint('✅ [WELCOME] User tapped Lanjut - Fetching roles from storage...');
                    
                    // Ambil roles dari storage
                    final rolesString = StorageService.getString('pending_ktm_roles');
                    debugPrint('📦 [WELCOME] Stored roles: $rolesString');
                    
                    if (rolesString == null || rolesString.isEmpty) {
                      debugPrint('❌ [WELCOME] No roles found! Redirecting to role selection');
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/register/role-multi');
                      return;
                    }
                    
                    // Parse roles (format: "driver,customer" atau "umkm")
                    final roles = rolesString.split(',').map((e) => e.trim()).toList();
                    debugPrint('✅ [WELCOME] Parsed roles: $roles');
                    
                    // 🔥 FIX: POPULATE verifiedMahasiswa DULU!
                    debugPrint('🔍 [WELCOME] Checking NIM to populate verifiedMahasiswa...');
                    final authProvider = context.read<AuthProvider>();
                    final nimCheckSuccess = await authProvider.checkNim(nim);
                    
                    if (!nimCheckSuccess) {
                      debugPrint('❌ [WELCOME] NIM check failed!');
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal memverifikasi NIM. Silakan coba lagi.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    debugPrint('✅ [WELCOME] verifiedMahasiswa populated successfully!');
                    debugPrint('📝 [WELCOME] Mahasiswa: ${authProvider.verifiedMahasiswa?.namaLengkap}');
                    
                    // ⚠️ JANGAN CLEAR STORAGE DI SINI!
                    // Biarkan cleanup dilakukan di register_form_screen setelah registrasi sukses
                    // Kalau clear di sini, user cancel register -> storage hilang tapi DB masih ada
                    
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    
                    // LANGSUNG KE REGISTER FORM (SKIP ROLE SELECTION!)
                    debugPrint('➡️ [WELCOME] Navigating to register form with roles: $roles');
                    Navigator.pushNamed(
                      context, 
                      '/register/form-multi',
                      arguments: roles,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                  ),
                  child: const Text('Lanjut ke Pendaftaran',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // POPUP: REJECTED ❌
  // ============================================================================
  void _showRejectedPopup(String nim, String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 50),
              ),
              const SizedBox(height: 20),
              const Text('Verifikasi Ditolak',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 12),
              Text('Admin menolak verifikasi KTM kamu (NIM: $nim).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 6),
                        Text('Alasan Penolakan:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(reason,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // ✅ FIX: Hapus DB record 'rejected' dulu, BARU clear storage
                    // Tanpa ini: DB masih ada record rejected → welcome screen akan
                    // tampil rejected popup lagi meskipun user sudah upload ulang
                    try {
                      // ✅ FIX: Hapus .isFilter - biarkan RLS yg handle, tambah .select() utk verify
                      final deleteResult = await Supabase.instance.client
                          .from('ktm_verification_requests')
                          .delete()
                          .eq('nim', nim)
                          .isFilter('id_user', null)
                          .select();
                      debugPrint('✅ [WELCOME] Delete result: $deleteResult (${deleteResult.length} rows deleted)');
                      if (deleteResult.isEmpty) {
                        debugPrint('⚠️ [WELCOME] Delete returned 0 rows - RLS mungkin blokir, acked flag sudah di-set sebagai fallback');
                      }
                    } catch (e) {
                      debugPrint('❌ [WELCOME] Error deleting rejected record: $e');
                      // Lanjut tetap, acked flag sudah di-set sebagai dual-defense
                    }

                    // ✅ FIX DUAL-DEFENSE: Simpan flag acked agar popup tidak muncul lagi
                    // meskipun RLS block delete dan record masih ada di DB
                    await StorageService.setString('ktm_rejection_acked', nim);
                    debugPrint('🛡️ [WELCOME] Saved rejection acked flag for NIM: $nim');

                    await StorageService.remove('pending_ktm_nim');
                    await StorageService.remove('pending_ktm_roles'); // ✅ FIX: Clear roles juga
                    debugPrint('✅ [WELCOME] Cleared pending_ktm_nim from storage (rejected)');
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/register/role-multi');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                  ),
                  child: const Text('Upload Ulang KTM',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // POPUP: PENDING ⏳
  // ============================================================================
  void _showPendingPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.schedule, color: Color(0xFFF59E0B), size: 50),
            ),
            const SizedBox(height: 20),
            const Text('Verifikasi Sedang Diproses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            const Text(
              'KTM kamu masih dalam proses review admin.\n\nMohon tunggu maksimal 1x24 jam. Kamu belum bisa mendaftar sampai KTM disetujui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                ),
                child: const Text('OK, Mengerti',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomBoxPadding = ResponsiveMobile.scaledH(80);

    // ✅ Register button di-disable jika status = pending
    final registerBlocked = _ktmStatus == 'pending';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // BACKGROUND — pakai AssetPaths.welcomeBackground (dari constants.dart)
            Positioned.fill(
              child: Image.asset(AssetPaths.welcomeBackground, fit: BoxFit.cover),
            ),

            // MAIN CONTENT
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(20)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    // BAWAH: Tombol-tombol vertikal
                    _buildSplitButtons(
                      hoverLeft: _hoverRegister,
                      hoverRight: _hoverLogin,
                      pressLeft: _pressRegister,
                      pressRight: _pressLogin,
                      onLeftHoverChange: (value) => setState(() => _hoverRegister = value),
                      onRightHoverChange: (value) => setState(() => _hoverLogin = value),
                      onLeftPressChange: (value) => setState(() => _pressRegister = value),
                      onRightPressChange: (value) => setState(() => _pressLogin = value),
                      onRegister: _onRegisterTap,
                      onLogin: () => Navigator.pushNamed(context, '/login'),
                      registerBlocked: registerBlocked,
                      isCheckingStatus: _isCheckingStatus,
                      ktmStatus: _ktmStatus,
                    ),
                    SizedBox(height: bottomBoxPadding),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // VERTICAL BUTTONS WIDGET (Login atas, Daftar bawah)
  // ============================================================================
  Widget _buildSplitButtons({
    required bool hoverLeft,
    required bool hoverRight,
    required bool pressLeft,
    required bool pressRight,
    required Function(bool) onLeftHoverChange,
    required Function(bool) onRightHoverChange,
    required Function(bool) onLeftPressChange,
    required Function(bool) onRightPressChange,
    required VoidCallback onRegister,
    required VoidCallback onLogin,
    required bool registerBlocked,
    required bool isCheckingStatus,
    required String ktmStatus,
  }) {
    final double scaleLeft = pressLeft && !registerBlocked
        ? 0.97
        : (hoverLeft && !registerBlocked)
            ? 1.02
            : 1.0;
    final double scaleRight = pressRight ? 0.97 : (hoverRight ? 1.02 : 1.0);

    return Column(
      children: [
        // ─── LOGIN (ATAS) — putih, teks biru ───────────────────────────────────────────────────────
        MouseRegion(
          onEnter: (_) => onRightHoverChange(true),
          onExit: (_) => onRightHoverChange(false),
          child: GestureDetector(
            onTap: onLogin,
            onTapDown: (_) => onRightPressChange(true),
            onTapUp: (_) => onRightPressChange(false),
            onTapCancel: () => onRightPressChange(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()..scale(scaleRight),
              transformAlignment: Alignment.center,
              height: ResponsiveMobile.scaledH(54),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(hoverRight ? 0.18 : 0.10),
                    blurRadius: hoverRight ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: const Color(0xFF1A3FBB),
                    fontWeight: FontWeight.w900,
                    fontSize: ResponsiveMobile.scaledFont(pressRight ? 16 : (hoverRight ? 19 : 17)),
                    letterSpacing: hoverRight ? 1.5 : 0.5,
                  ),
                  child: const Text('Login'),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: ResponsiveMobile.scaledH(14)),

        // ─── DAFTAR (BAWAH) — outline, transparan, teks putih ──────────────────────
        MouseRegion(
          onEnter: (_) => !registerBlocked ? onLeftHoverChange(true) : null,
          onExit: (_) => onLeftHoverChange(false),
          child: GestureDetector(
            onTap: onRegister,
            onTapDown: (_) => !registerBlocked ? onLeftPressChange(true) : null,
            onTapUp: (_) => onLeftPressChange(false),
            onTapCancel: () => onLeftPressChange(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()..scale(scaleLeft),
              transformAlignment: Alignment.center,
              height: ResponsiveMobile.scaledH(54),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCheckingStatus
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: ResponsiveMobile.scaledFont(pressLeft ? 16 : (hoverLeft ? 19 : 17)),
                              letterSpacing: hoverLeft ? 1.5 : 0.5,
                            ),
                            child: const Text('Daftar'),
                          ),
                          if (ktmStatus == 'pending')
                            const Text('KTM dalam review',
                                style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
