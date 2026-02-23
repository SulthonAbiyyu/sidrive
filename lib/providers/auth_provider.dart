// ============================================================================
// AUTH_PROVIDER.DART - ✅ FIXED!
// Provider untuk manage authentication state menggunakan Provider package
// UPDATE: Support multi-role dengan BENAR handle pending_verification
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidrive/models/user_model.dart';
import 'package:sidrive/models/mahasiswa_model.dart';
import 'package:sidrive/models/user_role_model.dart'; 
import 'package:sidrive/services/auth_service.dart';
import 'package:sidrive/services/storage_service.dart';
import 'package:sidrive/services/fcm_service.dart';
import 'package:sidrive/core/utils/image_utils.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // ===========================================================================
  // REALTIME SUBSCRIPTIONS
  // ===========================================================================
  final List<RealtimeChannel> _realtimeChannels = [];
  
  // State variables (EXISTING - tetap ada)
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  MahasiswaModel? _verifiedMahasiswa;

  // State variables (NEW - untuk multi-role)
  List<UserRoleModel> _userRoles = [];
  String? _activeRole;

  // Getters (EXISTING - tetap ada)
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MahasiswaModel? get verifiedMahasiswa => _verifiedMahasiswa;
  bool get isLoggedIn => _currentUser != null;

  // Getters (NEW - untuk multi-role)
  List<UserRoleModel> get userRoles => _userRoles;
  String? get activeRole => _activeRole ?? _currentUser?.role;
  
  // ============================================================================
  // ✅ FIX: AVAILABLE ROLES - TERMASUK PENDING!
  // User dengan role pending_verification TETAP BISA LOGIN KE DASHBOARD
  // Cuma tidak bisa terima order (itu dihandle di dashboard logic)
  // ============================================================================
  // ⚠️ PENTING: availableRoles INCLUDE pending roles!
  // User dengan pending role BOLEH login & akses dashboard,
  // tapi TIDAK BISA terima order (dihandle di page-level)
  List<String> get availableRoles {
    return _userRoles
        .where((r) => r.isActive) // ✅ Hanya cek isActive, TIDAK cek status!
        .map((r) => r.role)
        .toList();
  }
  
  // ============================================================================
  // ✅ NEW: Get role details with status
  // Untuk cek apakah role sudah active atau masih pending
  // ============================================================================
  UserRoleModel? getRoleDetails(String role) {
    try {
      return _userRoles.firstWhere(
        (r) => r.role == role && r.isActive
      );
    } catch (e) {
      return null;
    }
  }
  
  // ============================================================================
  // ✅ FIX: HAS ROLE - Cek apakah user punya role (termasuk pending!)
  // ============================================================================
  bool hasRole(String role) {
    return _userRoles.any((r) => r.role == role);
    // ✅ Cuma cek role-nya ada atau nggak, NGGAK peduli status!
  }
  
  // ============================================================================
  // ✅ NEW: Check if role is active (approved by admin)
  // ============================================================================
  bool isRoleActive(String role) {
    try {
      final roleDetails = _userRoles.firstWhere(
        (r) => r.role == role && r.isActive
      );
      return roleDetails.status == 'active';
    } catch (e) {
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CHECK NIM (EXISTING - tetap ada)
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> checkNim(String nim) async {
    _setLoading(true);
    _clearError();

    try {
      final mahasiswa = await _authService.checkNim(nim);
      
      if (mahasiswa == null) {
        _setError('NIM tidak terdaftar di database mahasiswa UMSIDA');
        _setLoading(false);
        return false;
      }

      _verifiedMahasiswa = mahasiswa;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REGISTER (EXISTING - tetap ada untuk backward compatibility)
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> register({
    required String nim,
    required String nama,
    required String noTelp,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.register(
        nim: nim,
        nama: nama,
        noTelp: noTelp,
        password: password,
        role: role,
      );

      _currentUser = user;
      
      // Load user roles
      await _loadUserRoles(user.idUser);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REGISTER MULTI ROLE (NEW - untuk daftar dengan banyak role)
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> registerMultiRole({
    required String nim,
    required String nama,
    required String noTelp,
    required String password,
    required List<String> roles, // ['customer', 'driver', 'umkm']
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.registerMultiRole(
        nim: nim,
        nama: nama,
        noTelp: noTelp,
        password: password,
        roles: roles,
      );

      _currentUser = user;
      
      // Load user roles
      await _loadUserRoles(user.idUser);
      
      // Set active role
      _activeRole = user.role;
      await _saveActiveRole(_activeRole!);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LOGIN (EXISTING - dengan tambahan load roles)
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String nim,
    required String password,
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(
        nim: nim,
        password: password,
      );

      _currentUser = user;

      // ✅ FIX: Load roles dan FCM secara parallel untuk performa lebih baik
      await Future.wait([
        _loadUserRoles(user.idUser),
        FCMService.refreshToken(),
      ]);

      // Load active role dari SharedPreferences atau pakai yang di database
      _activeRole = await _getActiveRole() ?? user.role;
      
      // ✅ FIX: Validasi active role ada di list available roles
      // PERHATIAN: availableRoles sekarang INCLUDE pending roles!
      if (!hasRole(_activeRole!)) {
        _activeRole = availableRoles.isNotEmpty ? availableRoles.first : user.role;
        await _saveActiveRole(_activeRole!);
      }

      // Save remember me & last NIM
      if (rememberMe) {
        await StorageService.setRememberMe(true);
        await StorageService.setLastNim(nim);
      } else {
        await StorageService.setRememberMe(false);
      }

      _setLoading(false);
      // ✅ Start realtime setelah login berhasil
      startRealtimeUser();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LOGOUT (EXISTING - dengan tambahan clear roles)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading(true);

    try {
      stopRealtimeUser(); // ✅ Stop realtime sebelum clear data
      await _authService.logout();
      _currentUser = null;
      _verifiedMahasiswa = null;
      _userRoles = []; // NEW: Clear roles
      _activeRole = null; // NEW: Clear active role
      
      // Clear remember me if not enabled
      if (!StorageService.getRememberMe()) {
        await StorageService.clearAll();
      }
      
      // Clear active role
      await _clearActiveRole();

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INIT (EXISTING - dengan tambahan load roles)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        
        // Load user roles (NEW)
        await _loadUserRoles(user.idUser);
        
        // Load active role (NEW)
        _activeRole = await _getActiveRole() ?? user.role;
        
        notifyListeners();
        // ✅ Start realtime saat session dipulihkan
        startRealtimeUser();
      }
    } catch (e) {
      // Silent fail - user not logged in
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SWITCH ROLE (NEW - untuk ganti role yang sedang aktif)
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> switchRole(String newRole) async {
    // ✅ FIX: Allow switch to pending roles!
    if (!hasRole(newRole)) {
      _setError('Role $newRole tidak tersedia');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      if (_currentUser == null) {
        throw Exception('User tidak ditemukan');
      }

      // Update active role di database
      await _authService.updateActiveRole(
        userId: _currentUser!.idUser,
        newRole: newRole,
      );

      // Update active role di state
      _activeRole = newRole;
      
      // Update di user model (optional, untuk consistency)
      _currentUser = _currentUser!.copyWith(role: newRole);
      
      // Save ke SharedPreferences
      await _saveActiveRole(newRole);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADD ROLE (NEW - untuk tambah role baru)
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> addRole(String role) async {
    if (_currentUser == null) {
      _setError('User tidak ditemukan');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Add role via service
      final userRole = await _authService.addUserRole(
        userId: _currentUser!.idUser,
        role: role,
      );

      // Add to local list
      _userRoles.add(userRole);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER METHODS (EXISTING - tetap ada)
  // ──────────────────────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearVerifiedMahasiswa() {
    _verifiedMahasiswa = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER METHODS (NEW - untuk multi-role)
  // ──────────────────────────────────────────────────────────────────────────
  
  // Load user roles dari database
  Future<void> _loadUserRoles(String userId) async {
    try {
      _userRoles = await _authService.getUserRoles(userId);
    } catch (e) {
      print('Error loading user roles: $e');
      _userRoles = [];
    }
  }

  // Save active role ke SharedPreferences
  Future<void> _saveActiveRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_role', role);
    } catch (e) {
      print('Error saving active role: $e');
    }
  }

  // Get active role dari SharedPreferences
  Future<String?> _getActiveRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('active_role');
    } catch (e) {
      print('Error getting active role: $e');
      return null;
    }
  }

  // Clear active role dari SharedPreferences
  Future<void> _clearActiveRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_role');
    } catch (e) {
      print('Error clearing active role: $e');
    }
  }

  // =========================================================================
  // UPDATE PROFILE PHOTO
  // =========================================================================
  Future<bool> updateProfilePhoto(String? photoUrl) async {
    try {
      if (_currentUser == null) return false;
      
      final success = await ImageUtils.updateUserProfilePhoto(
        userId: _currentUser!.idUser,
        photoUrl: photoUrl,
      );
      
      if (success) {
        // Update local user model
        _currentUser = _currentUser!.copyWith(fotoProfil: photoUrl);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error updating profile photo: $e');
      return false;
    }
  }

  // =========================================================================
  // DELETE PROFILE PHOTO
  // =========================================================================
  Future<bool> deleteProfilePhoto() async {
    try {
      if (_currentUser == null) return false;
      
      debugPrint('🗑️ AUTH: Starting delete - current photo: ${_currentUser!.fotoProfil}');
      
      final oldPhotoUrl = _currentUser!.fotoProfil;
      
      // Delete from storage if exists
      if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
        debugPrint('🗑️ AUTH: Deleting from storage...');
        await ImageUtils.deleteProfilePhoto(photoUrl: oldPhotoUrl);
        debugPrint('✅ AUTH: Storage delete done');
      }
      
      // Update database to null
      debugPrint('🗑️ AUTH: Updating database to NULL...');
      final success = await ImageUtils.updateUserProfilePhoto(
        userId: _currentUser!.idUser,
        photoUrl: null,
      );
      
      debugPrint('🗑️ AUTH: Database update result = $success');
      
      if (success) {
        // 🔥 FIX: Create new UserModel with fotoProfil explicitly set to null
        _currentUser = UserModel(
          idUser: _currentUser!.idUser,
          nim: _currentUser!.nim,
          nama: _currentUser!.nama,
          email: _currentUser!.email,
          noTelp: _currentUser!.noTelp,
          fotoProfil: null,  // 🔥 Explicitly null!
          role: _currentUser!.role,
          status: _currentUser!.status,
          isVerified: _currentUser!.isVerified,
          alamat: _currentUser!.alamat,
          tanggalLahir: _currentUser!.tanggalLahir,
          jenisKelamin: _currentUser!.jenisKelamin,
          createdAt: _currentUser!.createdAt,
          lastLogin: _currentUser!.lastLogin,
        );
        
        debugPrint('✅ AUTH: Provider state updated - foto is now null');
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting profile photo: $e');
      debugPrint('Stack: $stackTrace');
      return false;
    }
  }


  // ===========================================================================
  // REALTIME - AUTO UPDATE DATA USER
  // Dipanggil setelah login / init berhasil
  // ===========================================================================

  /// Subscribe realtime untuk data user yang bisa berubah karena aksi admin.
  /// - users       → saldo wallet bertambah setelah refund
  /// - user_roles  → status verifikasi (driver/UMKM/KTM) approve/reject
  /// - pesanan     → status pesanan user berubah
  void startRealtimeUser() {
    if (_currentUser == null) return;
    stopRealtimeUser(); // hindari double subscribe

    final client  = Supabase.instance.client;
    final userId  = _currentUser!.idUser;

    // Helper subscribe
    void _sub(String name, String table, String col, String val, VoidCallback cb) {
      final ch = client
          .channel(name)
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: col,
              value: val,
            ),
            callback: (_) {
              debugPrint('🔴 Realtime user [$table] changed');
              cb();
            },
          )
          .subscribe();
      _realtimeChannels.add(ch);
    }

    // 1. Saldo wallet → tabel users, filter id_user = userId
    _sub('rt-user-wallet', 'users', 'id_user', userId, _onWalletChanged);

    // 2. Status verifikasi role → tabel user_roles, filter id_user = userId
    _sub('rt-user-roles', 'user_roles', 'id_user', userId, _onRoleStatusChanged);

    // 3. Status pesanan → tabel pesanan, filter id_user = userId
    _sub('rt-user-pesanan', 'pesanan', 'id_user', userId, _onPesananChanged);

    debugPrint('✅ Realtime user: ${_realtimeChannels.length} subscriptions aktif (userId: $userId)');
  }

  /// Stop semua realtime subscription (panggil saat logout)
  void stopRealtimeUser() {
    if (_realtimeChannels.isEmpty) return;
    final client = Supabase.instance.client;
    for (final ch in _realtimeChannels) {
      client.removeChannel(ch);
    }
    _realtimeChannels.clear();
    debugPrint('🔴 Realtime user: semua subscription dihentikan');
  }

  /// Callback: saldo wallet berubah → reload user data
  Future<void> _onWalletChanged() async {
    if (_currentUser == null || !isLoggedIn) return;
    try {
      final updated = await _authService.getCurrentUser();
      if (updated != null && mounted) {
        _currentUser = updated;
        notifyListeners();
        debugPrint('💰 Saldo wallet updated untuk user: ${_currentUser!.idUser}');
      }
    } catch (e) {
      debugPrint('❌ Error refresh wallet: $e');
    }
  }

  /// Callback: status role berubah (approve/reject driver, UMKM, KTM)
  Future<void> _onRoleStatusChanged() async {
    if (_currentUser == null || !isLoggedIn) return;
    try {
      await _loadUserRoles(_currentUser!.idUser);
      debugPrint('✅ Role status updated');
    } catch (e) {
      debugPrint('❌ Error refresh roles: $e');
    }
  }

  /// Callback: status pesanan berubah
  Future<void> _onPesananChanged() async {
    if (_currentUser == null || !isLoggedIn) return;
    // notifyListeners saja — halaman pesanan akan rebuild otomatis
    notifyListeners();
    debugPrint('📦 Status pesanan updated');
  }

  // Helper: cek apakah widget masih mounted (provider masih aktif)
  bool get mounted => _currentUser != null;

  // =========================================================================
  // REFRESH USER DATA - Untuk reload data user dari database
  // =========================================================================
  Future<void> refreshUserData() async {
    try {
      if (_currentUser == null) return;
      
      debugPrint('🔄 Refreshing user data...');
      
      // Reload user data dari database
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        
        // Reload roles
        await _loadUserRoles(user.idUser);
        
        debugPrint('✅ User data refreshed successfully');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing user data: $e');
    }
  }

    // =====================================================
    // 🔥 UPDATE ACTIVE VEHICLE (AUTO REFRESH HOME PAGE)
    // =====================================================
    void updateActiveVehicle({
      required String activeVehicle,
      required String jenisKendaraan,
    }) {
      if (_currentUser == null) return;

      _currentUser = _currentUser!.copyWith(
        activeVehicle: activeVehicle,
        jenisKendaraan: jenisKendaraan,
      );

      notifyListeners(); // 🔥 INI YANG MEMBUAT HOME PAGE AUTO REFRESH
    }

}