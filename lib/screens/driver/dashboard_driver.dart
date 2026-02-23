import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ TAMBAHAN BARU
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/notifikasi_provider.dart';
import 'package:sidrive/screens/driver/pages/home_page.dart';
import 'package:sidrive/screens/driver/pages/pesanan_page.dart';
import 'package:sidrive/screens/driver/pages/pendapatan_page.dart';
import 'package:sidrive/screens/profile/profile_tab.dart';
import 'package:sidrive/services/fcm_service.dart';
import 'package:sidrive/services/wallet_service.dart';
import 'package:sidrive/screens/chat/chat_list_page.dart';
import 'package:sidrive/services/chat_service.dart';


// IMPORT Bottom Nav
import 'package:sidrive/core/widgets/custom_bottom_nav.dart';

class DashboardDriver extends StatefulWidget {
  const DashboardDriver({Key? key}) : super(key: key);

  @override
  State<DashboardDriver> createState() => _DashboardDriverState();
}

class _DashboardDriverState extends State<DashboardDriver> {
  final supabase = Supabase.instance.client;
  
  // Bottom Navigation
  int _currentIndex = 2;
  late int _unreadChatCount;
  late final ChatService _chatService;

  // Driver State
  bool _isOnline = false;
  bool _isAnimating = false;
  
  String? _driverId;
  Map<String, dynamic>? _driverData;
  List<Map<String, dynamic>> _pesananMasuk = [];
  Position? _currentPosition;
  StreamSubscription? _pesananStream;
  StreamSubscription? _positionStream;

  // ✅ TAMBAHAN BARU: Untuk fitur tekan back 2x keluar
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _unreadChatCount = 0;
    _chatService = ChatService();
    _initializeDriver();
    _initializeNotifikasi();
    _loadUnreadChatCount();
  }

  // GANTI SELURUH FUNGSI _initializeDriver()
  Future<void> _initializeDriver() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _redirectToLogin();
        return;
      }

      print('🔍 Checking driver for user: ${user.id}');

      // ✅ FIX 1: CEK ROLE DULU SEBELUM CEK DRIVERS TABLE
      final roleData = await supabase
          .from('user_roles')
          .select('status')
          .eq('id_user', user.id)
          .eq('role', 'driver')
          .eq('is_active', true)
          .maybeSingle();

      if (roleData == null) {
        print('❌ User tidak memiliki role driver!');
        _showError('Anda tidak memiliki akses driver');
        _redirectToLogin();
        return;
      }

      final roleStatus = roleData['status'] as String;
      print('📋 Role status: $roleStatus');

      // ✅ FIX 2: AMBIL USER DATA DULU
      final userData = await supabase
          .from('users')
          .select('*')
          .eq('id_user', user.id)
          .maybeSingle();

      if (userData == null) {
        _showError('Data user tidak ditemukan');
        _redirectToLogin();
        return;
      }

      // ✅ FIX 3: CEK DRIVERS TABLE (BOLEH NULL!)
      final driverResponse = await supabase
          .from('drivers')
          .select('''
            *,
            driver_vehicles(
              id_vehicle,
              jenis_kendaraan,
              plat_nomor,
              merk_kendaraan,
              status_verifikasi,
              is_active
            )
          ''')
          .eq('id_user', user.id)
          .maybeSingle();

      // ✅ FIX 4: JIKA NULL, BUAT STATE DEFAULT (SEPERTI UMKM!)
      if (driverResponse == null) {
        print('⚠️ Belum ada record di drivers table - buat state default');
        
        setState(() {
          _driverId = null; // Belum punya ID driver
          _isOnline = false;
          _driverData = {
            ...userData,
            'status_verifikasi': roleStatus,
            'vehicles': [],
            'active_vehicles': [],
            'active_vehicle_types': [],
            'has_approved_vehicle': false,
            'rating_driver': 0.0,
            'jumlah_order_belum_setor': 0,
          };
        });

        print('✅ Dashboard accessible with DEFAULT STATE');
        print('⚠️ User belum daftar kendaraan - tampilkan warning');
        
        // Show warning setelah build selesai
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showWarningNotKick(
              'Belum Terdaftar Sebagai Driver',
              'Anda sudah memiliki akun driver, tetapi belum upload dokumen kendaraan.\n\nUpload dokumen di menu Profile untuk mulai menerima order.',
            );
          }
        });

        return; // ✅ JANGAN REDIRECT! BIARKAN MASUK DASHBOARD
      }

      // ✅ JIKA ADA, PROSES NORMAL
      final allVehicles = driverResponse['driver_vehicles'] as List?;
      final approvedVehicles = allVehicles?.where((v) => 
        v['status_verifikasi'] == 'approved'
      ).toList() ?? [];
      
      final activeVehicles = approvedVehicles.where((v) => 
        v['is_active'] == true
      ).toList();
      
      List<String> activeVehicleTypes = activeVehicles
          .map((v) => v['jenis_kendaraan'] as String)
          .toList();

      setState(() {
        _driverId = driverResponse['id_driver'];
        _isOnline = false;
        _driverData = {
          ...driverResponse,
          ...userData,
          'status_verifikasi': roleStatus,
          'vehicles': approvedVehicles,
          'active_vehicles': activeVehicles,
          'active_vehicle_types': activeVehicleTypes,
          'has_approved_vehicle': approvedVehicles.isNotEmpty,
        };
      });

      print('✅ Driver initialized: ${_driverData?['nama']}');
      print('📊 Status: $roleStatus');
      print('✅ Dashboard accessible for ALL users (pending or active)');

      // FCM
      try {
        await FCMService.initialize();
        print('✅ FCM Service initialized successfully');
      } catch (e) {
        print('❌ FCM initialization failed: $e');
      }

      // Warning jika belum ada kendaraan approved
      if (approvedVehicles.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showWarningNotKick(
              'Belum Ada Kendaraan Aktif',
              'Upload dokumen kendaraan di menu Profile untuk mulai menerima order.',
            );
          }
        });
      } else {
        _getCurrentLocation();
      }
      
    } catch (e, stackTrace) {
      print('❌ Error init driver: $e');
      print('Stack trace: $stackTrace');
      _showError('Error: ${e.toString()}');
      _redirectToLogin();
    }
  }

  // ✅ TAMBAH FUNGSI BARU: Refresh Driver Data dari Database
  Future<void> _refreshDriverData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      print('🔄 Refreshing driver data...');

      final driverResponse = await supabase
          .from('drivers')
          .select('''
            *,
            driver_vehicles(
              id_vehicle,
              jenis_kendaraan,
              plat_nomor,
              merk_kendaraan,
              status_verifikasi,
              is_active
            )
          ''')
          .eq('id_user', user.id)
          .maybeSingle();
          
          print('🔍 ========== RAW DRIVER RESPONSE ==========');
          print('Full Response: $driverResponse');
          if (driverResponse != null) {
            print('driver_vehicles: ${driverResponse['driver_vehicles']}');
          }
          print('==========================================');

      if (driverResponse != null) {
        final allVehicles = driverResponse['driver_vehicles'] as List?;
        final approvedVehicles = allVehicles?.where((v) => v['status_verifikasi'] == 'approved').toList() ?? [];
        final userData = await supabase.from('users').select('*').eq('id_user', user.id).maybeSingle();
        final activeVehicles = approvedVehicles.where((v) => v['is_active'] == true).toList();
        List<String> activeVehicleTypes = activeVehicles.map((v) => v['jenis_kendaraan'] as String).toList();

        setState(() {
          _driverData = {
            ...driverResponse,
            'vehicles': approvedVehicles,
            'active_vehicles': activeVehicles,
            'active_vehicle_types': activeVehicleTypes,
            'has_approved_vehicle': approvedVehicles.isNotEmpty,
            ...?userData,
          };
        });

        print('✅ Driver data refreshed successfully');
        print('📊 NEW jumlah_order_belum_setor: ${_driverData?['jumlah_order_belum_setor']}');
        
        // ✅ RE-CHECK apakah masih bisa terima order setelah refresh
        if (_isOnline && _driverId != null) {
          final walletService = WalletService();
          final canAccept = await walletService.canDriverAcceptOrder(_driverId!);
          
          if (!canAccept) {
            print('⚠️ Driver masih tidak bisa terima order setelah refresh');
          } else {
            print('✅ Driver sudah bisa terima order lagi');
            // Clear pesanan kosong dan re-listen
            setState(() {
              _pesananMasuk = [];
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error refresh driver data: $e');
    }
  }

  // ✅ FUNGSI BARU: Initialize Notifikasi
  void _initializeNotifikasi() {
    debugPrint('🔔 [DRIVER_DASHBOARD] Initializing notifications...');
    
    // Delay untuk memastikan context sudah siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final userId = supabase.auth.currentUser?.id;
      
      if (userId != null) {
        // Load notifikasi pertama kali
        context.read<NotifikasiProvider>().loadNotifikasi(userId);
        
        // Start real-time listening
        context.read<NotifikasiProvider>().startListening(userId);
        
        debugPrint('✅ [DRIVER_DASHBOARD] Notifications initialized');
      }
    });
  }


  Future<void> _loadUnreadChatCount() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final count = await _chatService.getTotalUnreadCount(userId);
      if (mounted) {
        setState(() => _unreadChatCount = count);
      }
    }
  }


  void _listenPesananMasuk() {
    final List<String> activeVehicleTypes = (_driverData?['active_vehicle_types'] as List?)
        ?.cast<String>() ?? [];
    final String? driverUserId = supabase.auth.currentUser?.id;
    
    if (activeVehicleTypes.isEmpty) {
      print('❌ Driver belum memiliki kendaraan aktif');
      return;
    }
    
    print('👂 ========== DRIVER LISTENING FOR ORDERS ==========');
    print('👂 Driver ID: $_driverId');
    print('👂 Driver User ID: $driverUserId');
    print('👂 Active Vehicle Types: ${activeVehicleTypes.join(' + ')}');
    print('====================================================');
    
    _pesananStream = supabase
      .from('pesanan')
      .stream(primaryKey: ['id_pesanan'])
      .listen((data) async {
        print('📱 ========== STREAM UPDATE RECEIVED ==========');
        print('📱 Timestamp: ${DateTime.now()}');
        print('📱 Raw Data Count: ${data.length}');
        
        // ✅ FILTER: HANYA TAMPILKAN JIKA DRIVER ONLINE
        if (!_isOnline) {
          print('⚠️ Driver OFFLINE - pesanan tidak ditampilkan');
          if (mounted) {
            setState(() {
              _pesananMasuk = [];
            });
          }
          return;
        }
        
        // ✅ TAMBAH: CEK MAX 5 ORDER BELUM SETOR (dengan refresh data terbaru)
        if (_driverId != null) {
          // ✅ REFRESH driver data terlebih dahulu sebelum cek
          await _refreshDriverData();
          
          final walletService = WalletService();
          final canAccept = await walletService.canDriverAcceptOrder(_driverId!);
          
          print('📊 Can accept order: $canAccept');
          print('📊 jumlah_order_belum_setor: ${_driverData?['jumlah_order_belum_setor']}');
          
          if (!canAccept) {
            print('⚠️ Driver sudah mencapai limit 5 order belum setor');
            if (mounted) {
              setState(() {
                _pesananMasuk = [];
              });
            }
            
            // ✅ TAMPILKAN WARNING
            _showMaxOrderWarning();
            return;
          }
        }
        
        // ✅ FILTER: status, vehicle types (IN array), dan bukan self-order
        final filteredData = data.where((pesanan) {
          final matchStatus = pesanan['status_pesanan'] == 'mencari_driver';
          final jenisKendaraan = pesanan['jenis_kendaraan'] as String?;
          final matchVehicle = jenisKendaraan != null && activeVehicleTypes.contains(jenisKendaraan);
          final isNotSelfOrder = pesanan['id_user'] != driverUserId;
          
          if (!isNotSelfOrder) {
            print('⚠️ BLOCKED SELF-ORDER: ${pesanan['id_pesanan']}');
          }
          
          if (matchStatus && matchVehicle && isNotSelfOrder) {
            print('✅ MATCH: ${pesanan['id_pesanan']} - $jenisKendaraan');
          }
          
          return matchStatus && matchVehicle && isNotSelfOrder;
        }).toList();
        
        print('📱 Filtered Count: ${filteredData.length}');
        
        if (mounted) {
          setState(() {
            _pesananMasuk = List<Map<String, dynamic>>.from(filteredData);
          });
          print('✅ State updated: ${_pesananMasuk.length} pesanan');
        }
      }, onError: (error) {
        print('❌ Stream error: $error');
      });
  }

  // ✅ FUNGSI WARNING MAX ORDER
  void _showMaxOrderWarning() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Maksimal Order Tercapai',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda sudah mencapai limit 5 order dengan pembayaran cash yang belum disetor.',
              style: TextStyle(fontSize: 15, height: 1.5),
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
                  Icon(Icons.info_outline, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Setor saldo terlebih dahulu untuk menerima order baru',
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK, Mengerti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Aktifkan GPS terlebih dahulu');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Izin lokasi ditolak');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      if (_isOnline) {
        _startLocationTracking();
      }
      
    } catch (e) {
      _showError('Error lokasi: ${e.toString()}');
    }
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      setState(() {
        _currentPosition = position;
      });

      if (_driverId != null && _isOnline) {
        try {
          await supabase.from('drivers').update({
            'current_location': 'POINT(${position.longitude} ${position.latitude})',
            'last_location_update': DateTime.now().toIso8601String(),
          }).eq('id_driver', _driverId!);
        } catch (e) {
          print('❌ Error update location: $e');
        }
      }
    });
  }

  Future<void> _toggleOnlineStatus() async {
    if (_isAnimating) return;

    // ✅ REFRESH DATA DRIVER TERLEBIH DAHULU
    await _refreshDriverData();

    final statusVerifikasi = _driverData?['status_verifikasi'];

    if (statusVerifikasi == 'pending_verification') {
      _showWarningNotKick(
        'Menunggu Verifikasi Admin',
        'Akun driver Anda sedang dalam proses verifikasi oleh admin.\n\nAnda dapat mengakses dashboard, tetapi belum bisa menerima order hingga disetujui.',
      );
      return;
    }

    // ✅ CHECK: Apakah ada kendaraan approved?
    final hasApprovedVehicle = _driverData?['has_approved_vehicle'] == true;
    
    if (!hasApprovedVehicle) {
      _showWarningNotKick(
        'Belum Bisa Online',
        'Anda belum memiliki kendaraan yang disetujui.\n\nUpload dokumen kendaraan di Profile dan tunggu approval dari admin.',
      );
      return;
    }

    // ✅ CHECK: Apakah ada kendaraan aktif?
    final activeVehicleTypes = (_driverData?['active_vehicle_types'] as List?)?.cast<String>() ?? [];
    
    if (activeVehicleTypes.isEmpty) {
      _showWarningNotKick(
        'Belum Ada Kendaraan Aktif',
        'Aktifkan minimal 1 kendaraan di menu Profile untuk mulai menerima order.',
      );
      return;
    }

    // ✅ CHECK: Apakah sudah max 5 order belum setor?
    if (!_isOnline && _driverId != null) {
      final walletService = WalletService();
      final canAccept = await walletService.canDriverAcceptOrder(_driverId!);
      
      if (!canAccept) {
        _showWarningNotKick(
          'Tidak Bisa Online',
          'Anda sudah mencapai limit 5 order dengan pembayaran cash yang belum disetor.\n\nSetor saldo terlebih dahulu untuk bisa online kembali.',
        );
        return;
      }
    }
    
    setState(() => _isAnimating = true);

    try {
      if (!_isOnline) {
        // GOING ONLINE
        print('🟢 Going online - checking GPS...');
        
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() => _isAnimating = false);
          _showError('❌ GPS tidak aktif! Aktifkan GPS terlebih dahulu.', showSettingsButton: true);
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() => _isAnimating = false);
            _showError('❌ Izin lokasi ditolak! Berikan izin lokasi untuk online.');
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          setState(() => _isAnimating = false);
          _showError('❌ Izin lokasi diblokir permanen. Aktifkan di Settings HP!');
          return;
        }

        print('📍 Getting current location...');
        await _getCurrentLocation();
        
        if (_currentPosition == null) {
          setState(() => _isAnimating = false);
          _showError('❌ Gagal mendapatkan lokasi. Coba lagi!');
          return;
        }
        
        print('📍 Location obtained');
        _startLocationTracking();
        
        // ✅ Mulai listen pesanan
        _listenPesananMasuk();
        
      } else {
        // GOING OFFLINE
        print('🔴 Going offline');
        _positionStream?.cancel();
        _pesananStream?.cancel();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _isOnline = !_isOnline;
        _isAnimating = false;
      });
      
      print('✅ Status changed to: $_isOnline');

      if (_driverId != null) {
        final userId = supabase.auth.currentUser?.id;
        
        await supabase.from('drivers').upsert({
          'id_driver': _driverId,
          'id_user': userId,
          'is_online': _isOnline,
          'current_location': _currentPosition != null 
              ? 'POINT(${_currentPosition!.longitude} ${_currentPosition!.latitude})'
              : null,
          'last_location_update': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        print('✅ Driver status updated in database');
      }
      
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack: $stackTrace');
      
      setState(() => _isAnimating = false);
      _showError('❌ Error: ${e.toString()}');
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  void _showError(String message, {bool showSettingsButton = false}) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
        actions: [
          if (showSettingsButton)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text(
                'BUKA SETTINGS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ WARNING DIALOG YANG TIDAK KICK USER
  void _showWarningNotKick(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true, // ✅ User bisa close
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK, Mengerti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('🔔 [DRIVER_DASHBOARD] Disposing dashboard...');
    _pesananStream?.cancel();
    _positionStream?.cancel();
    
    // Stop notifikasi listener
    if (mounted) {
      context.read<NotifikasiProvider>().stopListening();
    }
    
    super.dispose();
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return PesananPage(
          pesananMasuk: _pesananMasuk,
          isOnline: _isOnline,
          driverData: _driverData,
          currentPosition: _currentPosition,
        );
      case 1:
        return PendapatanPage(driverId: _driverId ?? '');
      case 2:
        return HomePage(
          isOnline: _isOnline,
          onToggle: _toggleOnlineStatus,
          driverData: _driverData,
          pesananCount: _pesananMasuk.length,
          onRefreshData: _refreshDriverData, 
        );
      case 3:
        // ✅ GANTI: History jadi Chat
        return ChatListPage(
          currentUserId: supabase.auth.currentUser?.id ?? '',
          currentUserRole: 'driver',
        );
      case 4:
        return const ProfileTab();
      default:
        return HomePage(
          isOnline: _isOnline,
          onToggle: _toggleOnlineStatus,
          driverData: _driverData,
          pesananCount: _pesananMasuk.length,
          onRefreshData: _refreshDriverData, 
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: const Color(0xFFF8F9FA),
        body: _driverData == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6B9D),
                ),
              )
            : _getCurrentPage(),
        
        bottomNavigationBar: _driverData == null
        ? null
        : CustomBottomNav(
            selectedIndex: _currentIndex,
            onTap: (index) async {
              // 🔥 JIKA BALIK DARI PROFILE (INDEX 4) ATAU MASUK HOME (2)
              if ((index == 2 || index == 0) && _currentIndex == 4) {
                print('🔄 Balik dari Profile → refresh driver data');
                await _refreshDriverData();
              }

              if (index == 3) {
                setState(() => _currentIndex = index);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadUnreadChatCount();
                });
              } else {
                setState(() => _currentIndex = index);
              }
            },
            role: 'driver',
            badgeCounts: {
              0: _pesananMasuk.length,  
              3: _unreadChatCount, 
            },
          ),
      ),
    );
  }
}