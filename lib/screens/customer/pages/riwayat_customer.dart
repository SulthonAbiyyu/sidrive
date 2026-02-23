import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/screens/customer/pages/customer_live_tracking.dart';
import 'package:sidrive/screens/customer/pages/customer_umkm_tracking.dart';
import 'package:sidrive/services/rating_ulasan_service.dart';
import 'package:sidrive/core/widgets/rating_widgets.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';
import 'package:sidrive/services/order_timer_service.dart';
import 'package:sidrive/services/order_timer_initializer.dart';
import 'package:sidrive/screens/customer/pages/umkm_rating_dialog.dart';
import 'package:sidrive/screens/customer/pages/payment_gateway_screen.dart';
import 'package:sidrive/screens/customer/dashboard_customer.dart';


class RiwayatCustomer extends StatefulWidget {
  final String userId;
  final int initialTab;

  const RiwayatCustomer({
    Key? key,
    required this.userId,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<RiwayatCustomer> createState() => _RiwayatCustomerState();
}


class _RiwayatCustomerState extends State<RiwayatCustomer>
  with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _ratingService = RatingUlasanService();

  late TabController _tabController;
  String _ojekFilter = 'berlangsung';
  String _umkmFilter = 'semua';
  StreamSubscription? _pesananStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTab, // ✅ TAMBAH
    );
    _ensureTimerRestored();
  }
  

  // ✅ TAMBAHKAN FUNGSI BARU INI SETELAH initState
  Future<void> _ensureTimerRestored() async {
    try {
      print('🔄 [Riwayat] Ensuring timer restored...');
      await OrderTimerInitializer.restoreActiveTimer(widget.userId);
      print('✅ [Riwayat] Timer check complete');
    } catch (e) {
      print('❌ [Riwayat] Error restoring timer: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pesananStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardCustomer()),
          (route) => route.isFirst,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(ResponsiveMobile.scaledH(100)),
          child: _buildAppBar(),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOjekOnlineTab(),
            _buildUmkmTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFB6C1),
            Color(0xFFFFB6C1).withOpacity(0.95),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: ResponsiveMobile.scaledH(44),
              padding: ResponsiveMobile.horizontalPadding(context, 4),
              alignment: Alignment.center,
              child: Text(
                'Order History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Container(
              height: ResponsiveMobile.scaledH(46),
              margin: ResponsiveMobile.horizontalPadding(context, 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(23),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Color(0xFFFFB6C1),
                unselectedLabelColor: Colors.white.withOpacity(0.9),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Ojek Online'),
                  Tab(text: 'UMKM'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOjekOnlineTab() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(
            ResponsiveMobile.scaledW(16),
            ResponsiveMobile.scaledH(12),
            ResponsiveMobile.scaledW(16),
            ResponsiveMobile.scaledH(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  'Berlangsung',
                  'berlangsung',
                  Icons.access_time_rounded,
                  Color(0xFFFF6B9D),
                ),
              ),
              SizedBox(width: ResponsiveMobile.scaledW(8)),
              Expanded(
                child: _buildFilterButton(
                  'Selesai',
                  'selesai',
                  Icons.check_circle,
                  Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: ResponsiveMobile.scaledW(8)),
              Expanded(
                child: _buildFilterButton(
                  'Dibatalkan',
                  'dibatalkan',
                  Icons.cancel,
                  Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildPesananStream(),
        ),
      ],
    );
  }

  Widget _buildFilterButton(
    String label,
    String filter,
    IconData icon,
    Color activeColor,
  ) {
    final isActive = _ojekFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _ojekFilter = filter;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveMobile.scaledH(10),
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUmkmFilterButton(String label, String filter, IconData icon, Color activeColor) {
    final isActive = _umkmFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _umkmFilter = filter;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ResponsiveMobile.scaledH(10)),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : Colors.grey[600]),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUmkmPesananStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('pesanan')
          .stream(primaryKey: ['id_pesanan'])
          .eq('id_user', widget.userId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('Belum ada pesanan UMKM');
        }

        List<Map<String, dynamic>> filteredData = snapshot.data!;

        // ✅ FILTER UMKM MANUAL DI DART!
        filteredData = filteredData.where((item) => item['jenis'] == 'umkm').toList();

        // ✅ FILTER BERDASARKAN TAB
        if (_umkmFilter == 'diproses') {
          filteredData = filteredData.where((item) {
            final status = item['status_pesanan'];
            return status == 'menunggu_pembayaran' ||
                  status == 'diproses' || 
                  status == 'siap_kirim' || 
                  status == 'mencari_driver' || 
                  status == 'dalam_pengiriman';
          }).toList();
        } else if (_umkmFilter == 'selesai') {
          filteredData = filteredData.where((item) {
            final status = item['status_pesanan'];
            return status == 'selesai' || status == 'dibatalkan';
          }).toList();
        }

        if (filteredData.isEmpty) {
          return _buildEmptyState('Tidak ada pesanan $_umkmFilter');
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            ResponsiveMobile.scaledW(16),
            ResponsiveMobile.scaledH(4),
            ResponsiveMobile.scaledW(16),
            ResponsiveMobile.scaledH(16),
          ),
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            return _UmkmPesananCard(
              pesanan: filteredData[index],
              userId: widget.userId,
            );
          },
        );
      },
    );
  }

  Widget _buildPesananStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('pesanan')
          .stream(primaryKey: ['id_pesanan'])
          .eq('id_user', widget.userId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorDialogUtils.showErrorDialog(
              context: context,
              title: 'Terjadi Kesalahan',
              message: 'Gagal memuat data pesanan: ${snapshot.error}',
              actionText: 'Coba Lagi',
              onAction: () {
                setState(() {});
              },
            );
          });
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('Belum ada pesanan');
        }

        List<Map<String, dynamic>> filteredData = snapshot.data!;

        // ✅ FILTER OJEK MANUAL DI DART!
        filteredData = filteredData.where((item) => item['jenis'] == 'ojek').toList();

        if (_ojekFilter == 'berlangsung') {
          filteredData = filteredData.where((item) {
            final status = item['status_pesanan'];
            return item['jenis'] == 'ojek' &&
                status != 'selesai' &&
                status != 'dibatalkan' &&
                status != 'cancelled' &&
                status != 'gagal';
          }).toList();
        } else if (_ojekFilter == 'selesai') {
          filteredData = filteredData
              .where((item) => item['status_pesanan'] == 'selesai')
              .toList();
        } else if (_ojekFilter == 'dibatalkan') {
          filteredData = filteredData.where((item) {
            final status = item['status_pesanan'];
            return status == 'dibatalkan' ||
                status == 'cancelled' ||
                status == 'gagal';
          }).toList();
        }

        if (filteredData.isEmpty) {
          String message;
          switch (_ojekFilter) {
            case 'berlangsung':
              message = 'Tidak ada pesanan berlangsung';
              break;
            case 'selesai':
              message = 'Tidak ada riwayat selesai';
              break;
            case 'dibatalkan':
              message = 'Tidak ada pesanan dibatalkan';
              break;
            default:
              message = 'Belum ada pesanan';
          }
          return _buildEmptyState(message);
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            ResponsiveMobile.scaledW(16),
            ResponsiveMobile.scaledH(4),
            ResponsiveMobile.scaledW(16),
            ResponsiveMobile.scaledH(16),
          ),
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            return _PesananCard(
              pesanan: filteredData[index],
              isActive: _ojekFilter == 'berlangsung',
              userId: widget.userId,
              ratingService: _ratingService,
              onRatingSubmitted: () {
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUmkmTab() {
    return Column(
      children: [
        // Filter buttons
        Container(
          margin: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _buildUmkmFilterButton('Semua', 'semua', Icons.list, Color(0xFFFF6B9D)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildUmkmFilterButton('Diproses', 'diproses', Icons.hourglass_empty, Color(0xFF2196F3)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildUmkmFilterButton('Selesai', 'selesai', Icons.check_circle, Color(0xFF4CAF50)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildUmkmPesananStream(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat pesanan...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B9D),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text('Coba Lagi', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pesanan akan muncul di sini',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _PesananCard extends StatefulWidget {
  final Map<String, dynamic> pesanan;
  final bool isActive;
  final String userId;
  final RatingUlasanService ratingService;
  final VoidCallback onRatingSubmitted;

  const _PesananCard({
    required this.pesanan,
    required this.isActive,
    required this.userId,
    required this.ratingService,
    required this.onRatingSubmitted,
  });

  @override
  State<_PesananCard> createState() => _PesananCardState();
}

class _PesananCardState extends State<_PesananCard> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _pengirimanData;
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _ratingData;

  bool _isLoading = true;
  bool _isSubmittingRating = false;


  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      print('\n🔥 ========== LOAD ORDER DATA START ==========');
      print('📦 Pesanan ID: ${widget.pesanan['id_pesanan']}');
      
      // STEP 1: Load pengiriman
      if (widget.isActive) {
        final pengirimanResponse = await supabase
            .from('pengiriman')
            .select()
            .eq('id_pesanan', widget.pesanan['id_pesanan'])
            .maybeSingle();

        if (mounted) {
          setState(() => _pengirimanData = pengirimanResponse);
        }
      }

      // STEP 2: Get id_driver
      print('\n2️⃣ Getting driver ID...');
      final pengirimanForDriver = await supabase
          .from('pengiriman')
          .select('id_driver')
          .eq('id_pesanan', widget.pesanan['id_pesanan'])
          .maybeSingle();

      if (pengirimanForDriver == null || pengirimanForDriver['id_driver'] == null) {
        print('   ⚠️ No driver assigned yet');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final idDriver = pengirimanForDriver['id_driver'];
      print('   ✅ Driver ID: $idDriver');

      // STEP 3: Query driver + user
      print('\n3️⃣ Querying driver + user...');
      final driverResponse = await supabase
          .from('drivers')
          .select('''
            id_driver,
            rating_driver,
            total_rating,
            users!inner(
              nama,
              foto_profil
            )
          ''')
          .eq('id_driver', idDriver)
          .single();

      print('   ✅ Driver: ${driverResponse['users']['nama']}');

      // STEP 4: Query vehicle - PERBAIKAN DI SINI!
      print('\n4️⃣ Querying vehicle...');
      
      // ❌ CARA LAMA (SALAH):
      // final vehicleResponse = await supabase
      //     .from('driver_vehicles')
      //     .select('plat_nomor, merk_kendaraan')
      //     .eq('id_driver', idDriver)
      //     .eq('is_active', true)
      //     .eq('status_verifikasi', 'approved')
      //     .maybeSingle();  // ❌ INI YANG BIKIN NULL!

      // ✅ CARA BARU (BENAR):
      final vehicleList = await supabase
          .from('driver_vehicles')
          .select('plat_nomor, merk_kendaraan, is_active, status_verifikasi')
          .eq('id_driver', idDriver);
      
      print('   📊 Total vehicles found: ${vehicleList.length}');

      // Filter di Dart (bukan di query)
      final approvedVehicles = vehicleList.where((v) =>
        v['is_active'] == true && 
        v['status_verifikasi'] == 'approved'
      ).toList();

      print('   📊 Approved vehicles: ${approvedVehicles.length}');

      String platNomor = '-';
      String merkKendaraan = '-';

      if (approvedVehicles.isNotEmpty) {
        final vehicle = approvedVehicles.first;
        platNomor = vehicle['plat_nomor'] ?? '-';
        merkKendaraan = vehicle['merk_kendaraan'] ?? '-';
        print('   ✅ Vehicle: $merkKendaraan - $platNomor');
      } else {
        print('   ⚠️ No approved vehicle found');
      }

      // STEP 5: Combine data
      if (mounted) {
        setState(() {
          _driverData = {
            'id_driver': idDriver,
            'nama': driverResponse['users']['nama'],
            'foto_profil': driverResponse['users']['foto_profil'],
            'rating_driver': (driverResponse['rating_driver'] ?? 5.0).toDouble(),
            'total_rating': driverResponse['total_rating'] ?? 0,
            'plat_nomor': platNomor,
            'merk_kendaraan': merkKendaraan,
          };
        });
        print('\n5️⃣ ✅ State updated successfully');
        print('   📋 Plat: ${_driverData!['plat_nomor']}');
        print('   📋 Merk: ${_driverData!['merk_kendaraan']}');
      }

      // STEP 6: Load rating
      print('\n6️⃣ Loading rating...');
      final ratingResponse = await supabase
          .from('rating_reviews')
          .select()
          .eq('id_pesanan', widget.pesanan['id_pesanan'])
          .eq('id_user', widget.userId)
          .eq('target_type', 'driver')
          .maybeSingle();

      if (mounted) {
        setState(() {
          _ratingData = ratingResponse;
          _isLoading = false;
        });
      }

      print('🔥 ========== LOAD ORDER DATA END ==========\n');
      
    } catch (e, stackTrace) {
      print('\n❌ ERROR: $e');
      print('Stack: $stackTrace');
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.pesanan['status_pesanan'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isActive && _pengirimanData != null
              ? _lanjutkanPesanan
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: _isLoading
                ? _buildLoadingState()
                : _buildCardContent(status),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
        ),
      ),
    );
  }

  Widget _buildCardContent(String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(status),

        if (status == 'mencari_driver') ...[
          SizedBox(height: 12),
          _buildTimerIndicator(),
        ],
        
        SizedBox(height: 12),
        if (_driverData != null) _buildDriverInfo(),
        if (_driverData != null) SizedBox(height: 10),
        _buildVehicleType(),
        SizedBox(height: 10),
        _buildLokasiRow(
          icon: Icons.trip_origin,
          iconColor: Color(0xFF4CAF50),
          text: widget.pesanan['alamat_asal'] ?? 'Lokasi asal',
        ),
        SizedBox(height: 6),
        _buildLokasiRow(
          icon: Icons.location_on,
          iconColor: Color(0xFFFF6B9D),
          text: widget.pesanan['alamat_tujuan'] ?? 'Lokasi tujuan',
        ),
        SizedBox(height: 10),
        Divider(height: 1, color: Colors.grey[200]),
        SizedBox(height: 10),
        _buildPriceInfo(),
        
        // ✅ RATING SECTION - HANYA UNTUK SELESAI
        if (!widget.isActive && status == 'selesai') ...[
          SizedBox(height: 12),
          if (_ratingData != null)
            _buildDisplayedRating()
          else
            _buildRatingButton(),
        ],
        
        // ✅ BUTTON SECTION - UNTUK PESANAN AKTIF
        if (widget.isActive) ...[
          SizedBox(height: 12),
          // Jika sedang mencari driver - tampilkan cancel button
          if (status == 'mencari_driver')
            _buildCancelButton()
          // Jika ada pengiriman data - tampilkan track button
          else if (_pengirimanData != null)
            _buildLanjutkanButton(),
        ],
      ],
    );
  }

  // ✅ FUNGSI BARU UNTUK TIMER INDICATOR
  Widget _buildTimerIndicator() {
    return ListenableBuilder(
      listenable: OrderTimerService(),
      builder: (context, _) {
        final timerService = OrderTimerService();
        
        // Cek apakah timer aktif untuk pesanan ini
        final isMyOrder = timerService.activeOrderId == widget.pesanan['id_pesanan'];
        final hasTimer = timerService.hasActiveTimer;
        
        // Jika tidak ada timer ATAU bukan pesanan ini, hide
        if (!hasTimer || !isMyOrder) {
          return SizedBox.shrink();
        }
        
        final remainingSeconds = timerService.remainingSeconds;
        final formattedTime = timerService.getFormattedTime();
        
        // ✅ VISUAL INDICATOR BERDASARKAN WAKTU
        Color indicatorColor;
        IconData indicatorIcon;
        
        if (remainingSeconds > 60) {
          // Lebih dari 1 menit - hijau
          indicatorColor = Color(0xFF4CAF50);
          indicatorIcon = Icons.timer_outlined;
        } else if (remainingSeconds > 30) {
          // 30-60 detik - orange
          indicatorColor = Color(0xFFFF9800);
          indicatorIcon = Icons.timer_outlined;
        } else {
          // Kurang dari 30 detik - merah, animasi pulse
          indicatorColor = Color(0xFFF44336);
          indicatorIcon = Icons.timer_off_outlined;
        }
        
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: indicatorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: indicatorColor.withOpacity(0.3),
              width: remainingSeconds <= 30 ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                indicatorIcon,
                size: 20,
                color: indicatorColor,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Mencari Driver',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: indicatorColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: indicatorColor,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildCancelButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _cancelSearchingOrder,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'BATALKAN PESANAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

  Future<void> _cancelSearchingOrder() async {
    print('🚫 [RiwayatCard] Cancel searching order');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Batalkan Pesanan?'),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin membatalkan pencarian driver?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // Cancel timer
      OrderTimerService().cancelTimer();
      
      // Update status
      await supabase.from('pesanan').update({
        'status_pesanan': 'dibatalkan',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', widget.pesanan['id_pesanan']);

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
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('❌ Error cancel order: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildHeader(String status) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 13,
                  color: _getStatusColor(status),
                ),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            _formatFullDate(widget.pesanan['created_at']),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFFFF6B9D).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: _driverData!['foto_profil'] != null
                ? NetworkImage(_driverData!['foto_profil'])
                : null,
            backgroundColor: Colors.grey[200],
            child: _driverData!['foto_profil'] == null
                ? Icon(Icons.person, size: 22, color: Colors.grey[600])
                : null,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverData!['nama'] ?? 'Driver',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                RatingWidgets.buildStarRating(
                  rating: (_driverData!['rating_driver'] ?? 5.0).toDouble(),
                  size: 12,
                  totalReviews: _driverData!['total_rating'] ?? 0,
                ),
                SizedBox(height: 3),
                Text(
                  '${_driverData!['merk_kendaraan'] ?? ''} • ${_driverData!['plat_nomor'] ?? ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleType() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFFFF6B9D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.motorcycle, size: 13, color: Color(0xFFFF6B9D)),
          SizedBox(width: 5),
          Text(
            widget.pesanan['jenis_kendaraan']?.toUpperCase() ?? 'MOTOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF6B9D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLokasiRow({
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
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 13),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF4CAF50).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                '${widget.pesanan['jarak_km'] ?? '0'} km',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            'Rp ${_formatCurrency(widget.pesanan['total_harga'])}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayedRating() {
    final rating = _ratingData!['rating'] ?? 0;
    final reviewText = _ratingData!['review_text'] ?? '';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFFB300).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFFFB300).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ BINTANG RATING
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 18,
                color: index < rating
                    ? Color(0xFFFFB300)
                    : Colors.grey[300],
              );
            }),
          ),
          SizedBox(height: 8),
          // ✅ ULASAN DENGAN KUTIP DAN ITALIC
          Text(
            reviewText.isEmpty ? 'Tidak ada ulasan' : '"$reviewText"',
            style: TextStyle(
              fontSize: 12,
              color: reviewText.isEmpty ? Colors.grey[500] : Colors.black87,
              height: 1.4,
              fontStyle: reviewText.isEmpty ? FontStyle.normal : FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFB300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmittingRating ? null : _showRatingDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSubmittingRating)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  Icon(Icons.star, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'BERI RATING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingDialog() {
    int selectedRating = 0;
    final reviewController = TextEditingController();

    print('🎯 [DEBUG] Opening rating dialog');
    print('   - Pesanan ID: ${widget.pesanan['id_pesanan']}');
    print('   - Driver Data: $_driverData');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: 340),
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFB300).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        size: 36,
                        color: Color(0xFFFFB300),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Beri Penilaian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bagaimana perjalanan dengan\n${_driverData?['nama'] ?? 'driver'}?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            print('⭐ [DEBUG] Star ${index + 1} tapped');
                            setDialogState(() {
                              selectedRating = index + 1;
                            });
                            print('   - Selected rating: $selectedRating');
                          },
                          child: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            size: 36,
                            color: index < selectedRating
                                ? Color(0xFFFFB300)
                                : Colors.grey[300],
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: reviewController,
                      maxLength: 200,
                      maxLines: 3,
                      style: TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tulis ulasan (opsional)',
                        hintStyle: TextStyle(fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              print('❌ [DEBUG] Cancel button pressed');
                              Navigator.pop(dialogContext);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Batal', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: selectedRating == 0
                                ? null
                                : () {
                                    print('✅ [DEBUG] Kirim button pressed');
                                    print('   - Rating: $selectedRating');
                                    print('   - Review: ${reviewController.text.trim()}');
                                    
                                    _submitRating(
                                      dialogContext,
                                      selectedRating,
                                      reviewController.text.trim(),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: Text(
                              'Kirim',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
        },
      ),
    );
  }

  Future<void> _submitRating(
    BuildContext dialogContext,
    int rating,
    String reviewText,
  ) async {
    print('📝 [DEBUG] Starting _submitRating');
    print('   - Rating: $rating');
    print('   - Review: $reviewText');
    
    if (_driverData == null) {
      print('❌ [DEBUG] Driver data is NULL!');
      if (mounted && Navigator.canPop(dialogContext)) {
        Navigator.pop(dialogContext);
      }
      if (mounted) {
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Gagal',
          message: 'Data driver tidak ditemukan. Silakan refresh halaman.',
          actionText: 'OK',
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isSubmittingRating = true);
    }

    try {
      print('📤 [DEBUG] Calling ratingService.submitRating...');
      print('🎯 About to submit rating...');
      print('   - Pesanan: ${widget.pesanan['id_pesanan']}');
      print('   - Customer: ${widget.userId}');
      print('   - Driver: ${_driverData!['id_driver']}');
      print('   - Rating: $rating');
      print('   - Review: $reviewText');

      final success = await widget.ratingService.submitDriverRating(
        idPesanan: widget.pesanan['id_pesanan'],
        idCustomer: widget.userId,
        idDriver: _driverData!['id_driver'],
        rating: rating,
        reviewText: reviewText.isEmpty ? null : reviewText,
      );

      print('📥 [DEBUG] submitRating result: $success');

      if (!mounted) {
        print('⚠️ [DEBUG] Widget not mounted, skipping UI updates');
        return;
      }

      // ✅ TUTUP DIALOG DULU
      if (Navigator.canPop(dialogContext)) {
        Navigator.pop(dialogContext);
        print('✅ [DEBUG] Dialog closed');
      }

      if (success) {
        print('✅ [DEBUG] Rating submitted successfully');
        
        // ✅ RELOAD DATA
        await _loadOrderData();
        
        // ✅ SHOW SUCCESS SNACKBAR (BUKAN DIALOG!)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rating berhasil dikirim!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              duration: Duration(seconds: 2),
            ),
          );
        }

        // ✅ CALLBACK UNTUK REFRESH PARENT
        if (mounted) {
          widget.onRatingSubmitted();
        }
      } else {
        print('❌ [DEBUG] submitRating returned false');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim rating. Silakan coba lagi.'),
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
    } catch (e, stackTrace) {
      print('❌ [DEBUG] Exception caught: $e');
      print('📋 [DEBUG] Stack trace: $stackTrace');
      
      if (mounted) {
        if (Navigator.canPop(dialogContext)) {
          Navigator.pop(dialogContext);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
      }
    }
  }

  Widget _buildLanjutkanButton() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFF6B9D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _lanjutkanPesanan,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.my_location, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'LACAK PESANAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

  void _lanjutkanPesanan() {
    if (_pengirimanData == null) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Data Tidak Tersedia',
        message: 'Refresh halaman',
        actionText: 'OK',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerLiveTracking(
          idPesanan: widget.pesanan['id_pesanan'],
          pesananData: widget.pesanan,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'mencari_driver':
        return Color(0xFFFF9800);
      case 'diterima':
      case 'menuju_pickup':
      case 'sampai_pickup':
      case 'customer_naik':
      case 'perjalanan':
      case 'sampai_tujuan':
        return Color(0xFFFF6B9D);
      case 'selesai':
        return Color(0xFF4CAF50);
      case 'dibatalkan':
      case 'cancelled':
      case 'gagal':
        return Color(0xFF9E9E9E);
      default:
        return Color(0xFF9E9E9E);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'mencari_driver':
        return Icons.search;
      case 'diterima':
        return Icons.check_circle;
      case 'menuju_pickup':
        return Icons.directions_car;
      case 'sampai_pickup':
        return Icons.location_on;
      case 'customer_naik':
        return Icons.person;
      case 'perjalanan':
        return Icons.local_shipping;
      case 'sampai_tujuan':
        return Icons.place;
      case 'selesai':
        return Icons.done_all;
      case 'dibatalkan':
      case 'cancelled':
        return Icons.cancel;
      case 'gagal':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'mencari_driver':
        return 'MENCARI';
      case 'diterima':
        return 'DITERIMA';
      case 'menuju_pickup':
        return 'MENUJU';
      case 'sampai_pickup':
        return 'TIBA';
      case 'customer_naik':
        return 'NAIK';
      case 'perjalanan':
        return 'JALAN';
      case 'sampai_tujuan':
        return 'SAMPAI';
      case 'selesai':
        return 'SELESAI';
      case 'dibatalkan':
      case 'cancelled':
        return 'BATAL';
      case 'gagal':
        return 'GAGAL';
      default:
        return status.toUpperCase();
    }
  } 

  // ✅ FUNGSI BARU UNTUK FORMAT TANGGAL LENGKAP (DD/MM/YYYY)
  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '-';
    }
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
}

  // ============================================================================
  // UMKM PESANAN CARD - Match dengan pesanan_umkm_page.dart
  // ============================================================================

  class _UmkmPesananCard extends StatefulWidget {
    final Map<String, dynamic> pesanan;
    final String userId;

    const _UmkmPesananCard({
      required this.pesanan,
      required this.userId,
    });

    @override
    State<_UmkmPesananCard> createState() => _UmkmPesananCardState();
  }

  class _UmkmPesananCardState extends State<_UmkmPesananCard> {
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _umkmData;
  bool _isLoading = true;
  Map<String, dynamic>? _productRatingData;
  Map<String, dynamic>? _driverRatingData;
  bool _isLoadingRatings = false;
  StreamSubscription? _pesananListener;
  bool _hasNavigatedToTracking = false;
  bool _hasAssignedDriver = false;


  @override
  void initState() {
    super.initState();
    _loadData();
    // ✅ AUTO-NAVIGATE: Listen status pesanan untuk UMKM
    final status = widget.pesanan['status_pesanan'];
    final hasDriver = widget.pesanan['metode_pengiriman'] == 'driver';
    
    // Listen jika dalam status aktif yang memerlukan tracking
    if (hasDriver && (status == 'siap_kirim' || status == 'mencari_driver' || status == 'dalam_pengiriman')) {
      _listenForDriverAssignment();
    }
  }

  Future<void> _loadData() async {
    try {
      // 1. Load detail items
      final itemsResponse = await supabase
          .from('detail_pesanan')
          .select()
          .eq('id_pesanan', widget.pesanan['id_pesanan']);

      // 2. Load UMKM info
      final umkmResponse = await supabase
          .from('umkm')
          .select('nama_toko, foto_toko')
          .eq('id_umkm', widget.pesanan['id_umkm'])
          .maybeSingle();

      // 3. ✅ LOAD FOTO PRODUK - JOIN ke tabel produk
      for (var item in itemsResponse) {
        final produkData = await supabase
            .from('produk')
            .select('foto_produk')
            .eq('id_produk', item['id_produk'])
            .maybeSingle();
        
        item['foto_produk_list'] = produkData?['foto_produk'];
      }


      bool assignedDriver = false;
      if (widget.pesanan['metode_pengiriman'] == 'driver') {
        final pengirimanCheck = await supabase
            .from('pengiriman')
            .select('id_driver')
            .eq('id_pesanan', widget.pesanan['id_pesanan'])
            .maybeSingle();
        assignedDriver = pengirimanCheck != null && pengirimanCheck['id_driver'] != null;
      }

      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(itemsResponse);
          _hasAssignedDriver = assignedDriver;
          _umkmData = umkmResponse;
          _isLoading = false;
        });
        
        // ✅ LOAD RATINGS SETELAH ITEMS LOADED
        await _loadRatings();
      }
    } catch (e) {
      print('❌ Error load UMKM data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRatings() async {
    if (_isLoadingRatings || _items.isEmpty) return;
    
    setState(() => _isLoadingRatings = true);
    
    try {
      final idPesanan = widget.pesanan['id_pesanan'];
      final idUser = widget.pesanan['id_user'];
      
      print('🔍 [UmkmCard] Loading ratings for: $idPesanan');
      
      // ✅ FETCH RATING PRODUK (dari item pertama)
      final firstProduct = _items[0];
      final idProduk = firstProduct['id_produk'];
      
      final productRating = await supabase
          .from('rating_reviews')
          .select('rating, review_text, foto_ulasan, created_at')
          .eq('id_pesanan', idPesanan)
          .eq('id_user', idUser)
          .eq('target_type', 'produk')
          .eq('target_id', idProduk)
          .maybeSingle();
      
      if (productRating != null) {
        print('✅ Product rating found');
        _productRatingData = productRating;
      }
      
      // ✅ FETCH RATING DRIVER (jika pakai driver)
      if (widget.pesanan['metode_pengiriman'] == 'driver') {
        final pengirimanData = await supabase
            .from('pengiriman')
            .select('id_driver')
            .eq('id_pesanan', idPesanan)
            .maybeSingle();
        
        if (pengirimanData != null && pengirimanData['id_driver'] != null) {
          final idDriver = pengirimanData['id_driver'];
          
          final driverRating = await supabase
              .from('rating_reviews')
              .select('rating, review_text, created_at')
              .eq('id_pesanan', idPesanan)
              .eq('id_user', idUser)
              .eq('target_type', 'driver')
              .eq('target_id', idDriver)
              .maybeSingle();
          
          if (driverRating != null) {
            print('✅ Driver rating found');
            _driverRatingData = driverRating;
          }
        }
      }
      
      if (mounted) {
        setState(() => _isLoadingRatings = false);
      }
    } catch (e) {
      print('❌ Error loading ratings: $e');
      if (mounted) {
        setState(() => _isLoadingRatings = false);
      }
    }
  }

  // ✅ FUNGSI BARU: Listen untuk auto-navigate saat driver assigned (UMKM)
  void _listenForDriverAssignment() {
    print('👂 [UMKM] Listening for driver assignment and status updates...');
    
    _pesananListener = supabase
        .from('pesanan')
        .stream(primaryKey: ['id_pesanan'])
        .eq('id_pesanan', widget.pesanan['id_pesanan'])
        .listen((data) async {
          if (!mounted || _hasNavigatedToTracking) return;
          
          if (data.isNotEmpty) {
            final pesanan = data.first;
            final status = pesanan['status_pesanan'];
            print('📡 [UMKM] Status update: $status');
            
            // ✅ AUTO-NAVIGATE saat status berubah ke dalam_pengiriman
            if (status == 'dalam_pengiriman' && !_hasNavigatedToTracking) {
              // Double check ada pengiriman dengan driver
              final pengirimanData = await supabase
                  .from('pengiriman')
                  .select('id_driver')
                  .eq('id_pesanan', widget.pesanan['id_pesanan'])
                  .maybeSingle();
              
              if (pengirimanData != null && pengirimanData['id_driver'] != null) {
                print('🚀 [UMKM] Driver assigned! Auto-navigating to tracking...');
                _hasNavigatedToTracking = true;
                
                // Navigate setelah frame selesai
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerLiveTracking(
                          idPesanan: widget.pesanan['id_pesanan'],
                          pesananData: pesanan, // Gunakan data terbaru
                        ),
                      ),
                    );
                  }
                });
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _pesananListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.pesanan['status_pesanan'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ HEADER - Match dengan pesanan_umkm_page.dart
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  _formatDate(widget.pesanan['created_at']),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // ✅ BODY
          Padding(
            padding: EdgeInsets.all(12),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _buildCardBody(status),
          ),
        ],
      ),
    );
  }
  Widget _buildCardBody(String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_umkmData != null) ...[
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _umkmData!['foto_toko'] != null
                    ? NetworkImage(_umkmData!['foto_toko'])
                    : null,
                backgroundColor: Colors.orange.shade100,
                child: _umkmData!['foto_toko'] == null
                    ? Icon(Icons.store, color: Colors.orange, size: 20)
                    : null,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ NAMA TOKO + BADGE RATED
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _umkmData!['nama_toko'] ?? 'Toko',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ✅ BADGE "RATED" (kondisional)
                        FutureBuilder<bool>(
                          future: _checkIfAlreadyRated(widget.pesanan['id_pesanan']),
                          builder: (context, snapshot) {
                            if (snapshot.data == true) {
                              return Container(
                                margin: EdgeInsets.only(left: 6),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(0xFF4CAF50).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Color(0xFF4CAF50).withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 10,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'RATED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4CAF50),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${widget.pesanan['metode_pengiriman'] == 'driver' ? '🚗 Delivery' : '👤 Ambil Sendiri'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
        ],

        // ✅ ITEMS LIST - Dengan foto produk!
        ..._items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ FOTO PRODUK
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item['foto_produk_list'] != null && 
                       (item['foto_produk_list'] as List).isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['foto_produk_list'][0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.fastfood, color: Colors.grey);
                          },
                        ),
                      )
                    : Icon(Icons.fastfood, color: Colors.grey),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama_produk'] ?? '',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item['jumlah']}x',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          _formatCurrency(item['subtotal']),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),

        Divider(height: 16),

        // ✅ TOTAL
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _formatCurrency(widget.pesanan['total_harga']),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.orange,
              ),
            ),
          ],
        ),

        // ✅ ACTION BUTTONS
        _buildActionButtons(status),
      ],
    );
  }

  Widget _buildActionButtons(String status) {
    final hasDriver = widget.pesanan['metode_pengiriman'] == 'driver';
    
    // ✅ MENUNGGU PEMBAYARAN
    if (status == 'menunggu_pembayaran') {
      final paymentMethod = widget.pesanan['payment_method'] ?? '';
      
      return Column(
        children: [
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menunggu pembayaran...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              if (paymentMethod == 'transfer')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _lanjutkanPembayaran(widget.pesanan),
                    icon: Icon(Icons.payment, size: 16),
                    label: Text('Lanjut Bayar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              if (paymentMethod == 'transfer') SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _batalkanPesanan(widget.pesanan['id_pesanan']),
                  icon: Icon(Icons.close, size: 16),
                  label: Text('Batalkan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ✅ DIPROSES
    if (status == 'diproses') {
      return Column(
        children: [
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: Colors.blue.shade700, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toko sedang menyiapkan pesanan...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ✅ SIAP_KIRIM
    if (status == 'siap_kirim') {
      if (!hasDriver) {
        return Column(
          children: [
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✅ Pesanan siap diambil di toko!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _lacakPesanan,
              icon: Icon(Icons.navigation, size: 18),
              label: Text('Navigasi ke Toko'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      }
      
      return Column(
        children: [
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.indigo.shade700),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pesanan siap, mencari driver terdekat...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (status == 'mencari_driver') {
      return Column(
        children: [
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.orange.shade700),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sedang mencari driver terdekat...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (status == 'dalam_pengiriman') {
      return Column(
        children: [
          SizedBox(height: 12),
          if (_hasAssignedDriver)
            ElevatedButton.icon(
              onPressed: _lacakPesanan,
              icon: Icon(Icons.my_location, size: 18),
              label: Text('Lacak Driver Real-Time'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B9D),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.pink.shade700),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driver sedang dalam perjalanan...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.pink.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    // ✅ SELESAI - TAMPILKAN RATING ATAU BUTTON
    if (status == 'selesai') {
      final hasProductRating = _productRatingData != null;
      final hasDriverRating = _driverRatingData != null;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          SizedBox(height: 12),
          
          // Header
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              SizedBox(width: 6),
              Text(
                'Rating & Ulasan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // ✅ TAMPILKAN RATING PRODUK
          if (hasProductRating) ...[
            _buildDisplayedProductRating(),
            SizedBox(height: 10),
          ],
          
          // ✅ TAMPILKAN RATING DRIVER
          if (hasDriver && hasDriverRating) ...[
            _buildDisplayedDriverRating(),
            SizedBox(height: 10),
          ],
          
          // ✅ BUTTON - HANYA JIKA BELUM LENGKAP
          if (!hasProductRating || (hasDriver && !hasDriverRating))
            _buildRatingButton(hasProductRating, hasDriver, hasDriverRating),
        ],
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildDisplayedProductRating() {
    final rating = _productRatingData!['rating'] ?? 0;
    final reviewText = _productRatingData!['review_text'] ?? '';
    final fotoUlasan = _productRatingData!['foto_ulasan'];
    
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFFFF6B9D).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFFFF6B9D).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Produk',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6B9D),
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 14,
                color: index < rating ? Colors.amber : Colors.grey[300],
              );
            }),
          ),
          if (reviewText.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              '"$reviewText"',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black87,
                height: 1.3,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (fotoUlasan != null && fotoUlasan is List && fotoUlasan.isNotEmpty) ...[
            SizedBox(height: 6),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fotoUlasan.length > 3 ? 3 : fotoUlasan.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 6),
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: NetworkImage(fotoUlasan[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisplayedDriverRating() {
    final rating = _driverRatingData!['rating'] ?? 0;
    final reviewText = _driverRatingData!['review_text'] ?? '';
    
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF4CAF50).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFF4CAF50).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Driver',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 14,
                color: index < rating ? Colors.amber : Colors.grey[300],
              );
            }),
          ),
          if (reviewText.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              '"$reviewText"',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black87,
                height: 1.3,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingButton(bool hasProductRating, bool hasDriver, bool hasDriverRating) {
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;
    
    if (!hasProductRating) {
      buttonText = 'BERI RATING';
      buttonIcon = Icons.restaurant_menu;
      buttonColor = Color(0xFFFF6B9D);
    } else if (hasDriver && !hasDriverRating) {
      buttonText = 'BERI RATING DRIVER';
      buttonIcon = Icons.delivery_dining;
      buttonColor = Color(0xFF4CAF50);
    } else {
      return SizedBox.shrink();
    }
    
    return ElevatedButton.icon(
      onPressed: _beriRating,
      icon: Icon(buttonIcon, size: 16),
      label: Text(
        buttonText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
      ),
    );
  }


  void _lacakPesanan() {
    final metode = widget.pesanan['metode_pengiriman'];
    
    print('🗺️ ========== LACAK PESANAN ==========');
    print('   ID Pesanan: ${widget.pesanan['id_pesanan']}');
    print('   Jenis: ${widget.pesanan['jenis']}');
    print('   Metode Pengiriman: $metode');
    print('======================================');
    
    // ✅ DELIVERY (pakai driver) → CustomerLiveTracking (yang sudah proven!)
    if (metode == 'driver') {
      print('✅ Routing to CustomerLiveTracking (DELIVERY MODE)');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerLiveTracking(
            idPesanan: widget.pesanan['id_pesanan'],
            pesananData: widget.pesanan,
          ),
        ),
      );
    } 
    // ✅ PICKUP (ambil sendiri) → CustomerUmkmTracking
    else {
      print('✅ Routing to CustomerUmkmTracking (PICKUP MODE)');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerUmkmTracking(
            idPesanan: widget.pesanan['id_pesanan'],
            pesananData: widget.pesanan,
          ),
        ),
      );
    }
  }

  void _beriRating() async {
    try {
      final pesananId = widget.pesanan['id_pesanan'];
      final userId = widget.pesanan['id_user'];
      final metodeKirim = widget.pesanan['metode_pengiriman'];
      
      print('🎯 [RiwayatCustomer] Checking existing ratings...');
      print('   - Pesanan ID: $pesananId');
      print('   - User ID: $userId');
      print('   - Metode Pengiriman: $metodeKirim');

      // ✅ CEK APAKAH SUDAH ADA RATING PRODUK
      final existingProductRating = await supabase
          .from('rating_reviews')
          .select('id_review')
          .eq('id_pesanan', pesananId)
          .eq('id_user', userId)
          .eq('target_type', 'produk')
          .maybeSingle();

      print('   - Has existing product rating: ${existingProductRating != null}');

      // ✅ FETCH id_driver dari table pengiriman (JIKA PAKAI DRIVER)
      String? idDriver;
      bool hasDriver = false;
      
      if (metodeKirim == 'driver') {
        print('   - Fetching driver from pengiriman table...');
        
        final pengirimanData = await supabase
            .from('pengiriman')
            .select('id_driver')
            .eq('id_pesanan', pesananId)
            .maybeSingle();
        
        if (pengirimanData != null && pengirimanData['id_driver'] != null) {
          idDriver = pengirimanData['id_driver'];
          hasDriver = true;
          print('   ✅ Driver ID found: $idDriver');
        } else {
          print('   ⚠️ No driver assigned yet');
        }
      } else {
        print('   - Metode: PICKUP (tidak pakai driver)');
      }

      // ✅ CEK APAKAH SUDAH ADA RATING DRIVER (jika pakai driver)
      Map<String, dynamic>? existingDriverRating;
      if (hasDriver && idDriver != null) {
        existingDriverRating = await supabase
            .from('rating_reviews')
            .select('id_review')
            .eq('id_pesanan', pesananId)
            .eq('id_user', userId)
            .eq('target_type', 'driver')
            .eq('target_id', idDriver)
            .maybeSingle();
        
        print('   - Has existing driver rating: ${existingDriverRating != null}');
      }

      // ✅ VALIDASI: JIKA SUDAH RATING SEMUA, TAMPILKAN INFO
      if (existingProductRating != null && 
          (!hasDriver || existingDriverRating != null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Anda sudah memberikan penilaian untuk pesanan ini'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // ✅ BUAT pesananData LENGKAP dengan id_driver yang sudah di-fetch
      final Map<String, dynamic> pesananDataLengkap = {
        ...widget.pesanan,
        'id_driver': idDriver, // ← TAMBAHKAN id_driver yang sudah di-fetch
      };

      // ✅ TAMPILKAN DIALOG RATING
      print('✅ [RiwayatCustomer] Opening UmkmRatingDialog...');
      
      final dialog = UmkmRatingDialog(
        context: context,
        pesananData: pesananDataLengkap,
        onRatingSubmitted: () {
          // ✅ RELOAD RATINGS setelah submit
          _loadRatings();
          
          setState(() {
            // Trigger rebuild
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.star, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Terima kasih atas penilaian Anda!'),
                  ),
                ],
              ),
              backgroundColor: Color(0xFFFF6B9D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      );

      dialog.show();

    } catch (e) {
      print('❌ [RiwayatCustomer] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka dialog rating'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _checkIfAlreadyRated(String idPesanan) async {
    try {
      final result = await supabase
          .from('rating_reviews')
          .select('id_review')
          .eq('id_pesanan', idPesanan)
          .eq('target_type', 'produk')
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      print('❌ Error checking rating: $e');
      return false;
    }
  }

  // ✅ STATUS COLOR - Match dengan pesanan_umkm_model.dart
  Color _getStatusColor(String status) {
    switch (status) {
      case 'menunggu_pembayaran': return Color(0xFFFF9800);
      case 'diproses': return Color(0xFF2196F3);
      case 'siap_kirim': return Color(0xFF9C27B0);
      case 'mencari_driver': return Color(0xFFFF5722);
      case 'dalam_pengiriman': return Color(0xFF00BCD4);
      case 'selesai': return Color(0xFF4CAF50);
      case 'dibatalkan': return Color(0xFF757575);
      default: return Color(0xFF9E9E9E);
    }
  }

  // ✅ STATUS LABEL - Match dengan pesanan_umkm_model.dart
  String _getStatusLabel(String status) {
    switch (status) {
      case 'menunggu_pembayaran': return 'BAYAR';
      case 'diproses': return 'PROSES';
      case 'siap_kirim': return 'SIAP';
      case 'mencari_driver': return 'CARI DRIVER';
      case 'dalam_pengiriman': return 'KIRIM';
      case 'selesai': return 'SELESAI';
      case 'dibatalkan': return 'BATAL';
      default: return status.toUpperCase();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return 'Rp${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _lanjutkanPembayaran(Map<String, dynamic> pesanan) async {
    try {
      final response = await supabase.functions.invoke(
        'create-payment',
        body: {
          'orderId': pesanan['id_pesanan'],
          'grossAmount': (pesanan['total_harga'] ?? 0).toInt(),
          'customerDetails': {
            'first_name': pesanan['users']?['nama'] ?? 'Customer',
            'email': pesanan['users']?['email'] ?? 'customer@sidrive.com',
            'phone': pesanan['users']?['no_telp'] ?? '08123456789',
          },
        },
      );

      if (response.status == 200 && response.data != null) {
        final paymentData = response.data as Map<String, dynamic>;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentGatewayScreen(
              paymentUrl: paymentData['redirect_url'] ?? '',
              orderId: pesanan['id_pesanan'],
              pesananData: pesanan,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error resume payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka pembayaran'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _batalkanPesanan(String idPesanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Batalkan Pesanan?'),
        content: Text('Pesanan akan dibatalkan dan stok dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('pesanan').update({
          'status_pesanan': 'dibatalkan',
          'payment_status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', idPesanan);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Pesanan dibatalkan'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal batalkan pesanan'), backgroundColor: Colors.red),
        );
      }
    }
  }
}