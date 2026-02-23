import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/services/driver_location_service.dart';
import 'package:sidrive/screens/driver/pages/maproute_driver.dart';
import 'package:sidrive/services/driver_tracking_service.dart';
import 'package:sidrive/services/pesanan_service.dart';
import 'package:sidrive/screens/customer/pages/customer_tracking_constants.dart';
import 'package:sidrive/services/cancel_order_service.dart';
import 'package:sidrive/screens/chat/chat_room_page.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/models/chat_models.dart';
import 'package:geolocator/geolocator.dart';



class PengirimanDetailDriver extends StatefulWidget {
  final Map<String, dynamic> pengirimanData;
  final Map<String, dynamic> pesananData;

  const PengirimanDetailDriver({
    Key? key,
    required this.pengirimanData,
    required this.pesananData,
  }) : super(key: key);

  @override
  State<PengirimanDetailDriver> createState() => _PengirimanDetailDriverState();
}

class _PengirimanDetailDriverState extends State<PengirimanDetailDriver> {
  final supabase = Supabase.instance.client;
  final _locationService = DriverLocationService();
  final GlobalKey<MapRouteDriverState> _mapKey = GlobalKey<MapRouteDriverState>();
  
  String _currentStatus = 'diterima';
  Map<String, dynamic>? _customerData;
  StreamSubscription? _pengirimanStream;
  StreamSubscription? _pesananStream;
  bool _isPanelMinimized = false;
  final _driverTrackingService = DriverTrackingService();
  final _pesananService = PesananService();
  final _chatService = ChatService();
  
  // ✅ GPS STATUS TRACKING
  bool _isGpsActive = false;
  StreamSubscription<ServiceStatus>? _gpsStatusStream;

  List<Map<String, dynamic>> _statusSteps = [];
  List<Map<String, dynamic>> _getStatusSteps() {
    final isUmkm = widget.pesananData['jenis'] == 'umkm';
    
    if (isUmkm) {
      return [
        {'status': 'diterima', 'label': 'Diterima', 'icon': Icons.check_circle},
        {'status': 'menuju_pickup', 'label': 'Menuju Toko', 'icon': Icons.directions_car},
        {'status': 'sampai_pickup', 'label': 'Tiba di Toko', 'icon': Icons.store},
        {'status': 'customer_naik', 'label': 'Ambil Barang', 'icon': Icons.shopping_bag},
        {'status': 'perjalanan', 'label': 'Kirim ke Customer', 'icon': Icons.local_shipping},
        {'status': 'sampai_tujuan', 'label': 'Tiba Tujuan', 'icon': Icons.place},
        {'status': 'selesai', 'label': 'Selesai', 'icon': Icons.done_all},
      ];
    }
    
    // OJEK (existing)
    return [
      {'status': 'diterima', 'label': 'Diterima', 'icon': Icons.check_circle},
      {'status': 'menuju_pickup', 'label': 'Menuju Jemput', 'icon': Icons.directions_car},
      {'status': 'sampai_pickup', 'label': 'Tiba Jemput', 'icon': Icons.location_on},
      {'status': 'customer_naik', 'label': 'Customer Naik', 'icon': Icons.person},
      {'status': 'perjalanan', 'label': 'Perjalanan', 'icon': Icons.local_shipping},
      {'status': 'sampai_tujuan', 'label': 'Tiba Tujuan', 'icon': Icons.place},
      {'status': 'selesai', 'label': 'Selesai', 'icon': Icons.done_all},
    ];
  }

  @override
  void initState() {
    super.initState();
    _statusSteps = _getStatusSteps();
    _currentStatus = widget.pengirimanData['status_pengiriman'] ?? 'diterima';
    _loadCustomerData();
    _listenPengirimanUpdates();
    _listenPesananCancellation();
    _monitorGpsStatus(); // ✅ Monitor GPS
   
    print('📱 ========== DRIVER TRACKING INIT ==========');
    print('📱 Pengiriman ID: ${widget.pengirimanData['id_pengiriman']}');
    print('📱 Pesanan ID: ${widget.pesananData['id_pesanan']}');
    print('📱 Current Status: $_currentStatus');
    print('===========================================');
    
    _startLocationTracking();
  }

  // ✅ MONITOR GPS STATUS REAL-TIME
  void _monitorGpsStatus() async {
    // Check initial status
    _isGpsActive = await Geolocator.isLocationServiceEnabled();
    if (mounted) setState(() {});
    
    // Listen to GPS status changes
    _gpsStatusStream = Geolocator.getServiceStatusStream().listen((status) {
      final isEnabled = status == ServiceStatus.enabled;
      if (_isGpsActive != isEnabled) {
        setState(() {
          _isGpsActive = isEnabled;
        });
        
        // Show alert if GPS turned off during tracking
        if (!isEnabled && mounted) {
          _showGpsDisabledAlert();
        }
      }
    });
  }

  void _showGpsDisabledAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gps_off, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('GPS Nonaktif'),
          ],
        ),
        content: Text(
          'GPS Anda telah dinonaktifkan. Aktifkan kembali untuk melanjutkan tracking pesanan.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            icon: Icon(Icons.settings, size: 18),
            label: Text('Buka Pengaturan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startLocationTracking() async {
    final driverId = widget.pengirimanData['id_driver'];
    final orderId = widget.pesananData['id_pesanan'];
    final pengirimanId = widget.pengirimanData['id_pengiriman'];
    
    if (driverId == null || orderId == null || pengirimanId == null) {
      print('❌ Driver ID, Order ID, or Pengiriman ID null');
      if (mounted) {
        _showCriticalError('Data tidak valid');
      }
      return;
    }
    
    // ✅ START LOCATION SERVICE (GPS tracking)
    final locationSuccess = await _locationService.startTracking(
      driverId: driverId,
      orderId: orderId,
      initialStatus: _currentStatus,
    );
    
    if (!locationSuccess) {
      print('❌ GPS tracking failed to start');
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('GPS Diperlukan'),
            content: const Text(
              'GPS diperlukan untuk melanjutkan pesanan.\n\n'
              'Pastikan GPS aktif dan izin lokasi diberikan.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/driver/dashboard',
                    (route) => false,
                  );
                },
                child: const Text('Kembali'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startLocationTracking();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    // ✅ START DRIVER TRACKING SERVICE (untuk kompensasi cancel)
    _driverTrackingService.startTracking(
      idPengiriman: pengirimanId,
      idDriver: driverId,
    );
    
    print('✅ Both tracking services started successfully');
  }

  void _showCriticalError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error Kritis'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/driver/dashboard',
                (route) => false,
              );
            },
            child: const Text('Kembali ke Dashboard'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCustomerData() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id_user', widget.pesananData['id_user'])
          .single();
      
      setState(() {
        _customerData = response;
      });
      
      print('✅ Customer data loaded: ${response['nama']}');
    } catch (e) {
      print('❌ Error loading customer: $e');
    }
  }

  void _listenPengirimanUpdates() {
    print('👂 Listening to pengiriman updates...');
    
    _pengirimanStream = supabase
        .from('pengiriman')
        .stream(primaryKey: ['id_pengiriman'])
        .eq('id_pengiriman', widget.pengirimanData['id_pengiriman'])
        .listen((data) {
          if (data.isNotEmpty) {
            final newStatus = data.first['status_pengiriman'] ?? 'diterima';
            
            print('📱 ========== PENGIRIMAN UPDATE ==========');
            print('📱 Old Status: $_currentStatus');
            print('📱 New Status: $newStatus');
            print('=========================================');
            
            if (mounted) {
              setState(() {
                _currentStatus = newStatus;
              });
            }
          }
        }, onError: (error) {
          print('❌ Stream error: $error');
        });
  }

  void _listenPesananCancellation() {
    print('👂 Listening to pesanan cancellation...');
    
    _pesananStream = supabase
        .from('pesanan')
        .stream(primaryKey: ['id_pesanan'])
        .eq('id_pesanan', widget.pesananData['id_pesanan'])
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final pesanan = data.first;
            final status = pesanan['status_pesanan'];
            
            print('📱 Pesanan status update: $status');
            
            if (status == 'dibatalkan') {
              _handleOrderCancelled();
            }
          }
        }, onError: (error) {
          print('❌ Pesanan stream error: $error');
        });
  }

  void _handleOrderCancelled() {
    print('📱 ========== ORDER CANCELLED ==========');
    print('📱 Pesanan ID: ${widget.pesananData['id_pesanan']}');
    print('📱 Stopping tracking...');
    
    _locationService.stopTracking();
    _driverTrackingService.stopTracking();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
                Icons.info_outline,
                color: Colors.orange,
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Text('Pesanan Dibatalkan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer telah membatalkan pesanan ini.',
              style: TextStyle(fontSize: 14, height: 1.5),
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
                  Icon(Icons.monetization_on, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anda akan menerima kompensasi sesuai kebijakan.',
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
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/driver/dashboard',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Kembali ke Dashboard',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    print('📱 ========== UPDATE STATUS ==========');
    print('📱 From: $_currentStatus');
    print('📱 To: $newStatus');
    print('======================================');

    try {
      setState(() {
        _currentStatus = newStatus;
      });

      final updateData = {
        'status_pengiriman': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        await supabase
            .from('pengiriman')
            .update(updateData)
            .eq('id_pengiriman', widget.pengirimanData['id_pengiriman']);

        print('✅ Pengiriman updated');

        // ✅ FIX: Hapus .select() — menyebabkan throw exception saat RLS
        // memfilter rows. Update pesanan cukup await tanpa .select().
        if (newStatus == 'selesai') {
          await supabase.from('pesanan').update({
            'status_pesanan': 'selesai',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id_pesanan', widget.pesananData['id_pesanan']);

          print('✅ Pesanan marked as selesai');
        }
      } catch (e) {
        print('❌ Error updating status, attempting rollback...');
        
        try {
          await supabase
              .from('pengiriman')
              .update({
                'status_pengiriman': _currentStatus,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id_pengiriman', widget.pengirimanData['id_pengiriman']);
          
          print('✅ Rollback successful');
        } catch (rollbackError) {
          print('❌ Rollback failed: $rollbackError');
        }
        
        rethrow;
      }

      await supabase.from('notifikasi').insert({
        'id_user': widget.pesananData['id_user'],
        'judul': _getNotifTitle(newStatus),
        'pesan': _getNotifMessage(newStatus),
        'jenis': 'pesanan',
        'status': 'unread',
        'data_tambahan': {
        'id_pesanan': widget.pesananData['id_pesanan'],
        'id_pengiriman': widget.pengirimanData['id_pengiriman'],
        'status': newStatus,
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Notification inserted to DB');

      // ✅ UPDATE STATUS DI LOCATION SERVICE (yang akan auto kirim FCM)
      if (newStatus != 'selesai') {
        _locationService.updateStatus(newStatus);
        print('✅ Location service status updated to: $newStatus');
      }

      // ✅✅✅ CREDIT EARNINGS BERDASARKAN JENIS PESANAN ✅✅✅
      if (newStatus == 'selesai') {
        try {
          final jenisPesanan = widget.pesananData['jenis'];
          
          if (jenisPesanan == 'umkm') {
            print('🛒 ========== UMKM ORDER COMPLETION ==========');
            print('📦 Order ID: ${widget.pesananData['id_pesanan']}');
            
            await _pesananService.completeUmkmOrder(
              widget.pesananData['id_pesanan'],
            );
            
            print('✅ UMKM order completed - UMKM + Driver credited');
          } else {
            print('🏍️ ========== OJEK ORDER COMPLETION ==========');
            print('📦 Order ID: ${widget.pesananData['id_pesanan']}');
            
            await _pesananService.completeOjekOrder(
              widget.pesananData['id_pesanan'],
              widget.pengirimanData['id_driver'],
            );
            
            print('✅ Ojek order completed - Driver credited');
          }
        } catch (e) {
          print('❌ Error completing order: $e');
        }
        
        if (mounted) {
          print('✅ Order completed, navigating to dashboard...');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/driver/dashboard',
            (route) => false,
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ ========== ERROR UPDATING STATUS ==========');
      print('❌ Error: $e');
      print('❌ Stack: $stackTrace');
      print('=============================================');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getNotifTitle(String status) {
    switch (status) {
      case 'diterima':
        return 'Driver Ditemukan!';
      case 'menuju_pickup':
        return 'Driver Menuju Lokasi Anda';
      case 'sampai_pickup':
        return 'Driver Telah Tiba';
      case 'customer_naik':
        return 'Perjalanan Dimulai';
      case 'perjalanan':
        return 'Dalam Perjalanan';
      case 'sampai_tujuan':
        return 'Sampai di Tujuan';
      case 'selesai':
        return 'Pesanan Selesai';
      default:
        return 'Update Pesanan';
    }
  }

  String _getNotifMessage(String status) {
    switch (status) {
      case 'diterima':
        return 'Driver telah menerima pesanan Anda';
      case 'menuju_pickup':
        return 'Driver sedang dalam perjalanan menuju lokasi jemput Anda';
      case 'sampai_pickup':
        return 'Driver telah tiba di lokasi jemput. Silakan menuju ke lokasi driver';
      case 'customer_naik':
        return 'Anda telah naik. Perjalanan akan segera dimulai';
      case 'perjalanan':
        return 'Pesanan Anda sedang dalam perjalanan menuju tujuan';
      case 'sampai_tujuan':
        return 'Anda telah sampai di tujuan';
      case 'selesai':
        return 'Pesanan Anda telah selesai. Terima kasih telah menggunakan SiDrive!';
      default:
        return 'Status pesanan Anda telah diperbarui';
    }
  }

  @override
  void dispose() {
    _pengirimanStream?.cancel();
    _pesananStream?.cancel();
    _gpsStatusStream?.cancel(); // ✅ Cancel GPS monitoring
    _locationService.stopTracking();
    _driverTrackingService.stopTracking();
    super.dispose();
  }


  Future<void> _openChat() async {
    if (_customerData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data customer belum tersedia')),
      );
      return;
    }

    final isUmkmOrder = widget.pesananData['jenis'] == 'umkm';

    // ✅ Jika UMKM order: tampilkan pilihan chat
    if (isUmkmOrder) {
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Chat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                // Pilihan 1: Chat Customer
                ListTile(
                  onTap: () {
                    Navigator.pop(ctx);
                    _openChatWith(
                      targetId: widget.pesananData['id_user'],
                      targetRole: 'customer',
                      chatContext: ChatContext.customerDriver,
                    );
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF85A1).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Color(0xFFFF85A1)),
                  ),
                  title: const Text('Chat Customer',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _customerData?['nama'] ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 8),
                // Pilihan 2: Chat UMKM
                FutureBuilder<Map<String, dynamic>?>(
                  future: _getUmkmUserData(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final umkmUserId = snapshot.data?['id_user'];
                    final driverId = supabase.auth.currentUser?.id;
                    // ✅ Hide jika driver = user UMKM
                    if (umkmUserId == null || umkmUserId == driverId) return const SizedBox.shrink();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Divider(height: 8),
                        ListTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            _openChatWith(
                              targetId: umkmUserId,
                              targetRole: 'umkm',
                              chatContext: ChatContext.umkmDriver,
                            );
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.store, color: Colors.orange),
                          ),
                          title: const Text('Chat UMKM',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            snapshot.data?['nama'] ?? 'UMKM',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    } else {
      // Ojek: langsung chat customer
      _openChatWith(
        targetId: widget.pesananData['id_user'],
        targetRole: 'customer',
        chatContext: ChatContext.customerDriver,
      );
    }
  }

  // ✅ Helper: fetch UMKM user data dari tabel umkm → users
  Future<Map<String, dynamic>?> _getUmkmUserData() async {
    try {
      final idUmkm = widget.pesananData['id_umkm'];
      if (idUmkm == null) return null;

      final umkm = await supabase
          .from('umkm')
          .select('id_user, users(nama)')
          .eq('id_umkm', idUmkm)
          .maybeSingle();

      if (umkm == null) return null;
      final userId = umkm['id_user'] as String?;
      final nama = (umkm['users'] as Map?)?['nama'] ?? 'UMKM';
      return {'id_user': userId, 'nama': nama};
    } catch (e) {
      print('❌ Error get umkm user: $e');
      return null;
    }
  }

  // ✅ Helper: buka room chat berdasarkan target
  Future<void> _openChatWith({
    required String targetId,
    required String targetRole,
    required ChatContext chatContext,
  }) async {
    try {
      final driverId = supabase.auth.currentUser?.id;
      if (driverId == null) return;

      final room = await _chatService.createOrGetRoom(
        context: chatContext,
        participantIds: [targetId, driverId],
        participantRoles: {
          targetId: targetRole,
          driverId: 'driver',
        },
        orderId: widget.pesananData['id_pesanan'],
      );

      if (room == null) throw Exception('Gagal membuat chat room');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              roomId: room.id,
              room: room,
              currentUserId: driverId,
              currentUserRole: 'driver',
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error open chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _customerData == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ✅ MAPS - FULLSCREEN
                MapRouteDriver(
                  key: _mapKey,
                  pesananData: widget.pesananData,
                  currentStatus: _currentStatus,
                ),
                
                // ✅ GPS STATUS INDICATOR (TOP RIGHT)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isGpsActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isGpsActive ? Icons.gps_fixed : Icons.gps_off,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _isGpsActive ? 'GPS Aktif' : 'GPS Mati',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // ✅ BACK BUTTON (TOP LEFT)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                
                // ✅ MINIMIZABLE PANEL (BOTTOM)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 5 && !_isPanelMinimized) {
                        setState(() {
                          _isPanelMinimized = true;
                        });
                      }
                      else if (details.primaryDelta! < -5 && _isPanelMinimized) {
                        setState(() {
                          _isPanelMinimized = false;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _isPanelMinimized 
                          ? 100.0  // ✅ REDUCED from 120 to 100 to prevent overflow
                          : (screenHeight * 0.50).clamp(100.0, screenHeight * 0.65),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ DRAG HANDLE
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPanelMinimized = !_isPanelMinimized;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8), // ✅ REDUCED from 12 to 8
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          
                          // ✅ CONTENT
                          Flexible(
                            child: _isPanelMinimized
                                ? _buildMinimizedContent()
                                : _buildFullContent(screenWidth),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // ✅ CHAT BUTTON (KANAN BAWAH ATAS)
                Positioned(
                bottom: (_isPanelMinimized ? 100 : screenHeight * 0.50) + 80,
                right: 10,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFFFF85A1),
                  heroTag: 'chat_button',
                  onPressed: _openChat,
                  child: const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // ✅ FOLLOW BUTTON (KANAN BAWAH)
              Positioned(
                bottom: (_isPanelMinimized ? 100 : screenHeight * 0.50) + 10,
                right: 10,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.blue,
                  heroTag: 'follow_button',
                  onPressed: () {
                    _mapKey.currentState?.toggleFollowMode();
                  },
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ✅ MINIMIZED CONTENT - COMPACT VERSION (NO OVERFLOW)
  Widget _buildMinimizedContent() {
    final currentIndex = _statusSteps.indexWhere(
      (step) => step['status'] == _currentStatus,
    );
    
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;
    final currentStep = _statusSteps[safeIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // ✅ REDUCED padding
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8), // ✅ REDUCED from 10 to 8
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              currentStep['icon'],
              color: Colors.green,
              size: 20, // ✅ REDUCED from 24 to 20
            ),
          ),
          const SizedBox(width: 10),
          
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentStep['label'],
                  style: const TextStyle(
                    fontSize: 14, // ✅ REDUCED from 16 to 14
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _customerData?['nama'] ?? 'Customer',
                  style: TextStyle(
                    fontSize: 11, // ✅ REDUCED from 13 to 11
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  // ✅ FULL CONTENT - REDESIGNED
  Widget _buildFullContent(double screenWidth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomerCard(),
          const SizedBox(height: 16),
          _buildModernStatusProgress(screenWidth), // ✅ NEW DESIGN
          const SizedBox(height: 16),
          _buildActionButton(), // ✅ MOVED UP (before detail)
          const SizedBox(height: 16),
          _buildPesananDetail(), // ✅ MOVED DOWN (after button)
          const SizedBox(height: 12), 
          _buildCancelButton(), 
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: _customerData?['foto_profil'] != null
                ? NetworkImage(_customerData!['foto_profil'])
                : null,
            child: _customerData?['foto_profil'] == null
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customerData?['nama'] ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            onPressed: () {
              // Handle phone call
            },
          ),
        ],
      ),
    );
  }

  // ✅ NEW MODERN STATUS PROGRESS DESIGN
  Widget _buildModernStatusProgress(double screenWidth) {
    final currentIndex = _statusSteps.indexWhere(
      (step) => step['status'] == _currentStatus,
    );
    
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;
  
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.green.shade700, size: 20),
              SizedBox(width: 8),
              Text(
                'Status Pengiriman',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // ✅ MODERN PROGRESS BAR
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (safeIndex + 1) / _statusSteps.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                '${safeIndex + 1}/${_statusSteps.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // ✅ COMPACT STATUS STEPS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_statusSteps.length, (index) {
              final step = _statusSteps[index];
              final isCompleted = index <= safeIndex; 
              final isActive = index == safeIndex;

              return _buildCompactStatusChip(
                icon: step['icon'],
                label: step['label'],
                isCompleted: isCompleted,
                isActive: isActive,
              );
            }),
          ),
        ],
      ),
    );
  }

  // ✅ COMPACT STATUS CHIP
  Widget _buildCompactStatusChip({
    required IconData icon,
    required String label,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.green 
            : (isCompleted ? Colors.green.shade100 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
        border: isActive 
            ? Border.all(color: Colors.green.shade700, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : icon,
            color: isActive 
                ? Colors.white 
                : (isCompleted ? Colors.green.shade700 : Colors.grey.shade500),
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive 
                  ? Colors.white 
                  : (isCompleted ? Colors.green.shade900 : Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DETAIL PESANAN (SIMPLIFIED - NO JARAK)
  Widget _buildPesananDetail() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue.shade700, size: 18),
              SizedBox(width: 6),
              Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // ✅ ONLY ONGKIR, PAYMENT, CATATAN (NO JARAK)
          _buildDetailRow(
            icon: Icons.payments,
            label: 'Ongkir', 
            value: 'Rp ${CustomerTrackingConstants.formatCurrency(widget.pesananData['ongkir'])}',
          ), 
          _buildDetailRow(
            icon: widget.pesananData['payment_method'] == 'cash' 
                ? Icons.money 
                : Icons.credit_card,
            label: 'Pembayaran', 
            value: widget.pesananData['payment_method'] == 'cash' ? 'Tunai' : 'Transfer',
          ),
          if (widget.pesananData['catatan'] != null && widget.pesananData['catatan'].toString().isNotEmpty)
            _buildDetailRow(
              icon: Icons.note,
              label: 'Catatan', 
              value: widget.pesananData['catatan'],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ACTION BUTTON (MODERN DESIGN)
  Widget _buildActionButton() {
    final currentIndex = _statusSteps.indexWhere(
      (step) => step['status'] == _currentStatus,
    );
    
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;
    
    if (safeIndex >= _statusSteps.length - 1) {
      return const SizedBox();
    }

    final nextStep = _statusSteps[safeIndex + 1];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _updateStatus(nextStep['status']),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(nextStep['icon'], color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  nextStep['label'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    if (_currentStatus != 'diterima' && _currentStatus != 'menuju_pickup') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Batalkan pesanan hanya jika darurat. Pembatalan berlebihan dapat mempengaruhi rating Anda.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDriverCancelDialog(),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text(
              'Batalkan Pesanan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDriverCancelDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Batalkan Pesanan?',
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
              'Apakah Anda yakin ingin membatalkan pesanan ini?',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Konsekuensi:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Rating Anda dapat terpengaruh\n'
                    '• Customer akan mencari driver lain\n'
                    '• Pembatalan berlebihan dapat dikenai sanksi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Tidak, Lanjutkan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Ya, Batalkan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _processDriverCancellation();
    }
  }

  Future<void> _processDriverCancellation() async {
    final TextEditingController reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Alasan Pembatalan'),
        content: TextField(
          controller: reasonController,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Contoh: Kendaraan mogok, Darurat keluarga',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Alasan tidak boleh kosong')),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            child: Text('Kirim'),
          ),
        ],
      ),
    );
    
    if (reason == null) return;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Membatalkan pesanan...'),
              ],
            ),
          ),
        ),
      );

      final cancelService = CancelOrderService(); 
      final result = await cancelService.driverCancelOrder(
        idPesanan: widget.pesananData['id_pesanan'],
        driverId: widget.pengirimanData['id_driver'],
        cancelReason: reason,
      );

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        _locationService.stopTracking();
        _driverTrackingService.stopTracking();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Pesanan berhasil dibatalkan'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/driver/dashboard',
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal membatalkan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      print('❌ Error cancelling order: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan pesanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}