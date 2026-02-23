import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:sidrive/services/customer_location_service.dart';
import 'package:sidrive/screens/customer/pages/riwayat_customer.dart';

class CustomerTrackingDataLoader {
  final BuildContext context;
  final dynamic widget; // CustomerLiveTracking widget
  final SupabaseClient supabase;
  final CustomerLocationService customerLocationService;
  
  // Callbacks
  final Function(Map<String, dynamic>) onDriverDataLoaded;
  final Function(Map<String, dynamic>) onPengirimanDataLoaded;
  final Function(LatLng) onDriverLocationUpdated;
  final Function(LatLng) onCustomerLocationUpdated;
  final Function(String) onStatusUpdated;
  final Function() onOrderCompleted;
  final Function(StreamSubscription) onStreamCreated;
  final Function(Timer) onTimerCreated;

  // ✅ TAMBAHKAN: Simpan id_driver untuk digunakan di timer
  String? _cachedDriverId;

  CustomerTrackingDataLoader({
    required this.context,
    required this.widget,
    required this.supabase,
    required this.customerLocationService,
    required this.onDriverDataLoaded,
    required this.onPengirimanDataLoaded,
    required this.onDriverLocationUpdated,
    required this.onCustomerLocationUpdated,
    required this.onStatusUpdated,
    required this.onOrderCompleted,
    required this.onStreamCreated,
    required this.onTimerCreated,
  });

  Future<void> loadDriverAndPengiriman() async {
    print('🔥 ========== LOADING DRIVER & PENGIRIMAN ==========');
    print('🔥 Pesanan ID: ${widget.idPesanan}');
    
    try {
      final pengirimanList = await supabase
          .from('pengiriman')
          .select()
          .eq('id_pesanan', widget.idPesanan)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Timeout loading pengiriman'),
          );
      
      print('📡 Pengiriman result count: ${pengirimanList.length}');
      
      if (pengirimanList.isEmpty) {
        print('⚠️ Pengiriman belum ada, menunggu driver accept...');
        
        int retryCount = 0;
        while (retryCount < 6) {
          await Future.delayed(const Duration(seconds: 5));
          
          final retryList = await supabase
              .from('pengiriman')
              .select()
              .eq('id_pesanan', widget.idPesanan);
          
          print('🔄 Retry $retryCount: Found ${retryList.length} pengiriman');
          
          if (retryList.isNotEmpty) {
            print('✅ Pengiriman found after retry!');
            
            final pengiriman = retryList.first;
            onPengirimanDataLoaded(pengiriman);
            onStatusUpdated(pengiriman['status_pengiriman'] ?? 'diterima');
            
            // ✅ Simpan id_driver
            _cachedDriverId = pengiriman['id_driver'];
            
            await _loadDriverInfo(pengiriman['id_driver']);
            return;
          }
          
          retryCount++;
        }
        
        print('❌ Pengiriman not found after 30 seconds');
        
        _showErrorDialog(
          'Data pengiriman tidak ditemukan.\nSilakan kembali dan coba lagi.',
          onPressed: () {
            final userId = widget.pesananData['id_user'];
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RiwayatCustomer(userId: userId),
              ),
            );
          },
        );
        return;
      }
      
      final pengiriman = pengirimanList.first;
      print('✅ Pengiriman loaded: ${pengiriman['id_pengiriman']}');
      
      onPengirimanDataLoaded(pengiriman);
      onStatusUpdated(pengiriman['status_pengiriman'] ?? 'diterima');
      
      // ✅ Simpan id_driver
      _cachedDriverId = pengiriman['id_driver'];
      print('💾 Cached driver ID: $_cachedDriverId');
      
      await _loadDriverInfo(pengiriman['id_driver']);
      
    } catch (e, stackTrace) {
      print('❌ ========== ERROR LOADING PENGIRIMAN ==========');
      print('❌ Error: $e');
      print('❌ Stack: $stackTrace');
      print('===============================================');
      
      _showErrorDialog(
        'Gagal memuat data: $e\n\nSilakan coba lagi.',
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/customer/dashboard',
            (route) => false,
          );
        },
      );
    }
  }

  Future<void> _loadDriverInfo(String idDriver) async {
    print('👤 ========== LOADING DRIVER INFO ==========');
    print('👤 Driver ID: $idDriver');
    
    try {
      final driver = await supabase
          .from('drivers')
          .select('rating_driver, total_rating, id_user, current_location')
          .eq('id_driver', idDriver)
          .single();
      
      print('👤 Driver basic data: $driver');
      
      final user = await supabase
          .from('users')
          .select('nama, foto_profil, no_telp')
          .eq('id_user', driver['id_user'])
          .single();
      
      print('👤 User data: $user');
      print('🚗 Querying vehicles...');

      final vehicleList = await supabase
          .from('driver_vehicles')
          .select('plat_nomor, merk_kendaraan, is_active, status_verifikasi')
          .eq('id_driver', idDriver);

      print('🚗 Total vehicles found: ${vehicleList.length}');

      // Filter di Dart
      final approvedVehicles = vehicleList.where((v) =>
        v['is_active'] == true && 
        v['status_verifikasi'] == 'approved'
      ).toList();

      print('🚗 Approved vehicles: ${approvedVehicles.length}');

      Map<String, dynamic>? vehicle;
      if (approvedVehicles.isNotEmpty) {
        vehicle = approvedVehicles.first;
        print('✅ Vehicle found: ${vehicle['merk_kendaraan']} - ${vehicle['plat_nomor']}');
      } else {
        print('⚠️ No approved vehicle found');
      }

      print('🚗 Plat Nomor: ${vehicle?['plat_nomor'] ?? '-'}');
      print('🚗 Merk: ${vehicle?['merk_kendaraan'] ?? '-'}');
            
            // Gabungkan semua data
      final combinedData = {
        ...driver,
        ...user,
        'plat_nomor': vehicle?['plat_nomor'] ?? '-',
        'merk_kendaraan': vehicle?['merk_kendaraan'] ?? '-',
      };

      print('✅ Final combined data: $combinedData');

      onDriverDataLoaded(combinedData);
      
      if (driver['current_location'] != null) {
        try {
          final locationData = await supabase.rpc(
            'get_driver_location',
            params: {'driver_id': idDriver},
          ).single();

          print('✅ Location data: $locationData');
          
          if (locationData['lat'] != null && locationData['lng'] != null) {
            onDriverLocationUpdated(LatLng(
              locationData['lat'] as double,
              locationData['lng'] as double,
            ));
            print('✅ Driver location parsed');
          }
        } catch (e) {
          print('⚠️ Failed to parse driver location: $e');
        }
      }
      
    } catch (e, stackTrace) {
      print('❌ Error loading driver info: $e');
      print('❌ Stack: $stackTrace');
    }
  }

  void listenPengirimanUpdates() {
    print('👂 LISTENING PENGIRIMAN UPDATES');
    
    final stream = supabase
        .from('pengiriman')
        .stream(primaryKey: ['id_pengiriman'])
        .eq('id_pesanan', widget.idPesanan)
        .listen((data) {
          if (data.isNotEmpty) {
            final pengiriman = data.first;
            final newStatus = pengiriman['status_pengiriman'];
            
            print('📱 Status updated: $newStatus');
            
            onStatusUpdated(newStatus);
            
            if (newStatus == 'selesai') {
              onOrderCompleted();
            }
          }
        }, onError: (error) {
          print('❌ Stream error: $error');
          Future.delayed(const Duration(seconds: 5), () {
            listenPengirimanUpdates();
          });
        });
    
    onStreamCreated(stream);
  }

  void startDriverLocationUpdates() {
    // ✅ VALIDASI: Pastikan driver ID sudah ada
    if (_cachedDriverId == null) {
      print('❌ Cannot start driver location updates - driver ID is null');
      return;
    }
    
    print('🚗 Starting driver location updates for driver: $_cachedDriverId');
    
    final timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // ✅ Cek lagi jika tiba-tiba null
      if (_cachedDriverId == null) {
        print('⚠️ Driver ID became null, stopping timer');
        timer.cancel();
        return;
      }
      
      try {
        print('🔄 Fetching driver location... (${DateTime.now()})');
        
        // ✅ GUNAKAN _cachedDriverId yang sudah disimpan
        final driver = await supabase.rpc(
          'get_driver_location',
          params: {'driver_id': _cachedDriverId},
        ).maybeSingle();
        
        if (driver != null && driver['lat'] != null && driver['lng'] != null) {
          onDriverLocationUpdated(LatLng(
            driver['lat'] as double,
            driver['lng'] as double,
          ));
          print('✅ Driver location updated: ${driver['lat']}, ${driver['lng']}');
        } else {
          print('⚠️ Driver location is null or incomplete');
        }
      } catch (e) {
        print('❌ Error updating driver location: $e');
        
        // Jika error 406 (no rows), driver mungkin belum update lokasi
        if (e.toString().contains('PGRST116')) {
          print('ℹ️ Driver location not available yet (RPC returned no rows)');
        }
      }
    });
    
    onTimerCreated(timer);
  }

  Future<void> startCustomerLocationTracking() async {
    print('👤 Starting customer location tracking...');
    
    final customerId = widget.pesananData['id_user'];
    final pesananId = widget.idPesanan;
    
    final success = await customerLocationService.startTracking(
      customerId: customerId,
      pesananId: pesananId,
      onUpdate: (lat, lng) {
        onCustomerLocationUpdated(LatLng(lat, lng));
        print('👤 Customer UI updated: $lat, $lng');
      },
    );
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS gagal diaktifkan. Pastikan GPS aktif dan izin diberikan.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showErrorDialog(String message, {required VoidCallback onPressed}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: onPressed,
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}