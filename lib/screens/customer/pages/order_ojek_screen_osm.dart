import 'dart:math' show cos, sqrt, asin, sin;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/pesanan_service.dart';
import 'package:sidrive/screens/customer/pages/payment_gateway_screen.dart';
import 'package:sidrive/models/order_ojek_models.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/screens/customer/pages/maproute_order.dart';
import 'package:sidrive/screens/customer/pages/order_search_bar.dart';
import 'package:sidrive/screens/customer/pages/order_bottom_sheet.dart';
import 'package:sidrive/screens/customer/pages/customer_live_tracking.dart';
import 'package:sidrive/screens/customer/pages/order_searching_dialog.dart';
import 'package:sidrive/core/utils/order_utils.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';
import 'package:sidrive/services/wallet_service.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/providers/admin_provider.dart';



class OrderOjekScreenOsm extends StatefulWidget {
  final String jenisKendaraan;
  const OrderOjekScreenOsm({super.key, required this.jenisKendaraan});
  
  @override
  State<OrderOjekScreenOsm> createState() => _OrderOjekScreenOsmState();
}

class _OrderOjekScreenOsmState extends State<OrderOjekScreenOsm> {
  final GlobalKey<MapRouteOrderState> _mapKey = GlobalKey<MapRouteOrderState>();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();
  final _pesananService = PesananService();
  final supabase = Supabase.instance.client; 

  // ✅ KONSTANTA BARU: 1 lingkaran besar
  static const double SERVICE_RADIUS_KM = 30.0; // Radius area layanan 30km
  static const LatLng SERVICE_CENTER = LatLng(-7.468444, 112.697807); // Titik tengah 3 kampus

 


  LatLng? _currentPosition;
  LatLng? _destinationPosition;
  String _pickupAddress = '';
  String _destinationAddress = '';
  
  List<LatLng> _routePoints = [];
  double _jarakKm = 0;
  double _ongkirDriver = 0;      // Ongkir murni untuk driver
  double _biayaAdmin = 0;        // 10% biaya platform
  double _totalCustomer = 0;     // Total yang dibayar customer
  double _baseFare = 0;
  double _perKmFare = 0;
  double _driverEarningPercent = 80.0;   
  double _adminFeePercent = 20.0;       
  bool _isLoadingConfig = false;
  int _estimatedTime = 0;
  
  bool _isLoadingLocation = false;
  bool _isCalculating = false;
  bool _isCreatingOrder = false;
  bool _showSearchResults = false;
  bool _isSearchingPickup = true;

  // ✅ NEW: Drop pin mode
  bool _isDropPinMode = false;
  bool _isPickupMode = false;
  LatLng? _tempDropPinLocation;
  
  List<OsmPlace> _searchResults = [];
  Timer? _debounceTimer;
  
  // ✅ UX: Awal masuk HANYA tampilkan input tujuan
  bool _showPickupInput = false;
  
  double _bottomSheetHeight = 70.0;
  double _minHeight = 70.0;
  double _maxHeight = 560.0;
  double _collapsedHeight = 45.0;

  String _selectedPaymentMethod = 'cash';
  double _currentWalletBalance = 0.0;   

  StreamSubscription? _pesananStream;

  @override
  void initState() {
    super.initState();
    _initializeFares();
    _loadWalletBalance();
    _requestLocationPermissionAndGetCurrentLocation();

    _pickupFocus.addListener(() {
    if (_pickupFocus.hasFocus) {
      _pickupController.addListener(_onPickupSearchChanged);
    } else {
      _pickupController.removeListener(_onPickupSearchChanged);
    }
  });
  
  _destinationFocus.addListener(() {
    if (_destinationFocus.hasFocus) {
      _destinationController.addListener(_onDestinationSearchChanged);
    } else {
      _destinationController.removeListener(_onDestinationSearchChanged);
    }
  });
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _updateResponsiveHeights();
    _showMapGuidelinesDialog();
  });
}

  void _updateResponsiveHeights() {
    setState(() {
      if (ResponsiveMobile.isVerySmallPhone(context)) {
        _minHeight = ResponsiveMobile.scaledH(220); // ✅ NAIK LAGI
        _collapsedHeight = ResponsiveMobile.scaledH(40);
        _maxHeight = ResponsiveMobile.scaledH(500);
      } else if (ResponsiveMobile.isPhone(context) || ResponsiveMobile.isStandardPhone(context)) {
        _minHeight = ResponsiveMobile.scaledH(250); // ✅ NAIK LAGI
        _collapsedHeight = ResponsiveMobile.scaledH(45);
        _maxHeight = ResponsiveMobile.scaledH(560);
      } else if (ResponsiveMobile.isLargePhone(context)) {
        _minHeight = ResponsiveMobile.scaledH(270); // ✅ NAIK LAGI
        _collapsedHeight = ResponsiveMobile.scaledH(50);
        _maxHeight = ResponsiveMobile.scaledH(600);
      } else {
        _minHeight = ResponsiveMobile.scaledH(290); // ✅ NAIK LAGI
        _collapsedHeight = ResponsiveMobile.scaledH(55);
        _maxHeight = ResponsiveMobile.scaledH(640);
      }
      _bottomSheetHeight = _minHeight;
    });
  }

  void _showMapGuidelinesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // Radius container utama
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ BAGIAN INI DIUBAH
                // Memberikan jarak (padding) agar warna biru tidak menempel ke atas
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 0), // Kiri, Atas, Kanan, Bawah
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF3367D6)],
                      ),
                      // Ubah jadi circular semua sisi agar terlihat seperti kartu di dalam
                      borderRadius: BorderRadius.circular(24), 
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.map_outlined,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Panduan Area Layanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Info 1
                      _buildCompactInfoRow(
                        icon: Icons.circle_outlined,
                        iconColor: const Color(0xFF4285F4),
                        text:
                            'Lingkaran biru menunjukkan batas maksimal layanan.',
                      ),

                      const SizedBox(height: 12),

                      // Info 2
                      _buildCompactInfoRow(
                        icon: Icons.my_location,
                        iconColor: Colors.green,
                        text:
                            'Lokasi jemput dan tujuan harus berada di dalam lingkaran.',
                      ),

                      const SizedBox(height: 12),

                      // Info 3
                      _buildCompactInfoRow(
                        icon: Icons.info,
                        iconColor: Colors.orange,
                        text: 'Sistem akan validasi saat Anda memilih lokasi.',
                      ),

                      const SizedBox(height: 16),

                      // Note box
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade800, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pastikan GPS Anda aktif untuk akurasi terbaik.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Mengerti, Lanjutkan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper widget COMPACT untuk info row
  Widget _buildCompactInfoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocus.dispose();
    _destinationFocus.dispose();
    _debounceTimer?.cancel();
    _pesananStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeFares() async {
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
      if (widget.jenisKendaraan == 'motor') {
        _baseFare = _getConfigValue(configs, 'ojek_motor_base_fare', 2000);
        _perKmFare = _getConfigValue(configs, 'ojek_motor_per_km', 2000);
      } else {
        _baseFare = _getConfigValue(configs, 'ojek_mobil_base_fare', 2000);
        _perKmFare = _getConfigValue(configs, 'ojek_mobil_per_km', 4000);
      }
      
      // ✅ Ambil persentase fee
      _driverEarningPercent = _getConfigValue(configs, 'driver_earning_percent', 80);
      _adminFeePercent = _getConfigValue(configs, 'ojek_admin_fee_percent', 20);
      
      print('💰 Config loaded:');
      print('   Base Fare: Rp${_baseFare.toStringAsFixed(0)}');
      print('   Per KM: Rp${_perKmFare.toStringAsFixed(0)}');
      print('   Driver: ${_driverEarningPercent.toStringAsFixed(0)}%');
      print('   Admin: ${_adminFeePercent.toStringAsFixed(0)}%');

      setState(() => _isLoadingConfig = false);

    } catch (e) {
      print('❌ Error load tarif config: $e');
      if (mounted) {
        setState(() {
          // Fallback ke nilai default
          _baseFare = widget.jenisKendaraan == 'motor' ? 2000 : 3000;
          _perKmFare = widget.jenisKendaraan == 'motor' ? 2000 : 2500;
          _adminFeePercent = 20.0;
          _driverEarningPercent = 80.0;
          _isLoadingConfig = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Menggunakan tarif default'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
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

  Future<void> _loadWalletBalance() async {
    try {
      final userId = context.read<AuthProvider>().currentUser?.idUser;
      if (userId != null) {
        final walletService = WalletService();
        final balance = await walletService.getBalance(userId); // ✅ GANTI METHOD
        setState(() {
          _currentWalletBalance = balance;
        });
        print('💰 Wallet balance loaded: Rp${balance.toStringAsFixed(0)}');
      }
    } catch (e) {
      print('❌ Error loading wallet balance: $e');
    }
  }

  double _roundToNearest500(double value) {
    return (value / 500).round() * 500.0;
  }

  // ✅ FUNGSI 1: HITUNG JARAK ANTAR 2 KOORDINAT (HAVERSINE)
  double _calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) * 
         cos(_degreesToRadians(lat2)) * 
         sin(dLon / 2) * 
         sin(dLon / 2));
    
    final c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // ✅✅✅ FUNGSI BARU 1 - CEK LOKASI DALAM AREA LAYANAN ✅✅✅
  bool _isLocationInServiceArea(LatLng location) {
    final distance = _calculateDistanceInKm(
      location.latitude,
      location.longitude,
      SERVICE_CENTER.latitude,
      SERVICE_CENTER.longitude,
    );
    
    print('📍 Jarak dari pusat area layanan: ${distance.toStringAsFixed(2)} km');
    return distance <= SERVICE_RADIUS_KM;
  }

  // ✅✅✅ FUNGSI BARU 2 - DIALOG ERROR ✅✅✅
  void _showOutOfServiceAreaError(String locationType) {
    HapticFeedback.heavyImpact();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_off,
                        color: Colors.orange,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Di Luar Area Layanan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$locationType berada di luar area layanan kami.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Color(0xFF4285F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF4285F4).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Color(0xFF4285F4)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Area Layanan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Radius ${SERVICE_RADIUS_KM.toInt()} km dari pusat area kampus',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pilih lokasi di dalam lingkaran biru pada peta',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Button
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Mengerti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== LOCATION ====================
  Future<void> _requestLocationPermissionAndGetCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          _setDefaultLocation();
          return;
        }
      }
      
      if (permission == geo.LocationPermission.deniedForever) {
        _setDefaultLocation();
        return;
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );
      
      _currentPosition = LatLng(position.latitude, position.longitude);
      
      
      await _getAddressFromLatLng(position.latitude, position.longitude, isPickup: true);
      _pickupController.text = _pickupAddress;
      _mapKey.currentState?.moveToLocation(_currentPosition!, 15.0);
      
    } catch (e) {
      print('Error getting location: $e');
      _setDefaultLocation();
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _setDefaultLocation() {
    _currentPosition = LatLng(-7.4479, 112.7186);
    _pickupAddress = 'Sidoarjo, Jawa Timur';
    _pickupController.text = _pickupAddress;
    setState(() {});
  }

  Future<void> _getAddressFromLatLng(double lat, double lng, {required bool isPickup}) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?'
          'format=json&lat=$lat&lon=$lng&addressdetails=1&accept-language=id';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SiDrive/1.0'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String address = data['display_name'] ?? '';
        
        if (isPickup) {
          _pickupAddress = address;
          _pickupController.text = address;
        } else {
          _destinationAddress = address;
          _destinationController.text = address;
        }
        
        setState(() {});
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  // ==================== SEARCH ====================
  void _onPickupSearchChanged() {
    setState(() => _isSearchingPickup = true);
    _onSearchChanged(_pickupController.text);
  }

  void _onDestinationSearchChanged() {
    setState(() => _isSearchingPickup = false);
    _onSearchChanged(_destinationController.text);
  }

  void _onSearchChanged(String query) {

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }
    
    // ✅ JIKA KURANG DARI 3 KARAKTER = HIDE JUGA
    if (query.length < 3) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }
    
    // ✅ JANGAN SEARCH kalau text sama dengan address yang sudah dipilih
    if (_isSearchingPickup && query == _pickupAddress) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }
    
    if (!_isSearchingPickup && query == _destinationAddress) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }
    
    // ✅ Baru search kalau text berbeda
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) return;
    
    try {
      final url = 'https://nominatim.openstreetmap.org/search?'
          'q=$query&format=json&addressdetails=1&limit=10&accept-language=id'
          '&countrycodes=id&bounded=1'
          '&viewbox=112.5,-7.6,112.9,-7.2';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SiDrive/1.0'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final places = data.map((json) => OsmPlace.fromJson(json)).toList();
        
        setState(() {
          _searchResults = places;
          _showSearchResults = places.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error searching places: $e');
    }
  }

  void _selectPlace(OsmPlace place) async {
    _pickupController.removeListener(_onPickupSearchChanged);
    _destinationController.removeListener(_onDestinationSearchChanged);
    
    if (_isSearchingPickup) {
      // ✅ VALIDASI BARU: Cek apakah dalam area layanan 30km
      final tempPickupLocation = LatLng(place.lat, place.lon);
      
      if (!_isLocationInServiceArea(tempPickupLocation)) {
        _showOutOfServiceAreaError('Lokasi jemput');
        
        Future.delayed(Duration(milliseconds: 100), () {
          _pickupController.addListener(_onPickupSearchChanged);
          _destinationController.addListener(_onDestinationSearchChanged);
        });
        
        setState(() {
          _showSearchResults = false;
          _searchResults = [];
          _pickupFocus.unfocus();
        });
        return;
      }
      
      setState(() {
        _currentPosition = tempPickupLocation;
        _pickupAddress = place.displayName;
        _pickupController.text = place.displayName;
        _showSearchResults = false;
        _searchResults = [];
        _pickupFocus.unfocus();
      });
      _mapKey.currentState?.moveToLocation(_currentPosition!, 15.0);
      
      if (_destinationPosition != null) {
        _validateAndCalculateRoute();
      }
    } else {
      // DESTINATION
      final tempDestination = LatLng(place.lat, place.lon);
      
      if (!_isLocationInServiceArea(tempDestination)) {
        _showOutOfServiceAreaError('Lokasi tujuan');
        
        Future.delayed(Duration(milliseconds: 100), () {
          _pickupController.addListener(_onPickupSearchChanged);
          _destinationController.addListener(_onDestinationSearchChanged);
        });
        
        setState(() {
          _showSearchResults = false;
          _searchResults = [];
          _destinationFocus.unfocus();
        });
        return;
      }
      
      setState(() {
        _destinationPosition = tempDestination;
        _destinationAddress = place.displayName;
        _destinationController.text = place.displayName;
        _showSearchResults = false;
        _searchResults = [];
        _destinationFocus.unfocus();
        _showPickupInput = true;
      });
      
      if (_currentPosition != null) {
        _validateAndCalculateRoute();
      }
    }
    
    Future.delayed(Duration(milliseconds: 100), () {
      _pickupController.addListener(_onPickupSearchChanged);
      _destinationController.addListener(_onDestinationSearchChanged);
    });
  }

  void _confirmDropPin() {
    if (!_isDropPinMode || _tempDropPinLocation == null) return;
    
    if (_isPickupMode) {
      // ✅ VALIDASI BARU: Cek area layanan
      if (!_isLocationInServiceArea(_tempDropPinLocation!)) {
        _showOutOfServiceAreaError('Lokasi jemput');
        return;
      }
      
      // Konfirmasi pickup location
      setState(() {
        _currentPosition = _tempDropPinLocation;
        _isDropPinMode = false;
        _isPickupMode = false;
        _tempDropPinLocation = null;
      });
      
      _getAddressFromLatLng(
        _currentPosition!.latitude, 
        _currentPosition!.longitude, 
        isPickup: true
      );
      
      // Reload route jika ada tujuan
      if (_destinationPosition != null) {
        _validateAndCalculateRoute();
      }
      
      ErrorDialogUtils.showSuccessDialog(
        context: context,
        title: 'Berhasil!',
        message: 'Lokasi jemput berhasil diatur',
        actionText: 'OK',
      );
    } else {
      // ✅ VALIDASI BARU: Cek area layanan
      if (!_isLocationInServiceArea(_tempDropPinLocation!)) {
        _showOutOfServiceAreaError('Lokasi tujuan');
        return;
      }
      
      // Konfirmasi destination location
      setState(() {
        _destinationPosition = _tempDropPinLocation;
        _isDropPinMode = false;
        _showPickupInput = true;
        _tempDropPinLocation = null;
      });
      
      _getAddressFromLatLng(
        _destinationPosition!.latitude, 
        _destinationPosition!.longitude, 
        isPickup: false
      );
      
      if (_currentPosition != null) {
        _validateAndCalculateRoute();
      }
      
      ErrorDialogUtils.showSuccessDialog(
        context: context,
        title: 'Berhasil!',
        message: 'Tujuan berhasil diatur',
        actionText: 'OK',
      );
    }
  }

  void _cancelDropPin() {
    setState(() {
      _isDropPinMode = false;
      _isPickupMode = false;
      _tempDropPinLocation = null;
    });
  }

  // ✅ NEW: Update temp location saat map digeser
  void _onMapMoved(LatLng newCenter) {
    if (_isDropPinMode) {
      setState(() {
        _tempDropPinLocation = newCenter;
      });
    }
  }

  // ✅ NEW: Helper widget untuk toggle button
  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.black54,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Toggle drop pin mode
  void _toggleDropPinMode() {
    setState(() {
      _isDropPinMode = !_isDropPinMode;
      if (_isDropPinMode) {
        // Default ke destination mode
        _isPickupMode = false;
      }
    });
  }

  // ✅ NEW: Toggle pickup/destination mode saat drop pin
  void _togglePickupDestinationMode() {
    setState(() {
      _isPickupMode = !_isPickupMode;
    });
  }

  // ✅ NEW: Show dialog pilihan lokasi jemput
  Future<void> _showPickupOptionsDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.my_location, color: Color(0xFF4285F4)),
              SizedBox(width: 8),
              Text('Pilih Lokasi Jemput'),
            ],
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF4285F4).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: Color(0xFF4285F4),
                    size: 24,
                  ),
                ),
                title: Text(
                  'Lokasi Kamu',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Gunakan lokasi GPS terkini',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () => Navigator.pop(dialogContext, 'current'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF5DADE2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pin_drop,
                    color: Color(0xFF5DADE2),
                    size: 24,
                  ),
                ),
                title: Text(
                  'Choose on Map',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Tap lokasi di peta',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () => Navigator.pop(dialogContext, 'map'),
              ),
            ],
          ),
        );
      },
    );

    if (result == 'current') {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      
      await _requestLocationPermissionAndGetCurrentLocation();
      
      // ✅ VALIDASI BARU: Cek area layanan
      if (_currentPosition != null) {
        if (!_isLocationInServiceArea(_currentPosition!)) {
          _showOutOfServiceAreaError('Lokasi Anda saat ini');
          
          setState(() {
            _currentPosition = null;
            _pickupAddress = '';
            _pickupController.clear();
          });
          return;
        }
      }
      
      if (_destinationPosition != null) {
        _validateAndCalculateRoute();
      }
    } else if (result == 'map') {
      // ✅ TAMBAHKAN: Hide search results
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      
      // Aktifkan drop pin mode untuk pickup
      setState(() {
        _isDropPinMode = true;
        _isPickupMode = true;
        _tempDropPinLocation = _currentPosition;
      });
    }
  }

  // ✅ NEW: Show dialog pilihan lokasi TUJUAN
  Future<void> _showDestinationOptionsDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFFEA4335)),
              SizedBox(width: 8),
              Text('Pilih Tujuan'),
            ],
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF5DADE2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pin_drop,
                    color: Color(0xFF5DADE2),
                    size: 24,
                  ),
                ),
                title: Text(
                  'Choose on Map',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Pilih lokasi di peta dengan presisi',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () => Navigator.pop(dialogContext, 'map'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_location_alt,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                ),
                title: Text(
                  'Ketik Manual',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Cari dengan mengetik alamat',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () => Navigator.pop(dialogContext, 'type'),
              ),
            ],
          ),
        );
      },
    );

    // Handle hasil pilihan
    if (result == 'map') {
      // ✅ TAMBAHKAN: Hide search results
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      
      // Aktifkan drop pin mode untuk destination
      setState(() {
        _isDropPinMode = true;
        _isPickupMode = false;
        _tempDropPinLocation = _currentPosition;
      });
    } else if (result == 'type') {
      // ✅ TAMBAHKAN: Hide search results dulu, baru focus
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      
      // Focus ke text field untuk ketik manual
      _destinationFocus.requestFocus();
    }
  }

  Future<void> _calculateRouteAndDistance() async {
    if (_currentPosition == null || _destinationPosition == null) return;
    
    setState(() => _isCalculating = true);
    
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${_currentPosition!.longitude},${_currentPosition!.latitude};'
          '${_destinationPosition!.longitude},${_destinationPosition!.latitude}'
          '?overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          double distanceMeters = data['routes'][0]['distance'].toDouble();
          _jarakKm = distanceMeters / 1000;
          
          double durationSeconds = data['routes'][0]['duration'].toDouble();
          _estimatedTime = (durationSeconds / 60).round();

          double rawOngkir = _baseFare + (_jarakKm * _perKmFare);
          double ongkirMurni = _roundToNearest500(rawOngkir);
          
          _ongkirDriver = _roundToNearest500(ongkirMurni * (_driverEarningPercent / 100));
          _biayaAdmin = _roundToNearest500(ongkirMurni * (_adminFeePercent / 100));

          _totalCustomer = ongkirMurni;

          print('💰 OJEK ONGKIR:');
          print('   Ongkir murni: Rp${ongkirMurni.toStringAsFixed(0)}');
          print('   Driver ${_driverEarningPercent.toStringAsFixed(0)}%: Rp${_ongkirDriver.toStringAsFixed(0)}');
          print('   Admin ${_adminFeePercent.toStringAsFixed(0)}%: Rp${_biayaAdmin.toStringAsFixed(0)}');

          
          List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];
          _routePoints = coordinates.map((coord) {
            return LatLng(coord[1], coord[0]);
          }).toList();
          
          if (_routePoints.isNotEmpty) {
            _fitBoundsToRoute();
          }
          
          setState(() {
            _bottomSheetHeight = _maxHeight;
          });
        }
      } else {
        throw Exception('Failed to calculate route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calculating route: $e');
      OrderUtils.showErrorDialog(context, 'Error', 'Gagal menghitung rute. Pastikan koneksi internet Anda stabil dan coba lagi.');
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  Future<void> _validateAndCalculateRoute() async {
    // ✅ VALIDASI SEDERHANA: Cek kedua lokasi dalam area layanan
    if (_currentPosition != null && !_isLocationInServiceArea(_currentPosition!)) {
      _showOutOfServiceAreaError('Lokasi jemput');
      _clearDestination();
      return;
    }
    
    if (_destinationPosition != null && !_isLocationInServiceArea(_destinationPosition!)) {
      _showOutOfServiceAreaError('Lokasi tujuan');
      _clearDestination();
      return;
    }
    
    // Jika valid, lanjut hitung route
    await _calculateRouteAndDistance();
  }

  void _fitBoundsToRoute() {
    if (_routePoints.isEmpty) return;
    
    double minLat = _routePoints[0].latitude;
    double maxLat = _routePoints[0].latitude;
    double minLon = _routePoints[0].longitude;
    double maxLon = _routePoints[0].longitude;
    
    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }
    
    LatLngBounds bounds = LatLngBounds(
      LatLng(minLat, minLon),
      LatLng(maxLat, maxLon),
    );
    
    _mapKey.currentState?.fitBounds(
      bounds,
      EdgeInsets.all(ResponsiveMobile.scaledW(100)),
    );
  }

  void _clearDestination() {
    setState(() {
      _destinationPosition = null;
      _destinationAddress = '';
      _destinationController.clear();
      _routePoints.clear();
      _jarakKm = 0;
      _estimatedTime = 0;
      _bottomSheetHeight = _minHeight;
      _showPickupInput = false;
      _showSearchResults = false; 
      _searchResults = [];
    });
  }

  // ==================== FIND DRIVER ====================
  Future<void> _findDriver() async {
    if (_currentPosition == null || _destinationPosition == null) {
      OrderUtils.showErrorDialog(context, 'Error', 'Mohon pilih lokasi jemput dan tujuan');
      return;
    }


    if (_jarakKm <= 0 || _totalCustomer <= 0) {
      OrderUtils.showErrorDialog(
        context, 
        'Belum Dihitung', 
        'Harga belum dihitung. Pastikan koneksi internet Anda stabil dan coba pilih ulang tujuan.'
      );
      return;
    }

    // ✅ TAMBAH VALIDASI 2: Cek minimum fare
    if (_ongkirDriver < _baseFare) {
      OrderUtils.showErrorDialog(
        context, 
        'Harga Tidak Valid', 
        'Terjadi kesalahan perhitungan harga. Silakan pilih ulang lokasi tujuan.'
      );
      return;
    }

    setState(() => _isCreatingOrder = true);

    try {
      final userId = context.read<AuthProvider>().currentUser?.idUser;

      if (userId == null) {
        setState(() => _isCreatingOrder = false);
        OrderUtils.showErrorDialog(context, 'Error', 'User tidak ditemukan. Silakan login kembali.');
        return;
      }

      print('🧹 ========== AUTO-COMPLETE STALE ORDERS ==========');
      await _pesananService.autoCompleteStaleOrders(userId);

      print('🔍 ========== CHECKING ACTIVE ORDERS ==========');
      final activeOrder = await _pesananService.getActiveOrder(userId);
      
      if (activeOrder != null) {
        setState(() => _isCreatingOrder = false);
        
        final status = activeOrder['status_pesanan'];
        final createdAt = DateTime.parse(activeOrder['created_at']);
        final timeAgo = DateTime.now().difference(createdAt).inMinutes;
        
        OrderUtils.showErrorDialog(
          context, 
          'Pesanan Aktif Ditemukan', 
          'Anda masih memiliki pesanan dengan status "$status" yang dibuat $timeAgo menit yang lalu.\n\nSelesaikan atau batalkan pesanan tersebut terlebih dahulu.'
        );
        return;
      }

      print('✅ No active orders - OK to create new order');

      // ✅ TAMBAH CEK WALLET PAYMENT
      if (_selectedPaymentMethod == 'wallet') {
        await _processWalletPayment(userId);
        return;
      }

      // ✅ JIKA TRANSFER → PROSES PAYMENT GATEWAY
      if (_selectedPaymentMethod != 'cash') {
        await _processPaymentGateway(userId);
        return;
      }

      // ✅ JIKA CASH → PROSES NORMAL
      print('🧹 ========== CLEANING OLD ORDERS (BACKUP) ==========');
      
      final fifteenMinutesAgo = DateTime.now().subtract(Duration(minutes: 15)).toIso8601String();
      
      final cleanupResult = await supabase
          .from('pesanan')
          .update({
            'status_pesanan': 'dibatalkan',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user', userId)
          .eq('status_pesanan', 'mencari_driver')
          .eq('jenis_kendaraan', widget.jenisKendaraan)
          .lt('created_at', fifteenMinutesAgo)
          .select();
      
      if (cleanupResult.isNotEmpty) {
        print('🧹 Cleaned ${cleanupResult.length} old order(s)');
      }

      print('🚀 ========== CREATE ORDER ==========');

      final lokasiAsal = 'POINT(${_currentPosition!.longitude} ${_currentPosition!.latitude})';
      final lokasiTujuan = 'POINT(${_destinationPosition!.longitude} ${_destinationPosition!.latitude})';

      final response = await _pesananService.createOrderOjek(
        idCustomer: userId,
        jenisKendaraan: widget.jenisKendaraan,
        lokasiJemput: _pickupAddress,
        lokasiAntar: _destinationAddress,
        lokasiAsal: lokasiAsal,
        lokasiTujuan: lokasiTujuan,
        jarakKm: _jarakKm,
        ongkirDriver: _ongkirDriver,
        biayaAdmin: _biayaAdmin,
        totalCustomer: _totalCustomer,
        paymentMethod: _selectedPaymentMethod,
      );

      print('📢 ========== SENDING NOTIFICATION TO DRIVERS ==========');
      await Future.delayed(Duration(milliseconds: 500));
      await _sendNewOrderNotification(response, userId);
      print('========================================');

      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
        });

        _showSearchingDialog(response);
      }
    } catch (e, stackTrace) {
      print('❌ ERROR CREATE ORDER: $e');
      print('Stack: $stackTrace');
      
      if (mounted) {
        setState(() => _isCreatingOrder = false);
        OrderUtils.showErrorDialog(context, 'Error', 'Gagal membuat pesanan: ${e.toString()}');
      }
    }
  }

  Future<void> _processPaymentGateway(String userId) async {
    try {
      final userName = context.read<AuthProvider>().currentUser?.nama ?? 'Customer';
      final userEmail = context.read<AuthProvider>().currentUser?.email ?? 'customer@sidrive.com';
      final userPhone = context.read<AuthProvider>().currentUser?.noTelp ?? '08123456789';

      print('💳 ========== CREATING PAYMENT ORDER (PENDING) ==========');

      final lokasiAsal = 'POINT(${_currentPosition!.longitude} ${_currentPosition!.latitude})';
      final lokasiTujuan = 'POINT(${_destinationPosition!.longitude} ${_destinationPosition!.latitude})';

      // 1. Buat pesanan dengan status PENDING_PAYMENT
      final pesananResponse = await _pesananService.createOrderOjek(
        idCustomer: userId,
        jenisKendaraan: widget.jenisKendaraan,
        lokasiJemput: _pickupAddress,
        lokasiAntar: _destinationAddress,
        lokasiAsal: lokasiAsal,
        lokasiTujuan: lokasiTujuan,
        jarakKm: _jarakKm,
        ongkirDriver: _ongkirDriver,
        biayaAdmin: _biayaAdmin,
        totalCustomer: _totalCustomer,
        paymentMethod: _selectedPaymentMethod,
      );

      final orderId = pesananResponse['id_pesanan'];
      print('✅ Order created with PENDING status: $orderId');
      
      // 2. Call Midtrans
      final response = await supabase.functions.invoke(
        'create-payment',
        body: {
          'orderId': orderId,
          'grossAmount': _totalCustomer.toInt(),
          'customerDetails': {
            'first_name': userName,
            'email': userEmail,
            'phone': userPhone,
          },
          'itemDetails': [
            {
              'id': 'ojek_${widget.jenisKendaraan}',
              'price': _ongkirDriver.toInt(),
              'quantity': 1,
              'name': 'Ojek ${widget.jenisKendaraan == 'motor' ? 'Motor' : 'Mobil'}',
            },
            {
              'id': 'admin_fee',
              'price': _biayaAdmin.toInt(),
              'quantity': 1,
              'name': 'Biaya Admin',
            },
          ],
        },
      );

      if (response.status != 200 || response.data == null) {
        await supabase.from('pesanan').update({
          'status_pesanan': 'dibatalkan',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', orderId);
        
        setState(() => _isCreatingOrder = false);
        OrderUtils.showErrorDialog(context, 'Error', 'Gagal membuat transaksi pembayaran');
        return;
      }

      final paymentData = response.data as Map<String, dynamic>;
      setState(() => _isCreatingOrder = false);

      print('🚀 Navigating to payment gateway...');
      
      // 3. Navigate ke Payment Gateway
      final paymentResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentGatewayScreen(
            paymentUrl: paymentData['redirect_url']?.toString() ?? '',
            orderId: orderId,
            pesananData: pesananResponse,
          ),
        ),
      );

      print('💰 Payment result: $paymentResult');

      // ✅ KALAU USER CANCEL/BACK, LANGSUNG RETURN
      if (paymentResult != true) {
        print('⚠️ User cancelled payment');
        return;
      }

      // ✅ CEK STATUS PAYMENT DARI DATABASE
      print('🔍 Verifying payment status...');
      
      await Future.delayed(Duration(milliseconds: 500));
      
      final pesananCheck = await supabase
          .from('pesanan')
          .select()
          .eq('id_pesanan', orderId)
          .single();

      print('📊 Payment status: ${pesananCheck['payment_status']}');

      // ✅ KALAU PAYMENT BERHASIL, SHOW SEARCHING DIALOG
      // Dialog yang akan create pesanan dengan status mencari_driver
      if (pesananCheck['payment_status'] == 'paid') {
        print('✅ Payment verified! Showing searching dialog...');
        
        if (mounted) {
          _showSearchingDialog(pesananCheck);
        }
      } else {
        print('❌ Payment not successful');
      }

    } catch (e) {
      print('❌ Error payment gateway: $e');
      setState(() => _isCreatingOrder = false);
      OrderUtils.showErrorDialog(context, 'Error', 'Gagal memproses pembayaran: $e');
    }
  }

  Future<void> _processWalletPayment(String userId) async {
    try {
      print('💰 ========== WALLET PAYMENT ==========');

      final walletService = WalletService();

      // 1. Cek saldo
      final currentBalance = await walletService.getBalance(userId); 
      
      if (currentBalance < _totalCustomer) {
        setState(() => _isCreatingOrder = false);
        OrderUtils.showErrorDialog(
          context, 
          'Saldo Tidak Cukup', 
          'Saldo Anda: ${CurrencyFormatter.format(currentBalance)}\nTotal: ${CurrencyFormatter.format(_totalCustomer)}\n\nSilakan top up terlebih dahulu.'
        );
        return;
      }

      print('💳 Balance sufficient, creating order...');

      final lokasiAsal = 'POINT(${_currentPosition!.longitude} ${_currentPosition!.latitude})';
      final lokasiTujuan = 'POINT(${_destinationPosition!.longitude} ${_destinationPosition!.latitude})';

      // 2. Buat pesanan
      final response = await _pesananService.createOrderOjek(
        idCustomer: userId,
        jenisKendaraan: widget.jenisKendaraan,
        lokasiJemput: _pickupAddress,
        lokasiAntar: _destinationAddress,
        lokasiAsal: lokasiAsal,
        lokasiTujuan: lokasiTujuan,
        jarakKm: _jarakKm,
        ongkirDriver: _ongkirDriver,
        biayaAdmin: _biayaAdmin,
        totalCustomer: _totalCustomer,
        paymentMethod: 'wallet',
      );

      final orderId = response['id_pesanan'];
      print('✅ Order created: $orderId');

      // 3. Deduct wallet
      final deductResult = await walletService.deductWalletForOrder(
        userId: userId,
        amount: _totalCustomer,
        description: 'Pembayaran ojek ${widget.jenisKendaraan} - Order: $orderId',
      );

      if (deductResult['success'] != true) {
        // Rollback: cancel order
        await supabase.from('pesanan').update({
          'status_pesanan': 'dibatalkan',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', orderId);

        setState(() => _isCreatingOrder = false);
        OrderUtils.showErrorDialog(context, 'Error', deductResult['message'] ?? 'Gagal memotong saldo');
        return;
      }

      // 4. Update pesanan status
      await supabase.from('pesanan').update({
        'payment_status': 'paid',
        'paid_with_wallet': true,
        'wallet_deducted_amount': _totalCustomer,
        'status_pesanan': 'mencari_driver',
        'search_start_time': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', orderId);

      // 5. Reload balance
      await _loadWalletBalance();

      print('📢 Sending notification to drivers...');
      await _sendNewOrderNotification(response, userId);

      if (mounted) {
        setState(() => _isCreatingOrder = false);

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
                  child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pembayaran Berhasil',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Saldo terpotong ${CurrencyFormatter.format(_totalCustomer)}',
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
        
        // Tunggu sebentar biar user lihat konfirmasi
        await Future.delayed(Duration(milliseconds: 500));
        
        if (mounted) {
          _showSearchingDialog(response);
        }
      }
    } catch (e) {
      print('❌ Error wallet payment: $e');
      setState(() => _isCreatingOrder = false);
      OrderUtils.showErrorDialog(context, 'Error', 'Gagal memproses pembayaran: $e');
    }
  }

  Future<void> _sendNewOrderNotification(Map<String, dynamic> pesananData, String customerId) async {
    try {
      final userName = context.read<AuthProvider>().currentUser?.nama ?? 'Customer';
      
      print('📤 Calling send-new-order-notification...');
      print('📦 Order ID: ${pesananData['id_pesanan']}');
      print('🚗 Vehicle: ${widget.jenisKendaraan}');
      
      // ✅ TAMBAH: Extract lat/lng dari _currentPosition
      if (_currentPosition == null) {
        print('⚠️ WARNING: Current position is NULL!');
      }
      
      final response = await supabase.functions.invoke(
        'send-new-order-notification',
        body: {
          'orderId': pesananData['id_pesanan'],
          'customerId': customerId,
          'customerName': userName,
          'jenisKendaraan': widget.jenisKendaraan,
          'lokasiJemput': _pickupAddress,
          'lokasiTujuan': _destinationAddress,
          'lokasiJemputLat': _currentPosition!.latitude,   // ✅ TAMBAH INI
          'lokasiJemputLng': _currentPosition!.longitude,  // ✅ TAMBAH INI
          'jarak': _jarakKm,
          'ongkir': _ongkirDriver,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (response.status == 200 && response.data != null) {
        final result = response.data as Map<String, dynamic>;
        final driversNotified = result['driversNotified'] ?? 0;
        final driversWithin10km = result['driversWithin10km'] ?? 0;
        
        print('✅ Notification sent!');
        print('   - Online drivers: ${result['totalDriversOnline'] ?? 0}');
        print('   - Within 10km: $driversWithin10km');
        print('   - Notified: $driversNotified');
        
        if (driversNotified == 0) {
          print('⚠️ No drivers notified!');
          if (driversWithin10km == 0) {
            print('   Reason: No drivers within 10km radius');
          }
        }
      } else {
        print('⚠️ Failed to send notification: ${response.status}');
      }
      
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  void _showSearchingDialog(Map<String, dynamic> pesananData) {
    print('🔍 SHOW SEARCHING DRIVER DIALOG');
    
    _listenPesananUpdates(pesananData['id_pesanan']);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => OrderSearchingDialog(
        pesananData: pesananData,
        onCancel: () => _cancelSearchingOrder(dialogContext, pesananData['id_pesanan']),
      ),
    ).then((_) {

      print('🧹 Dialog closed, cleaning up...');
      _pesananStream?.cancel();
    });
  }

 

  void _listenPesananUpdates(String idPesanan) {
    print('👂 LISTENING PESANAN: $idPesanan');
    
    _pesananStream?.cancel();
    _pesananStream = supabase
        .from('pesanan')
        .stream(primaryKey: ['id_pesanan'])
        .eq('id_pesanan', idPesanan)
        .listen((data) async {
          if (data.isEmpty) return;
          if (!mounted) return;
          
          final pesanan = data.first;
          final newStatus = pesanan['status_pesanan'];
          
          print('📱 Status update: $newStatus');
          
          if (newStatus == 'diterima') {
            print('✅ DRIVER ACCEPTED!');
            
            _pesananStream?.cancel();
            
            if (!mounted) return;
            
            // ✅ TUTUP DIALOG SEARCHING (kalau ada)
            if (Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            
            await Future.delayed(Duration(milliseconds: 300));
            
            if (!mounted) return;
            
            // ✅ NAVIGATE KE LIVE TRACKING
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerLiveTracking(
                  idPesanan: pesanan['id_pesanan'],
                  pesananData: pesanan,
                ),
              ),
            );
          } else if (newStatus == 'dibatalkan' || newStatus == 'gagal') {
            print('🚫 Order cancelled/failed');
            
            _pesananStream?.cancel();
            
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          }
        });
  }

  Future<void> _cancelSearchingOrder(BuildContext dialogContext, String idPesanan) async {
    print('🚫 CANCEL ORDER');
    
    final confirm = await OrderUtils.showCancelConfirmDialog(dialogContext);
    if (confirm != true) return;

    try {
      _pesananStream?.cancel();
      
      // ✅ CEK APAKAH ORDER PAKAI WALLET ATAU TRANSFER
      final pesanan = await supabase
          .from('pesanan')
          .select('id_user, paid_with_wallet, wallet_deducted_amount, payment_method, total_harga')
          .eq('id_pesanan', idPesanan)
          .single();
      
      final paidWithWallet = pesanan['paid_with_wallet'] == true;
      final walletAmount = (pesanan['wallet_deducted_amount'] ?? 0).toDouble();
      final userId = pesanan['id_user'];
      final paymentMethod = pesanan['payment_method'];
      final totalHarga = (pesanan['total_harga'] ?? 0).toDouble();
      
      print('💳 Payment method: $paymentMethod');
      print('💰 Paid with wallet: $paidWithWallet');
      print('💵 Wallet amount: Rp${walletAmount.toStringAsFixed(0)}');
      
      // ✅ UPDATE STATUS KE DIBATALKAN
      await supabase.from('pesanan').update({
        'status_pesanan': 'dibatalkan',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);

      String refundMessage = '';

      // ✅ REFUND JIKA PAKAI WALLET
      if (paidWithWallet && walletAmount > 0) {
        print('💸 Processing wallet refund...');
        
        final walletService = WalletService();
        final refunded = await walletService.refundWalletForFailedOrder(
          userId: userId,
          orderId: idPesanan,
          amount: walletAmount,
          reason: 'Pesanan dibatalkan oleh customer',
        );
        
        if (refunded) {
          print('✅ Wallet refund successful');
          await _loadWalletBalance();
          refundMessage = '\n\nSaldo ${CurrencyFormatter.format(walletAmount)} telah dikembalikan';
        } else {
          print('❌ Wallet refund failed');
          refundMessage = '\n\nGagal mengembalikan saldo. Hubungi customer service.';
        }
      }
      // ✅ TANDAI JIKA PAKAI TRANSFER (untuk admin)
      else if (paymentMethod == 'transfer' || paymentMethod == 'qris' || paymentMethod == 'gopay') {
        print('🏷️ Marking transfer order for manual refund...');
        
        // ✅ CUKUP UPDATE CATATAN ADMIN
        await supabase.from('pesanan').update({
          'catatan_admin': 'Pesanan dibatalkan oleh customer - Perlu refund manual Midtrans sejumlah Rp${totalHarga.toStringAsFixed(0)}',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', idPesanan);
        
        print('✅ Order marked for admin review');
        refundMessage = '\n\nRefund akan diproses dalam 1x24 jam ke metode pembayaran Anda.';
      }

      // ✅ TUTUP DIALOG - PERBAIKAN: Simpan context dulu
      final navigatorContext = Navigator.of(dialogContext, rootNavigator: true).context;
      
      if (Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext, rootNavigator: true).pop();
      }
      
      // ✅ TUNGGU LEBIH LAMA agar widget tree stabil
      await Future.delayed(Duration(milliseconds: 500));
      
      // ✅ CEK mounted SEBELUM tampilkan dialog
      if (mounted && navigatorContext.mounted) {
        ErrorDialogUtils.showWarningDialog(
          context: context, // ✅ Gunakan context dari State, bukan dialogContext
          title: 'Pesanan Dibatalkan',
          message: 'Pesanan Anda telah dibatalkan$refundMessage',
        );
      }
      
    } catch (e) {
      print('❌ Error cancel: $e');
      
      // ✅ TUTUP DIALOG terlebih dahulu
      if (Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext, rootNavigator: true).pop();
      }
      
      // ✅ TUNGGU sebentar
      await Future.delayed(Duration(milliseconds: 500));
      
      // ✅ CEK mounted SEBELUM tampilkan error
      if (mounted) {
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Error',
          message: 'Gagal membatalkan pesanan',
        );
      }
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    Color vehicleColor = widget.jenisKendaraan == 'motor'
        ? Color(0xFF00880F)
        : Color(0xFF1E88E5);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapRouteOrder(
            key: _mapKey,
            currentPosition: _currentPosition,
            destinationPosition: _destinationPosition,
            routePoints: _routePoints,
            onMapMoved: _onMapMoved,
            isDropPinMode: _isDropPinMode,
            centerPoint: SERVICE_CENTER,
            radiusKm: SERVICE_RADIUS_KM,
          ),


          if (!_isDropPinMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black87, size: 24),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Kembali',
                  padding: EdgeInsets.all(8),
                ),
              ),
            ),

          // ✅ OrderSearchBar - Geser kanan, HANYA tampil saat TIDAK drop pin mode
          if (!_isDropPinMode)
            Positioned(
              top: MediaQuery.of(context).padding.top - 23,
              left: 65, // ✅ Geser kanan agar tidak overlap back button
              right: 16,
              child: OrderSearchBar(
                pickupController: _pickupController,
                destinationController: _destinationController,
                pickupFocus: _pickupFocus,
                destinationFocus: _destinationFocus,
                destinationPosition: _destinationPosition,
                onClearDestination: _clearDestination,
                onClose: () => Navigator.pop(context),
                showSearchResults: _showSearchResults,
                searchResults: _searchResults,
                onSelectPlace: _selectPlace,
                showPickupInput: _showPickupInput,
                onPickupFieldTap: _showPickupOptionsDialog,
                onDestinationFieldTap: _showDestinationOptionsDialog,
              ),
            ),

          if (_isDropPinMode)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, -80), // ✅ NAIKKAN 80 pixel ke atas (ubah angka ini untuk naikkan/turunkan)
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: 60,
                            color: _isPickupMode ? Color(0xFF4285F4) : Color(0xFFEA4335),
                          ),
                        ),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ✅ Control panel - Hanya tampil saat drop pin mode
          if (_isDropPinMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Info banner
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPickupMode ? Icons.my_location : Icons.location_on,
                          color: _isPickupMode ? Color(0xFF4285F4) : Color(0xFFEA4335),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _isPickupMode
                                ? 'Geser peta untuk lokasi jemput'
                                : 'Geser peta untuk tujuan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Toggle Jemput/Tujuan
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton(
                          label: 'Jemput',
                          icon: Icons.my_location,
                          isActive: _isPickupMode,
                          color: Color(0xFF4285F4),
                          onTap: () => setState(() => _isPickupMode = true),
                        ),
                        SizedBox(width: 4),
                        _buildToggleButton(
                          label: 'Tujuan',
                          icon: Icons.location_on,
                          isActive: !_isPickupMode,
                          color: Color(0xFFEA4335),
                          onTap: () => setState(() => _isPickupMode = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ✅ Confirm & Cancel buttons - Hanya tampil saat drop pin mode
          if (_isDropPinMode)
            Positioned(
              bottom: _bottomSheetHeight + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 44, // ✅ DIKECILKAN dari 54 jadi 44
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22), // ✅ SESUAIKAN radius
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _cancelDropPin,
                        icon: Icon(Icons.close, size: 18), // ✅ KECILKAN icon dari 20 jadi 18
                        label: Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 14, // ✅ KECILKAN font dari 16 jadi 14
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade600,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ✅ TAMBAH padding untuk center
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22), // ✅ SESUAIKAN radius
                            side: BorderSide(color: Colors.red.shade600, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Confirm button
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 44, // ✅ DIKECILKAN dari 54 jadi 44
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22), // ✅ SESUAIKAN radius
                        gradient: LinearGradient(
                          colors: _isPickupMode
                              ? [Color(0xFF4285F4), Color(0xFF3367D6)]
                              : [Color(0xFFEA4335), Color(0xFFD33426)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isPickupMode ? Color(0xFF4285F4) : Color(0xFFEA4335))
                                .withOpacity(0.5),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _confirmDropPin,
                        icon: Icon(Icons.check_circle, size: 18), // ✅ KECILKAN icon dari 22 jadi 18
                        label: Text(
                          'Konfirmasi Lokasi',
                          style: TextStyle(
                            fontSize: 14, // ✅ KECILKAN font dari 16 jadi 14
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ✅ TAMBAH padding untuk center
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22), // ✅ SESUAIKAN radius
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom sheet
          OrderBottomSheet(
            bottomSheetHeight: _bottomSheetHeight,
            minHeight: _minHeight,
            maxHeight: _maxHeight,
            onDragUpdate: (details) {
              setState(() {
                _bottomSheetHeight -= details.delta.dy;
                
                double effectiveMinHeight = _destinationPosition == null ? _minHeight : _collapsedHeight;
                
                if (_bottomSheetHeight < effectiveMinHeight) {
                  _bottomSheetHeight = effectiveMinHeight;
                }
                if (_bottomSheetHeight > _maxHeight) {
                  _bottomSheetHeight = _maxHeight;
                }
              });
            },
            jenisKendaraan: widget.jenisKendaraan,
            destinationPosition: _destinationPosition,
            estimatedTime: _estimatedTime,
            jarakKm: _jarakKm,
            pickupAddress: _pickupAddress,
            destinationAddress: _destinationAddress,
            ongkirDriver: _ongkirDriver,       
            biayaAdmin: _biayaAdmin,           
            totalCustomer: _totalCustomer,
            isCreatingOrder: _isCreatingOrder,
            onFindDriver: _findDriver,
            selectedPaymentMethod: _selectedPaymentMethod,
            currentWalletBalance: _currentWalletBalance,
            onPaymentMethodChanged: (method) {
              setState(() {
                _selectedPaymentMethod = method;
              });
            },
            isDropPinMode: _isDropPinMode,
            isPickupMode: _isPickupMode,
            onToggleDropPin: _toggleDropPinMode,
            onTogglePickupDestination: _togglePickupDestinationMode,
          ),

          // ✅ REVISI: Badge kampus DI TENGAH (dekat bottom sheet) & GPS button DI POJOK KANAN
          if (!_isDropPinMode) ...[
            // ✅ 2. GPS BUTTON - DI POJOK KANAN
            Positioned(
              bottom: _bottomSheetHeight + ResponsiveMobile.scaledH(20),
              right: ResponsiveMobile.scaledW(16), // ✅ POJOK KANAN
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_currentPosition != null) {
                    _mapKey.currentState?.moveToLocation(_currentPosition!, 15.0);
                  }
                },
                child: Icon(
                  Icons.my_location,
                  color: Color(0xFF4285F4),
                  size: ResponsiveMobile.scaledFont(20),
                ),
              ),
            ),
          ],

          // Loading overlay
          if (_isLoadingLocation || _isCalculating || _isLoadingConfig)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(vehicleColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025