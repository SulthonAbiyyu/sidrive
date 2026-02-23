import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/screens/driver/pages/trackingpage_driver.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';


class PesananPage extends StatefulWidget {
  final List<Map<String, dynamic>> pesananMasuk;
  final bool isOnline;
  final Map<String, dynamic>? driverData;
  final Position? currentPosition;

  const PesananPage({
    Key? key,
    required this.pesananMasuk,
    required this.isOnline,
    this.driverData,
    this.currentPosition,
  }) : super(key: key);

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  final supabase = Supabase.instance.client;
  late List<Map<String, dynamic>> _filteredPesanan;
  final Map<String, Map<String, dynamic>> _customerCache = {};

  @override
  void initState() {
    super.initState();
    _filteredPesanan = List.from(widget.pesananMasuk);
    // ❌ HAPUS _listenToPesananUpdates() - sudah ada di dashboard!
  }

  @override
  void didUpdateWidget(PesananPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // ✅ Update dari dashboard saat pesananMasuk berubah
    if (oldWidget.pesananMasuk != widget.pesananMasuk) {
      print('🔄 PESANAN UPDATE: ${widget.pesananMasuk.length} pesanan');
      
      // ✅ FIXED: Hanya satu for loop (tidak nested)
      for (var p in widget.pesananMasuk) {
        print('   - ID: ${p['id_pesanan']}');
        print('     Jenis: ${p['jenis']}');
        print('     Kendaraan: ${p['jenis_kendaraan']}');
        print('     Status: ${p['status_pesanan']}');
      }

      print('   Driver Vehicle: ${widget.driverData?['active_vehicle_types']}');
      print('   Driver Online: ${widget.isOnline}');
      print('======================================');
      
      setState(() {
        _filteredPesanan = List.from(widget.pesananMasuk);
      });
    }
    
    // ✅ Kalau isOnline berubah dari true ke false
    if (oldWidget.isOnline && !widget.isOnline) {
      print('🔴 Driver went OFFLINE - clearing pesanan');
      setState(() {
        _filteredPesanan = [];
      });
    }
    
    // ✅ Kalau active_vehicle_type berubah (driver ganti kendaraan)
    if (oldWidget.driverData?['active_vehicle_type'] != widget.driverData?['active_vehicle_type']) {
      print('🔄 Active vehicle changed - clearing cache and list');
      _customerCache.clear();
      setState(() {
        _filteredPesanan = [];
      });
    }
  }

  // ❌ HAPUS METHOD _listenToPesananUpdates() - tidak diperlukan lagi!

  Future<Map<String, dynamic>?> _getCustomerData(String userId) async {
    if (_customerCache.containsKey(userId)) {
      return _customerCache[userId];
    }
    
    try {
      final response = await supabase
          .from('users')
          .select('nama, no_telp, foto_profil')
          .eq('id_user', userId)
          .maybeSingle();
      
      if (response != null) {
        _customerCache[userId] = response;
      }
      return response;
    } catch (e) {
      print('❌ Error loading customer: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _customerCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _filteredPesanan.isEmpty
                    ? _buildEmptyState(widget.isOnline)
                    : _buildPesananList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final List<String> activeVehicleTypes = (widget.driverData?['active_vehicle_types'] as List?)
    ?.cast<String>() ?? [];

    String vehicleText = 'Belum pilih kendaraan';
    IconData vehicleIcon = Icons.directions_car;

    if (activeVehicleTypes.isNotEmpty) {
      if (activeVehicleTypes.length == 1) {
        vehicleText = 'Pesanan ${activeVehicleTypes.first.toUpperCase()}';
        vehicleIcon = activeVehicleTypes.first == 'motor' ? Icons.two_wheeler : Icons.directions_car;
      } else {
        vehicleText = 'Pesanan ${activeVehicleTypes.map((t) => t.toUpperCase()).join(' + ')}';
        vehicleIcon = Icons.commute;
      }
    }
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveMobile.scaledW(20),
        ResponsiveMobile.scaledH(16),
        ResponsiveMobile.scaledW(20),
        ResponsiveMobile.scaledH(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesanan Masuk',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(28),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF6B9D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: ResponsiveMobile.scaledH(4)),
                    // ✅ Tampilkan kendaraan aktif di subtitle
                    Row(
                      children: [
                        Icon(
                          vehicleIcon,
                          size: ResponsiveMobile.scaledFont(14),
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: ResponsiveMobile.scaledW(4)),
                        Text(
                          vehicleText,
                          style: TextStyle(
                            fontSize: ResponsiveMobile.scaledFont(14),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_filteredPesanan.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveMobile.scaledW(16),
                    vertical: ResponsiveMobile.scaledH(8),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: const Color(0xFFFF6B9D),
                        size: ResponsiveMobile.scaledFont(18),
                      ),
                      SizedBox(width: ResponsiveMobile.scaledW(6)),
                      Text(
                        '${_filteredPesanan.length}',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(16),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF6B9D),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isOnline) {
    final List<String> activeVehicleTypes = (widget.driverData?['active_vehicle_types'] as List?)
        ?.cast<String>() ?? [];
    final bool hasActiveVehicle = activeVehicleTypes.isNotEmpty;
    
    return Center(
      child: Container(
        margin: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(32)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
              decoration: BoxDecoration(
                color: isOnline 
                    ? const Color(0xFFFF6B9D).withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasActiveVehicle 
                    ? (isOnline ? Icons.inbox_outlined : Icons.cloud_off_outlined)
                    : Icons.warning_amber_rounded,
                size: ResponsiveMobile.scaledFont(64),
                color: hasActiveVehicle
                    ? (isOnline ? const Color(0xFFFF6B9D) : Colors.grey.shade400)
                    : Colors.orange,
              ),
            ),
            SizedBox(height: ResponsiveMobile.scaledH(24)),
            Text(
              !hasActiveVehicle
                  ? 'Belum Pilih Kendaraan'
                  : (isOnline 
                      ? 'Belum Ada Pesanan' 
                      : 'Anda Sedang Offline'),
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(20),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveMobile.scaledH(12)),
            Text(
              !hasActiveVehicle
                  ? 'Pilih kendaraan aktif di Profile untuk mulai menerima pesanan'
                  : (isOnline
                      ? 'Pesanan akan muncul di sini saat ada customer yang membutuhkan kendaraan ${activeVehicleTypes.map((t) => t.toUpperCase()).join(' atau ')}'
                      : 'Aktifkan status online Anda untuk mulai menerima pesanan'),
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(14),
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasActiveVehicle) ...[
              SizedBox(height: ResponsiveMobile.scaledH(24)),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to profile to select vehicle
                  Navigator.pushNamed(context, '/profile');
                },
                icon: const Icon(Icons.directions_car, size: 20),
                label: const Text('Pilih Kendaraan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveMobile.scaledW(24),
                    vertical: ResponsiveMobile.scaledH(12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  ),
                ),
              ),
            ],
            if (!isOnline && hasActiveVehicle) ...[
              SizedBox(height: ResponsiveMobile.scaledH(24)),
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: ResponsiveMobile.scaledFont(18),
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(8)),
                    Expanded(
                      child: Text(
                        'Klik tombol toggle di Home untuk online',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(12),
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPesananList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        ResponsiveMobile.scaledW(16),
        ResponsiveMobile.scaledH(8),
        ResponsiveMobile.scaledW(16),
        ResponsiveMobile.scaledH(16),
      ),
      itemCount: _filteredPesanan.length,
      itemBuilder: (context, index) {
        final pesanan = _filteredPesanan[index];
        return _buildPesananCard(pesanan);
      },
    );
  }
  
  Widget _buildPesananCard(Map<String, dynamic> pesanan) {
    final String jenisKendaraan = pesanan['jenis_kendaraan']?.toString() ?? 'motor';
    final bool isMotor = jenisKendaraan == 'motor';
    final Color vehicleColor = isMotor ? Colors.green : Colors.blue;
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCustomerData(pesanan['id_user']),
      builder: (context, snapshot) {
        final customerData = snapshot.data;
        final customerName = customerData?['nama'] ?? 'Customer';
        
        return Container(
          margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
              onTap: () => _showConfirmationDialog(pesanan),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan customer info dan badge kendaraan
                    Row(
                      children: [
                        CircleAvatar(
                          radius: ResponsiveMobile.scaledR(24),
                          backgroundImage: customerData?['foto_profil'] != null
                              ? NetworkImage(customerData!['foto_profil'])
                              : null,
                          backgroundColor: const Color(0xFFFF6B9D).withOpacity(0.1),
                          child: customerData?['foto_profil'] == null
                              ? Icon(
                                  Icons.person,
                                  size: ResponsiveMobile.scaledFont(24),
                                  color: const Color(0xFFFF6B9D),
                                )
                              : null,
                        ),
                        SizedBox(width: ResponsiveMobile.scaledW(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(16),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: ResponsiveMobile.scaledH(4)),
                              Text(
                                customerData?['no_telp'] ?? '',
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(13),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ✅ BADGE KENDARAAN
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveMobile.scaledW(10),
                            vertical: ResponsiveMobile.scaledH(6),
                          ),
                          decoration: BoxDecoration(
                            color: vehicleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                            border: Border.all(
                              color: vehicleColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isMotor ? Icons.two_wheeler : Icons.directions_car,
                                size: ResponsiveMobile.scaledFont(14),
                                color: vehicleColor,
                              ),
                              SizedBox(width: ResponsiveMobile.scaledW(4)),
                              Text(
                                jenisKendaraan.toUpperCase(),
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(10),
                                  fontWeight: FontWeight.bold,
                                  color: vehicleColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: ResponsiveMobile.scaledH(16)),
                    
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    
                    SizedBox(height: ResponsiveMobile.scaledH(16)),
                    
                    // Alamat Jemput
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                          ),
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: ResponsiveMobile.scaledFont(18),
                          ),
                        ),
                        SizedBox(width: ResponsiveMobile.scaledW(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lokasi Jemput',
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(11),
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: ResponsiveMobile.scaledH(4)),
                              Text(
                                pesanan['alamat_asal'] ?? '-',
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(13),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: ResponsiveMobile.scaledH(12)),
                    
                    // Alamat Tujuan
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B9D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                          ),
                          child: Icon(
                            Icons.place,
                            color: const Color(0xFFFF6B9D),
                            size: ResponsiveMobile.scaledFont(18),
                          ),
                        ),
                        SizedBox(width: ResponsiveMobile.scaledW(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tujuan',
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(11),
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: ResponsiveMobile.scaledH(4)),
                              Text(
                                pesanan['alamat_tujuan'] ?? '-',
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(13),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: ResponsiveMobile.scaledH(16)),
                    
                    // Footer dengan jarak dan harga
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Jarak
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveMobile.scaledW(12),
                            vertical: ResponsiveMobile.scaledH(8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.route,
                                size: ResponsiveMobile.scaledFont(16),
                                color: Colors.grey.shade700,
                              ),
                              SizedBox(width: ResponsiveMobile.scaledW(6)),
                              Text(
                                '${pesanan['jarak_km']?.toStringAsFixed(1) ?? '0'} km',
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(13),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Harga
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveMobile.scaledW(16),
                            vertical: ResponsiveMobile.scaledH(10),
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Rp ${_formatCurrency(pesanan['ongkir'])}',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledFont(16),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: ResponsiveMobile.scaledH(16)),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showConfirmationDialog(pesanan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B9D),
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveMobile.scaledH(14),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: ResponsiveMobile.scaledFont(18),
                            ),
                            SizedBox(width: ResponsiveMobile.scaledW(8)),
                            Text(
                              'TERIMA PESANAN',
                              style: TextStyle(
                                fontSize: ResponsiveMobile.scaledFont(14),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    try {
      final number = value is num ? value : double.tryParse(value.toString()) ?? 0;
      return number.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    } catch (e) {
      return '0';
    }
  }


  Future<void> _acceptPesanan(String idPesanan) async {
    print('🔍 ========== DEBUG ACCEPT PESANAN ==========');
    
    if (widget.currentPosition == null) {
      print('❌ ERROR: currentPosition is NULL');
      _showModernDialog(
        context: context,
        icon: Icons.location_off,
        iconColor: Colors.orange,
        title: 'Lokasi Tidak Tersedia',
        message: 'Tidak dapat mendeteksi lokasi Anda. Pastikan GPS aktif.',
      );
      return;
    }
    
    print('✅ Current Position: ${widget.currentPosition!.latitude}, ${widget.currentPosition!.longitude}');
    
    final driverId = widget.driverData?['id_driver'];
    print('🔍 driverId extracted: $driverId');
    
    if (driverId == null) {
      print('❌ ERROR: driverId is NULL');
      _showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'Error',
        message: 'Data driver tidak ditemukan',
      );
      return;
    }

    _showLoadingDialog(context);

    try {
      print('📄 Step 1: Accepting order: $idPesanan by driver: $driverId');

      // ✅ 1. Update pesanan status ke "dalam_pengiriman"
      print('📄 Step 2: Updating pesanan to dalam_pengiriman...');
      final updatePesananResponse = await supabase
          .from('pesanan')
          .update({
            'status_pesanan': 'dalam_pengiriman', // ← UBAH dari 'diterima'
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_pesanan', idPesanan)
          .select()
          .maybeSingle();

      print('📄 Step 3: Update result: $updatePesananResponse');

      if (updatePesananResponse == null) {
        throw Exception('Gagal update status pesanan');
      }

      print('✅ Pesanan status updated to dalam_pengiriman');

      // ✅ 2. Insert ke tabel pengiriman dengan status "diterima"
      print('📄 Step 4: Preparing pengiriman data...');
      
      final pengirimanData = {
        'id_pesanan': idPesanan,
        'id_driver': driverId,
        'status_pengiriman': 'diterima', // ← Status pengiriman
        'waktu_terima': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('📄 Step 5: Pengiriman data prepared: $pengirimanData');
      
      print('📄 Step 6: Inserting to pengiriman table...');
      final insertPengirimanResponse = await supabase
          .from('pengiriman')
          .insert(pengirimanData)
          .select()
          .maybeSingle();

      print('📄 Step 7: Insert result: $insertPengirimanResponse');

      if (insertPengirimanResponse == null) {
        throw Exception('Gagal membuat record pengiriman');
      }

      print('✅ Pengiriman record created: ${insertPengirimanResponse['id_pengiriman']}');

      if (mounted) {
        print('📄 Step 8: Closing dialog and navigating...');
        Navigator.pop(context);
        
        print('📄 Step 9: Showing success dialog...');
        _showSuccessDialog(
          context: context,
          onContinue: () {
            print('📄 Step 10: Navigating to tracking page...');
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PengirimanDetailDriver(
                  pengirimanData: insertPengirimanResponse,
                  pesananData: updatePesananResponse,
                ),
              ),
            );
          },
        );
      }
      
      print('✅ ========== ACCEPT PESANAN SUCCESS ==========');
    } catch (e, stackTrace) {
      print('❌ ========== ERROR ACCEPT PESANAN ==========');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      
      if (mounted) {
        Navigator.pop(context);
        
        _showModernDialog(
          context: context,
          icon: Icons.error_outline,
          iconColor: Colors.red,
          title: 'Gagal Terima Pesanan',
          message: e.toString().contains('pesanan sudah diterima') 
              ? 'Maaf, pesanan ini sudah diambil driver lain'
              : 'Terjadi kesalahan. Silakan coba lagi.',
        );
      }
    }
  }

  Future<void> _showConfirmationDialog(Map<String, dynamic> pesanan) async {
    final String jenisKendaraan = pesanan['jenis_kendaraan']?.toString() ?? 'motor';
    final bool isMotor = jenisKendaraan == 'motor';
    final Color vehicleColor = isMotor ? Colors.green : Colors.blue;
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
        ),
        child: Container(
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B9D),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_turned_in,
                  size: ResponsiveMobile.scaledFont(40),
                  color: Colors.white,
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              Text(
                'Terima Pesanan?',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(12)),
              
              // ✅ Badge jenis kendaraan
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveMobile.scaledW(12),
                  vertical: ResponsiveMobile.scaledH(6),
                ),
                decoration: BoxDecoration(
                  color: vehicleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                  border: Border.all(
                    color: vehicleColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMotor ? Icons.two_wheeler : Icons.directions_car,
                      size: ResponsiveMobile.scaledFont(16),
                      color: vehicleColor,
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(6)),
                    Text(
                      'Pesanan ${jenisKendaraan.toUpperCase()}',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(12),
                        fontWeight: FontWeight.bold,
                        color: vehicleColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(16)),
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: ResponsiveMobile.scaledFont(16),
                          color: Colors.blue,
                        ),
                        SizedBox(width: ResponsiveMobile.scaledW(8)),
                        Expanded(
                          child: Text(
                            pesanan['alamat_asal']?.toString() ?? '-',
                            style: TextStyle(fontSize: ResponsiveMobile.scaledFont(12)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveMobile.scaledH(8)),
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          size: ResponsiveMobile.scaledFont(16),
                          color: const Color(0xFFFF6B9D),
                        ),
                        SizedBox(width: ResponsiveMobile.scaledW(8)),
                        Expanded(
                          child: Text(
                            pesanan['alamat_tujuan']?.toString() ?? '-',
                            style: TextStyle(fontSize: ResponsiveMobile.scaledFont(12)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveMobile.scaledH(8)),
                    Text(
                      'Rp ${_formatCurrency(pesanan['ongkir'])}',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(18),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(24)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: ResponsiveMobile.scaledH(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Batal', style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14))),
                    ),
                  ),
                  SizedBox(width: ResponsiveMobile.scaledW(12)),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B9D),
                        padding: EdgeInsets.symmetric(vertical: ResponsiveMobile.scaledH(14)),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Ya, Terima',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(14),
                          fontWeight: FontWeight.bold,
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

    if (confirmed == true && mounted) {
      _acceptPesanan(pesanan['id_pesanan']);
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF6B9D)),
              SizedBox(height: ResponsiveMobile.scaledH(16)),
              Text('Memproses...', style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14))),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog({required BuildContext context, required VoidCallback onContinue}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: ResponsiveMobile.scaledFont(48),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveMobile.scaledH(20)),
                Text(
                  'Berhasil!',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveMobile.scaledH(12)),
                Text(
                  'Pesanan berhasil diterima',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(14),
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveMobile.scaledH(24)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: EdgeInsets.symmetric(vertical: ResponsiveMobile.scaledH(14)),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Lanjutkan',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(16),
                        fontWeight: FontWeight.bold,
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

    void _showModernDialog({
      required BuildContext context,
      required IconData icon,
      required Color iconColor,
      required String title,
      required String message,
    }) {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: ResponsiveMobile.scaledFont(48), color: iconColor),
            ),
            SizedBox(height: ResponsiveMobile.scaledH(20)),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveMobile.scaledH(12)),
            Text(
              message,
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(14),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveMobile.scaledH(24)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  padding: EdgeInsets.symmetric(vertical: ResponsiveMobile.scaledH(14)),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(16),
                    fontWeight: FontWeight.bold,
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
}