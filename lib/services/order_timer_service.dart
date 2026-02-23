import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderTimerService extends ChangeNotifier {
  static final OrderTimerService _instance = OrderTimerService._internal();
  factory OrderTimerService() => _instance;
  OrderTimerService._internal();

  final _supabase = Supabase.instance.client;
  
  Timer? _countdownTimer;
  Timer? _syncTimer;
  String? _activeOrderId;
  int _remainingSeconds = 120;
  
  // Getters
  int get remainingSeconds => _remainingSeconds;
  bool get hasActiveTimer => _activeOrderId != null;
  String? get activeOrderId => _activeOrderId;
  
  // Callback untuk timeout
  Function(String orderId)? onTimeout;
  
  // Start timer untuk pesanan baru
  void startTimer(String orderId) {
    print('🕐 [TimerService] Starting timer for order: $orderId');
    
    // ✅ CEK DULU: Kalau timer untuk orderId yang sama sudah jalan, skip!
    if (_activeOrderId == orderId && _countdownTimer != null && _countdownTimer!.isActive) {
      print('ℹ️ [TimerService] Timer for this order already running, skipping start');
      return;
    }
    
    // ✅ CANCEL TIMER LAMA DULU
    cancelTimer();
    
    _activeOrderId = orderId;
    _remainingSeconds = 120;
    
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
        
        if (_remainingSeconds % 30 == 0) {
          print('⏱️ [TimerService] Remaining: $_remainingSeconds seconds');
        }
      } else {
        print('⏰ [TimerService] Timer finished for order: $_activeOrderId');
        _handleTimeout();
      }
    });
    
    _startSyncTimer();
    notifyListeners();
  }
  
  // Restore timer dari waktu sebelumnya
  void restoreTimer(String orderId, DateTime searchStartTime) {
    print('🔄 [TimerService] Restoring timer for order: $orderId');
    
    // ✅ CEK DULU: Kalau timer untuk orderId yang sama sudah jalan, skip!
    if (_activeOrderId == orderId && _countdownTimer != null && _countdownTimer!.isActive) {
      print('ℹ️ [TimerService] Timer for this order already running, skipping restore');
      return;
    }
    
    // ✅ CANCEL TIMER LAMA DULU (untuk mencegah multiple timer)
    cancelTimer();
    
    final now = DateTime.now();
    
    // Validasi: searchStartTime tidak boleh di masa depan
    if (searchStartTime.isAfter(now)) {
      print('⚠️ [TimerService] searchStartTime is in future! Starting fresh timer');
      startTimer(orderId);
      return;
    }
    
    final elapsed = now.difference(searchStartTime).inSeconds;
    
    // Validasi: elapsed tidak boleh negatif
    if (elapsed < 0) {
      print('⚠️ [TimerService] Negative elapsed! Starting fresh timer');
      startTimer(orderId);
      return;
    }
    
    // Validasi: jika sudah lebih dari 10 menit, anggap error
    if (elapsed > 600) {
      print('⚠️ [TimerService] Elapsed too large ($elapsed sec)! Cancelling order');
      _activeOrderId = orderId;
      _handleTimeout();
      return;
    }
    
    _remainingSeconds = 120 - elapsed;
    
    print('📊 [TimerService] Elapsed: $elapsed sec, Remaining: $_remainingSeconds sec');
    
    if (_remainingSeconds <= 0) {
      print('⏰ [TimerService] Timer already expired');
      _activeOrderId = orderId;
      _handleTimeout();
      return;
    }
    
    _activeOrderId = orderId;
    
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        print('⏰ [TimerService] Timer finished for order: $_activeOrderId');
        _handleTimeout();
      }
    });
    
    _startSyncTimer();
    notifyListeners();
  }
  
  // Handle ketika timer habis
  Future<void> _handleTimeout() async {
    if (_activeOrderId == null) return;
    
    final String orderId = _activeOrderId!;
    cancelTimer();
    
    try {
      print('🔄 [TimerService] Updating order status to dibatalkan: $orderId');
      
      await _supabase
          .from('pesanan')
          .update({
            'status_pesanan': 'dibatalkan',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_pesanan', orderId)
          .eq('status_pesanan', 'mencari_driver');
      
      print('✅ [TimerService] Order cancelled due to timeout');
      
      // Trigger callback
      if (onTimeout != null) {
        onTimeout!(orderId);
      }
      
    } catch (e) {
      print('❌ [TimerService] Error cancelling order: $e');
    }
  }

  // ✅ PERBAIKAN: Sync timer TANPA koreksi otomatis
  void _startSyncTimer() {
    _syncTimer?.cancel();
    
    _syncTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (_activeOrderId == null) {
        timer.cancel();
        return;
      }
      
      try {
        final order = await _supabase
            .from('pesanan')
            .select('search_start_time, status_pesanan')
            .eq('id_pesanan', _activeOrderId!)
            .maybeSingle();
        
        // Jika order tidak ada atau status berubah, cancel timer
        if (order == null || order['status_pesanan'] != 'mencari_driver') {
          print('🔄 [TimerService] Order status changed, cancelling timer');
          cancelTimer();
          return;
        }
        
        print('🔄 [TimerService] Sync check OK - timer still running: $_remainingSeconds sec');
        
      } catch (e) {
        print('❌ [TimerService] Sync error: $e');
      }
    });
  }
  
  // Cancel timer
  void cancelTimer() {
    _countdownTimer?.cancel();
    _syncTimer?.cancel();
    _countdownTimer = null;
    _syncTimer = null;
    _activeOrderId = null;
    _remainingSeconds = 120;
    notifyListeners();
  }
  
  // Format waktu untuk display
  String getFormattedTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}