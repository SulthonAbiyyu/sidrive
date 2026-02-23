import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  final _supabase = Supabase.instance.client;

  // ==================== UNIFIED WALLET (CUSTOMER, DRIVER, UMKM) ====================
  
  /// Get unified wallet balance (berlaku untuk semua role)
  Future<double> getBalance(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('saldo_wallet')
          .eq('id_user', userId)
          .single();
      
      return (response['saldo_wallet'] ?? 0).toDouble();
    } catch (e) {
      print('❌ Error get balance: $e');
      return 0;
    }
  }

  /// Deduct wallet (atomic) - untuk payment order
  Future<Map<String, dynamic>> deductWalletForOrder({
    required String userId,
    required double amount,
    required String description,
  }) async {
    try {
      print('💳 Deducting wallet for order - Rp${amount.toStringAsFixed(0)}');

      final result = await _supabase.rpc('deduct_wallet_for_order', params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_description': description,
      });

      print('✅ Deduct result: $result');

      if (result == null) {
        return {
          'success': false,
          'message': 'Terjadi kesalahan pada server',
        };
      }

      final resultMap = result as Map<String, dynamic>;

      if (resultMap['success'] == true) {
        print('✅ Wallet deducted successfully!');
        print('📊 Old balance: Rp${resultMap['old_balance']}');
        print('📊 New balance: Rp${resultMap['new_balance']}');
      } else {
        print('⚠️ ${resultMap['message']}');
      }

      return resultMap;

    } catch (e) {
      print('❌ Error deduct wallet: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<bool> topUpWallet({
    required String userId,
    required double amount,
    required String paymentMethod,
    bool isDriverCashSettlement = false, // ✅ NEW parameter
  }) async {
    try {
      final currentBalance = await getBalance(userId);
      final newBalance = currentBalance + amount;

      await _supabase.from('users').update({
        'saldo_wallet': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_user', userId);

      // Record transaction
      await _supabase.from('transaksi_keuangan').insert({
        'id_user': userId,
        'jenis_transaksi': isDriverCashSettlement ? 'topup_settlement' : 'topup',
        'jumlah': amount,
        'saldo_sebelum': currentBalance,
        'saldo_sesudah': newBalance,
        'deskripsi': isDriverCashSettlement 
            ? 'Top up untuk cash settlement' 
            : 'Top up via $paymentMethod',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Top up success: +Rp${amount.toStringAsFixed(0)}');
      
      // ✅ Auto-submit settlement jika ini top-up untuk settlement
      if (isDriverCashSettlement) {
        print('🔄 Auto-submitting cash settlement...');
        final settlementResult = await submitCashSettlement(
          driverId: userId,
          topUpAmount: amount,
        );
        
        if (settlementResult['success'] == true) {
          print('✅ Settlement auto-submitted');
        } else {
          print('⚠️ Settlement submission failed: ${settlementResult['message']}');
        }
      }
      
      return true;
    } catch (e) {
      print('❌ Error top up wallet: $e');
      return false;
    }
  }

  // ==================== REFUND WALLET ====================
  
  /// Refund wallet jika order gagal/dibatalkan
  Future<bool> refundWalletForFailedOrder({
    required String userId,
    required String orderId,
    required double amount,
    required String reason,
  }) async {
    try {
      print('💸 Refunding wallet for failed order: $orderId');

      final user = await _supabase
          .from('users')
          .select('saldo_wallet')
          .eq('id_user', userId)
          .single();

      final oldBalance = (user['saldo_wallet'] ?? 0).toDouble();
      final newBalance = oldBalance + amount;

      await _supabase.from('users').update({
        'saldo_wallet': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_user', userId);

      await _supabase.from('pesanan').update({
        'refund_status': 'completed',
        'refund_amount': amount,
        'refund_processed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', orderId);

      await _supabase.from('transaksi_keuangan').insert({
        'id_user': userId,
        'id_pesanan': orderId,
        'jenis_transaksi': 'refund',
        'jumlah': amount,
        'saldo_sebelum': oldBalance,
        'saldo_sesudah': newBalance,
        'deskripsi': 'Refund: $reason - Order ID: $orderId',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Refund processed successfully!');
      return true;

    } catch (e) {
      print('❌ Error refund wallet: $e');
      return false;
    }
  }

  // ==================== CASH PAYMENT TRACKING (untuk Driver) ====================

  /// Increment cash order count for driver
  Future<void> incrementCashOrderCount(String driverId, double cashAmount) async {
    try {
      final driver = await _supabase
          .from('drivers')
          .select('jumlah_order_belum_setor, total_cash_pending')
          .eq('id_driver', driverId)
          .single();

      final newCount = (driver['jumlah_order_belum_setor'] ?? 0) + 1;
      final newCashPending = (driver['total_cash_pending'] ?? 0) + cashAmount;

      await _supabase.from('drivers').update({
        'jumlah_order_belum_setor': newCount,
        'total_cash_pending': newCashPending,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_driver', driverId);

      print('📊 Driver cash order count: $newCount, pending: Rp${newCashPending.toStringAsFixed(0)}');
    } catch (e) {
      print('❌ Error increment cash order: $e');
    }
  }

  /// Check if driver can accept new order (max 5 pending)
  Future<bool> canDriverAcceptOrder(String driverId) async {
    try {
      final driver = await _supabase
          .from('drivers')
          .select('jumlah_order_belum_setor')
          .eq('id_driver', driverId)
          .single();

      final count = driver['jumlah_order_belum_setor'] ?? 0;
      return count < 5;
    } catch (e) {
      print('❌ Error check driver order limit: $e');
      return false;
    }
  }

  /// Reset cash order count after driver top up (setor)
  Future<bool> resetCashOrderCount(String driverId, double topUpAmount) async {
    try {
      final driver = await _supabase
          .from('drivers')
          .select('total_cash_pending')
          .eq('id_driver', driverId)
          .single();

      final cashPending = (driver['total_cash_pending'] ?? 0).toDouble();

      if (topUpAmount < cashPending) {
        print('⚠️ Top up amount ($topUpAmount) less than pending ($cashPending)');
        return false;
      }

      await _supabase.from('drivers').update({
        'jumlah_order_belum_setor': 0,
        'total_cash_pending': 0,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_driver', driverId);

      print('✅ Driver cash order count reset');
      return true;
    } catch (e) {
      print('❌ Error reset cash order count: $e');
      return false;
    }
  }

  // ==================== WITHDRAWAL (PENARIKAN) ====================
  
  /// Request withdrawal (atomic & secure)
  Future<Map<String, dynamic>> requestWithdrawal({
    required String userId,
    required double amount,
    required String bankName,
    required String accountName,
    required String accountNumber,
  }) async {
    try {
      print('💰 Requesting withdrawal - Rp${amount.toStringAsFixed(0)}');

      // Validasi lokal dulu
      if (amount < 50000) {
        return {
          'success': false,
          'message': 'Minimal penarikan Rp 50.000',
        };
      }

      if (amount > 5000000) {
        return {
          'success': false,
          'message': 'Maksimal penarikan Rp 5.000.000',
        };
      }

      // Call RPC atomic function
      final result = await _supabase.rpc('request_withdrawal_atomic', params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_bank_name': bankName,
        'p_account_name': accountName,
        'p_account_number': accountNumber,
      });

      if (result == null) {
        return {
          'success': false,
          'message': 'Terjadi kesalahan pada server',
        };
      }

      final resultMap = result as Map<String, dynamic>;

      if (resultMap['success'] == true) {
        print('✅ Withdrawal request success!');
        print('📊 Withdrawal ID: ${resultMap['withdrawal_id']}');
        print('📊 New balance: Rp${resultMap['new_balance']}');
      } else {
        print('⚠️ ${resultMap['message']}');
      }

      return resultMap;

    } catch (e) {
      print('❌ Error request withdrawal: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Get withdrawal history
  Future<List<Map<String, dynamic>>> getWithdrawalHistory(String userId) async {
    try {
      final response = await _supabase
          .from('penarikan_saldo')
          .select()
          .eq('id_user', userId)
          .order('tanggal_pengajuan', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error get withdrawal history: $e');
      return [];
    }
  }

  /// Get pending withdrawal count today
  Future<int> getPendingWithdrawalCountToday(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('penarikan_saldo')
          .select('id_penarikan')
          .eq('id_user', userId)
          .gte('tanggal_pengajuan', startOfDay.toIso8601String());

      return (response as List).length;
    } catch (e) {
      print('❌ Error get pending count: $e');
      return 0;
    }
  }

  // ==================== ADMIN: PROCESS WITHDRAWAL ====================
  
  /// Admin: Approve withdrawal dan transfer
  /// ✅ FIXED: Pakai 'selesai' sesuai enum database (BUKAN 'completed')
  Future<bool> approveWithdrawal({
    required String withdrawalId,
    required String adminId,
    required String proofUrl,
  }) async {
    try {
      print('✅ Admin approving withdrawal: $withdrawalId');
      print('   Admin ID: $adminId');
      print('   Proof URL: $proofUrl');

      await _supabase.from('penarikan_saldo').update({
        'status': 'selesai', // ✅ FIXED: 'selesai' sesuai enum (bukan 'completed')
        'id_admin': adminId,
        'bukti_transfer': proofUrl,
        'tanggal_diproses': DateTime.now().toIso8601String(),
        'tanggal_selesai': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_penarikan', withdrawalId);

      print('✅ Withdrawal approved: $withdrawalId');
      return true;
    } catch (e) {
      print('❌ Error approve withdrawal: $e');
      return false;
    }
  }

  Future<bool> rejectWithdrawal({
    required String withdrawalId,
    required String adminId,
    required String reason,
  }) async {
    try {
      print('🚫 Admin rejecting withdrawal: $withdrawalId');

      // 1. Get withdrawal data
      final withdrawal = await _supabase
          .from('penarikan_saldo')
          .select('id_user, jumlah')
          .eq('id_penarikan', withdrawalId)
          .single();

      final userId = withdrawal['id_user'] as String;
      final amount = (withdrawal['jumlah'] as num).toDouble();

      // 2. Get current balance
      final user = await _supabase
          .from('users')
          .select('saldo_wallet')
          .eq('id_user', userId)
          .single();

      final oldBalance = (user['saldo_wallet'] ?? 0).toDouble();
      final newBalance = oldBalance + amount;

      // 3. ✅ KEMBALIKAN saldo ke USER
      await _supabase.from('users').update({
        'saldo_wallet': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_user', userId);

      // 4. ✅ KURANGI saldo admin_master_wallet
      await _supabase.rpc('update_admin_wallet', params: {
        'p_amount': -amount, // Negative = kurangi
        'p_type': 'withdrawal_reversal',
      });

      // 5. Update withdrawal status
      await _supabase.from('penarikan_saldo').update({
        'status': 'ditolak',
        'id_admin': adminId,
        'catatan_admin': reason,
        'tanggal_diproses': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_penarikan', withdrawalId);

      // 6. Record refund transaction
      await _supabase.from('transaksi_keuangan').insert({
        'id_user': userId,
        'jenis_transaksi': 'refund',
        'jumlah': amount,
        'saldo_sebelum': oldBalance,
        'saldo_sesudah': newBalance,
        'deskripsi': 'Pengembalian dana penarikan ditolak: $reason',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Withdrawal rejected & refunded: $withdrawalId');
      return true;
    } catch (e) {
      print('❌ Error reject withdrawal: $e');
      return false;
    }
  }

  // ==================== DRIVER CANCEL DEDUCTION ====================
  
  /// Deduct driver balance untuk cancel order (atomic)
  Future<Map<String, dynamic>> deductDriverCancelFee({
    required String driverId,
    required double amount,
    required String orderId,
    required String reason,
  }) async {
    try {
      print('💳 Deducting driver cancel fee - Rp${amount.toStringAsFixed(0)}');

      final result = await _supabase.rpc('deduct_wallet_for_order', params: {
        'p_user_id': driverId,
        'p_amount': amount,
        'p_description': 'Biaya cancel order - $reason',
      });

      print('✅ Deduct result: $result');

      if (result == null) {
        return {
          'success': false,
          'message': 'Terjadi kesalahan pada server',
        };
      }

      final resultMap = result as Map<String, dynamic>;

      if (resultMap['success'] == true) {
        // Record transaction untuk tracking
        await _supabase.from('transaksi_keuangan').insert({
          'id_user': driverId,
          'id_pesanan': orderId,
          'jenis_transaksi': 'biaya_cancel',
          'jumlah': -amount, // negative karena deduct
          'saldo_sebelum': resultMap['old_balance'],
          'saldo_sesudah': resultMap['new_balance'],
          'deskripsi': 'Biaya admin cancel order - Order ID: $orderId',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        print('✅ Driver cancel fee deducted successfully!');
      }

      return resultMap;

    } catch (e) {
      print('❌ Error deduct driver cancel fee: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== CASH SETTLEMENT ====================

  /// Driver submit cash settlement (after top-up)
  Future<Map<String, dynamic>> submitCashSettlement({
    required String driverId,
    required double topUpAmount,
    String? proofUrl,
  }) async {
    try {
      print('💵 ========== SUBMIT CASH SETTLEMENT ==========');
      print('💵 Driver: $driverId');
      print('💵 Top-up: Rp${topUpAmount.toStringAsFixed(0)}');

      // 1. Get driver's cash pending
      final driver = await _supabase
          .from('drivers')
          .select('total_cash_pending')
          .eq('id_driver', driverId)
          .single();

      final cashPending = (driver['total_cash_pending'] ?? 0).toDouble();

      if (cashPending <= 0) {
        return {
          'success': false,
          'message': 'Tidak ada cash yang perlu disetor',
        };
      }

      if (topUpAmount < cashPending) {
        return {
          'success': false,
          'message': 'Jumlah top-up kurang dari cash pending (Rp${cashPending.toStringAsFixed(0)})',
        };
      }

      // 2. Create settlement record
      final settlement = await _supabase.from('cash_settlements').insert({
        'id_driver': driverId,
        'jumlah_cash': cashPending,
        'jumlah_topup': topUpAmount,
        'bukti_topup_url': proofUrl,
        'status': 'pending',
        'tanggal_pengajuan': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      print('✅ Settlement created: ${settlement['id_settlement']}');

      return {
        'success': true,
        'settlement_id': settlement['id_settlement'],
        'cash_amount': cashPending,
        'topup_amount': topUpAmount,
        'message': 'Settlement berhasil diajukan, menunggu approval admin',
      };
    } catch (e) {
      print('❌ Error submit settlement: $e');
      return {
        'success': false,
        'message': 'Gagal submit settlement: ${e.toString()}',
      };
    }
  }

  /// Get pending settlements for driver
  Future<List<Map<String, dynamic>>> getDriverSettlements(String driverId) async {
    try {
      final response = await _supabase
          .from('cash_settlements')
          .select()
          .eq('id_driver', driverId)
          .order('tanggal_pengajuan', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error get settlements: $e');
      return [];
    }
  }
}