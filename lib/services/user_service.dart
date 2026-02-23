// ============================================================================
// USER_SERVICE.DART - FIXED VERSION WITH PROPER TRANSACTION
// ============================================================================
// SOLUSI FINAL untuk masalah FK constraint violation
// Menggunakan RPC function di Supabase untuk ensure transaction atomicity

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/models/user_detail_model.dart';
import 'package:sidrive/models/user_transaction_model.dart';
import 'package:sidrive/models/user_role_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════════════════
  // GET ALL USERS WITH STATISTICS
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<UserDetailModel>> getAllUsers({
    String? searchQuery,
    String? roleFilter,
    String? statusFilter,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('users')
          .select('''
            *,
            user_roles!inner(*)
          ''')
          .neq('role', 'admin');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('nama.ilike.%$searchQuery%,nim.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final response = await query.order('created_at', ascending: false);
      final List<UserDetailModel> users = [];
      
      for (var userData in response) {
        final userId = userData['id_user'];
        final stats = await _getUserStatistics(userId);
        final roles = (userData['user_roles'] as List)
            .map((r) => UserRoleModel.fromJson(r))
            .toList();

        if (roleFilter != null && roleFilter.isNotEmpty) {
          if (!roles.any((r) => r.role == roleFilter && r.isActive)) {
            continue;
          }
        }

        final userDetail = UserDetailModel.fromJson({
          ...userData,
          ...stats,
          'user_roles': roles.map((r) => r.toJson()).toList(),
        });

        users.add(userDetail);
      }

      if (offset != null && limit != null) {
        final start = offset;
        final end = offset + limit;
        return users.sublist(
          start < users.length ? start : users.length,
          end < users.length ? end : users.length,
        );
      }

      return users;
    } catch (e) {
      throw Exception('Error getting users: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET TOTAL USERS COUNT
  // ══════════════════════════════════════════════════════════════════════════
  Future<int> getTotalUsersCount({
    String? searchQuery,
    String? roleFilter,
    String? statusFilter,
  }) async {
    try {
      var query = _supabase
          .from('users')
          .select('id_user, user_roles!inner(*)')
          .neq('role', 'admin');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('nama.ilike.%$searchQuery%,nim.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final response = await query;
      
      if (roleFilter != null && roleFilter.isNotEmpty) {
        // Filter by role manually since we need to check user_roles
        final users = response as List;
        int count = 0;
        for (var userData in users) {
          final roles = (userData['user_roles'] as List)
              .map((r) => UserRoleModel.fromJson(r))
              .toList();
          if (roles.any((r) => r.role == roleFilter && r.isActive)) {
            count++;
          }
        }
        return count;
      }

      return (response as List).length;
    } catch (e) {
      throw Exception('Error getting total users count: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET USER STATISTICS
  // ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> _getUserStatistics(String userId) async {
    try {
      final result = <String, dynamic>{};

      final customerStats = await _supabase
          .from('pesanan')
          .select('jenis, status_pesanan, total_harga')
          .eq('id_user', userId);

      result['total_order_ojek'] = customerStats.where((p) => p['jenis'] == 'ojek').length;
      result['total_order_umkm'] = customerStats.where((p) => p['jenis'] == 'umkm').length;
      result['total_order_selesai'] = customerStats.where((p) => p['status_pesanan'] == 'selesai').length;
      result['total_order_dibatalkan'] = customerStats.where((p) => p['status_pesanan'] == 'dibatalkan').length;
      result['total_spending'] = customerStats
          .where((p) => p['status_pesanan'] == 'selesai')
          .fold<double>(0, (sum, p) => sum + ((p['total_harga'] ?? 0) as num).toDouble());

      final driverData = await _supabase
          .from('drivers')
          .select('*')
          .eq('id_user', userId)
          .maybeSingle();

      if (driverData != null) {
        final driverId = driverData['id_driver'] as String;
        result['id_driver'] = driverId;
        result['status_driver'] = driverData['status_driver'];
        result['rating_driver'] = driverData['rating_driver'];
        result['total_rating_driver'] = driverData['total_rating'];
        result['active_vehicle_type'] = driverData['active_vehicle_type'];
        result['jumlah_order_belum_setor'] = driverData['jumlah_order_belum_setor'];
        result['total_cash_pending'] = driverData['total_cash_pending'];

        // Hitung LIVE dari tabel pengiriman — kolom cached di drivers
        // (jumlah_pesanan_selesai & total_pendapatan) tidak pernah diupdate
        // oleh kodebase manapun sehingga selalu bernilai 0.
        // Pendekatan ini sama persis dengan pendapatan_service.dart.
        final pengirimanSelesai = await _supabase
            .from('pengiriman')
            .select('id_pengiriman, pesanan(ongkir)')
            .eq('id_driver', driverId)
            .eq('status_pengiriman', 'selesai');

        result['jumlah_pesanan_selesai_driver'] = (pengirimanSelesai as List).length;
        result['total_pendapatan_driver'] = (pengirimanSelesai as List)
            .fold<double>(0, (sum, item) {
              final ongkir = item['pesanan']?['ongkir'];
              if (ongkir == null) return sum;
              return sum + (ongkir is int ? ongkir.toDouble() : (ongkir as double));
            });
      }

      final umkmData = await _supabase
          .from('umkm')
          .select('*')
          .eq('id_user', userId)
          .maybeSingle();

      if (umkmData != null) {
        result['id_umkm'] = umkmData['id_umkm'];
        result['nama_toko'] = umkmData['nama_toko'];
        result['status_toko'] = umkmData['status_toko'];
        result['rating_toko'] = umkmData['rating_toko'];
        result['total_rating_umkm'] = umkmData['total_rating'];
        result['total_penjualan'] = umkmData['total_penjualan'];
        result['jumlah_produk_terjual'] = umkmData['jumlah_produk_terjual'];
        result['kategori_toko'] = umkmData['kategori_toko'];
        result['foto_toko'] = umkmData['foto_toko'];
      }

      return result;
    } catch (e) {
      print('Error getting user statistics: $e');
      return {};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET USER DETAIL BY ID
  // ══════════════════════════════════════════════════════════════════════════
  Future<UserDetailModel?> getUserDetail(String userId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select('*')
          .eq('id_user', userId)
          .single();

      final roles = await _supabase
          .from('user_roles')
          .select('*')
          .eq('id_user', userId)
          .eq('is_active', true);

      final stats = await _getUserStatistics(userId);

      return UserDetailModel.fromJson({
        ...userData,
        ...stats,
        'user_roles': roles,
      });
    } catch (e) {
      throw Exception('Error getting user detail: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET USER TRANSACTIONS
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<UserTransactionModel>> getUserTransactions(String userId) async {
    try {
      final response = await _supabase
          .from('pesanan')
          .select('''
            *,
            umkm(nama_toko),
            pengiriman(id_driver)
          ''')
          .eq('id_user', userId)
          .order('tanggal_pesanan', ascending: false);

      return (response as List).map((json) => UserTransactionModel.fromJson({
        ...json,
        'nama_toko': json['umkm']?['nama_toko'],
      })).toList();
    } catch (e) {
      throw Exception('Error getting transactions: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET DRIVER DELIVERIES
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<UserTransactionModel>> getDriverDeliveries(String userId) async {
    try {
      final driver = await _supabase
          .from('drivers')
          .select('id_driver')
          .eq('id_user', userId)
          .single();

      final response = await _supabase
          .from('pengiriman')
          .select('''
            *,
            pesanan!inner(
              id_pesanan,
              id_user,
              jenis,
              status_pesanan,
              total_harga,
              ongkir,
              jenis_kendaraan,
              tanggal_pesanan,
              waktu_selesai,
              payment_method,
              payment_status,
              users(nama)
            )
          ''')
          .eq('id_driver', driver['id_driver'])
          .order('created_at', ascending: false);

      return (response as List).map((json) => UserTransactionModel.fromJson({
        'id_pesanan': json['pesanan']['id_pesanan'],
        'id_user': json['pesanan']['id_user'],
        'jenis': json['pesanan']['jenis'],
        'status_pesanan': json['pesanan']['status_pesanan'],
        'total_harga': json['pesanan']['total_harga'],
        'ongkir': json['pesanan']['ongkir'],
        'jenis_kendaraan': json['pesanan']['jenis_kendaraan'],
        'tanggal_pesanan': json['pesanan']['tanggal_pesanan'],
        'waktu_selesai': json['pesanan']['waktu_selesai'],
        'payment_method': json['pesanan']['payment_method'],
        'payment_status': json['pesanan']['payment_status'],
        'customer_name': json['pesanan']['users']['nama'],
      })).toList();
    } catch (e) {
      throw Exception('Error getting deliveries: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET DRIVER RATINGS
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getDriverRatings(String userId) async {
    try {
      final driver = await _supabase
          .from('drivers')
          .select('id_driver')
          .eq('id_user', userId)
          .single();

      final response = await _supabase
          .from('rating_reviews')
          .select('''
            *,
            pesanan!inner(
              id_pesanan,
              jenis,
              tanggal_pesanan,
              users(nama)
            )
          ''')
          .eq('pesanan.pengiriman.id_driver', driver['id_driver'])
          .order('created_at', ascending: false);

      return (response as List).map((json) => {
        'id_rating': json['id_rating'],
        'rating': json['rating'],
        'ulasan': json['ulasan'],
        'created_at': json['created_at'],
        'id_pesanan': json['pesanan']['id_pesanan'],
        'customer_name': json['pesanan']['users']['nama'],
        'tanggal_pesanan': json['pesanan']['tanggal_pesanan'],
      }).toList();
    } catch (e) {
      throw Exception('Error getting driver ratings: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET UMKM ORDERS
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<UserTransactionModel>> getUmkmOrders(String userId) async {
    try {
      final umkm = await _supabase
          .from('umkm')
          .select('id_umkm')
          .eq('id_user', userId)
          .single();

      final response = await _supabase
          .from('pesanan')
          .select('''
            *,
            users(nama),
            detail_pesanan!inner(
              id_detail_pesanan,
              id_produk,
              jumlah,
              harga_satuan,
              produk(nama_produk)
            )
          ''')
          .eq('detail_pesanan.produk.id_umkm', umkm['id_umkm'])
          .order('tanggal_pesanan', ascending: false);

      return (response as List).map((json) => UserTransactionModel.fromJson({
        ...json,
        'customer_name': json['users']['nama'],
      })).toList();
    } catch (e) {
      throw Exception('Error getting UMKM orders: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET UMKM REVIEWS
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getUmkmReviews(String userId) async {
    try {
      final umkm = await _supabase
          .from('umkm')
          .select('id_umkm, nama_toko')
          .eq('id_user', userId)
          .single();

      final response = await _supabase
          .from('ulasan')
          .select('''
            *,
            users(nama),
            pesanan(tanggal_pesanan)
          ''')
          .eq('id_umkm', umkm['id_umkm'])
          .order('created_at', ascending: false);

      return (response as List).map((json) => {
        'id_ulasan': json['id_ulasan'],
        'rating': json['rating'],
        'ulasan': json['ulasan'],
        'created_at': json['created_at'],
        'customer_name': json['users']['nama'],
        'tanggal_pesanan': json['pesanan']['tanggal_pesanan'],
      }).toList();
    } catch (e) {
      throw Exception('Error getting UMKM reviews: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADD USER ROLE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> addUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      final existingRole = await _supabase
          .from('user_roles')
          .select()
          .eq('id_user', userId)
          .eq('role', role)
          .maybeSingle();

      if (existingRole != null) {
        await _supabase
            .from('user_roles')
            .update({
              'is_active': true,
              'status': role == 'driver' ? 'pending_verification' : 'active',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id_user', userId)
            .eq('role', role);
      } else {
        await _supabase.from('user_roles').insert({
          'id_user': userId,
          'role': role,
          'is_active': true,
          'status': role == 'driver' ? 'pending_verification' : 'active',
        });
      }

      if (role == 'driver') {
        final existingDriver = await _supabase
            .from('drivers')
            .select('id_driver')
            .eq('id_user', userId)
            .maybeSingle();

        if (existingDriver == null) {
          await _supabase.from('drivers').insert({
            'id_user': userId,
            'status_driver': 'pending',
            'rating_driver': 0.0,
            'total_rating': 0,
            'jumlah_pesanan_selesai': 0,
            'total_pendapatan': 0.0,
            'active_vehicle_type': null,
            'jumlah_order_belum_setor': 0,
            'total_cash_pending': 0.0,
          });
        }
      } else if (role == 'umkm') {
        final existingUmkm = await _supabase
            .from('umkm')
            .select('id_umkm')
            .eq('id_user', userId)
            .maybeSingle();

        if (existingUmkm == null) {
          await _supabase.from('umkm').insert({
            'id_user': userId,
            'nama_toko': 'Toko Baru',
            'status_toko': 'pending',
            'rating_toko': 0.0,
            'total_rating': 0,
            'total_penjualan': 0.0,
            'jumlah_produk_terjual': 0,
          });
        }
      }
    } catch (e) {
      throw Exception('Error adding role: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UPDATE ROLE STATUS
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> updateUserRoleStatus({
    required String userId,
    required String role,
    required String status,
  }) async {
    try {
      await _supabase
          .from('user_roles')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user', userId)
          .eq('role', role);

      if (role == 'driver' && status == 'active') {
        await _supabase
            .from('drivers')
            .update({'status_driver': 'available'})
            .eq('id_user', userId);
      } else if (role == 'umkm' && status == 'active') {
        await _supabase
            .from('umkm')
            .update({'status_toko': 'buka'})
            .eq('id_user', userId);
      }
    } catch (e) {
      throw Exception('Error updating role status: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DELETE ROLE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> deleteUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      print('\n🗑️ Deleting role: $role for user: $userId');

      if (role == 'driver') {
        // ✅ SPECIAL HANDLING untuk driver
        final driverData = await _supabase
            .from('drivers')
            .select('id_driver')
            .eq('id_user', userId)
            .maybeSingle();

        if (driverData != null) {
          final driverId = driverData['id_driver'];
          
          // 1. DELETE PENGIRIMAN DULU! (yang reference id_driver)
          print('  → Deleting pengiriman...');
          await _supabase
              .from('pengiriman')
              .delete()
              .eq('id_driver', driverId);
          
          // 2. DELETE CASH SETTLEMENTS
          print('  → Deleting cash_settlements...');
          await _supabase
              .from('cash_settlements')
              .delete()
              .eq('id_driver', driverId);
          
          // 3. NOW SAFE: Delete driver record
          print('  → Deleting driver...');
          await _supabase
              .from('drivers')
              .delete()
              .eq('id_driver', driverId);
          
          print('✅ Driver data deleted');
        }
        
      } else if (role == 'umkm') {
        // ✅ SPECIAL HANDLING untuk UMKM
        final umkmData = await _supabase
            .from('umkm')
            .select('id_umkm')
            .eq('id_user', userId)
            .maybeSingle();

        if (umkmData != null) {
          final umkmId = umkmData['id_umkm'];
          
          // 1. DELETE ALL detail_pesanan yang reference produk UMKM ini
          print('  → Deleting detail_pesanan for UMKM products...');
          final produkIds = await _supabase
              .from('produk')
              .select('id_produk')
              .eq('id_umkm', umkmId);
          
          if (produkIds.isNotEmpty) {
            final ids = (produkIds as List).map((p) => p['id_produk']).toList();
            await _supabase
                .from('detail_pesanan')
                .delete()
                .inFilter('id_produk', ids);
          }
          
          // 2. DELETE PRODUK
          print('  → Deleting produk...');
          await _supabase
              .from('produk')
              .delete()
              .eq('id_umkm', umkmId);
          
          // 3. DELETE WITHDRAWAL REQUESTS
          print('  → Deleting withdrawal_requests...');
          await _supabase
              .from('withdrawal_requests')
              .delete()
              .eq('id_umkm', umkmId);
          
          // 4. DELETE UMKM
          print('  → Deleting umkm...');
          await _supabase
              .from('umkm')
              .delete()
              .eq('id_umkm', umkmId);
          
          print('✅ UMKM data deleted');
        }
      }

      // Update user_roles
      await _supabase
          .from('user_roles')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user', userId)
          .eq('role', role);
      
      print('✅ Role deleted successfully\n');
    } catch (e) {
      print('❌ Error deleting role: $e');
      throw Exception('Error deleting role: ${e.toString()}');
    }
  }


  // ══════════════════════════════════════════════════════════════════════════
  // DELETE USER - MENGGUNAKAN DATABASE FUNCTION
  // ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> deleteUser({
    required String userId,
    bool forceDelete = true,
  }) async {
    try {
      print('\n🗑️ Starting user deletion process...');
      print('User ID: $userId');

      // Check related data (untuk info saja)
      final relatedData = await _checkRelatedData(userId);
      print('Related data: $relatedData');

      // ⚡ CRITICAL: Call RPC function and CHECK result!
      print('\n📞 Calling database RPC function: delete_user_cascade');
      
      final result = await _supabase.rpc('delete_user_cascade', params: {
        'target_user_id': userId,
      });
      
      print('✅ RPC result: $result');
      
      // ✅ CHECK if RPC actually succeeded!
      if (result != null && result is Map) {
        if (result['success'] == true) {
          print('✅ User deleted successfully via RPC!');
          return {
            'success': true,
            'message': 'User berhasil dihapus beserta semua data terkait',
            'deletedData': relatedData,
          };
        } else {
          // RPC returned error
          final errorMsg = result['message'] ?? 'Unknown RPC error';
          print('❌ RPC returned error: $errorMsg');
          throw Exception('RPC deletion failed: $errorMsg');
        }
      }
      
      // If result is null or weird format
      print('⚠️ Unexpected RPC result format: $result');
      throw Exception('RPC returned unexpected result');
      
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow; // ✅ PENTING: Throw ulang biar UI tau ada error!
    }
  }

 
  // ══════════════════════════════════════════════════════════════════════════
  // HELPER: Check Related Data
  // ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, int>> _checkRelatedData(String userId) async {
    try {
      final result = <String, int>{};
      int totalRecords = 0;

      // Count roles
      final roles = await _supabase
          .from('user_roles')
          .select('id_user_role')
          .eq('id_user', userId);
      result['roles'] = (roles as List).length;
      totalRecords += result['roles']!;

      // Count pesanan
      final pesanan = await _supabase
          .from('pesanan')
          .select('id_pesanan')
          .eq('id_user', userId);
      result['pesanan'] = (pesanan as List).length;
      totalRecords += result['pesanan']!;

      // Count ulasan
      try {
        final ulasan = await _supabase
            .from('ulasan')
            .select('id_ulasan')
            .eq('id_user', userId);
        result['ulasan'] = (ulasan as List).length;
        totalRecords += result['ulasan']!;
      } catch (e) {
        result['ulasan'] = 0;
      }

      // Count rating_reviews
      try {
        final ratings = await _supabase
            .from('rating_reviews')
            .select('id_rating')
            .eq('id_user', userId);
        result['ratings'] = (ratings as List).length;
        totalRecords += result['ratings']!;
      } catch (e) {
        result['ratings'] = 0;
      }

      // Count driver deliveries
      try {
        final driver = await _supabase
            .from('drivers')
            .select('id_driver')
            .eq('id_user', userId)
            .maybeSingle();

        if (driver != null) {
          final deliveries = await _supabase
              .from('pengiriman')
              .select('id_pengiriman')
              .eq('id_driver', driver['id_driver']);
          result['deliveries'] = (deliveries as List).length;
          totalRecords += result['deliveries']!;
        } else {
          result['deliveries'] = 0;
        }
      } catch (e) {
        result['deliveries'] = 0;
      }

      // Count UMKM products
      try {
        final umkm = await _supabase
            .from('umkm')
            .select('id_umkm')
            .eq('id_user', userId)
            .maybeSingle();

        if (umkm != null) {
          final products = await _supabase
              .from('produk')
              .select('id_produk')
              .eq('id_umkm', umkm['id_umkm']);
          result['products'] = (products as List).length;
          totalRecords += result['products']!;
        } else {
          result['products'] = 0;
        }
      } catch (e) {
        result['products'] = 0;
      }

      // Count transaksi keuangan
      try {
        final transaksi = await _supabase
            .from('transaksi_keuangan')
            .select('id_transaksi')
            .eq('id_user', userId);
        result['transaksi_keuangan'] = (transaksi as List).length;
        totalRecords += result['transaksi_keuangan']!;
      } catch (e) {
        result['transaksi_keuangan'] = 0;
      }

      result['total_records'] = totalRecords;
      return result;
    } catch (e) {
      print('Error checking related data: $e');
      return {'total_records': 0};
    }
  }
}