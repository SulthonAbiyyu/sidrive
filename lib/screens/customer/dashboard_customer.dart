import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ TAMBAHAN BARU
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/screens/customer/pages/home_page.dart';
import 'package:sidrive/screens/customer/pages/umkm_page.dart';
import 'package:sidrive/screens/chat/chat_list_page.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/screens/profile/profile_tab.dart';
import 'package:sidrive/core/widgets/custom_bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/services/order_timer_service.dart';
import 'package:sidrive/services/app_lifecycle_manager.dart';
import 'package:sidrive/providers/notifikasi_provider.dart';
import 'package:sidrive/services/wallet_service.dart';

class DashboardCustomer extends StatefulWidget {
  const DashboardCustomer({super.key});

  @override
  State<DashboardCustomer> createState() => DashboardCustomerState();
}

class DashboardCustomerState extends State<DashboardCustomer> {
  int _selectedIndex = 0;
  final _lifecycleManager = AppLifecycleManager(); 
  int _unreadChatCount = 0;
  final _chatService = ChatService();

  // ✅ TAMBAHAN BARU: Untuk fitur tekan back 2x keluar
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _restoreTimer();
    _setupTimeoutListener();
    _setupLifecycleListener(); 
    _initializeNotifikasi();
    _loadUnreadChatCount();
  }

  @override
  void dispose() {
    debugPrint('🔔 [CUSTOMER_DASHBOARD] Disposing dashboard...');
    _lifecycleManager.dispose();
    
    // Stop notifikasi listener
    if (mounted) {
      context.read<NotifikasiProvider>().stopListening();
    }
    
    super.dispose();
  }

  // ✅ FUNGSI BARU: Setup lifecycle listener
  void _setupLifecycleListener() {
    _lifecycleManager.initialize();
    
    // Ketika app kembali ke foreground (user buka app lagi)
    _lifecycleManager.setOnAppResumed(() async {
      print('🔄 [Dashboard] App resumed, re-syncing timer...');
      
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _restoreActiveTimer(userId);
        print('✅ [Dashboard] Timer re-synced after app resumed');
      }
    });
    
    // Ketika app masuk background (optional, untuk logging)
    _lifecycleManager.setOnAppPaused(() {
      print('⏸️ [Dashboard] App paused, timer running in background...');
    });
  }

  void _initializeNotifikasi() {
    debugPrint('🔔 [CUSTOMER_DASHBOARD] Initializing notifications...');
    
    // Delay untuk memastikan context sudah siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId != null) {
        // Load notifikasi pertama kali
        context.read<NotifikasiProvider>().loadNotifikasi(userId);
        
        // Start real-time listening
        context.read<NotifikasiProvider>().startListening(userId);
        
        debugPrint('✅ [CUSTOMER_DASHBOARD] Notifications initialized');
      }
    });
  }


  Future<void> _loadUnreadChatCount() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final count = await _chatService.getTotalUnreadCount(userId);
      if (mounted) {
        setState(() => _unreadChatCount = count);
      }
    }
  }


  // ✅ Restore active timer dari database
  Future<void> _restoreActiveTimer(String userId) async {
    try {
      print('🔍 [Dashboard] Checking for active order...');
      
      final supabase = Supabase.instance.client;
      
      // Cek apakah ada pesanan aktif
      final activeOrder = await supabase
          .from('pesanan')
          .select('id_pesanan, search_start_time')
          .eq('id_user', userId)
          .eq('status_pesanan', 'mencari_driver')
          .maybeSingle();
      
      if (activeOrder == null) {
        print('ℹ️ [Dashboard] No active order found');
        return;
      }
      
      final orderId = activeOrder['id_pesanan'] as String;
      final searchStartTimeStr = activeOrder['search_start_time'] as String?;
      
      if (searchStartTimeStr == null) {
        print('⚠️ [Dashboard] No search_start_time, starting fresh timer');
        OrderTimerService().startTimer(orderId);
        return;
      }
      
      final searchStartTime = DateTime.parse(searchStartTimeStr);
      
      print('📋 [Dashboard] Found active order: $orderId');
      print('⏰ [Dashboard] Search started at: $searchStartTime');
      
      // Restore timer menggunakan OrderTimerService
      OrderTimerService().restoreTimer(orderId, searchStartTime);
      
    } catch (e) {
      print('❌ [Dashboard] Error restoring timer: $e');
    }
  }

  Future<void> _restoreTimer() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await _restoreActiveTimer(userId);
    }
  }

  void _setupTimeoutListener() {
    OrderTimerService().onTimeout = (orderId) {
      print('⏰ [Dashboard] Timer timeout for order: $orderId');
      
      if (!mounted) return;
      
      _showTimeoutDialog(orderId);
    };
  }

  Future<void> _showTimeoutDialog(String orderId) async {
    final supabase = Supabase.instance.client;
    
    try {
      final order = await supabase
          .from('pesanan')
          .select()
          .eq('id_pesanan', orderId)
          .maybeSingle();
      
      if (order == null || !mounted) return;
      
      final paidWithWallet = order['paid_with_wallet'] == true;
      final walletAmount = (order['wallet_deducted_amount'] ?? 0).toDouble();
      final userId = order['id_user'];
      final paymentMethod = order['payment_method'];
      
      if (paidWithWallet && walletAmount > 0) {
        print('💸 [Dashboard] Processing wallet refund...');
        
        final walletService = WalletService();
        await walletService.refundWalletForFailedOrder(
          userId: userId,
          orderId: orderId,
          amount: walletAmount,
          reason: 'Driver tidak ditemukan (timeout dari dashboard)',
        );
        
        print('✅ [Dashboard] Wallet refund processed');
      } else if (paymentMethod == 'transfer' || paymentMethod == 'qris' || paymentMethod == 'gopay') {
        print('🏷️ [Dashboard] Transfer order timeout - admin needs to handle refund manually');
        
        // ✅ CUKUP UPDATE CATATAN ADMIN DI PESANAN
        await supabase.from('pesanan').update({
          'catatan_admin': 'Driver tidak ditemukan (timeout) - Perlu refund manual Midtrans',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', orderId);
      }
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded, 
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Driver Tidak Ditemukan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mohon maaf, driver tidak ditemukan dalam waktu 2 menit.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Silakan coba lagi atau hubungi customer service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Tutup'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _retryOrder(order);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Coba Lagi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('❌ Error showing timeout dialog: $e');
    }
  }

  Future<void> _retryOrder(Map<String, dynamic> oldOrder) async {
    try {
      print('🔄 [Dashboard] Retrying order...');
      
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) return;
      
      // ✅ Validasi: Pastikan order lama sudah dibatalkan
      final existingOrder = await supabase
          .from('pesanan')
          .select('status_pesanan')
          .eq('id_pesanan', oldOrder['id_pesanan'])
          .maybeSingle();
      
      if (existingOrder != null && existingOrder['status_pesanan'] != 'dibatalkan') {
        print('⚠️ [Dashboard] Old order not cancelled yet, cancelling...');
        
        await supabase.from('pesanan').update({
          'status_pesanan': 'dibatalkan',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', oldOrder['id_pesanan']);
      }
      
      final response = await supabase.from('pesanan').insert({
        'id_user': userId,
        'jenis': 'ojek',
        'jenis_kendaraan': oldOrder['jenis_kendaraan'],
        'alamat_asal': oldOrder['alamat_asal'],
        'alamat_tujuan': oldOrder['alamat_tujuan'],
        'lokasi_asal': oldOrder['lokasi_asal'],
        'lokasi_tujuan': oldOrder['lokasi_tujuan'],
        'jarak_km': oldOrder['jarak_km'],
        'ongkir': oldOrder['ongkir'] ?? oldOrder['ongkir_driver'],
        'subtotal': oldOrder['subtotal'] ?? oldOrder['ongkir'] ?? oldOrder['ongkir_driver'],
        'total_harga': oldOrder['total_harga'],
        'fee_admin': oldOrder['fee_admin'] ?? 0,
        'fee_payment_gateway': oldOrder['fee_payment_gateway'] ?? 0,
        'payment_method': oldOrder['payment_method'] ?? oldOrder['metode_pembayaran'],
        'payment_status': (oldOrder['payment_method'] ?? oldOrder['metode_pembayaran']) == 'cash' ? 'pending' : 'pending',
        'status_pesanan': 'mencari_driver',
        'search_start_time': DateTime.now().toIso8601String(),
        'tanggal_pesanan': DateTime.now().toIso8601String(),
        'catatan': oldOrder['catatan'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      print('✅ [Dashboard] New order created: ${response['id_pesanan']}');
      
      // Start timer untuk order baru
      OrderTimerService().startTimer(response['id_pesanan']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search, color: Colors.white, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mencari Driver',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Pesanan baru dibuat, mohon tunggu...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error retrying order: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal membuat pesanan: ${e.toString()}',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void goToTab(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const HomeTab();
      case 1:
        return const UmkmTab();
      case 3:
        // ✅ GANTI ChatTab dengan ChatListPage
        return ChatListPage(
          currentUserId: Supabase.instance.client.auth.currentUser?.id ?? '',
          currentUserRole: 'customer',
        );
      case 4:
        return const ProfileTab();
      default:
        return const HomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider?>();
    final user = auth?.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ TAMBAHAN BARU: PopScope untuk fitur tekan back 2x keluar
    // Cara kerja: tekan back pertama → muncul snackbar "tekan lagi untuk keluar"
    // Tekan back kedua dalam 2 detik → keluar aplikasi
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          // Tekan pertama → simpan waktu & tampilkan snackbar
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tekan sekali lagi untuk keluar'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          // Tekan kedua dalam 2 detik → keluar aplikasi
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: _getCurrentPage(),
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTap: (index) async {
            if (index == 3) {
              setState(() {
                _selectedIndex = index;
              });
              
              Future.delayed(Duration(milliseconds: 300), () {
                if (mounted) {
                  _loadUnreadChatCount();
                }
              });
            } else {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          role: 'customer',
          badgeCounts: {
            3: _unreadChatCount, 
          },
        ),
      ),
    );
  }
}