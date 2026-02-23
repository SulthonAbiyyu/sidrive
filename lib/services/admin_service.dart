// ============================================================================
// ADMIN SERVICE - FINAL VERSION WITH SUPABASE AUTH
// PRODUCTION READY - SECURE & COMPLETE
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:sidrive/models/cash_settlement_model.dart';
import 'package:sidrive/models/financial_tracking_model.dart';
import 'package:sidrive/models/ktm_verification_model.dart'; 
import 'package:sidrive/services/ktm_verification_service.dart';
import 'package:sidrive/models/saved_bank_account_model.dart';


class AdminService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════════════════
  // ADMIN LOGIN - SUPABASE AUTH VERSION
  // ══════════════════════════════════════════════════════════════════════════

  Future<AdminModel> adminLogin({
    required String username,
    required String password,
  }) async {
    print('🔍 AdminService.adminLogin called');
    print('   Username: $username');
    
    try {
      // STEP 1: Cari email admin by username
      final adminData = await _supabase
          .from('admins')
          .select('email, username, nama, level, is_active')
          .eq('username', username)
          .eq('is_active', true)
          .maybeSingle();

      if (adminData == null) {
        print('❌ Admin not found');
        throw Exception('Username tidak ditemukan atau tidak aktif');
      }

      final email = adminData['email'] as String;
      print('✅ Admin found: ${adminData['nama']}');
      print('   Email: $email');

      // STEP 2: Login dengan Supabase Auth
      print('🔐 Logging in with Supabase Auth...');
      
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        print('❌ Auth login failed');
        throw Exception('Login gagal, password salah');
      }

      print('✅ Supabase Auth login success!');
      print('   User ID: ${authResponse.user!.id}');

      // STEP 3: Get admin details lengkap
      final adminDetails = await _supabase
          .from('admins')
          .select('*')
          .eq('id_user', authResponse.user!.id)
          .eq('is_active', true)
          .single();

      print('✅ Admin details loaded');
      print('   Level: ${adminDetails['level']}');

      return AdminModel(
        idAdmin: adminDetails['id_admin'] ?? '',
        idUser: authResponse.user!.id,
        level: adminDetails['level'] ?? 'admin',
        isActive: adminDetails['is_active'] ?? true,
        createdAt: adminDetails['created_at'] != null
            ? DateTime.parse(adminDetails['created_at'])
            : DateTime.now(),
        nim: '',
        nama: adminDetails['nama'] ?? 'Admin',
        email: adminDetails['email'] ?? authResponse.user!.email ?? '',
        fotoProfil: null,
        username: adminDetails['username'] ?? '',
      );
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Password salah');
      }
      if (e.message.contains('Email not confirmed')) {
        throw Exception('Email belum dikonfirmasi');
      }
      throw Exception('Login gagal: ${e.message}');
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> logoutAdmin() async {
    try {
      await _supabase.auth.signOut();
      print('✅ Admin logged out');
    } catch (e) {
      print('⚠️ Logout error: $e');
      // Tetap anggap sukses logout meskipun ada error
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET CURRENT ADMIN
  // ══════════════════════════════════════════════════════════════════════════

  Future<AdminModel?> getCurrentAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('ℹ️ No current user');
        return null;
      }

      print('🔍 Getting current admin for user: ${user.id}');

      final response = await _supabase
    .from('admins')
    .select('*')
    .eq('id_user', user.id)
    .eq('is_active', true)
    .maybeSingle();

if (response == null) {
  print('⚠️ User exists but not an admin');
  return null;
}

  print('✅ Current admin loaded: ${response['nama']}');

  return AdminModel(
    idAdmin: response['id_admin'] ?? '',
    idUser: user.id,
    level: response['level'] ?? 'admin',
    isActive: response['is_active'] ?? true,
    createdAt: response['created_at'] != null
        ? DateTime.parse(response['created_at'])
        : DateTime.now(),
    nim: '',
    nama: response['nama'] ?? 'Admin',
    email: response['email'] ?? user.email ?? '',
    fotoProfil: null,
    username: response['username'] ?? '',
  );
    } catch (e) {
      print('❌ Error getting current admin: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════

  Future<DashboardSummary> getDashboardSummary() async {
    try {
      print('🔍 Getting dashboard summary...');
      
      final response = await _supabase
          .from('view_admin_dashboard')
          .select()
          .maybeSingle();

      if (response == null) {
        print('⚠️ Dashboard view returned null, using empty summary');
        return DashboardSummary.empty();
      }

      print('✅ Dashboard summary loaded');
      return DashboardSummary.fromJson(response);
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      return DashboardSummary.empty();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VERIFIKASI DRIVER
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<DriverVerification>> getPendingDrivers() async {
    print('🔍 AdminService: Getting pending drivers from VIEW...');
    
    try {
      final response = await _supabase
          .from('view_pending_drivers')
          .select()
          .order('tanggal_daftar', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      print('✅ AdminService: Got ${data.length} pending drivers from VIEW');

      if (data.isEmpty) {
        print('ℹ️ No pending drivers found');
        return [];
      }

      return data.map((json) {
        return DriverVerification.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ AdminService: Error getting pending drivers: $e');
      rethrow;
    }
  }

  Future<DriverVerification?> getDriverDetail(String idVehicle) async {
    print('🔍 AdminService: Getting driver detail for vehicle $idVehicle');
    
    try {
      final response = await _supabase
          .from('view_pending_drivers')
          .select()
          .eq('id_vehicle', idVehicle)
          .maybeSingle();

      if (response == null) {
        print('❌ Driver not found in view');
        return null;
      }

      print('✅ AdminService: Got driver detail from VIEW');
      return DriverVerification.fromJson(response);
    } catch (e) {
      print('❌ AdminService: Error getting driver detail: $e');
      return null;
    }
  }

  Future<bool> approveDriver(String idUser, String idDriver, String idVehicle) async {
    print('🔍 AdminService: Approving driver vehicle');
    print('   ID User: $idUser');
    print('   ID Driver: $idDriver');
    print('   ID Vehicle: $idVehicle');
    
    try {
      // ✅ PANGGIL RPC FUNCTION (lebih aman!)
      final result = await _supabase.rpc('approve_driver_vehicle', params: {
        'p_id_vehicle': idVehicle,
        'p_id_user': idUser,
      });
      
      if (result['success'] == true) {
        print('✅ Vehicle approved & activated via RPC!');
        
        // Send notification
        await _sendNotification(
          idUser: idUser,
          judul: 'Kendaraan Disetujui ✅',
          pesan: 'Selamat! Kendaraan Anda telah disetujui oleh admin dan sudah aktif.',
          jenis: 'sistem',
        );
        
        return true;
      }
      
      throw Exception('RPC returned false');
    } catch (e) {
      print('❌ Error approving driver: $e');
      rethrow;
    }
  }

  Future<bool> rejectDriver(String idUser, String idDriver, String idVehicle, String alasan) async {
    print('🔍 AdminService: Rejecting driver vehicle');
    print('   ID User: $idUser');
    print('   ID Vehicle: $idVehicle');
    print('   Reason: $alasan');
    
    try {
      // Update status kendaraan
      await _supabase
          .from('driver_vehicles')
          .update({
            'status_verifikasi': 'rejected',
            'alasan_penolakan': alasan,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id_vehicle', idVehicle);

      print('✅ Vehicle status updated to rejected');

      // Send notification
      await _sendNotification(
        idUser: idUser,
        judul: 'Kendaraan Ditolak ❌',
        pesan: 'Mohon maaf, pengajuan kendaraan ditolak.\n\nAlasan: $alasan',
        jenis: 'sistem',
      );

      print('✅✅✅ REJECTION COMPLETE! ✅✅✅');
      return true;
    } catch (e) {
      print('❌❌❌ ERROR REJECTING DRIVER ❌❌❌');
      print('Error: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VERIFIKASI UMKM - FIXED VERSION 🔥
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<UmkmVerification>> getPendingUmkm() async {
    print('🔍 AdminService: Getting pending UMKM from VIEW...');
    
    try {
      final response = await _supabase
          .from('view_pending_umkm')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      print('✅ AdminService: Got ${data.length} pending UMKM from VIEW');

      return data.map((json) => UmkmVerification.fromJson(json)).toList();
    } catch (e) {
      print('❌ AdminService: Error getting pending UMKM: $e');
      rethrow;
    }
  }

  Future<UmkmVerification?> getUmkmDetail(String idUmkm) async {
    print('🔍 AdminService: Getting UMKM detail for $idUmkm');
    
    try {
      final response = await _supabase
          .from('view_pending_umkm')
          .select()
          .eq('id_umkm', idUmkm)
          .maybeSingle();

      if (response == null) {
        print('❌ UMKM not found in view');
        return null;
      }

      print('✅ AdminService: Got UMKM detail from VIEW');
      return UmkmVerification.fromJson(response);
    } catch (e) {
      print('❌ AdminService: Error getting UMKM detail: $e');
      return null;
    }
  }

  Future<bool> approveUmkm(String idUser, String idUmkm) async {
    print('🔍 AdminService: Approving UMKM');
    print('   ID User: $idUser');
    print('   ID UMKM: $idUmkm');
    
    try {
      // Validasi UMKM exists dan ambil bank info
      final umkmInfo = await _supabase
          .from('umkm')
          .select('nama_toko, id_user, nama_bank, nomor_rekening, nama_rekening')
          .eq('id_umkm', idUmkm)
          .maybeSingle();

      if (umkmInfo == null) {
        throw Exception('UMKM tidak ditemukan');
      }

      print('🔄 Updating user role status...');
      
      // Update user role status
      await _supabase
          .from('user_roles')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id_user', idUser)
          .eq('role', 'umkm');

      print('✅ User role status updated to active');

      // 🔥 FIX: Update bank info ke table users (seperti driver!)
      if (umkmInfo['nama_bank'] != null && 
          umkmInfo['nomor_rekening'] != null) {
        print('💳 Updating bank info to users table...');
        
        await _supabase
            .from('users')
            .update({
              'nama_bank': umkmInfo['nama_bank'],
              'nomor_rekening': umkmInfo['nomor_rekening'],
              'nama_rekening': umkmInfo['nama_rekening'],
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id_user', idUser);
        
        print('✅ Bank info updated to users table!');
      } else {
        print('ℹ️ No bank info to update');
      }

      // Send notification
      await _sendNotification(
        idUser: idUser,
        judul: 'Toko UMKM Disetujui ✅',
        pesan: 'Selamat! Toko UMKM Anda "${umkmInfo['nama_toko']}" telah disetujui oleh admin. Anda sudah bisa mulai berjualan!',
        jenis: 'sistem',
      );

      print('✅✅✅ UMKM APPROVAL COMPLETE! ✅✅✅');
      return true;
    } catch (e) {
      print('❌❌❌ ERROR APPROVING UMKM ❌❌❌');
      print('Error: $e');
      rethrow;
    }
  }

  Future<bool> rejectUmkm(String idUser, String idUmkm, String alasan) async {
    print('🔍 AdminService: Rejecting UMKM');
    print('   ID User: $idUser');
    print('   ID UMKM: $idUmkm');
    print('   Reason: $alasan');
    
    try {
      // Get UMKM info
      final umkmInfo = await _supabase
          .from('umkm')
          .select('nama_toko')
          .eq('id_umkm', idUmkm)
          .maybeSingle();

      if (umkmInfo == null) {
        throw Exception('UMKM tidak ditemukan');
      }

      print('🔄 Updating user role status...');
      
      // Update user role status
      await _supabase
          .from('user_roles')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id_user', idUser)
          .eq('role', 'umkm');

      print('✅ User role status updated to rejected');

      // Send notification
      await _sendNotification(
        idUser: idUser,
        judul: 'Toko UMKM Ditolak ❌',
        pesan: 'Mohon maaf, pengajuan toko UMKM "${umkmInfo['nama_toko']}" ditolak.\n\nAlasan: $alasan',
        jenis: 'sistem',
      );

      print('✅✅✅ UMKM REJECTION COMPLETE! ✅✅✅');
      return true;
    } catch (e) {
      print('❌❌❌ ERROR REJECTING UMKM ❌❌❌');
      print('Error: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PENARIKAN SALDO - FIXED VERSION
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<PenarikanSaldo>> getPendingPenarikan() async {
    print('🔍 AdminService: Getting pending penarikan...');
    
    try {
      // 1. Get penarikan data (WITHOUT JOIN)
      final response = await _supabase
          .from('penarikan_saldo')
          .select('''
            id_penarikan,
            id_user,
            jumlah,
            nama_bank,
            nama_rekening,
            nomor_rekening,
            status,
            tanggal_pengajuan,
            created_at
          ''')
          .eq('status', 'pending')
          .order('tanggal_pengajuan', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      print('✅ AdminService: Got ${data.length} pending penarikan');

      if (data.isEmpty) {
        print('ℹ️ No pending penarikan found');
        return [];
      }

      // 2. Get user IDs
      final userIds = data.map((item) => item['id_user'] as String).toList();

      // 3. Fetch users data in bulk
      final usersResponse = await _supabase
          .from('users')
          .select('id_user, nama, nim, role')
          .inFilter('id_user', userIds);

      final List<dynamic> usersData = usersResponse as List<dynamic>;
      
      // 4. Create user map for quick lookup
      final userMap = <String, Map<String, dynamic>>{};
      for (var user in usersData) {
        userMap[user['id_user']] = user;
      }

      print('✅ AdminService: Loaded ${usersData.length} user data');

      // 5. Map to PenarikanSaldo objects
      return data.map((json) {
        final userId = json['id_user'] as String;
        final userData = userMap[userId] ?? {};
        
        return PenarikanSaldo(
          idPenarikan: json['id_penarikan'],
          idUser: userId,
          nim: userData['nim'] ?? '',
          nama: userData['nama'] ?? 'Unknown',
          role: userData['role'] ?? '',
          jumlah: (json['jumlah'] as num).toDouble(),
          namaBank: json['nama_bank'],
          nomorRekening: json['nomor_rekening'],
          namaRekening: json['nama_rekening'],
          status: json['status'],
          tanggalPengajuan: DateTime.parse(json['tanggal_pengajuan']),
        );
      }).toList();
    } catch (e) {
      print('❌ AdminService: Error getting pending penarikan: $e');
      rethrow;
    }
  }

  /// ✅ FIXED: Approve dengan upload bukti transfer
  Future<bool> approveWithdrawalWithProof({
    required String withdrawalId,
    required String adminId,
    required String proofUrl,
  }) async {
    print('✅ AdminService: Approving withdrawal...');
    print('   Withdrawal ID: $withdrawalId');
    print('   Admin ID: $adminId');
    print('   Proof URL: $proofUrl');
    
    try {
      // 1. Update status penarikan
      await _supabase.from('penarikan_saldo').update({
        'status': 'selesai', // ✅ FIXED: Pakai 'selesai' sesuai enum
        'id_admin': adminId,
        'bukti_transfer': proofUrl,
        'tanggal_diproses': DateTime.now().toIso8601String(),
        'tanggal_selesai': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_penarikan', withdrawalId);

      // 2. Get data untuk notifikasi
      final penarikan = await _supabase
          .from('penarikan_saldo')
          .select('id_user, jumlah')
          .eq('id_penarikan', withdrawalId)
          .single();

      // 3. Send notification
      await _sendNotification(
        idUser: penarikan['id_user'],
        judul: '✅ Penarikan Saldo Berhasil',
        pesan: 'Penarikan saldo Rp ${(penarikan['jumlah'] as num).toStringAsFixed(0)} telah diproses. Dana akan diterima dalam 1-3 hari kerja.',
        jenis: 'withdrawal',
      );

      print('✅ AdminService: Withdrawal approved successfully');
      return true;
    } catch (e) {
      print('❌ AdminService: Error approving withdrawal: $e');
      rethrow;
    }
  }

  /// ✅ FIXED: Reject dengan refund saldo
  Future<bool> rejectWithdrawalWithRefund({
    required String withdrawalId,
    required String adminId,
    required String reason,
  }) async {
    print('🚫 AdminService: Rejecting withdrawal...');
    print('   Withdrawal ID: $withdrawalId');
    print('   Admin ID: $adminId');
    print('   Reason: $reason');
    
    try {
      // 1. Get withdrawal data
      final withdrawal = await _supabase
          .from('penarikan_saldo')
          .select('id_user, jumlah')
          .eq('id_penarikan', withdrawalId)
          .single();

      final userId = withdrawal['id_user'] as String;
      final amount = (withdrawal['jumlah'] as num).toDouble();

      print('   Refunding Rp${amount.toStringAsFixed(0)} to user $userId');

      // 2. Get current balance
      final user = await _supabase
          .from('users')
          .select('saldo_wallet')
          .eq('id_user', userId)
          .single();

      final oldBalance = (user['saldo_wallet'] ?? 0).toDouble();
      final newBalance = oldBalance + amount;

      // 3. Refund saldo
      await _supabase.from('users').update({
        'saldo_wallet': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_user', userId);

      // 4. Update withdrawal status
      await _supabase.from('penarikan_saldo').update({
        'status': 'ditolak', // ✅ FIXED: Pakai 'ditolak' sesuai enum
        'id_admin': adminId,
        'catatan_admin': reason,
        'tanggal_diproses': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_penarikan', withdrawalId);

      // 5. Record refund transaction
      await _supabase.from('transaksi_keuangan').insert({
        'id_user': userId,
        'jenis_transaksi': 'refund',
        'jumlah': amount,
        'saldo_sebelum': oldBalance,
        'saldo_sesudah': newBalance,
        'deskripsi': 'Pengembalian dana penarikan ditolak: $reason - ID: $withdrawalId',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 6. Send notification
      await _sendNotification(
        idUser: userId,
        judul: '❌ Penarikan Saldo Ditolak',
        pesan: 'Penarikan saldo Rp ${amount.toStringAsFixed(0)} ditolak. Alasan: $reason. Saldo telah dikembalikan ke wallet Anda.',
        jenis: 'withdrawal',
      );

      print('✅ AdminService: Withdrawal rejected & refunded successfully');
      return true;
    } catch (e) {
      print('❌ AdminService: Error rejecting withdrawal: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER - NOTIFICATION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _sendNotification({
    required String idUser,
    required String judul,
    required String pesan,
    required String jenis,
  }) async {
    try {
      await _supabase.from('notifikasi').insert({
        'id_user': idUser,
        'judul': judul,
        'pesan': pesan,
        'jenis': jenis,
        'status': 'unread',
        'tanggal_notifikasi': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Notification sent to $idUser');
    } catch (e) {
      print('⚠️ Warning: Failed to send notification: $e');
      // Don't throw - notification failure shouldn't break the main flow
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CRUD ADMIN - UNTUK SUPER_ADMIN ONLY
  // ══════════════════════════════════════════════════════════════════════════

  /// Get all admins dengan filter
  Future<List<AdminModel>> getAllAdmins({
    String? searchQuery,
    String? filterLevel,
    String? filterStatus,
    int limit = 20,
    int offset = 0,
  }) async {
    print('🔍 AdminService: Getting all admins...');
    print('   Search: ${searchQuery ?? "none"}');
    print('   Level: ${filterLevel ?? "all"}');
    print('   Status: ${filterStatus ?? "all"}');
    print('   Limit: $limit, Offset: $offset');
    
    try {
      var query = _supabase
          .from('admins')
          .select('*');

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('username.ilike.%$searchQuery%,nama.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      if (filterLevel != null && filterLevel != 'Semua') {
        query = query.eq('level', filterLevel);
      }

      if (filterStatus != null && filterStatus != 'Semua') {
        final isActive = filterStatus == 'aktif';
        query = query.eq('is_active', isActive);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final List<dynamic> data = response as List<dynamic>;

      print('✅ AdminService: Got ${data.length} admins');

      return data.map((json) => AdminModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ AdminService: Error getting admins: $e');
      rethrow;
    }
  }

  Future<int> getTotalAdmins({
    String? filterLevel,
    String? filterStatus,
  }) async {
    try {
      var query = _supabase
          .from('admins')
          .select('*');

      if (filterLevel != null && filterLevel != 'Semua') {
        query = query.eq('level', filterLevel);
      }

      if (filterStatus != null && filterStatus != 'Semua') {
        final isActive = filterStatus == 'aktif';
        query = query.eq('is_active', isActive);
      }

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;
      return data.length;
    } catch (e) {
      print('❌ Error getting total admins: $e');
      return 0;
    }
  }

    /// Create new admin - MENGGUNAKAN EDGE FUNCTION
  Future<void> createAdmin({
    required String email,
    required String password,
    required String username,
    required String nama,
    required String level,
  }) async {
    print('🔥 AdminService: Creating new admin via Edge Function...');
    print('   Email: $email');
    print('   Username: $username');
    print('   Level: $level');
    
    try {
      // Dapatkan token user yang sedang login
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final token = session.accessToken;

      // Panggil Edge Function
      final response = await _supabase.functions.invoke(
        'create-admin',
        body: {
          'email': email,
          'password': password,
          'username': username,
          'nama': nama,
          'level': level,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Edge Function response status: ${response.status}');
      print('📡 Edge Function response data: ${response.data}');

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map ? errorData['error'] : 'Unknown error';
        throw Exception(errorMessage);
      }

      final responseData = response.data;
      if (responseData is Map && responseData['success'] == true) {
        print('✅✅✅ Admin created successfully via Edge Function! ✅✅✅');
      } else {
        throw Exception('Failed to create admin');
      }
    } catch (e) {
      print('❌❌❌ Error creating admin: $e');
      rethrow;
    }
  }

  /// Update admin - MENGGUNAKAN EDGE FUNCTION
  Future<void> updateAdmin({
    required String idAdmin,
    required String nama,
    required String level,
    required bool isActive,
    String? newPassword,
  }) async {
    print('🔥 AdminService: Updating admin via Edge Function...');
    print('   ID: $idAdmin');
    print('   Nama: $nama');
    print('   Level: $level');
    print('   Active: $isActive');
    print('   New Password: ${newPassword != null ? "YES" : "NO"}');
    
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final token = session.accessToken;

      final response = await _supabase.functions.invoke(
        'update-admin',
        body: {
          'id_admin': idAdmin,
          'nama': nama,
          'level': level,
          'is_active': isActive,
          'new_password': newPassword,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Edge Function response status: ${response.status}');
      print('📡 Edge Function response data: ${response.data}');

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map ? errorData['error'] : 'Unknown error';
        throw Exception(errorMessage);
      }

      final responseData = response.data;
      if (responseData is Map && responseData['success'] == true) {
        print('✅✅✅ Admin updated successfully via Edge Function! ✅✅✅');
      } else {
        throw Exception('Failed to update admin');
      }
    } catch (e) {
      print('❌❌❌ Error updating admin: $e');
      rethrow;
    }
  }

  /// Delete admin (soft delete) - MENGGUNAKAN EDGE FUNCTION
  Future<void> deleteAdmin(String idAdmin) async {
    print('🗑️ AdminService: Deleting admin via Edge Function...');
    print('   ID: $idAdmin');
    
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final token = session.accessToken;

      final response = await _supabase.functions.invoke(
        'delete-admin',
        body: {
          'id_admin': idAdmin,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Edge Function response status: ${response.status}');
      print('📡 Edge Function response data: ${response.data}');

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map ? errorData['error'] : 'Unknown error';
        throw Exception(errorMessage);
      }

      final responseData = response.data;
      if (responseData is Map && responseData['success'] == true) {
        print('✅✅✅ Admin deleted successfully via Edge Function! ✅✅✅');
      } else {
        throw Exception('Failed to delete admin');
      }
    } catch (e) {
      print('❌❌❌ Error deleting admin: $e');
      rethrow;
    }
  }

  /// Get level list untuk dropdown
  List<String> getLevelList() {
    return ['admin', 'super_admin'];
  }

  // ============================================================================
  // FINANCIAL TRACKING MANAGEMENT
  // ============================================================================

  /// Get financial tracking data dengan filter
  Future<List<FinancialTrackingModel>> getFinancialTracking({
    String? jenisFilter,
    String? metodePembayaran,
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    print('🔍 AdminService: Getting financial tracking...');

    try {
      var query = _supabase
          .from('view_financial_tracking')
          .select();

      if (jenisFilter != null && jenisFilter.isNotEmpty) {
        query = query.eq('jenis_pesanan', jenisFilter);
      }
      if (metodePembayaran != null && metodePembayaran.isNotEmpty) {
        query = query.eq('metode_pembayaran', metodePembayaran);
      }
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('financial_status', statusFilter);
      }
      if (startDate != null) {
        query = query.gte('tanggal_pesanan', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('tanggal_pesanan', endDate.toIso8601String());
      }

      final List<dynamic> response = await query
          .order('tanggal_pesanan', ascending: false)
          .range(offset, offset + limit - 1);

      print('✅ Got ${response.length} financial tracking records');
      return response.map((json) => FinancialTrackingModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting financial tracking: $e');
      rethrow;
    }
  }

  /// Get financial summary
  Future<FinancialSummary> getFinancialSummary() async {
    print('🔍 AdminService: Getting financial summary...');

    try {
      final response = await _supabase
          .from('view_financial_summary')
          .select()
          .maybeSingle();

      if (response == null) {
        print('⚠️ Financial summary returned null, using empty');
        return FinancialSummary.empty();
      }

      print('✅ Financial summary loaded');
      return FinancialSummary.fromJson(response);
    } catch (e) {
      print('❌ Error loading financial summary: $e');
      return FinancialSummary.empty();
    }
  }

  /// Search financial tracking by order ID atau customer name
  Future<List<FinancialTrackingModel>> searchFinancialTracking(String query) async {
    print('🔍 AdminService: Searching financial tracking: $query');

    try {
      final List<dynamic> response = await _supabase
          .from('view_financial_tracking')
          .select()
          .or('id_pesanan.ilike.%$query%,customer_nama.ilike.%$query%')
          .order('tanggal_pesanan', ascending: false)
          .limit(50);

      print('✅ Found ${response.length} results');
      return response.map((json) => FinancialTrackingModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error searching financial tracking: $e');
      rethrow;
    }
  }

  /// Get total count untuk pagination
  Future<int> getFinancialTrackingCount({
    String? jenisFilter,
    String? metodePembayaran,
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('view_financial_tracking')
          .select('id_pesanan');

      if (jenisFilter != null && jenisFilter.isNotEmpty) {
        query = query.eq('jenis_pesanan', jenisFilter);
      }
      if (metodePembayaran != null && metodePembayaran.isNotEmpty) {
        query = query.eq('metode_pembayaran', metodePembayaran);
      }
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('financial_status', statusFilter);
      }
      if (startDate != null) {
        query = query.gte('tanggal_pesanan', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('tanggal_pesanan', endDate.toIso8601String());
      }

      final List<dynamic> response = await query;
      return response.length;
    } catch (e) {
      print('❌ Error getting financial tracking count: $e');
      return 0;
    }
  }

  // ============================================================================
  // REFUND MANAGEMENT
  // ============================================================================

  /// Get count refund pending saja (efisien untuk badge sidebar)
  /// Refund tersimpan di tabel 'pesanan'
  /// - Wallet refund  : paid_with_wallet=true, wallet_deducted_amount>0, refund_status IS NULL atau 'pending_manual'
  /// - Transfer refund: paid_with_wallet=false/null, refund_status='pending_manual'
  Future<int> getPendingRefundCount() async {
    try {
      print('🔍 AdminService: Getting pending refund count...');

      // Ambil semua pesanan dibatalkan/gagal yang masih pending refund
      final response = await _supabase
          .from('pesanan')
          .select('id_pesanan, paid_with_wallet, wallet_deducted_amount, refund_status')
          .inFilter('status_pesanan', ['dibatalkan', 'gagal'])
          .or('refund_status.is.null,refund_status.eq.pending_manual');

      final List<dynamic> rows = response as List<dynamic>;

      // Terapkan logika filter yang sama dengan RefundManagementContent
      int count = 0;
      for (final row in rows) {
        final paidWithWallet = row['paid_with_wallet'] == true;
        final refundStatus   = row['refund_status'] as String?;
        final walletAmount   = (row['wallet_deducted_amount'] ?? 0) as num;

        if (paidWithWallet) {
          // Wallet: hitung jika ada saldo yang perlu dikembalikan
          if (walletAmount > 0 &&
              (refundStatus == null || refundStatus == 'pending_manual')) {
            count++;
          }
        } else {
          // Transfer: hitung hanya jika pending_manual
          if (refundStatus == 'pending_manual') count++;
        }
      }

      print('✅ AdminService: Pending refund count = $count');
      return count;
    } catch (e) {
      print('❌ AdminService: Error getting refund count: $e');
      return 0;
    }
  }

  // ============================================================================
  // CASH SETTLEMENT MANAGEMENT
  // ============================================================================

  Future<List<CashSettlementModel>> getPendingSettlements() async {
    print('🔍 AdminService: Getting pending settlements...');
    
    try {
      final response = await _supabase
          .from('view_pending_cash_settlements')
          .select()
          .order('tanggal_pengajuan', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      print('✅ Got ${data.length} pending settlements');
      
      return data.map((json) => CashSettlementModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting settlements: $e');
      rethrow;
    }
  }

  Future<bool> approveSettlement(String settlementId, String adminId, {String? catatan}) async {
    print('✅ Approving settlement: $settlementId');
    
    try {
      final result = await _supabase.rpc('approve_cash_settlement', params: {
        'p_settlement_id': settlementId,
        'p_admin_id': adminId,
        'p_catatan': catatan,
      });

      if (result['success'] == true) {
        print('✅ Settlement approved!');
        
        // ✅ FIX: Pakai driver_user_id (bukan driver_id!)
        final driverUserId = result['driver_user_id'];  // ← INI YANG BENAR!
        
        await _sendNotification(
          idUser: driverUserId,  // ✅ Ini ID dari tabel users
          judul: '✅ Settlement Disetujui',
          pesan: 'Settlement cash Anda disetujui! Counter reset, Anda bisa tarik order lagi.',
          jenis: 'sistem',
        );
        return true;
      }
      
      throw Exception(result['message']);
    } catch (e) {
      print('❌ Error approve settlement: $e');
      rethrow;
    }
  }

  Future<bool> rejectSettlement(String settlementId, String adminId, String alasan) async {
    print('🚫 Rejecting settlement: $settlementId');
    
    try {
      final result = await _supabase.rpc('reject_cash_settlement', params: {
        'p_settlement_id': settlementId,
        'p_admin_id': adminId,
        'p_catatan': alasan,
      });

      if (result['success'] == true) {
        print('✅ Settlement rejected!');
        // Note: driver_id tidak ada di result reject, kita perlu get dulu
        final settlement = await _supabase
            .from('cash_settlements')
            .select('id_driver')
            .eq('id_settlement', settlementId)
            .single();
            
        final driver = await _supabase
            .from('drivers')
            .select('id_user')
            .eq('id_driver', settlement['id_driver'])
            .single();
        
        await _sendNotification(
          idUser: driver['id_user'],
          judul: '❌ Settlement Ditolak',
          pesan: 'Settlement ditolak: $alasan. Top-up di-refund, silakan ajukan ulang.',
          jenis: 'sistem',
        );
        return true;
      }
      
      throw Exception(result['message']);
    } catch (e) {
      print('❌ Error reject settlement: $e');
      rethrow;
    }
  }

  Future<AdminWalletStats> getAdminWalletStats(String adminId) async {
    try {
      // ✅ Ambil dari admin_master_wallet (shared wallet)
      final wallet = await _supabase
          .from('admin_master_wallet')
          .select('saldo_wallet, total_settlement_approved, total_settlement_rejected')
          .eq('id', 1)
          .single();
      
      final pendingCount = await _supabase
          .from('cash_settlements')
          .select('id_settlement')
          .eq('status', 'pending');
      
      return AdminWalletStats.fromJson({
        'total_cash_masuk': wallet['saldo_wallet'] ?? 0,
        'total_settlement_approved': wallet['total_settlement_approved'] ?? 0,
        'total_settlement_rejected': wallet['total_settlement_rejected'] ?? 0,
        'pending_count': (pendingCount as List).length,
      });
    } catch (e) {
      print('❌ Error get admin wallet stats: $e');
      return AdminWalletStats.empty();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // KTM VERIFICATION
  // ══════════════════════════════════════════════════════════════════════════

  final KtmVerificationService _ktmService = KtmVerificationService();

  /// Get pending KTM verification requests
  Future<List<KtmVerificationModel>> getPendingKtmVerifications() async {
    try {
      print('🔍 AdminService: Getting pending KTM verifications...');
      
      final requests = await _ktmService.getPendingRequests();
      
      print('✅ AdminService: Found ${requests.length} pending requests');
      return requests;
    } catch (e) {
      print('❌ AdminService: Error getting pending KTM: $e');
      throw Exception('Gagal load pending KTM verifications: ${e.toString()}');
    }
  }

  // SiDrive - Originally developed by Muhammad Sulthon Abiyyu
  // Contact: 0812-4975-4004
  // Created: November 2025

  /// Approve KTM verification
  Future<bool> approveKtmVerification(String requestId, String adminId) async {
    try {
      print('✅ AdminService: Approving KTM verification...');
      print('   Request ID: $requestId');
      print('   Admin ID: $adminId');
      
      // 1. Get request detail untuk ambil user_id
      final request = await _ktmService.getUserVerificationRequestById(requestId);
      if (request == null) {
        throw Exception('Request tidak ditemukan');
      }
      
      // 2. Approve request di database
      await _ktmService.approveRequest(requestId, adminId);
      
      // 3. Kirim FCM notification ke user (jika user sudah register)
      if (request.idUser != null) {
        await _sendKtmApprovalNotification(request.idUser!);
      }
      
      print('✅ AdminService: KTM verification approved successfully');
      return true;
    } catch (e) {
      print('❌ AdminService: Error approving KTM: $e');
      throw Exception('Gagal approve KTM verification: ${e.toString()}');
    }
  }

  /// Reject KTM verification
  Future<bool> rejectKtmVerification(
    String requestId,
    String adminId,
    String reason,
  ) async {
    try {
      print('❌ AdminService: Rejecting KTM verification...');
      print('   Request ID: $requestId');
      print('   Admin ID: $adminId');
      print('   Reason: $reason');
      
      // 1. Get request detail untuk ambil user_id
      final request = await _ktmService.getUserVerificationRequestById(requestId);
      if (request == null) {
        throw Exception('Request tidak ditemukan');
      }
      
      // 2. Reject request di database
      await _ktmService.rejectRequest(requestId, adminId, reason);
      
      // 3. Kirim FCM notification ke user (jika user sudah register)
      if (request.idUser != null) {
        await _sendKtmRejectionNotification(request.idUser!, reason);
      }
      
      print('✅ AdminService: KTM verification rejected successfully');
      return true;
    } catch (e) {
      print('❌ AdminService: Error rejecting KTM: $e');
      throw Exception('Gagal reject KTM verification: ${e.toString()}');
    }
  }

  /// Send FCM notification for KTM approval ✅ METHOD BARU
  Future<void> _sendKtmApprovalNotification(String userId) async {
    try {
      print('📤 Sending KTM approval notification to user: $userId');
      
      // Get user FCM token
      final userData = await _supabase
          .from('users')
          .select('fcm_token, nama')
          .eq('id_user', userId)
          .single();
      
      final fcmToken = userData['fcm_token'] as String?;
      final nama = userData['nama'] as String? ?? 'User';
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ User FCM token is null, skip sending notification');
        return;
      }
      
      // TODO: Kirim FCM menggunakan Firebase Admin SDK atau Cloud Function
      // Untuk sekarang, kita simpan ke table notifications dulu
      await _supabase.from('notifications').insert({
        'id_user': userId,
        'type': 'ktm_verification',
        'status': 'approved',
        'title': 'KTM Terverifikasi ✅',
        'body': 'Selamat $nama! KTM Anda telah diverifikasi. Silakan lanjutkan pendaftaran.',
        'data': {'type': 'ktm_verification', 'status': 'approved'},
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ KTM approval notification sent');
      
    } catch (e) {
      print('❌ Error sending KTM approval notification: $e');
      // Don't throw error, notification failure shouldn't block approval
    }
  }

  /// Send FCM notification for KTM rejection ✅ METHOD BARU
  Future<void> _sendKtmRejectionNotification(String userId, String reason) async {
    try {
      print('📤 Sending KTM rejection notification to user: $userId');
      
      // Get user FCM token
      final userData = await _supabase
          .from('users')
          .select('fcm_token, nama')
          .eq('id_user', userId)
          .single();
      
      final fcmToken = userData['fcm_token'] as String?;
      final nama = userData['nama'] as String? ?? 'User';
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ User FCM token is null, skip sending notification');
        return;
      }
      
      // TODO: Kirim FCM menggunakan Firebase Admin SDK atau Cloud Function
      // Untuk sekarang, kita simpan ke table notifications dulu
      await _supabase.from('notifications').insert({
        'id_user': userId,
        'type': 'ktm_verification',
        'status': 'rejected',
        'title': 'KTM Ditolak ❌',
        'body': 'Maaf $nama, verifikasi KTM ditolak. Alasan: $reason',
        'data': {
          'type': 'ktm_verification',
          'status': 'rejected',
          'reason': reason,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ KTM rejection notification sent');
      
    } catch (e) {
      print('❌ Error sending KTM rejection notification: $e');
      // Don't throw error, notification failure shouldn't block rejection
    }
  }

  Future<List<Map<String, dynamic>>> fetchTarifConfigs() async {
    try {
      print('🔍 AdminService: Fetching tarif configs...');
      final data = await _supabase
          .from('app_config')
          .select('id, config_key, config_value, config_type, label, description, category, sort_order, updated_at, updated_by_name')
          .order('category', ascending: true)
          .order('sort_order', ascending: true);

      print('✅ AdminService: Loaded ${(data as List).length} tarif configs');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ AdminService: Error fetching tarif configs: $e');
      rethrow;
    }
  }

  /// Update satu nilai config
  Future<void> updateTarifConfig({
    required String configKey,
    required String newValue,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      print('🔄 AdminService: Updating config $configKey = $newValue');

      // Ambil nama admin untuk updated_by_name
      String updatedByName = 'Admin';
      if (userId != null) {
        final adminData = await _supabase
            .from('admins')
            .select('nama')
            .eq('id_user', userId)
            .maybeSingle();
        updatedByName = adminData?['nama'] ?? 'Admin';
      }

      await _supabase
          .from('app_config')
          .update({
            'config_value': newValue,
            'updated_by': userId,
            'updated_by_name': updatedByName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('config_key', configKey);

      print('✅ AdminService: Config $configKey updated successfully');
    } catch (e) {
      print('❌ AdminService: Error updating config: $e');
      rethrow;
    }
  }

  /// Batch update beberapa config sekaligus
  Future<void> batchUpdateTarifConfigs(Map<String, String> updates) async {
    try {
      print('🔄 AdminService: Batch updating ${updates.length} configs...');
      for (final entry in updates.entries) {
        await updateTarifConfig(
          configKey: entry.key,
          newValue: entry.value,
        );
      }
      print('✅ AdminService: Batch update complete');
    } catch (e) {
      print('❌ AdminService: Error in batch update: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADMIN PAYOUT (WITHDRAWAL/DISBURSEMENT)
  // ══════════════════════════════════════════════════════════════════════════

  /// Create admin payout request
  Future<bool> createAdminPayout({
    required String adminId,
    required String adminNama,
    required double amount,
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    String? notes,
  }) async {
    try {
      print('💰 AdminService: Creating payout request...');
      print('   Admin: $adminNama');
      print('   Amount: $amount');
      print('   Bank: $bankCode - $accountNumber');

      // STEP 1: Insert payout record to database
      final payoutData = await _supabase
          .from('admin_payouts')
          .insert({
            'id_admin': adminId,
            'admin_nama': adminNama,
            'amount': amount,
            'bank_code': bankCode.toLowerCase(),
            'bank_name': bankName,
            'account_number': accountNumber,
            'account_holder_name': accountHolderName,
            'status': 'pending',
            'notes': notes,
          })
          .select()
          .single();

      final payoutId = payoutData['id'];
      print('✅ Payout record created with ID: $payoutId');

      // STEP 2: Call Edge Function to process payout with Midtrans
      print('🔄 Calling Edge Function: create-payout...');
      
      final response = await _supabase.functions.invoke(
        'create-payout',
        body: {
          'payoutId': payoutId,
          'adminId': adminId,
          'amount': amount,
          'bankCode': bankCode.toLowerCase(),
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountHolderName': accountHolderName,
          'notes': notes ?? 'Admin Payout - ${DateTime.now().toIso8601String()}',
        },
      );

      if (response.status == 200) {
        final result = response.data;
        print('✅ Edge Function success: ${result['message']}');
        print('   Reference No: ${result['data']['reference_no']}');
        return true;
      } else {
        print('❌ Edge Function failed: ${response.data}');
        throw Exception(response.data['error'] ?? 'Failed to create payout');
      }
    } catch (e) {
      print('❌ AdminService: Error creating payout: $e');
      rethrow;
    }
  }

  /// Get payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory({
    String? adminId,
    String? status,
    int limit = 50,
  }) async {
    try {
      print('🔄 AdminService: Fetching payout history...');
      
      // ✅ FIX: Build query dengan conditional filters yang benar
      var queryBuilder = _supabase
          .from('admin_payouts')
          .select();

      // Apply filters jika ada
      if (adminId != null) {
        queryBuilder = queryBuilder.eq('id_admin', adminId);
      }

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status);
      }

      // Execute query dengan order & limit
      final data = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);
      
      print('✅ Loaded ${(data as List).length} payout records');
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ AdminService: Error fetching payout history: $e');
      return [];
    }
  }

  Future<List<SavedBankAccount>> getSavedBankAccounts(String adminId) async {
    try {
      print('💳 AdminService: Getting saved bank accounts for admin: $adminId');
      
      final response = await _supabase
          .from('admin_saved_bank_accounts')
          .select()
          .eq('id_admin', adminId)
          .order('is_default', ascending: false)
          .order('last_used_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      print('✅ AdminService: Got ${data.length} saved accounts');
      
      return data.map((json) => SavedBankAccount.fromJson(json)).toList();
    } catch (e) {
      print('❌ AdminService: Error getting saved accounts: $e');
      return [];
    }
  }

  /// Save new bank account
  Future<void> saveBankAccount({
    required String adminId,
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    required bool setAsDefault,
  }) async {
    try {
      print('💾 AdminService: Saving bank account...');
      print('   Admin ID: $adminId');
      print('   Bank: $bankCode - $accountNumber');
      print('   Set as default: $setAsDefault');
      
      await _supabase.from('admin_saved_bank_accounts').insert({
        'id_admin': adminId,
        'bank_code': bankCode.toLowerCase(),
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder_name': accountHolderName,
        'is_default': setAsDefault,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ AdminService: Bank account saved');
    } catch (e) {
      print('❌ AdminService: Error saving bank account: $e');
      
      // Handle duplicate account error
      if (e.toString().contains('duplicate')) {
        throw Exception('Rekening ini sudah tersimpan');
      }
      
      rethrow;
    }
  }

  /// Update last used timestamp
  Future<void> updateLastUsedAccount(String accountId) async {
    try {
      await _supabase
          .from('admin_saved_bank_accounts')
          .update({
            'last_used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', accountId);
      
      print('✅ Updated last used timestamp for account: $accountId');
    } catch (e) {
      print('⚠️ Warning: Failed to update last used: $e');
      // Don't throw - this is not critical
    }
  }

  /// Delete saved bank account
  Future<void> deleteSavedBankAccount(String accountId) async {
    try {
      print('🗑️ AdminService: Deleting bank account: $accountId');
      
      await _supabase
          .from('admin_saved_bank_accounts')
          .delete()
          .eq('id', accountId);
      
      print('✅ AdminService: Bank account deleted');
    } catch (e) {
      print('❌ AdminService: Error deleting bank account: $e');
      rethrow;
    }
  }

  /// Set default bank account
  Future<void> setDefaultBankAccount(String accountId) async {
    try {
      print('⭐ AdminService: Setting default bank account: $accountId');
      
      // Get admin_id from this account
      final account = await _supabase
          .from('admin_saved_bank_accounts')
          .select('id_admin')
          .eq('id', accountId)
          .single();
      
      final adminId = account['id_admin'];
      
      // Unset all defaults for this admin
      await _supabase
          .from('admin_saved_bank_accounts')
          .update({'is_default': false})
          .eq('id_admin', adminId);
      
      // Set this as default
      await _supabase
          .from('admin_saved_bank_accounts')
          .update({'is_default': true})
          .eq('id', accountId);
      
      print('✅ AdminService: Default bank account set');
    } catch (e) {
      print('❌ AdminService: Error setting default: $e');
      rethrow;
    }
  }
}


// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025