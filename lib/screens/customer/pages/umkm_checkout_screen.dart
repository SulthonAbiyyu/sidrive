import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/providers/cart_provider.dart';
import 'package:sidrive/services/pesanan_service.dart';
import 'package:sidrive/services/wallet_service.dart';
import 'package:sidrive/services/umkm_service.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';
import 'package:sidrive/screens/customer/pages/payment_gateway_screen.dart';
import 'package:sidrive/screens/customer/pages/umkm_delivery_map_screen.dart';
import 'package:sidrive/screens/customer/pages/umkm_store_location_screen.dart';
import 'package:sidrive/screens/customer/pages/riwayat_customer.dart';
import 'package:sidrive/providers/admin_provider.dart';


class UmkmCheckoutScreen extends StatefulWidget {
  const UmkmCheckoutScreen({Key? key}) : super(key: key);

  @override
  State<UmkmCheckoutScreen> createState() => _UmkmCheckoutScreenState();
}

class _UmkmCheckoutScreenState extends State<UmkmCheckoutScreen> {
  final _supabase = Supabase.instance.client;
  final _pesananService = PesananService();
  final _walletService = WalletService();
  final _umkmService = UmkmService();
  
  // State
  String _selectedPayment = 'cash';
  String _metodePengiriman = 'driver';
  bool _isProcessing = false;
  bool _isCalculatingOngkir = false;
  double _cachedSubtotal = 0;
  List<String> _availableDriverTypes = ['motor', 'mobil'];
  String? _selectedDriverType;
  double _baseFare = 2000;
  double _perKmFare = 2000;
  double _umkmAdminFeePercent = 10.0;  
  bool _isLoadingConfig = false;
  
  // Location
  LatLng? _customerLocation;
  LatLng? _tokoLocation;
  String _customerAddress = '';
  String _tokoAddress = '';
  String _tokoName = '';
  String _jamBuka = '';
  String _jamTutup = '';
  
  // Price
  double _ongkir = 0.0;
  double _jarakKm = 0.0;
  double _walletBalance = 0.0;

  // ✅ COLOR PALETTE (Full Blue Theme)
  final Color _primaryBlue = const Color(0xFF2563EB); // Darker Blue
  final Color _lightBlue = const Color(0xFF3B82F6);   // Lighter Blue

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
    _loadTokoLocation();
    _calculateAvailableDriverTypes().then((_) {
      _updateFares();
    });
  }

  Future<void> _loadWalletBalance() async {
    try {
      final userId = context.read<AuthProvider>().currentUser?.idUser;
      if (userId != null) {
        final balance = await _walletService.getBalance(userId);
        if (mounted) {
          setState(() => _walletBalance = balance);
        }
      }
    } catch (e) {
      print('❌ Error load wallet: $e');
    }
  }

  Future<void> _loadTokoLocation() async {
    try {
      final cart = context.read<CartProvider>();
      final selectedItems = cart.items.where((item) => item.isSelected).toList();
      
      if (selectedItems.isEmpty) return;
      
      final idUmkm = selectedItems.first.idUmkm;
      final umkm = await _umkmService.getUmkmById(idUmkm);
      
      if (umkm == null) throw Exception('Toko tidak ditemukan');
      
      if (mounted) {
        setState(() {
          _tokoAddress = umkm.alamatToko;
          _tokoName = umkm.namaToko;
          _jamBuka = umkm.jamBuka ?? '08:00';
          _jamTutup = umkm.jamTutup ?? '20:00';
        });
      }
      
      // Parse lokasi_toko POINT
      if (umkm.lokasiToko != null) {
        final regex = RegExp(r'POINT\(([^ ]+) ([^ ]+)\)');
        final match = regex.firstMatch(umkm.lokasiToko!);
        
        if (match != null) {
          final lng = double.parse(match.group(1)!);
          final lat = double.parse(match.group(2)!);
          _tokoLocation = LatLng(lat, lng);
        }
      }
      
      // Validasi: Cek apakah toko sudah set lokasi
      if (_tokoLocation == null || 
          _tokoLocation!.latitude == 0 || 
          _tokoLocation!.longitude == 0) {
        if (mounted) {
          ErrorDialogUtils.showWarningDialog(
            context: context,
            title: 'Toko Belum Set Lokasi',
            message: 'Toko ini belum mengatur lokasi GPS. Hubungi pemilik toko.',
          );
        }
      }
      
    } catch (e) {
      print('❌ Error load toko: $e');
      if (mounted) {
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Error',
          message: 'Gagal memuat data toko: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _calculateAvailableDriverTypes() async {
    try {
      final cart = context.read<CartProvider>();
      final selectedItems = cart.items.where((item) => item.isSelected).toList();
      
      if (selectedItems.isEmpty) return;
      
      List<Map<String, dynamic>> productData = [];
      
      for (var item in selectedItems) {
        final produk = await _supabase
            .from('produk')
            .select('berat_gram, allowed_driver_type') 
            .eq('id_produk', item.idProduk)
            .single();
        
        productData.add({
          'berat_gram': produk['berat_gram'] ?? 0, 
          'allowed_driver_type': produk['allowed_driver_type'] ?? 'MOTOR_AND_CAR',
          'quantity': item.quantity,
        });
      }
      
      int totalBeratGram = 0; 
      for (var prod in productData) {
        totalBeratGram += (prod['berat_gram'] as int) * (prod['quantity'] as int);
      }
      
      print('📦 Total berat: $totalBeratGram gram');
      
      if (totalBeratGram >= 7000) {
        if (mounted) {
          setState(() {
            _availableDriverTypes = ['mobil'];
            _selectedDriverType = 'mobil';
          });
        }
        print('⚠️ Berat >= 7kg → Hanya Mobil tersedia');
        return;
      }
      
      Set<String> motorSet = {'motor'};
      Set<String> mobilSet = {'mobil'};
      
      for (var prod in productData) {
        final allowedType = prod['allowed_driver_type'] as String;
        
        if (allowedType == 'MOTOR_ONLY') {
          mobilSet.clear(); 
        } else if (allowedType == 'CAR_ONLY') {
          motorSet.clear(); 
        }
      }
      
      List<String> available = [];
      if (motorSet.isNotEmpty) available.add('motor');
      if (mobilSet.isNotEmpty) available.add('mobil');
      
      if (mounted) {
        setState(() {
          _availableDriverTypes = available.isEmpty ? ['mobil'] : available;
          _selectedDriverType = _availableDriverTypes.first; 
        });
      }
      
      print('✅ Available drivers: $_availableDriverTypes');
      
    } catch (e) {
      print('❌ Error calculate driver types: $e');
      if (mounted) {
        setState(() {
          _availableDriverTypes = ['motor', 'mobil'];
          _selectedDriverType = 'motor';
        });
      }
    }
  }

  Future<void> _pilihLokasiPengiriman() async {
    if (_tokoLocation == null) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Error',
        message: 'Lokasi toko belum tersedia',
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UmkmDeliveryMapScreen(
          tokoLocation: _tokoLocation!,
          tokoName: _tokoName,
        ),
      ),
    );

    if (result != null && result is Map && mounted) {
      setState(() {
        _customerLocation = result['location'];
        _customerAddress = result['address'];
      });

      if (_metodePengiriman == 'driver') {
        await _calculateOngkir();
        await _calculateAvailableDriverTypes();
      }
    }
  }

  /// Navigate to store location screen (untuk metode ambil sendiri)
  Future<void> _lihatLokasiToko() async {
    if (_tokoLocation == null) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Error',
        message: 'Lokasi toko belum tersedia',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UmkmStoreLocationScreen(
          tokoLocation: _tokoLocation!,
          tokoName: _tokoName,
          tokoAddress: _tokoAddress,
          jamBuka: _jamBuka,
          jamTutup: _jamTutup,
        ),
      ),
    );
  }

  Future<void> _calculateOngkir() async {
    if (_customerLocation == null || _tokoLocation == null) return;
    
    setState(() => _isCalculatingOngkir = true);
    
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${_tokoLocation!.longitude},${_tokoLocation!.latitude};'
          '${_customerLocation!.longitude},${_customerLocation!.latitude}'
          '?overview=false';
      
      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final distanceMeters = data['routes'][0]['distance'].toDouble();
          final distanceKm = distanceMeters / 1000;
          
          final ongkirMurni = _baseFare + (distanceKm * _perKmFare);
          
          if (mounted) {
            setState(() {
              _jarakKm = distanceKm;
              _ongkir = (ongkirMurni / 500).round() * 500.0;
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error calculate ongkir: $e');
      if (mounted) {
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Error',
          message: 'Gagal menghitung ongkir',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCalculatingOngkir = false);
      }
    }
  }

  void _onMetodePengirimanChanged(String? value) {
    if (value == null) return;
    
    setState(() {
      _metodePengiriman = value;
      
      if (value == 'ambil_sendiri') {
        _ongkir = 0.0;
        _jarakKm = 0.0;
        
        // ✅ AUTO-RESET: Jika pindah ke pickup dan payment masih cash, reset ke wallet
        if (_selectedPayment == 'cash') {
          _selectedPayment = 'wallet';
          // Tampilkan notifikasi
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Untuk pickup, metode pembayaran Cash tidak tersedia. Dialihkan ke Wallet.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
        }
      } else if (value == 'driver' && _customerLocation != null) {
        _calculateOngkir();
      }
    });
  }

  Future<void> _updateFares() async {
    setState(() => _isLoadingConfig = true);
    
    try {
      // ✅ Load config dari AdminProvider
      final adminProvider = context.read<AdminProvider>();
      
      // Pastikan config sudah di-load
      if (adminProvider.tarifConfigs.isEmpty) {
        await adminProvider.loadTarifConfigs();
      }
      
      final configs = adminProvider.tarifConfigs;
      
      // ✅ Ambil tarif sesuai jenis kendaraan
      if (_selectedDriverType == 'mobil') {
        _baseFare = _getConfigValue(configs, 'umkm_mobil_base_fare', 5000);
        _perKmFare = _getConfigValue(configs, 'umkm_mobil_per_km', 3000);
      } else {
        _baseFare = _getConfigValue(configs, 'umkm_motor_base_fare', 2000);
        _perKmFare = _getConfigValue(configs, 'umkm_motor_per_km', 2000);
      }
      
      // ✅ Ambil persentase fee admin UMKM
      _umkmAdminFeePercent = _getConfigValue(configs, 'umkm_admin_fee_percent', 10);
      
      print('💰 UMKM Config loaded:');
      print('   Base Fare: Rp${_baseFare.toStringAsFixed(0)}');
      print('   Per KM: Rp${_perKmFare.toStringAsFixed(0)}');
      print('   Admin Fee: ${_umkmAdminFeePercent.toStringAsFixed(0)}%');
      
      setState(() {});
      
    } catch (e) {
      print('❌ Error loading UMKM fare config: $e');
      // Gunakan default jika error
      if (_selectedDriverType == 'mobil') {
        _baseFare = 5000;
        _perKmFare = 3000;
      } else {
        _baseFare = 2000;
        _perKmFare = 2000;
      }
      _umkmAdminFeePercent = 10;
      setState(() {});
    } finally {
      setState(() => _isLoadingConfig = false);
    }
    
    // Hitung ulang ongkir setelah tarif berubah
    if (_customerLocation != null && _tokoLocation != null && _metodePengiriman == 'driver') {
      _calculateOngkir();
    }
  }

  // ✅ Helper function untuk ambil nilai config
  double _getConfigValue(List<Map<String, dynamic>> configs, String key, double defaultValue) {
    try {
      final item = configs.firstWhere(
        (config) => config['config_key'] == key,
        orElse: () => {},
      );
      
      if (item.isEmpty) return defaultValue;
      
      final value = item['config_value'];
      if (value == null) return defaultValue;
      
      return double.parse(value.toString());
    } catch (e) {
      print('⚠️ Error parsing config $key: $e');
      return defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final selectedItems = cart.items.where((item) => item.isSelected).toList();
    
    if (selectedItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Checkout'),
          backgroundColor: _primaryBlue, // ✅ Blue
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tidak ada produk dipilih', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
    final umkmGroups = <String, List>{};
    for (var item in selectedItems) {
      umkmGroups.putIfAbsent(item.idUmkm, () => []).add(item);
    }
    
    if (umkmGroups.length > 1) {
      return _buildMultiStoreError();
    }
    
    
    final subtotal = selectedItems.fold<double>(0, (sum, item) => sum + item.subtotal);

    // ✅ FEE ADMIN = Dari database (default 10% DARI SUBTOTAL PRODUK)
    // CATATAN: Fee admin ini dipotong dari wallet UMKM saat settlement, 
    // BUKAN ditambahkan ke tagihan customer
    final biayaAdmin = (subtotal * (_umkmAdminFeePercent / 100)).roundToDouble();

    // ✅ TOTAL yang dibayar customer = SUBTOTAL PRODUK + ONGKIR
    // Fee admin TIDAK ditambahkan ke total customer
    final total = subtotal + _ongkir;

    _cachedSubtotal = subtotal;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: _primaryBlue, // ✅ Blue
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildTokoAndProductCard(selectedItems),
                SizedBox(height: 12),
                _buildMetodePengirimanCard(),
                SizedBox(height: 12),
                if (_metodePengiriman == 'driver')
                  _buildLocationCard()
                else
                  _buildAmbilSendiriInfo(),
                SizedBox(height: 12),
                _buildDriverTypeSelector(),
                _buildPaymentMethodCard(total),
                SizedBox(height: 12),
                _buildSummaryCard(subtotal, biayaAdmin, total),
              ],
            ),
          ),
          _buildModernBottomButton(total, selectedItems.first.idUmkm),
        ],
      ),
    );
  }

  Widget _buildMultiStoreError() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: _primaryBlue, // ✅ Blue
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64, color: _primaryBlue), // ✅ Blue
              SizedBox(height: 16),
              Text(
                'Hanya Bisa 1 Toko',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Saat ini hanya bisa checkout dari 1 toko per transaksi.\n\nSilakan hapus produk dari toko lain.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokoAndProductCard(List selectedItems) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Toko (Blue Gradient)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_lightBlue.withOpacity(0.2), _primaryBlue.withOpacity(0.1)], // ✅ Blue Gradient
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryBlue, // ✅ Blue
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store, color: Colors.white, size: 22),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tokoName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            'Buka: $_jamBuka - $_jamTutup',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // List Produk
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: selectedItems.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final item = selectedItems[index];
              return Container(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    // ✅ GAMBAR PRODUK ASLI
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.fotoProduk != null && item.fotoProduk!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.fotoProduk!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade100,
                                child: Icon(Icons.image, color: Colors.grey.shade400, size: 28),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade100,
                                child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 28),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade100,
                              child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 28),
                            ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.namaProduk,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'x${item.quantity}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              Text(
                                CurrencyFormatter.formatRupiahWithPrefix(item.subtotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _primaryBlue, // ✅ Blue
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetodePengirimanCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.local_shipping, color: _primaryBlue, size: 20), // ✅ Blue
                SizedBox(width: 8),
                Text(
                  'Metode Pengiriman',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _buildShippingOption(
            value: 'driver',
            icon: Icons.two_wheeler,
            title: 'Antar dengan Driver',
            subtitle: 'Pesanan diantar ke lokasimu • 30-45 menit',
          ),
          _buildShippingOption(
            value: 'ambil_sendiri',
            icon: Icons.shopping_bag,
            title: 'Ambil Sendiri',
            subtitle: 'Ambil langsung di toko • Hemat ongkir',
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _metodePengiriman == value;
    
    return InkWell(
      onTap: () => _onMetodePengirimanChanged(value),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _lightBlue.withOpacity(0.1) : Colors.white, // ✅ Blue Tint
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryBlue : Colors.grey.shade400, // ✅ Blue
                  width: 2,
                ),
                color: isSelected ? _primaryBlue : Colors.transparent, // ✅ Blue
              ),
              child: isSelected
                  ? Center(child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ))
                  : null,
            ),
            SizedBox(width: 12),
            Icon(icon, color: _primaryBlue, size: 20), // ✅ Blue
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: _primaryBlue, size: 20), // ✅ Blue
              SizedBox(width: 8),
              Text(
                'Lokasi Pengiriman',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          if (_customerLocation != null) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place, color: _primaryBlue, size: 16), // ✅ Blue
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _customerAddress,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade900),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (_jarakKm > 0) ...[
                    SizedBox(height: 6),
                    Text(
                      '📍 ${_jarakKm.toStringAsFixed(1)} km dari toko',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lightBlue.withOpacity(0.1), // ✅ Blue Tint
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _lightBlue.withOpacity(0.3)), // ✅ Blue Border
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _primaryBlue, size: 16), // ✅ Blue
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilih lokasi pengiriman untuk menghitung ongkir',
                      style: TextStyle(fontSize: 12, color: _primaryBlue), // ✅ Blue
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pilihLokasiPengiriman,
              icon: Icon(Icons.map, size: 18),
              label: Text(_customerLocation != null ? 'Ubah Lokasi' : 'Pilih Lokasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue, // ✅ Blue
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbilSendiriInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.store, color: Colors.white, size: 18),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ambil Pesanan di Toko',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Pesanan akan disiapkan oleh toko. Silakan datang ke toko untuk mengambil pesanan.',
            style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.blue.shade700),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _tokoAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _lihatLokasiToko,
              icon: Icon(Icons.map, size: 18),
              label: Text('Lihat Lokasi Toko'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade600, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverTypeSelector() {
    if (_metodePengiriman != 'driver' || _customerLocation == null) {
      return SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: _primaryBlue, size: 20), // ✅ Blue
              SizedBox(width: 8),
              Text(
                'Jenis Kendaraan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          if (_availableDriverTypes.contains('motor'))
            _buildDriverTypeOption(
              'motor',
              'Motor',
              Icons.motorcycle,
              _primaryBlue, // ✅ Blue
            ),
          
          if (_availableDriverTypes.length > 1)
            SizedBox(height: 8),
          
          if (_availableDriverTypes.contains('mobil'))
            _buildDriverTypeOption(
              'mobil',
              'Mobil',
              Icons.directions_car,
              Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildDriverTypeOption(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedDriverType == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDriverType = value;
        });
        _updateFares();
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade800,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.payment, color: _primaryBlue, size: 20), // ✅ Blue
                SizedBox(width: 8),
                Text(
                  'Metode Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          
          _buildPaymentOption(
            value: 'cash',
            icon: Icons.payments,
            iconColor: Colors.green,
            title: 'Cash (COD)',
            subtitle: _metodePengiriman == 'driver' 
                ? 'Bayar saat pesanan tiba'
                : 'Bayar saat ambil di toko',
            isDisabled: _metodePengiriman != 'driver',
            warningText: _metodePengiriman != 'driver' ? 'Coming Soon' : null,
          ),
          
          _buildPaymentOption(
            value: 'wallet',
            icon: Icons.account_balance_wallet,
            iconColor: _primaryBlue, // ✅ Blue
            title: 'SiDrive Wallet',
            subtitle: 'Saldo: ${CurrencyFormatter.formatRupiahWithPrefix(_walletBalance)}',
            isDisabled: _walletBalance < total,
            warningText: _walletBalance < total ? 'Saldo tidak cukup' : null,
          ),

          _buildPaymentOption(
            value: 'transfer',
            icon: Icons.credit_card,
            iconColor: Colors.purple,
            title: 'Transfer/E-Wallet',
            subtitle: 'Via payment gateway',
            isDisabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDisabled,
    String? warningText,
  }) {
    final isSelected = _selectedPayment == value;
    
    return InkWell(
      onTap: isDisabled ? null : () {
        setState(() => _selectedPayment = value);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled 
              ? Colors.grey.shade50 
              : (isSelected ? _lightBlue.withOpacity(0.1) : Colors.white), // ✅ Blue Tint
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 0.5),
          ),
        ),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? _primaryBlue : Colors.grey.shade400, // ✅ Blue
                    width: 2,
                  ),
                  color: isSelected ? _primaryBlue : Colors.transparent, // ✅ Blue
                ),
                child: isSelected
                    ? Center(child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ))
                    : null,
              ),
              SizedBox(width: 12),
              Icon(icon, color: iconColor, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: warningText != null ? Colors.red.shade600 : Colors.grey.shade600,
                        fontWeight: warningText != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDisabled)
                Icon(Icons.block, color: Colors.red.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double subtotal, double biayaAdmin, double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          
          SizedBox(height: 12),
          
          _buildSummaryRow('Subtotal Produk', subtotal, isRegular: true),
          
          if (_metodePengiriman == 'driver') ...[
            SizedBox(height: 8),
            _buildSummaryRow(
              'Ongkir ${_jarakKm > 0 ? "(${_jarakKm.toStringAsFixed(1)} km)" : ""}',
              _ongkir,
              isRegular: true,
              isCalculating: _isCalculatingOngkir || _isLoadingConfig,
            ),
          ],
          
          
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.grey.shade900,
                ),
              ),
              Text(
                CurrencyFormatter.formatRupiahWithPrefix(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: _primaryBlue, // ✅ Blue
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {
    required bool isRegular,
    bool isCalculating = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        isCalculating
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue), // ✅ Blue
              )
            : Text(
                CurrencyFormatter.formatRupiahWithPrefix(value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
      ],
    );
  }

  Widget _buildModernBottomButton(double total, String idUmkm) {
    final canProceed = _metodePengiriman == 'ambil_sendiri' || 
                       (_metodePengiriman == 'driver' && _customerLocation != null);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatRupiahWithPrefix(total),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue, // ✅ Blue
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: canProceed && !_isProcessing
                            ? LinearGradient(
                                colors: [_lightBlue, _primaryBlue], // ✅ Blue Gradient
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: !canProceed || _isProcessing ? Colors.grey.shade300 : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: canProceed && !_isProcessing
                            ? [
                                BoxShadow(
                                  color: _primaryBlue.withOpacity(0.4), // ✅ Blue Shadow
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (canProceed && !_isProcessing) 
                              ? () => _processOrder(total, idUmkm)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _isProcessing
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Bayar Sekarang',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processOrder(double total, String idUmkm) async {
    // Validasi final
    if (_metodePengiriman == 'driver' && _customerLocation == null) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Lokasi Belum Dipilih',
        message: 'Silakan pilih lokasi pengiriman terlebih dahulu',
      );
      return;
    }

    // Validasi wallet
    if (_selectedPayment == 'wallet' && _walletBalance < total) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Saldo Tidak Cukup',
        message: 'Saldo wallet Anda tidak mencukupi untuk transaksi ini.\n\nSaldo: ${CurrencyFormatter.formatRupiahWithPrefix(_walletBalance)}\nTotal: ${CurrencyFormatter.formatRupiahWithPrefix(total)}',
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      final userId = context.read<AuthProvider>().currentUser?.idUser;
      if (userId == null) throw Exception('User not found');
      
      final cart = context.read<CartProvider>();
      final selectedItems = cart.items.where((item) => item.isSelected).toList();
      
      // Validate anti self-order
      final cartData = selectedItems.map((item) => {
        'id_umkm': item.idUmkm,
      }).toList();
      
      final isValid = await _pesananService.validateUmkmOrder(
        customerId: userId,
        cartItems: cartData,
      );
      
      if (!isValid) {
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Tidak Bisa Pesan',
          message: 'Anda tidak bisa memesan produk dari toko sendiri',
        );
        setState(() => _isProcessing = false);
        return;
      }

      // ✅ CEK PESANAN AKTIF
      final activeOrder = await _pesananService.getActiveOrder(userId);
      if (activeOrder != null) {
        final status = activeOrder['status_pesanan'];
        final createdAt = DateTime.parse(activeOrder['created_at']);
        final timeAgo = DateTime.now().difference(createdAt).inMinutes;
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Pesanan Aktif Ditemukan',
          message: 'Anda masih memiliki pesanan aktif dengan status "$status" yang dibuat $timeAgo menit lalu.\n\nSelesaikan atau batalkan pesanan tersebut terlebih dahulu.',
        );
        setState(() => _isProcessing = false);
        return;
      }
      
      // Prepare items
      final items = selectedItems.map((item) => {
        'idProduk': item.idProduk,
        'namaProduk': item.namaProduk,
        'hargaSatuan': item.hargaProduk,
        'jumlah': item.quantity,
        'catatanItem': null,
      }).toList();
      
      final subtotal = selectedItems.fold<double>(0, (sum, item) => sum + item.subtotal);
      final biayaAdmin = (subtotal * 0.10).roundToDouble();
      
      String lokasiAsal = 'POINT(${_tokoLocation!.longitude} ${_tokoLocation!.latitude})';
      String alamatAsal = _tokoAddress;
      
      String lokasiTujuan;
      String alamatTujuan;
      
      if (_metodePengiriman == 'driver') {
        lokasiTujuan = 'POINT(${_customerLocation!.longitude} ${_customerLocation!.latitude})';
        alamatTujuan = _customerAddress;
      } else {
        lokasiTujuan = lokasiAsal;
        alamatTujuan = alamatAsal;
      }
      
      // Create order
      final pesanan = await _pesananService.createOrderUmkm(
        idCustomer: userId,
        idUmkm: idUmkm,
        items: items,
        alamatAsal: alamatAsal,
        lokasiAsal: lokasiAsal,
        alamatPengiriman: alamatTujuan,
        lokasiPengiriman: lokasiTujuan,
        subtotalProduk: subtotal,
        ongkir: _ongkir,
        biayaAdmin: biayaAdmin,
        totalHarga: total,
        paymentMethod: _selectedPayment,
        metodePengiriman: _metodePengiriman,
        jenisKendaraan: _selectedDriverType,
      );
      
      // Handle payment
      if (_selectedPayment == 'wallet') {
        await _processWalletPayment(userId, pesanan, total);
      } else if (_selectedPayment == 'transfer') {
        await _processTransferPayment(userId, pesanan, total);
      } else {
        // Cash - Clear cart SEBELUM navigasi
        await cart.clearSelectedItems();
        
        // ✅ FIX: Ambil userId SEBELUM setState
        final currentUserId = context.read<AuthProvider>().currentUser?.idUser;
        
        setState(() => _isProcessing = false);
        
        if (mounted && currentUserId != null) {
          if (_metodePengiriman == 'driver') {
            // Driver: Menunggu konfirmasi toko
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Pesanan berhasil! Menunggu konfirmasi toko.'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Ambil sendiri
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Pesanan berhasil! Toko sedang menyiapkan.'),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => RiwayatCustomer(
                userId: currentUserId,
                initialTab: 1, // Tab UMKM
              ),
            ),
            (route) => route.isFirst,
          );
        }
      }
      
    } catch (e) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Error',
        message: e.toString(),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processWalletPayment(
    String userId,
    Map<String, dynamic> pesanan,
    double total,
  ) async {
    try {
      final deductResult = await _walletService.deductWalletForOrder(
        userId: userId,
        amount: total,
        description: 'Pembayaran UMKM - Order: ${pesanan['id_pesanan']}',
      );
      
      if (deductResult['success'] != true) {
        throw Exception(deductResult['message'] ?? 'Gagal memotong saldo');
      }
      
      await _supabase.from('pesanan').update({
        'payment_status': 'paid',
        'paid_with_wallet': true,
        'wallet_deducted_amount': total,
        'status_pesanan': 'menunggu_konfirmasi',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', pesanan['id_pesanan']);
      
      // ✅ CLEAR CART SEBELUM NAVIGASI
      final cart = context.read<CartProvider>();
      await cart.clearSelectedItems();
      
      // ✅ FIX: Ambil userId SEBELUM setState
      final currentUserId = context.read<AuthProvider>().currentUser?.idUser;
      
      setState(() => _isProcessing = false);

      // ✅ Redirect ke Riwayat
      if (mounted && currentUserId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Pesanan berhasil! Menunggu konfirmasi toko.'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => RiwayatCustomer(
              userId: currentUserId,
              initialTab: 1, // Tab UMKM
            ),
          ),
          (route) => route.isFirst,
        );
      }
      
    } catch (e) {
      setState(() => _isProcessing = false);
      throw e;
    }
  }

  Future<void> _processTransferPayment(
    String userId,
    Map<String, dynamic> pesanan,
    double total,
  ) async {
    try {
      final userName = context.read<AuthProvider>().currentUser?.nama ?? 'Customer';
      final userEmail = context.read<AuthProvider>().currentUser?.email ?? 'customer@sidrive.com';
      final userPhone = context.read<AuthProvider>().currentUser?.noTelp ?? '08123456789';
      
      final response = await _supabase.functions.invoke(
        'create-payment',
        body: {
          'orderId': pesanan['id_pesanan'],
          'grossAmount': total.toInt(),
          'customerDetails': {
            'first_name': userName,
            'email': userEmail,
            'phone': userPhone,
          },
          'itemDetails': [
            {
              'id': 'umkm_products',
              'price': _cachedSubtotal.toInt(),  
              'quantity': 1,
              'name': 'Produk UMKM',
            },
            if (_ongkir > 0) {
              'id': 'delivery_fee',
              'price': _ongkir.toInt(),
              'quantity': 1,
              'name': 'Ongkir',
            },
          ],
        },
      );
      
      if (response.status != 200 || response.data == null) {
        throw Exception('Gagal membuat transaksi pembayaran');
      }
      
      final paymentData = response.data as Map<String, dynamic>;
      
      // ✅ CLEAR CART SEBELUM NAVIGASI
      final cart = context.read<CartProvider>();
      await cart.clearSelectedItems();
      
      setState(() => _isProcessing = false);
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentGatewayScreen(
            paymentUrl: paymentData['redirect_url']?.toString() ?? '',
            orderId: pesanan['id_pesanan'],
            pesananData: pesanan,
          ),
        ),
      );

      // ✅ SETELAH KEMBALI DARI PAYMENT GATEWAY → REDIRECT KE RIWAYAT UMKM
      final currentUserId = context.read<AuthProvider>().currentUser?.idUser;
      if (mounted && currentUserId != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => RiwayatCustomer(
              userId: currentUserId,
              initialTab: 1, // Tab UMKM
            ),
          ),
          (route) => route.isFirst,
        );
      }
      
    } catch (e) {
      setState(() => _isProcessing = false);
      throw e;
    }
  }
}

// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025