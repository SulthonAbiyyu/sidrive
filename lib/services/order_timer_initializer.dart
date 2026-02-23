import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/services/order_timer_service.dart';

class OrderTimerInitializer {
  static Future<void> restoreActiveTimer(String userId) async {
    try {
      print('🔄 [TimerInitializer] Checking for active orders for user: $userId');
      
      final supabase = Supabase.instance.client;
      
      final activeOrder = await supabase
          .from('pesanan')
          .select('id_pesanan, search_start_time, created_at')
          .eq('id_user', userId)
          .eq('status_pesanan', 'mencari_driver')
          .maybeSingle();
      
      if (activeOrder == null) {
        print('✅ [TimerInitializer] No active order found');
        return;
      }
      
      print('📦 [TimerInitializer] Found active order: ${activeOrder['id_pesanan']}');
      
      // ✅ VALIDASI 1: Cek umur order (max 10 menit)
      final createdAt = DateTime.parse(activeOrder['created_at']);
      final now = DateTime.now();
      final orderAge = now.difference(createdAt).inMinutes;
      
      if (orderAge > 10) {
        print('⚠️ [TimerInitializer] Order too old ($orderAge min), cancelling...');
        
        await supabase
            .from('pesanan')
            .update({
              'status_pesanan': 'dibatalkan',
              'updated_at': now.toIso8601String(),
            })
            .eq('id_pesanan', activeOrder['id_pesanan']);
        
        print('✅ [TimerInitializer] Old order cancelled');
        return;
      }
      
      final searchStartTime = activeOrder['search_start_time'];
      
      // ✅ JIKA TIDAK ADA search_start_time
      if (searchStartTime == null) {
        print('⚠️ [TimerInitializer] No search_start_time found');
        
        // ✅ GUNAKAN created_at SEBAGAI PATOKAN
        print('🔧 [TimerInitializer] Using created_at as search_start_time');
        
        final elapsed = now.difference(createdAt).inSeconds;
        
        print('📊 [TimerInitializer] Elapsed since created: $elapsed seconds');
        
        // Jika sudah lebih dari 2 menit, cancel order
        if (elapsed >= 120) {
          print('⏰ [TimerInitializer] Timer already expired (from created_at)');
          
          await supabase
              .from('pesanan')
              .update({
                'status_pesanan': 'dibatalkan',
                'updated_at': now.toIso8601String(),
              })
              .eq('id_pesanan', activeOrder['id_pesanan']);
          
          print('✅ [TimerInitializer] Expired order cancelled');
          return;
        }
        
        // ✅ UPDATE search_start_time = created_at (FIX DATA)
        await supabase
            .from('pesanan')
            .update({'search_start_time': createdAt.toIso8601String()})
            .eq('id_pesanan', activeOrder['id_pesanan']);
        
        print('🔧 [TimerInitializer] search_start_time set to created_at');
        
        // ✅ RESTORE TIMER DARI created_at (BUKAN START BARU!)
        OrderTimerService().restoreTimer(activeOrder['id_pesanan'], createdAt);
        print('✅ [TimerInitializer] Timer restored from created_at');
        return;
      }
      
      // ✅ JIKA ADA search_start_time
      final startTime = DateTime.parse(searchStartTime);
      
      // ✅ VALIDASI 2: startTime tidak boleh di masa depan
      if (startTime.isAfter(now)) {
        print('⚠️ [TimerInitializer] search_start_time in future! Using created_at instead');
        
        final elapsed = now.difference(createdAt).inSeconds;
        
        if (elapsed >= 120) {
          print('⏰ [TimerInitializer] Timer expired');
          
          await supabase
              .from('pesanan')
              .update({
                'status_pesanan': 'dibatalkan',
                'updated_at': now.toIso8601String(),
              })
              .eq('id_pesanan', activeOrder['id_pesanan']);
          
          return;
        }
        
        // Fix corrupt data
        await supabase
            .from('pesanan')
            .update({'search_start_time': createdAt.toIso8601String()})
            .eq('id_pesanan', activeOrder['id_pesanan']);
        
        OrderTimerService().restoreTimer(activeOrder['id_pesanan'], createdAt);
        return;
      }
      
      final elapsed = now.difference(startTime).inSeconds;
      
      print('🕐 [TimerInitializer] Order elapsed time: $elapsed seconds');
      
      // ✅ VALIDASI 3: elapsed tidak boleh lebih dari 10 menit (corrupt data)
      if (elapsed > 600) {
        print('⚠️ [TimerInitializer] Elapsed too large, cancelling...');
        
        await supabase
            .from('pesanan')
            .update({
              'status_pesanan': 'dibatalkan',
              'updated_at': now.toIso8601String(),
            })
            .eq('id_pesanan', activeOrder['id_pesanan']);
        
        print('✅ [TimerInitializer] Order with corrupted time cancelled');
        return;
      }
      
      // ✅ VALIDASI 4: Jika timer sudah habis (>= 120 detik)
      if (elapsed >= 120) {
        print('⏰ [TimerInitializer] Timer already expired, cancelling order...');
        
        await supabase
            .from('pesanan')
            .update({
              'status_pesanan': 'dibatalkan',
              'updated_at': now.toIso8601String(),
            })
            .eq('id_pesanan', activeOrder['id_pesanan']);
        
        print('✅ [TimerInitializer] Expired order cancelled');
        return;
      }
      
      // ✅ RESTORE TIMER DARI search_start_time YANG ADA
      print('✅ [TimerInitializer] Restoring timer (${120 - elapsed} seconds remaining)');
      OrderTimerService().restoreTimer(activeOrder['id_pesanan'], startTime);
      
    } catch (e, stackTrace) {
      print('❌ [TimerInitializer] Error: $e');
      print('Stack: $stackTrace');
    }
  }
}