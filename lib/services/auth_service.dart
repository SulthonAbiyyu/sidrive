import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/config/constants.dart';
import 'package:sidrive/models/user_model.dart';
import 'package:sidrive/models/mahasiswa_model.dart';
import 'package:sidrive/models/user_role_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _determinePriorityRole(List<String> roles) {
    if (roles.contains('customer')) return 'customer';
    if (roles.contains('driver')) return 'driver';
    if (roles.contains('umkm')) return 'umkm';
    return roles.first; // Fallback
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CHECK NIM - Verifikasi NIM di database mahasiswa_aktif
  // ──────────────────────────────────────────────────────────────────────────
  Future<MahasiswaModel?> checkNim(String nim) async {
    try {
      print('🔍 [AUTH_SERVICE] checkNim called with nim: $nim');
      print('🔍 [AUTH_SERVICE] Table name: ${ApiEndpoints.mahasiswaAktif}');
      
      final response = await _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .select()
          .eq('nim', nim)
          .eq('status_mahasiswa', 'aktif')
          .maybeSingle();

      print('🔍 [AUTH_SERVICE] Query response: $response');
      
      if (response == null) {
        print('❌ [AUTH_SERVICE] Response is NULL - mahasiswa not found');
        return null;
      }
      
      print('✅ [AUTH_SERVICE] Mahasiswa found, parsing to model...');
      final mahasiswa = MahasiswaModel.fromJson(response);
      print('✅ [AUTH_SERVICE] Parsed successfully: ${mahasiswa.namaLengkap}');
      
      return mahasiswa;
    } catch (e, stackTrace) {
      print('❌ [AUTH_SERVICE] Exception in checkNim: $e');
      print('❌ [AUTH_SERVICE] StackTrace: $stackTrace');
      throw Exception('Error checking NIM: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CHECK NIM AVAILABILITY 
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> isNimAvailable(String nim) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.users)
          .select('nim')
          .eq('nim', nim)
          .maybeSingle();

      // Kalau null = belum terdaftar = available
      // Kalau ada = sudah terdaftar = not available
      return response == null;
    } catch (e) {
      throw Exception('Error checking NIM availability: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REGISTER (SINGLE ROLE) - Untuk backward compatibility
  // Method lama tetap ada, tapi sekarang lebih baik pakai registerMultiRole()
  // ──────────────────────────────────────────────────────────────────────────
  Future<UserModel> register({
    required String nim,
    required String nama,
    required String noTelp,
    required String password,
    required String role, // 'customer', 'driver', 'umkm'
  }) async {
    // Redirect ke registerMultiRole dengan 1 role saja
    return await registerMultiRole(
      nim: nim,
      nama: nama,
      noTelp: noTelp,
      password: password,
      roles: [role], // Convert single role ke list
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REGISTER MULTI ROLE 
  // Kalau NIM sudah ada, REJECT! User harus login dulu.
  // ──────────────────────────────────────────────────────────────────────────
  Future<UserModel> registerMultiRole({
    required String nim,
    required String nama,
    required String noTelp,
    required String password,
    required List<String> roles, // ['customer', 'driver', 'umkm']
  }) async {
    try {
      // ========================================================================
      // STEP 1: CEK APAKAH NIM SUDAH TERDAFTAR (SAFETY CHECK)
      // ========================================================================
      final isAvailable = await isNimAvailable(nim);
      
      if (!isAvailable) {
        throw Exception(
          'NIM sudah terdaftar! Silakan login untuk menambah role baru.'
        );
      }

      // ========================================================================
      // STEP 2: REGISTER DI SUPABASE AUTH
      // ========================================================================
      final email = nim + AppConstants.emailDomain;

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Registrasi gagal di Supabase Auth');
      }

      final userId = authResponse.user!.id;

      // ========================================================================
      // STEP 3: TENTUKAN ACTIVE ROLE & STATUS USER
      // ========================================================================
      // Prioritas: customer > driver > umkm > first
      String activeRole = _determinePriorityRole(roles);  

      // Status: active kalau ada customer, pending kalau tidak
      String userStatus = roles.contains('customer') 
          ? 'active' 
          : 'pending_verification';

      // ========================================================================
      // STEP 4: INSERT KE TABLE USERS
      // ========================================================================
      await _supabase.from(ApiEndpoints.users).insert({
        'id_user': userId,
        'nim': nim,
        'nama': nama,
        'email': email,
        'no_telp': noTelp,
        'password_hash': 'dummy', // Tidak dipakai, auth by Supabase
        'role': activeRole, // Role yang sedang aktif
        'status': userStatus,
        'is_verified': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      // ========================================================================
      // STEP 5: INSERT KE TABLE USER_ROLES
      // ========================================================================
      for (String role in roles) {
        final status = (role == 'customer') ? 'active' : 'pending_verification';
        
        await _supabase.from('user_roles').insert({
          'id_user': userId,
          'role': role,
          'status': status,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // ========================================================================
      // STEP 6: AMBIL DATA USER YANG BARU DIBUAT
      // ========================================================================
      final userResponse = await _supabase
          .from(ApiEndpoints.users)
          .select()
          .eq('id_user', userId)
          .single();

      return UserModel.fromJson(userResponse);

    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('NIM sudah terdaftar! Silakan login.');
      }
      throw Exception('Error auth: ${e.message}');
    } catch (e) {
      throw Exception('Error registrasi: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LOGIN - Login dengan NIM & Password
  // ──────────────────────────────────────────────────────────────────────────
  Future<UserModel> login({
    required String nim,
    required String password,
  }) async {
    try {
      final email = nim + AppConstants.emailDomain;

      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Login gagal');
      }

      final userId = authResponse.user!.id;

      // Update last_login
      await _supabase
          .from(ApiEndpoints.users)
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id_user', userId);

      // Get user data
      final userResponse = await _supabase
          .from(ApiEndpoints.users)
          .select()
          .eq('id_user', userId)
          .single();

      return UserModel.fromJson(userResponse);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login')) {
        throw Exception('NIM atau password salah');
      }
      throw Exception('Error login: ${e.message}');
    } catch (e) {
      throw Exception('Error login: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LOGOUT - Logout user
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error logout: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET CURRENT USER - Ambil data user yang sedang login
  // ──────────────────────────────────────────────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from(ApiEndpoints.users)
          .select()
          .eq('id_user', user.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // IS LOGGED IN
  // ──────────────────────────────────────────────────────────────────────────
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET USER ID
  // ──────────────────────────────────────────────────────────────────────────
  String? getUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET USER ROLES - Ambil semua role yang dimiliki user
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<UserRoleModel>> getUserRoles(String userId) async {
    try {
      final response = await _supabase
          .from('user_roles')
          .select()
          .eq('id_user', userId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => UserRoleModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error getting user roles: ${e.toString()}');
    }
  }

  // SiDrive - Originally developed by Muhammad Sulthon Abiyyu
  // Contact: 0812-4975-4004
  // Created: November 2025

  // ──────────────────────────────────────────────────────────────────────────
  // ADD USER ROLE - ✅ Ini untuk user yang SUDAH LOGIN mau tambah role baru
  // ──────────────────────────────────────────────────────────────────────────
  Future<UserRoleModel> addUserRole({
    required String userId,
    required String role, // 'driver' atau 'umkm'
  }) async {
    try {
      // Check apakah role sudah ada
      final existing = await _supabase
          .from('user_roles')
          .select()
          .eq('id_user', userId)
          .eq('role', role)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Anda sudah memiliki role $role');
      }

      final status = (role == 'customer') ? 'active' : 'pending_verification';
      
      final userRoleData = {
        'id_user': userId,
        'role': role,
        'status': status,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_roles')
          .insert(userRoleData)
          .select()
          .single();

      return UserRoleModel.fromJson(response);
    } catch (e) {
      throw Exception('Error adding user role: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPDATE ACTIVE ROLE - Ganti role yang sedang aktif
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> updateActiveRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      // ✅ FIX: Check apakah user punya role ini (tidak peduli status!)
      // User dengan pending_verification BOLEH switch ke role tersebut
      final userRole = await _supabase
          .from('user_roles')
          .select()
          .eq('id_user', userId)
          .eq('role', newRole)
          .eq('is_active', true)
          .maybeSingle();

      if (userRole == null) {
        throw Exception('Role $newRole tidak tersedia');
      }

      // Update active role di table users
      await _supabase
          .from(ApiEndpoints.users)
          .update({'role': newRole})
          .eq('id_user', userId);
    } catch (e) {
      throw Exception('Error updating active role: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET AVAILABLE ROLES - Role yang bisa dipilih (sudah active)
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<String>> getAvailableRoles(String userId) async {
    try {
      final response = await _supabase
          .from('user_roles')
          .select('role')
          .eq('id_user', userId)
          .eq('status', 'active')
          .eq('is_active', true);

      return (response as List)
          .map((item) => item['role'] as String)
          .toList();
    } catch (e) {
      throw Exception('Error getting available roles: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET KTM VERIFICATION STATUS - Cek status verifikasi KTM user
  // ──────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getKtmVerificationStatus(String userId) async {
    try {
      final response = await _supabase
          .from('ktm_verification_requests')
          .select()
          .eq('id_user', userId)
          .order('created_at', ascending: false)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error getting KTM verification status: $e');
      return null;
    }
  }
}


// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025