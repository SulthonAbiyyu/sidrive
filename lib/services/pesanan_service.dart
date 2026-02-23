// PESANAN SERVICE - Service untuk handle order ojek & UMKM
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/services/wallet_service.dart';

class PesananService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getActiveOrder(String userId) async {
    try {
      print('🔍 Checking active order for user: $userId');
      
      final response = await _supabase
          .from('pesanan')
          .select()
          .eq('id_user', userId)
          .not('status_pesanan', 'in', '(selesai,dibatalkan,gagal)')  // ← INI KUNCINYA!
          .maybeSingle();
      
      if (response != null) {
        print('⚠️ Found active order: ${response['id_pesanan']} - Status: ${response['status_pesanan']}');
      } else {
        print('✅ No active order found');
      }
      
      return response;
    } catch (e) {
      print('❌ Error get active order: $e');
      return null;
    }
  }

  // ==================== UMKM ORDER METHODS ====================

  /// Validasi anti self-order untuk UMKM
  Future<bool> validateUmkmOrder({
    required String customerId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      print('🔍 Validating UMKM order...');
      
      // Ambil semua id_umkm dari cart
      final umkmIds = cartItems.map((item) => item['id_umkm']).toSet().toList();
      
      // Cek apakah customer punya toko di id_umkm manapun yang ada di cart
      final ownedUmkm = await _supabase
          .from('umkm')
          .select('id_umkm, nama_toko')
          .eq('id_user', customerId)
          .inFilter('id_umkm', umkmIds)
          .maybeSingle();
      
      if (ownedUmkm != null) {
        print('❌ Self-order detected! Customer owns: ${ownedUmkm['nama_toko']}');
        return false;
      }
      
      print('✅ Validation passed - not self-order');
      return true;
      
    } catch (e) {
      print('❌ Error validating order: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createOrderUmkm({
    required String idCustomer,
    required String idUmkm,
    required List<Map<String, dynamic>> items, // [{idProduk, namaProduk, hargaSatuan, jumlah, catatanItem}]
    required String alamatAsal,        // Alamat toko UMKM
    required String lokasiAsal,
    required String alamatPengiriman,
    required String lokasiPengiriman, // POINT geometry
    required double subtotalProduk,
    required double ongkir,
    required double biayaAdmin,
    required double totalHarga,
    required String paymentMethod,
    required String metodePengiriman,
    String? jenisKendaraan,
    String? catatanPesanan,
  }) async {
    try {
      print('📦 ========== CREATE UMKM ORDER ==========');
      print('   Customer: $idCustomer');
      print('   UMKM: $idUmkm');
      print('   Items: ${items.length}');
      print('   Subtotal: Rp${subtotalProduk.toStringAsFixed(0)}');
      print('   Ongkir: Rp${ongkir.toStringAsFixed(0)}');
      print('   Admin: Rp${biayaAdmin.toStringAsFixed(0)}');
      print('   Total: Rp${totalHarga.toStringAsFixed(0)}');
      print('   Metode: $metodePengiriman'); // ✅ NEW
      
      // Hitung fee gateway HANYA jika transfer/e-wallet
      double feeGateway = 0;
      if (paymentMethod != 'cash') {
        feeGateway = totalHarga * 0.02;
      }
      
      double biayaAdminBersih = biayaAdmin - feeGateway;
      
     String statusAwal;
     String paymentStatusAwal;

      if (paymentMethod == 'cash') {
        // Cash order: langsung menunggu konfirmasi UMKM
        statusAwal = 'menunggu_konfirmasi';
        paymentStatusAwal = 'pending';
      } else {
        // Non-cash: tunggu pembayaran dulu, baru konfirmasi UMKM
        statusAwal = 'menunggu_pembayaran';
        paymentStatusAwal = 'pending';
      }
      
      // 1️⃣ INSERT HEADER PESANAN
      final pesananData = {
        'id_user': idCustomer,
        'id_umkm': idUmkm,
        'jenis': 'umkm',
        'alamat_asal': alamatAsal,
        'lokasi_asal': lokasiAsal,
        'alamat_tujuan': alamatPengiriman,
        'lokasi_tujuan': lokasiPengiriman,
        'subtotal': subtotalProduk,
        'ongkir': ongkir,
        'total_harga': totalHarga,
        'fee_admin': biayaAdminBersih,
        'fee_payment_gateway': feeGateway,
        'metode_pengiriman': metodePengiriman,
        'jenis_kendaraan': jenisKendaraan,
        'status_pesanan': statusAwal,
        'payment_method': paymentMethod,
        'payment_status': paymentStatusAwal,
        'catatan': catatanPesanan,
        'tanggal_pesanan': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final pesanan = await _supabase
          .from('pesanan')
          .insert(pesananData)
          .select()
          .single();
      
      final idPesanan = pesanan['id_pesanan'];
      print('✅ Pesanan created: $idPesanan');
      
      final detailItems = items.map((item) => {
        'id_pesanan': idPesanan,
        'id_produk': item['idProduk'],
        'nama_produk': item['namaProduk'],
        'jumlah': item['jumlah'],
        'harga_satuan': item['hargaSatuan'],
        'subtotal': item['hargaSatuan'] * item['jumlah'],
        'catatan_item': item['catatanItem'],
        'created_at': DateTime.now().toIso8601String(),
      }).toList();
      
      await _supabase.from('detail_pesanan').insert(detailItems);
      
      print('✅ ${detailItems.length} items inserted');
      
      for (var item in items) {
        await _supabase.rpc('reduce_product_stock', params: {
          'p_product_id': item['idProduk'],
          'p_quantity': item['jumlah'],
        });
      }
      
      print('✅ Stock updated for ${items.length} products');
      
      return pesanan;
      
    } catch (e) {
      print('❌ Error create UMKM order: $e');
      throw Exception('Gagal membuat pesanan: ${e.toString()}');
    }
  }

  Future<void> completeUmkmOrder(String idPesanan) async {
    try {
      print('💰 ========== COMPLETE UMKM ORDER ==========');
      print('🕐 Timestamp: ${DateTime.now().toIso8601String()}');
      
      // 1. Get order details
      final pesanan = await _supabase
          .from('pesanan')
          .select('id_umkm, subtotal, ongkir, metode_pengiriman, payment_method, payment_status, id_user')
          .eq('id_pesanan', idPesanan)
          .single();
      
      final paymentStatus = pesanan['payment_status'] as String;
      final paymentMethod = pesanan['payment_method'] as String;
      
      print('   Payment: $paymentMethod');
      print('   Status: $paymentStatus');
      
      if (paymentMethod != 'cash' && paymentStatus != 'paid') {
        throw Exception('Order belum dibayar. Payment status: $paymentStatus');
      }
      
      final idUmkm = pesanan['id_umkm'];
      final subtotal = (pesanan['subtotal'] ?? 0).toDouble();
      final ongkir = (pesanan['ongkir'] ?? 0).toDouble();
      final metodePengiriman = pesanan['metode_pengiriman'] ?? 'driver';
      
      final feeAdminProduk = subtotal * 0.10;
      final pendapatanUmkm = subtotal - feeAdminProduk;  // 90%
      
      print('   Subtotal: Rp${subtotal.toStringAsFixed(0)}');
      print('   Ongkir: Rp${ongkir.toStringAsFixed(0)}');
      print('   Pendapatan UMKM: Rp${pendapatanUmkm.toStringAsFixed(0)}');
      print('   Metode Pengiriman: $metodePengiriman');
      
      // 2. Get UMKM data
      final umkm = await _supabase
          .from('umkm')
          .select('id_user')
          .eq('id_umkm', idUmkm)
          .single();
      
      final umkmUserId = umkm['id_user'] as String;
      
      print('');
      print('🔍 ========== STEP 1: CREDIT UMKM EARNINGS ==========');
      print('   UMKM User ID: $umkmUserId');
      print('   Amount: Rp${pendapatanUmkm.toStringAsFixed(0)}');
      
      // 3. ✅ CREDIT UMKM EARNINGS
      final umkmResult = await _supabase.rpc('credit_umkm_earnings', params: {
        'p_umkm_user_id': umkmUserId,
        'p_order_id': idPesanan,
        'p_amount': pendapatanUmkm,
        'p_description': 'Pendapatan produk UMKM (90%) - Order: ${idPesanan.substring(0, 8)}',
      });
      
      print('   RPC Result: $umkmResult');
      
      if (umkmResult == null) {
        throw Exception('RPC credit_umkm_earnings returned null');
      }
      
      final umkmResultMap = umkmResult as Map<String, dynamic>;
      
      if (umkmResultMap['success'] != true) {
        throw Exception('Gagal credit pendapatan UMKM: ${umkmResultMap['message'] ?? 'Unknown error'}');
      }
      
      print('✅ UMKM earnings credited successfully!');
      print('   Amount: Rp${pendapatanUmkm.toStringAsFixed(0)}');
      print('   Admin fee (10%): Rp${feeAdminProduk.toStringAsFixed(0)}');
      
      // 4. ✅ CREDIT DRIVER EARNINGS (jika pakai driver)
      print('');
      print('🔍 ========== STEP 2: CHECK DRIVER EARNINGS ==========');
      print('   Metode Pengiriman: $metodePengiriman');
      
      if (metodePengiriman == 'driver') {
        final ongkirDriver = ongkir * 0.80;  // Driver dapat 80%
        final feeAdminOngkir = ongkir * 0.20;
        
        print('💰 Processing driver earnings...');
        print('   Total Ongkir: Rp${ongkir.toStringAsFixed(0)}');
        print('   Driver gets (80%): Rp${ongkirDriver.toStringAsFixed(0)}');
        print('   Admin fee (20%): Rp${feeAdminOngkir.toStringAsFixed(0)}');
        
        // 🔥 CRITICAL: Get pengiriman data
        print('');
        print('🔍 Getting pengiriman data...');
        final pengiriman = await _supabase
            .from('pengiriman')
            .select('id_driver, status_pengiriman, created_at')
            .eq('id_pesanan', idPesanan)
            .maybeSingle();
        
        print('   Query result: $pengiriman');
        
        // 🔥 FIX: THROW ERROR if pengiriman not found!
        if (pengiriman == null) {
          throw Exception(
            '❌ CRITICAL ERROR: Pengiriman tidak ditemukan!\n\n'
            'Order ID: $idPesanan\n'
            'Metode pengiriman: "$metodePengiriman"\n\n'
            'Kemungkinan penyebab:\n'
            '1. completeUmkmOrder() dipanggil SEBELUM driver assign\n'
            '2. Data pengiriman terhapus/corrupt\n'
            '3. Flow order salah\n\n'
            'SOLUSI: completeUmkmOrder() HANYA boleh dipanggil:\n'
            '- Saat driver klik "Selesai" di tracking page\n'
            '- SETELAH data pengiriman dibuat\n'
            '- Status pengiriman = "selesai"'
          );
        }
        
        final idDriver = pengiriman['id_driver'];
        final statusPengiriman = pengiriman['status_pengiriman'];
        final pengirimanCreatedAt = pengiriman['created_at'];
        
        print('   ✅ Pengiriman found!');
        print('   Driver ID: $idDriver');
        print('   Status: $statusPengiriman');
        print('   Created at: $pengirimanCreatedAt');
        
        // 🔥 FIX: Validate id_driver
        if (idDriver == null) {
          throw Exception('id_driver NULL di pengiriman! Data corrupt!');
        }
        
        // Get driver user_id
        print('');
        print('🔍 Getting driver user data...');
        final driverData = await _supabase
            .from('drivers')
            .select('id_user')
            .eq('id_driver', idDriver)
            .single();
        
        final driverUserId = driverData['id_user'] as String;
        print('   Driver User ID: $driverUserId');

        // ✅ HANDLE PAYMENT METHOD (PENTING: Bedakan cash vs non-cash!)
        if (paymentMethod != 'cash') {
          // NON-CASH: Credit wallet (customer sudah bayar via Midtrans/Wallet)
          print('');
          print('🔍 Calling RPC credit_driver_earnings...');
          print('   Parameters:');
          print('   - driver_user_id: $driverUserId');
          print('   - order_id: $idPesanan');
          print('   - amount: Rp${ongkirDriver.toStringAsFixed(0)}');
          
          final driverResult = await _supabase.rpc('credit_driver_earnings', params: {
            'p_driver_user_id': driverUserId,
            'p_order_id': idPesanan,
            'p_amount': ongkirDriver,
            'p_description': 'Pendapatan delivery UMKM (80%) - Order: ${idPesanan.substring(0, 8)}',
          });
          
          print('   RPC Result: $driverResult');
          
          if (driverResult == null) {
            throw Exception('RPC credit_driver_earnings returned null');
          }
          
          final driverResultMap = driverResult as Map<String, dynamic>;
          
          if (driverResultMap['success'] != true) {
            throw Exception(
              'Gagal credit pendapatan driver!\n'
              'Error: ${driverResultMap['message'] ?? 'Unknown error'}\n'
              'Driver User ID: $driverUserId\n'
              'Amount: Rp${ongkirDriver.toStringAsFixed(0)}'
            );
          }
          
          print('✅ Driver earnings credited successfully!');
          print('   Amount: Rp${ongkirDriver.toStringAsFixed(0)}');
          print('   Admin fee (20%): Rp${feeAdminOngkir.toStringAsFixed(0)}');
          
        } else {
          // CASH: Increment counter (sama seperti ojek order)
          print('');
          print('💵 Processing CASH payment for UMKM delivery...');
          
          // Total yang driver terima dari customer
          final totalDariCustomer = subtotal + ongkir;
          
          print('   Driver receives cash from customer: Rp${totalDariCustomer.toStringAsFixed(0)}');
          print('   (Subtotal: Rp${subtotal.toStringAsFixed(0)} + Ongkir: Rp${ongkir.toStringAsFixed(0)})');
          
          final walletService = WalletService();
          await walletService.incrementCashOrderCount(idDriver, totalDariCustomer);
          
          print('✅ Cash order count incremented!');
          print('   Driver ID: $idDriver');
          print('   Amount added to cash_pending: Rp${totalDariCustomer.toStringAsFixed(0)}');
          print('   (Driver akan setor ke admin saat sudah 5 order)');
        }
        
      } else {
        print('📦 Pickup order (metode = "$metodePengiriman")');
        print('   No driver earnings (normal)');
      }
      
      print('');
      print('✅✅✅ UMKM ORDER COMPLETED SUCCESSFULLY ✅✅✅');
      print('🕐 Completed at: ${DateTime.now().toIso8601String()}');
      
    } catch (e, stack) {
      print('');
      print('❌❌❌ ERROR COMPLETE UMKM ORDER ❌❌❌');
      print('❌ Error: $e');
      print('❌ Stack trace:');
      print(stack);
      print('════════════════════════════════════════');
      rethrow;
    }
  }

  // ==================== UMKM COMPLETION WITHOUT DRIVER (AMBIL SENDIRI) ====================

  Future<void> completeUmkmOrderWithoutDriver(String idPesanan) async {
    try {
      print('🏪 ========== COMPLETE UMKM ORDER (AMBIL SENDIRI) ==========');
      
      // 1. Get order details
      final pesanan = await _supabase
          .from('pesanan')
          .select('id_umkm, subtotal, payment_method, payment_status, metode_pengiriman')
          .eq('id_pesanan', idPesanan)
          .single();
      
      final paymentStatus = pesanan['payment_status'] as String;
      final paymentMethod = pesanan['payment_method'] as String;
      final metodePengiriman = pesanan['metode_pengiriman'] as String;
      
      print('   Payment: $paymentMethod');
      print('   Status: $paymentStatus');
      print('   Metode: $metodePengiriman');
      
      // ✅ VALIDASI: Harus ambil sendiri
      if (metodePengiriman != 'ambil_sendiri') {
        throw Exception('Order ini menggunakan driver, tidak bisa langsung selesai!');
      }
      
      // ✅ VALIDASI: Non-cash HARUS sudah paid
      if (paymentMethod != 'cash' && paymentStatus != 'paid') {
        print('❌ Order belum dibayar! Cannot complete.');
        throw Exception('Order belum dibayar. Payment status: $paymentStatus');
      }
      
      final idUmkm = pesanan['id_umkm'];
      final subtotal = (pesanan['subtotal'] ?? 0).toDouble();
      
      final feeAdminProduk = subtotal * 0.10;
      final pendapatanUmkm = subtotal - feeAdminProduk;
      
      print('   Subtotal: Rp${subtotal.toStringAsFixed(0)}');
      print('   Pendapatan UMKM: Rp${pendapatanUmkm.toStringAsFixed(0)}');
      
      // 2. Get UMKM data
      final umkm = await _supabase
          .from('umkm')
          .select('id_user')
          .eq('id_umkm', idUmkm)
          .single();
      
      final umkmUserId = umkm['id_user'] as String;
      
      // 3. ✅ Credit ke wallet UMKM
      print('💰 Crediting UMKM wallet: Rp${pendapatanUmkm.toStringAsFixed(0)}');
      
      final user = await _supabase
          .from('users')
          .select('saldo_wallet')
          .eq('id_user', umkmUserId)
          .single();
      
      final saldoLama = (user['saldo_wallet'] ?? 0).toDouble();
      final saldoBaru = saldoLama + pendapatanUmkm;
      
      await _supabase.from('users').update({
        'saldo_wallet': saldoBaru,
        'updated_at': DateTime.now().toIso8601String(), 
      }).eq('id_user', umkmUserId);
      
      // 4. Record transaction
      await _supabase.from('transaksi_keuangan').insert({
        'id_user': umkmUserId,
        'id_pesanan': idPesanan,
        'jenis_transaksi': 'pendapatan_umkm',
        'jumlah': pendapatanUmkm,
        'saldo_sebelum': saldoLama,
        'saldo_sesudah': saldoBaru,
        'deskripsi': 'Pendapatan UMKM (Ambil Sendiri) - Order: ${idPesanan.substring(0, 8)}',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ UMKM wallet credited');

      // ✅ STEP 3.3: CREDIT ADMIN FEE PRODUK (10%)
      print('💰 Crediting admin fee from products: Rp${feeAdminProduk.toStringAsFixed(0)}');
      
      await _supabase.rpc('update_admin_wallet', params: {
        'p_amount': feeAdminProduk,
        'p_type': 'product_fee',
      });
      
      print('✅ Admin fee from products credited (ambil sendiri)');
      print('   Admin keeps: Rp${feeAdminProduk.toStringAsFixed(0)} (10% fee)');
      
      // 5. Update UMKM stats
      final details = await _supabase
          .from('detail_pesanan')
          .select('jumlah')
          .eq('id_pesanan', idPesanan);
      
      final totalItemTerjual = details.fold<int>(
        0, 
        (sum, item) => sum + (item['jumlah'] as int),
      );
      
      await _supabase.rpc('update_umkm_stats', params: {
        'p_umkm_id': idUmkm,
        'p_additional_sales': subtotal,
        'p_additional_items': totalItemTerjual,
      });
      
      print('✅✅✅ UMKM ORDER (AMBIL SENDIRI) COMPLETED ✅✅✅');
      
    } catch (e) {
      print('❌ Error complete UMKM ambil sendiri: $e');
      rethrow;
    }
  }

  // ==================== AUTO COMPLETE & DRIVER METHODS ====================

  /// Auto-complete stale OJEK orders (bukan UMKM!)
  Future<void> autoCompleteStaleOrders(String userId) async {
    try {
      print('🧹 Auto-completing stale OJEK orders...');
      
      final twoHoursAgo = DateTime.now()
          .subtract(Duration(hours: 2))
          .toIso8601String();
      
      // ✅ Complete order OJEK NON-FINAL yang > 2 jam
      final completedResult = await _supabase
          .from('pesanan')
          .update({
            'status_pesanan': 'selesai',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user', userId)
          .eq('jenis', 'ojek')
          .not('status_pesanan', 'in', '(selesai,dibatalkan,gagal)')
          .lt('created_at', twoHoursAgo)
          .select();
      
      if (completedResult.isNotEmpty) {
        print('✅ Auto-completed ${completedResult.length} stale OJEK order(s)');
      }
      
      // ✅ Cancel 'mencari_driver' OJEK yang > 15 menit
      final fifteenMinutesAgo = DateTime.now()
          .subtract(Duration(minutes: 15))
          .toIso8601String();
      
      final cancelledResult = await _supabase
          .from('pesanan')
          .update({
            'status_pesanan': 'dibatalkan',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user', userId)
          .eq('jenis', 'ojek')
          .eq('status_pesanan', 'mencari_driver')
          .lt('created_at', fifteenMinutesAgo)
          .select();
      
      if (cancelledResult.isNotEmpty) {
        print('✅ Auto-cancelled ${cancelledResult.length} OJEK searching order(s)');
      }
      
    } catch (e) {
      print('❌ Error auto-complete stale orders: $e');
    }
  }

  Future<void> autoCompleteSafeUmkm(String userId) async {
    try {
      print('🧹 [SAFE] Auto-completing stale UMKM orders...');
      
      final twoHoursAgo = DateTime.now()
          .subtract(Duration(hours: 2))
          .toIso8601String();
      
      // ✅ Complete order NON-FINAL yang > 2 jam
      final completedResult = await _supabase
          .from('pesanan')
          .update({
            'status_pesanan': 'selesai',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user', userId)
          .eq('jenis', 'umkm')
          .not('status_pesanan', 'in', '(selesai,dibatalkan,gagal)')
          .lt('created_at', twoHoursAgo)
          .select();
      
      if (completedResult.isNotEmpty) {
        print('✅ [SAFE] Auto-completed ${completedResult.length} stale UMKM order(s)');
      }
      
      // ✅ FIXED: HANYA cancel yang BELUM BAYAR & sudah > 2 menit
      final twoMinutesAgo = DateTime.now()
          .subtract(Duration(minutes: 2))
          .toIso8601String();
      
      final cancelledResult = await _supabase
          .from('pesanan')
          .update({
            'status_pesanan': 'gagal',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user', userId)
          .eq('jenis', 'umkm')
          .eq('status_pesanan', 'mencari_driver')
          .eq('payment_status', 'pending')  // ✅ TAMBAH INI! HANYA CANCEL YANG BELUM BAYAR
          .lt('search_start_time', twoMinutesAgo)
          .select();
      
      if (cancelledResult.isNotEmpty) {
        print('✅ [SAFE] Auto-cancelled ${cancelledResult.length} UNPAID searching order(s)');
      }
      
    } catch (e) {
      print('❌ Error auto-complete safe UMKM: $e');
    }
  }

  /// Cek apakah driver punya pesanan aktif
  Future<Map<String, dynamic>?> getDriverActiveOrder(String driverId) async {
    try {
      print('🔍 Checking active order for driver: $driverId');
      
      // ✅ Cari di tabel PENGIRIMAN (bukan pesanan!)
      final response = await _supabase
          .from('pengiriman')
          .select('*, pesanan(*)')
          .eq('id_driver', driverId)
          .not('status_pengiriman', 'in', '(selesai,dibatalkan,gagal)')
          .maybeSingle();
      
      if (response != null) {
        print('⚠️ Driver has active order: ${response['id_pesanan']}');
      } else {
        print('✅ Driver available');
      }
      
      return response;
    } catch (e) {
      print('❌ Error get driver active order: $e');
      return null;
    }
  }

  // SiDrive - Originally developed by Muhammad Sulthon Abiyyu
  // Contact: 0812-4975-4004
  // Created: November 2025

  // ==================== OJEK ORDER METHODS ====================

  /// Create order ojek online dengan validasi komprehensif
  Future<Map<String, dynamic>> createOrderOjek({
    required String idCustomer,
    required String jenisKendaraan,
    required String lokasiJemput,
    required String lokasiAntar,
    required String lokasiAsal,
    required String lokasiTujuan,
    required double jarakKm,
    required double ongkirDriver,
    required double biayaAdmin,
    required double totalCustomer,
    required String paymentMethod,
    String? catatan,
  }) async {
    try {
      print('📦 ========== CREATE OJEK ORDER ==========');
      print('   Customer: $idCustomer');
      print('   Kendaraan: $jenisKendaraan');
      print('   Jarak: ${jarakKm.toStringAsFixed(2)} km');
      print('   Ongkir Driver: Rp${ongkirDriver.toStringAsFixed(0)}');
      print('   Admin: Rp${biayaAdmin.toStringAsFixed(0)}');
      print('   Total Customer: Rp${totalCustomer.toStringAsFixed(0)}');
      print('   Payment: $paymentMethod');

      // Hitung fee gateway HANYA jika transfer/e-wallet
      double feeGateway = 0;
      if (paymentMethod != 'cash') {
        feeGateway = totalCustomer * 0.02;
      }

      double biayaAdminBersih = biayaAdmin - feeGateway;

      // ✅ Status awal tergantung payment method
      String statusAwal;
      String paymentStatusAwal;

      if (paymentMethod == 'cash') {
        // Cash: langsung mencari driver
        statusAwal = 'mencari_driver';
        paymentStatusAwal = 'pending';
      } else {
        // Transfer/E-wallet: menunggu pembayaran dulu
        statusAwal = 'menunggu_pembayaran';
        paymentStatusAwal = 'pending';
      }

      final data = {
        'id_user': idCustomer,
        'jenis': 'ojek',
        'jenis_kendaraan': jenisKendaraan,
        'alamat_asal': lokasiJemput,
        'alamat_tujuan': lokasiAntar,
        'lokasi_asal': lokasiAsal,
        'lokasi_tujuan': lokasiTujuan,
        'jarak_km': jarakKm,
        'ongkir': ongkirDriver,
        'subtotal': 0,
        'total_harga': totalCustomer,
        'fee_admin': biayaAdminBersih,
        'fee_payment_gateway': feeGateway,
        'status_pesanan': statusAwal,
        'tanggal_pesanan': DateTime.now().toIso8601String(),
        'payment_method': paymentMethod,
        'payment_status': paymentStatusAwal,
        'catatan': catatan,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📦 Membuat pesanan: $data');

      final response = await _supabase
          .from('pesanan')
          .insert(data)
          .select()
          .single();

      print('✅ Pesanan berhasil: ${response['id_pesanan']} - Status: ${response['status_pesanan']}');
      return response;

    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Gagal membuat pesanan: ${e.toString()}');
    }
  }

  // Get pesanan by ID
  Future<Map<String, dynamic>?> getPesananById(String idPesanan) async {
    try {
      final response = await _supabase
          .from('pesanan')
          .select()
          .eq('id_pesanan', idPesanan)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // Get user orders history
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final response = await _supabase
          .from('pesanan')
          .select()
          .eq('id_user', userId)
          .order('tanggal_pesanan', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }


  // ✅ STEP 4.3: Restore stock saat cancel order UMKM
  Future<void> _restoreStockOnCancel(String idPesanan) async {
    try {
      print('🔄 Restoring stock for cancelled order...');
      
      // Check if UMKM order
      final pesanan = await _supabase
          .from('pesanan')
          .select('jenis')
          .eq('id_pesanan', idPesanan)
          .maybeSingle();
      
      if (pesanan == null || pesanan['jenis'] != 'umkm') {
        print('⏭️ Not UMKM order, skip restore stock');
        return;
      }
      
      // Get detail items
      final details = await _supabase
          .from('detail_pesanan')
          .select('id_produk, jumlah, nama_produk')
          .eq('id_pesanan', idPesanan);
      
      if (details.isEmpty) {
        print('⏭️ No items to restore');
        return;
      }
      
      // Restore each product stock
      for (var item in details) {
        await _supabase.rpc('restore_product_stock', params: {
          'p_product_id': item['id_produk'],
          'p_quantity': item['jumlah'],
        });
        
        print('   ✅ ${item['nama_produk']}: +${item['jumlah']}');
      }
      
      print('✅ Stock restored for ${details.length} products');
    } catch (e) {
      print('⚠️ Error restoring stock: $e');
      // Don't throw - let cancel proceed even if restore fails
    }
  }

  Future<void> cancelOrder(String idPesanan) async {
    try {
      await _restoreStockOnCancel(idPesanan);
      
      await _supabase
          .from('pesanan')
          .update({
            'status_pesanan': 'dibatalkan',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_pesanan', idPesanan);
    } catch (e) {
      throw Exception('Gagal membatalkan: ${e.toString()}');
    }
  }

  Future<void> completeOjekOrder(String idPesanan, String idDriver) async {
    try {
      print('💰 ========== COMPLETE OJEK ORDER ==========');
      
      // 1. Get order details
      final pesanan = await _supabase
          .from('pesanan')
          .select('ongkir, payment_method, payment_status, total_harga, id_user')
          .eq('id_pesanan', idPesanan)
          .single();
      
      final paymentStatus = pesanan['payment_status'] as String;
      final paymentMethod = pesanan['payment_method'] as String;
      
      print('   Payment: $paymentMethod');
      print('   Status: $paymentStatus');
      
      // ✅ VALIDASI: Non-cash HARUS sudah paid
      if (paymentMethod != 'cash' && paymentStatus != 'paid') {
        print('❌ Order belum dibayar! Cannot complete.');
        throw Exception('Order belum dibayar. Payment status: $paymentStatus');
      }
      
      final ongkir = (pesanan['ongkir'] ?? 0).toDouble();
      final totalHarga = (pesanan['total_harga'] ?? 0).toDouble();
      
      // 2. Get driver user_id
      final driver = await _supabase
          .from('drivers')
          .select('id_user')
          .eq('id_driver', idDriver)
          .single();
      
      final driverUserId = driver['id_user'] as String;
      
      // 3. ✅ CREDIT DRIVER EARNINGS
      if (paymentMethod != 'cash') {
        // NON-CASH: Credit wallet (customer sudah bayar via Midtrans/Wallet)
        final ongkirDriver = ongkir * 0.80; // Driver dapat 80%
        
        print('💰 Crediting driver wallet: Rp${ongkirDriver.toStringAsFixed(0)}');
        
        // ✅ PANGGIL RPC BARU (yang sudah kita buat di TAHAP 3)
        final result = await _supabase.rpc('credit_driver_earnings', params: {
          'p_driver_user_id': driverUserId,
          'p_order_id': idPesanan,
          'p_amount': ongkirDriver,
          'p_description': 'Pendapatan ojek (80%) - Order: ${idPesanan.substring(0, 8)}',
        });
        
        // ✅ CEK RESULT
        if (result == null) {
          throw Exception('RPC credit_driver_earnings returned null');
        }
        
        final resultMap = result as Map<String, dynamic>;
        
        if (resultMap['success'] != true) {
          throw Exception('Gagal credit pendapatan driver: ${resultMap['message'] ?? 'Unknown error'}');
        }
        
        print('✅ Driver earnings credited: Rp${ongkirDriver.toStringAsFixed(0)}');
        print('   Admin keeps: Rp${(ongkir * 0.20).toStringAsFixed(0)} (20% fee)');
        
      } else {
        // CASH: Increment counter (existing logic - JANGAN UBAH)
        print('💵 Processing cash payment...');
        
        final walletService = WalletService();
        await walletService.incrementCashOrderCount(idDriver, totalHarga);
        
        print('✅ Cash order count incremented');
      }
      
      print('✅✅✅ OJEK ORDER COMPLETED ✅✅✅');
      
    } catch (e, stack) {
      print('❌ Error complete ojek order: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // ==================== CASH PAYMENT AUTO DEDUCT ====================
  
  Future<void> processCashPaymentDeduction({
    required String idPesanan,
    required String idDriver,
  }) async {
    try {
      print('💰 ========== PROCESS CASH PAYMENT ==========');

      // 1. Get order details
      final pesanan = await _supabase
          .from('pesanan')
          .select('total_harga, payment_method')
          .eq('id_pesanan', idPesanan)
          .single();

      if (pesanan['payment_method'] != 'cash') {
        print('⏭️ Not cash payment, skipping');
        return;
      }

      final totalHarga = (pesanan['total_harga'] ?? 0).toDouble();

      // 2. Increment cash order count
      final walletService = WalletService();
      await walletService.incrementCashOrderCount(idDriver, totalHarga);

      print('✅ Cash payment processed: Rp${totalHarga.toStringAsFixed(0)}');
    } catch (e) {
      print('❌ Error process cash payment: $e');
    }
  }

  // ==================== SETTLEMENT INFO ====================
  
  /// Get driver settlement info
  Future<Map<String, dynamic>> getDriverSettlementInfo(String driverId) async {
    try {
      // 1. Get driver cash info
      final driver = await _supabase
          .from('drivers')
          .select('jumlah_order_belum_setor, total_cash_pending')
          .eq('id_driver', driverId)
          .single();
      
      // 2. Get settlement history
      final settlements = await _supabase
          .from('cash_settlements')
          .select()
          .eq('id_driver', driverId)
          .order('tanggal_pengajuan', ascending: false)
          .limit(5);
      
      return {
        'cash_pending': (driver['total_cash_pending'] ?? 0).toDouble(),
        'order_count': driver['jumlah_order_belum_setor'] ?? 0,
        'can_withdraw': (driver['jumlah_order_belum_setor'] ?? 0) < 5,
        'settlements': List<Map<String, dynamic>>.from(settlements),
      };
      
    } catch (e) {
      print('❌ Error get settlement info: $e');
      return {
        'cash_pending': 0.0,
        'order_count': 0,
        'can_withdraw': true,
        'settlements': [],
      };
    }
  }

  /// Auto cleanup stuck payments
  Future<void> autoCleanupStuckPayments() async {
    try {
      final oneHourAgo = DateTime.now()
          .subtract(Duration(hours: 1))
          .toIso8601String();
      
      final result = await _supabase
          .from('pesanan')
          .update({
            'status_pesanan': 'dibatalkan',
            'payment_status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('status_pesanan', 'menunggu_pembayaran')
          .eq('payment_status', 'pending')
          .lt('created_at', oneHourAgo)
          .select();
      
      if (result.isNotEmpty) {
        print('🧹 Auto-cancelled ${result.length} stuck payment(s)');
      }
    } catch (e) {
      print('❌ Error cleanup stuck payments: $e');
    }
  }
}


// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025