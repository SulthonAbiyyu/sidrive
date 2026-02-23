import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/screens/driver/pages/trackingpage_driver.dart';
import 'package:sidrive/services/rating_ulasan_service.dart';
import 'package:sidrive/core/widgets/rating_widgets.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';
import 'dart:async';

class RiwayatPage extends StatefulWidget {
  final String driverId;

  const RiwayatPage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _ratingService = RatingUlasanService();
  
  String _selectedFilter = 'aktif';
  StreamSubscription? _pengirimanStream;
  
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _ratingBreakdown;
  bool _isLoadingDriverData = true;
  bool _isRatingExpanded = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadDriverData();
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _pengirimanStream?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    try {
      final driverResponse = await supabase
          .from('drivers')
          .select('''
            *,
            users!inner(
              nama,
              foto_profil
            )
          ''')
          .eq('id_driver', widget.driverId)
          .single()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Koneksi timeout'),
          );

      final breakdown = await _ratingService.getRatingBreakdown(
        targetType: 'driver',
        targetId: widget.driverId,
      );

      if (mounted) {
        setState(() {
          _driverData = {
            ...driverResponse,
            'nama': driverResponse['users']['nama'],
            'foto_profil': driverResponse['users']['foto_profil'],
          };
          _ratingBreakdown = breakdown;
          _isLoadingDriverData = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [RiwayatPage] Error: $e');
      if (mounted) {
        setState(() => _isLoadingDriverData = false);
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Gagal Memuat Data',
          message: 'Tidak dapat memuat data driver.',
          actionText: 'Coba Lagi',
          onAction: _loadDriverData,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildPinkHeader(context),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: ResponsiveMobile.scaledH(12)),
                      
                      // Rating compact section
                      if (_driverData != null && _ratingBreakdown != null)
                        _buildCompactRatingSection(),
                      
                      SizedBox(height: ResponsiveMobile.scaledH(12)),
                      
                      // Filter tabs
                      _buildFilterTabs(),
                      
                      SizedBox(height: ResponsiveMobile.scaledH(12)),
                      
                      // List riwayat
                      _buildRiwayatStream(),  
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PINK GRADIENT HEADER (sama seperti homepage)
  // ═══════════════════════════════════════════════════════════
  Widget _buildPinkHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ResponsiveMobile.scaledW(16),
        ResponsiveMobile.scaledH(12),
        ResponsiveMobile.scaledW(16),
        ResponsiveMobile.scaledH(16),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF9EC5),
            const Color(0xFFFFB8D4),
            const Color(0xFFFFC9E0),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ResponsiveMobile.scaledR(24)),
          bottomRight: Radius.circular(ResponsiveMobile.scaledR(24)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9EC5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Riwayat Perjalanan',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: ResponsiveMobile.scaledFont(20),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveMobile.scaledH(6)),
          Text(
            _getFilterSubtitle(),
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(11),
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterSubtitle() {
    switch (_selectedFilter) {
      case 'aktif': return 'Pesanan yang sedang berjalan';
      case 'selesai': return 'Pesanan yang telah selesai';
      case 'dibatalkan': return 'Pesanan yang dibatalkan';
      default: return '';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // COMPACT RATING SECTION (bisa di-minimize)
  // ═══════════════════════════════════════════════════════════
  Widget _buildCompactRatingSection() {
    if (_isLoadingDriverData) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(16)),
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: ResponsiveMobile.scaledW(20),
            height: ResponsiveMobile.scaledW(20),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9EC5)),
            ),
          ),
        ),
      );
    }

    final rating = (_driverData!['rating_driver'] ?? 5.0).toDouble();
    final totalReviews = _ratingBreakdown!['total_reviews'] as int;
    final isNewDriver = _ratingBreakdown!['is_new_driver'] as bool;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        child: Column(
          children: [
            // Header yang bisa diklik untuk expand/collapse
            InkWell(
              onTap: () => setState(() => _isRatingExpanded = !_isRatingExpanded),
              child: Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
                child: Row(
                  children: [
                    // Icon star
                    Container(
                      padding: EdgeInsets.all(ResponsiveMobile.scaledW(6)),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: ResponsiveMobile.scaledFont(14),
                      ),
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(10)),
                    
                    // Rating number
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(20),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(6)),
                    
                    // Stars
                    RatingWidgets.buildStarRating(
                      rating: rating,
                      size: ResponsiveMobile.scaledFont(12),
                      showLabel: false,
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(6)),
                    
                    // Review count
                    Text(
                      '($totalReviews)',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(11),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Badge driver baru
                    if (isNewDriver && totalReviews > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveMobile.scaledW(6),
                          vertical: ResponsiveMobile.scaledH(3),
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                          ),
                          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
                        ),
                        child: Text(
                          'BARU',
                          style: TextStyle(
                            fontSize: ResponsiveMobile.scaledFont(8),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    SizedBox(width: ResponsiveMobile.scaledW(8)),
                    
                    // Expand/collapse icon
                    Icon(
                      _isRatingExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade600,
                      size: ResponsiveMobile.scaledFont(20),
                    ),
                  ],
                ),
              ),
            ),
            
            // Breakdown (hanya muncul jika expanded)
            if (_isRatingExpanded && totalReviews > 0)
              Container(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveMobile.scaledW(12),
                  0,
                  ResponsiveMobile.scaledW(12),
                  ResponsiveMobile.scaledH(12),
                ),
                child: Column(
                  children: [
                    Divider(height: 1, color: Colors.grey.shade200),
                    SizedBox(height: ResponsiveMobile.scaledH(10)),
                    _buildMiniBreakdown(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBreakdown() {
    return Column(
      children: List.generate(5, (index) {
        final stars = 5 - index;
        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(4)),
          child: _buildMiniBreakdownRow(
            stars,
            _ratingBreakdown!['star_$stars'],
            _ratingBreakdown!['percentage_$stars'],
          ),
        );
      }),
    );
  }

  Widget _buildMiniBreakdownRow(int stars, int count, double percentage) {
    final totalReviews = _ratingBreakdown!['total_reviews'] as int;
    
    return Row(
      children: [
        SizedBox(
          width: ResponsiveMobile.scaledW(22),
          child: Row(
            children: [
              Text(
                '$stars',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(9),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: ResponsiveMobile.scaledW(2)),
              Icon(
                Icons.star,
                size: ResponsiveMobile.scaledFont(8),
                color: Colors.amber,
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(2)),
            child: LinearProgressIndicator(
              value: totalReviews > 0 ? percentage / 100 : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_getStarColor(stars)),
              minHeight: ResponsiveMobile.scaledH(4),
            ),
          ),
        ),
        SizedBox(width: ResponsiveMobile.scaledW(6)),
        SizedBox(
          width: ResponsiveMobile.scaledW(18),
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(9),
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStarColor(int stars) {
    switch (stars) {
      case 5: return Colors.green;
      case 4: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 2: return Colors.deepOrange;
      case 1: return Colors.red;
      default: return Colors.grey;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FILTER TABS (pink theme)
  // ═══════════════════════════════════════════════════════════
  Widget _buildFilterTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(16)),
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildFilterChip('Aktif', 'aktif')),
          SizedBox(width: ResponsiveMobile.scaledW(4)),
          Expanded(child: _buildFilterChip('Selesai', 'selesai')),
          SizedBox(width: ResponsiveMobile.scaledW(4)),
          Expanded(child: _buildFilterChip('Dibatalkan', 'dibatalkan')),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isActive = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: ResponsiveMobile.scaledH(10)),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFFF9EC5), Color(0xFFFFB8D4)],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF9EC5).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontSize: ResponsiveMobile.scaledFont(11),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STREAM RIWAYAT
  // ═══════════════════════════════════════════════════════════
  Widget _buildRiwayatStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('pengiriman')
          .stream(primaryKey: ['id_pengiriman'])
          .eq('id_driver', widget.driverId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(40)),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9EC5)),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('❌ [RiwayatPage] Stream error: ${snapshot.error}');
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        List<Map<String, dynamic>> filteredData = snapshot.data!;
        
        if (_selectedFilter == 'aktif') {
          filteredData = filteredData.where((item) {
            final status = item['status_pengiriman'];
            return status != 'selesai' && status != 'dibatalkan';
          }).toList();
        } else if (_selectedFilter == 'selesai') {
          filteredData = filteredData
              .where((item) => item['status_pengiriman'] == 'selesai')
              .toList();
        } else if (_selectedFilter == 'dibatalkan') {
          filteredData = filteredData
              .where((item) => item['status_pengiriman'] == 'dibatalkan')
              .toList();
        }

        if (filteredData.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(16)),
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            return _RiwayatCompactCard(
              pengiriman: filteredData[index],
              isAktif: _selectedFilter == 'aktif',
              ratingService: _ratingService,
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EMPTY & ERROR STATES
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    String title, subtitle;
    IconData icon;
    
    if (_selectedFilter == 'aktif') {
      title = 'Belum Ada Pesanan Aktif';
      subtitle = 'Pesanan yang Anda terima akan muncul di sini';
      icon = Icons.delivery_dining_rounded;
    } else if (_selectedFilter == 'selesai') {
      title = 'Belum Ada Riwayat Selesai';
      subtitle = 'Pesanan yang selesai akan muncul di sini';
      icon = Icons.check_circle_outline_rounded;
    } else {
      title = 'Belum Ada Pesanan Dibatalkan';
      subtitle = 'Pesanan yang dibatalkan akan muncul di sini';
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveMobile.scaledW(32),
        vertical: ResponsiveMobile.scaledH(60),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF9EC5).withOpacity(0.1),
                  const Color(0xFFFFB8D4).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: ResponsiveMobile.scaledFont(48),
              color: const Color(0xFFFF9EC5),
            ),
          ),
          SizedBox(height: ResponsiveMobile.scaledH(16)),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(15),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveMobile.scaledH(6)),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(11),
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: ResponsiveMobile.scaledFont(48),
            color: Colors.red.shade300,
          ),
          SizedBox(height: ResponsiveMobile.scaledH(12)),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(14),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveMobile.scaledH(6)),
          Text(
            error,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(11),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveMobile.scaledH(16)),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: Icon(Icons.refresh_rounded, size: ResponsiveMobile.scaledFont(16)),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9EC5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(20),
                vertical: ResponsiveMobile.scaledH(10),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// COMPACT CARD WIDGET (ukuran lebih kecil, lebih banyak muat)
// ═══════════════════════════════════════════════════════════
class _RiwayatCompactCard extends StatefulWidget {
  final Map<String, dynamic> pengiriman;
  final bool isAktif;
  final RatingUlasanService ratingService;

  const _RiwayatCompactCard({
    required this.pengiriman,
    required this.isAktif,
    required this.ratingService,
  });

  @override
  State<_RiwayatCompactCard> createState() => _RiwayatCompactCardState();
}

class _RiwayatCompactCardState extends State<_RiwayatCompactCard> {
  final supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _pesananData;
  Map<String, dynamic>? _customerData;
  Map<String, dynamic>? _ratingData;
  
  bool _isLoading = true;
  String? _errorMessage;
  bool _isExpanded = false; // untuk expand detail

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      final pesananResponse = await supabase
          .from('pesanan')
          .select('*, jenis_kendaraan')
          .eq('id_pesanan', widget.pengiriman['id_pesanan'])
          .maybeSingle()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('Timeout'),
          );

      if (pesananResponse == null) {
        throw Exception('Data pesanan tidak ditemukan');
      }

      final customerResponse = await supabase
          .from('users')
          .select('nama, foto_profil, no_telp')
          .eq('id_user', pesananResponse['id_user'])
          .maybeSingle()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('Timeout'),
          );

      // Ambil kendaraan aktif driver
      final idDriver = widget.pengiriman['id_driver'];
      final vehicleData = await supabase
          .from('driver_vehicles')
          .select('plat_nomor, merk_kendaraan')
          .eq('id_driver', idDriver)
          .eq('is_active', true)
          .maybeSingle();

      Map<String, dynamic>? ratingResponse;
      if (!widget.isAktif && widget.pengiriman['status_pengiriman'] == 'selesai') {
        try {
          ratingResponse = await widget.ratingService.getRatingForOrder(
            idPesanan: widget.pengiriman['id_pesanan'],
            idDriver: widget.pengiriman['id_driver'],
          );
        } catch (e) {
          debugPrint('⚠️ Rating not found: $e');
        }
      }

      if (mounted) {
        setState(() {
          _pesananData = {
            ...pesananResponse,
            'plat_nomor': vehicleData?['plat_nomor'] ?? '-',
            'merk_kendaraan': vehicleData?['merk_kendaraan'] ?? '-',
          };
          _customerData = customerResponse;
          _ratingData = ratingResponse;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildCardContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
      child: Center(
        child: SizedBox(
          width: ResponsiveMobile.scaledW(20),
          height: ResponsiveMobile.scaledW(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9EC5)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: ResponsiveMobile.scaledFont(18),
            color: Colors.orange,
          ),
          SizedBox(width: ResponsiveMobile.scaledW(8)),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(10),
                color: Colors.grey.shade600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: ResponsiveMobile.scaledFont(18),
            ),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadOrderData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent() {
    final status = widget.pengiriman['status_pengiriman'] ?? '';
    
    return InkWell(
      onTap: () {
        if (widget.isAktif && _pesananData != null) {
          _lanjutkanPesanan();
        } else {
          setState(() => _isExpanded = !_isExpanded);
        }
      },
      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status + Vehicle Type + Date
            Row(
              children: [
                _buildCompactStatusBadge(status),
                SizedBox(width: ResponsiveMobile.scaledW(6)),
                _buildVehicleBadge(), // ⚠️ TAMBAH INI
                const Spacer(),
                Text(
                  _formatDate(widget.pengiriman['created_at']),
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(9),
                    color: Colors.grey.shade500,
                  ),
                ),
                if (!widget.isAktif) ...[
                  SizedBox(width: ResponsiveMobile.scaledW(6)),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: ResponsiveMobile.scaledFont(16),
                    color: Colors.grey.shade500,
                  ),
                ],
              ],
            ),
            
            SizedBox(height: ResponsiveMobile.scaledH(10)),
            
            // Lokasi (compact)
            _buildCompactLocation(),
            
            SizedBox(height: ResponsiveMobile.scaledH(8)),
            
            // Info row (jarak + ongkir)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: ResponsiveMobile.scaledFont(12),
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(4)),
                    Text(
                      '${_pesananData?['jarak_km'] ?? '0'} km',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(10),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rp ${_formatCurrency(_pesananData?['ongkir'])}',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(12),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            
            // Expanded details
            if (_isExpanded) ...[
              SizedBox(height: ResponsiveMobile.scaledH(10)),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: ResponsiveMobile.scaledH(10)),
              _buildExpandedDetails(),
            ],
            
            // Button untuk aktif
            if (widget.isAktif) ...[
              SizedBox(height: ResponsiveMobile.scaledH(10)),
              _buildCompactButton(),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // COMPACT STATUS BADGE
  // ═══════════════════════════════════════════════════════════
  Widget _buildCompactStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveMobile.scaledW(8),
        vertical: ResponsiveMobile.scaledH(4),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(status).withOpacity(0.2),
            _getStatusColor(status).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: ResponsiveMobile.scaledFont(10),
            color: _getStatusColor(status),
          ),
          SizedBox(width: ResponsiveMobile.scaledW(4)),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: ResponsiveMobile.scaledFont(9),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleBadge() {
    final String jenisKendaraan = _pesananData?['jenis_kendaraan'] ?? '';
    if (jenisKendaraan.isEmpty) return const SizedBox();
    
    final bool isMotor = jenisKendaraan == 'motor';
    final Color vehicleColor = isMotor ? Colors.green : Colors.blue;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveMobile.scaledW(6),
        vertical: ResponsiveMobile.scaledH(3),
      ),
      decoration: BoxDecoration(
        color: vehicleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
        border: Border.all(
          color: vehicleColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMotor ? Icons.two_wheeler : Icons.directions_car,
            size: ResponsiveMobile.scaledFont(9),
            color: vehicleColor,
          ),
          SizedBox(width: ResponsiveMobile.scaledW(3)),
          Text(
            jenisKendaraan.toUpperCase(),
            style: TextStyle(
              color: vehicleColor,
              fontSize: ResponsiveMobile.scaledFont(8),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // COMPACT LOCATION
  // ═══════════════════════════════════════════════════════════
  Widget _buildCompactLocation() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(4)),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trip_origin,
                size: ResponsiveMobile.scaledFont(10),
                color: const Color(0xFF4CAF50),
              ),
            ),
            SizedBox(width: ResponsiveMobile.scaledW(8)),
            Expanded(
              child: Text(
                _pesananData?['alamat_asal'] ?? 'Lokasi asal',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(10),
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveMobile.scaledH(6)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(4)),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                size: ResponsiveMobile.scaledFont(10),
                color: const Color(0xFFF44336),
              ),
            ),
            SizedBox(width: ResponsiveMobile.scaledW(8)),
            Expanded(
              child: Text(
                _pesananData?['alamat_tujuan'] ?? 'Lokasi tujuan',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(10),
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EXPANDED DETAILS (customer info + rating)
  // ═══════════════════════════════════════════════════════════
  Widget _buildExpandedDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer info
        if (_customerData != null) _buildCustomerInfo(),
        
        // Rating (jika ada)
        if (!widget.isAktif && widget.pengiriman['status_pengiriman'] == 'selesai') ...[
          SizedBox(height: ResponsiveMobile.scaledH(10)),
          if (_ratingData != null)
            _buildRatingInfo()
          else
            _buildNoRatingInfo(),
        ],
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(10)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF9EC5).withOpacity(0.1),
            const Color(0xFFFFB8D4).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
        border: Border.all(
          color: const Color(0xFFFF9EC5).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveMobile.scaledW(16),
            backgroundImage: _customerData!['foto_profil'] != null
                ? NetworkImage(_customerData!['foto_profil'])
                : null,
            backgroundColor: Colors.grey.shade200,
            child: _customerData!['foto_profil'] == null
                ? Icon(
                    Icons.person,
                    size: ResponsiveMobile.scaledFont(16),
                    color: Colors.grey.shade500,
                  )
                : null,
          ),
          SizedBox(width: ResponsiveMobile.scaledW(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customerData!['nama'] ?? 'Customer',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(11),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveMobile.scaledH(2)),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: ResponsiveMobile.scaledFont(10),
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(4)),
                    Expanded(
                      child: Text(
                        _customerData!['no_telp'] ?? '-',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(9),
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveMobile.scaledW(6),
              vertical: ResponsiveMobile.scaledH(3),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9EC5), Color(0xFFFFB8D4)],
              ),
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
            ),
            child: Text(
              'Customer',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(8),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingInfo() {
    final rating = _ratingData!['rating'] as int;
    final reviewText = _ratingData!['review_text'] as String?;

    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(10)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
        border: Border.all(
          color: Colors.amber.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: ResponsiveMobile.scaledFont(14),
              ),
              SizedBox(width: ResponsiveMobile.scaledW(6)),
              Text(
                'Rating: ',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(10),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              RatingWidgets.buildStarRating(
                rating: rating.toDouble(),
                size: ResponsiveMobile.scaledFont(11),
                showLabel: false,
              ),
            ],
          ),
          if (reviewText != null && reviewText.isNotEmpty) ...[
            SizedBox(height: ResponsiveMobile.scaledH(6)),
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
              ),
              child: Text(
                '"$reviewText"',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(9),
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoRatingInfo() {
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(10)),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_border,
            size: ResponsiveMobile.scaledFont(14),
            color: Colors.grey.shade400,
          ),
          SizedBox(width: ResponsiveMobile.scaledW(8)),
          Text(
            'Belum ada rating',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(10),
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // COMPACT BUTTON (untuk pesanan aktif)
  // ═══════════════════════════════════════════════════════════
  Widget _buildCompactButton() {
    return Container(
      width: double.infinity,
      height: ResponsiveMobile.scaledH(36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9EC5), Color(0xFFFFB8D4)],
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9EC5).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _lanjutkanPesanan,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: ResponsiveMobile.scaledFont(14),
                ),
                SizedBox(width: ResponsiveMobile.scaledW(6)),
                Text(
                  'LANJUTKAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveMobile.scaledFont(11),
                    fontWeight: FontWeight.bold,
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

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════
  void _lanjutkanPesanan() {
    if (_pesananData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data tidak lengkap'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    debugPrint('🚀 Lanjutkan: ${widget.pengiriman['id_pengiriman']}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PengirimanDetailDriver(
          pengirimanData: widget.pengiriman,
          pesananData: _pesananData!,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS HELPERS
  // ═══════════════════════════════════════════════════════════
  Color _getStatusColor(String status) {
    switch (status) {
      case 'diterima':
      case 'diterima_driver':
        return const Color(0xFF2196F3);
      case 'menuju_pickup':
        return const Color(0xFF3F51B5);
      case 'sampai_pickup':
        return const Color(0xFF9C27B0);
      case 'customer_naik':
        return const Color(0xFF673AB7);
      case 'perjalanan':
        return const Color(0xFFFF9800);
      case 'sampai_tujuan':
        return const Color(0xFFFFC107);
      case 'selesai':
        return const Color(0xFF4CAF50);
      case 'dibatalkan':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'diterima':
      case 'diterima_driver':
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
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'diterima':
      case 'diterima_driver':
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
        return 'BATAL';
      default:
        return status.toUpperCase();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FORMAT HELPERS
  // ═══════════════════════════════════════════════════════════
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          if (diff.inMinutes == 0) return 'Baru saja';
          return '${diff.inMinutes}m lalu';
        }
        return '${diff.inHours}j lalu';
      } else if (diff.inDays == 1) {
        return 'Kemarin';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}h lalu';
      } else {
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        return '$day/$month/${date.year}';
      }
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