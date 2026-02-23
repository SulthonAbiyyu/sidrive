import 'dart:async';  
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/pesanan_umkm_service.dart';
import 'package:sidrive/services/umkm_service.dart';
import 'package:sidrive/services/pesanan_service.dart';
import 'package:sidrive/models/pesanan_umkm_model.dart';
import 'package:sidrive/screens/umkm/pages/umkm_searching_dialog.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/models/chat_models.dart';
import 'package:sidrive/screens/chat/chat_room_page.dart';


class PesananUmkmPage extends StatefulWidget {
  const PesananUmkmPage({Key? key}) : super(key: key);

  @override
  State<PesananUmkmPage> createState() => _PesananUmkmPageState();
}

class _PesananUmkmPageState extends State<PesananUmkmPage> with SingleTickerProviderStateMixin {
  final _pesananService = PesananUmkmService();
  final _umkmService = UmkmService();
  final _supabase = Supabase.instance.client;
  
  late TabController _tabController;
  String? _umkmId;
  bool _isLoading = true;
  
  List<PesananUmkmModel> _allPesanan = [];
  List<PesananUmkmModel> _filteredPesanan = [];
  StreamSubscription? _pesananSubscription;
  Map<String, Map<String, dynamic>> _ratingsCache = {};
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _pesananSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

   void _setupRealtimeListener() {
    Future.delayed(Duration(seconds: 1), () {
      if (_umkmId != null && mounted) {
        _listenToPesananChanges();
      }
    });
  }

  void _listenToPesananChanges() {
    if (_umkmId == null) return;
    
    print('👂 Setting up realtime listener for UMKM: $_umkmId');
    
    _pesananSubscription = _supabase
      .from('pesanan')
      .stream(primaryKey: ['id_pesanan'])
      .eq('id_umkm', _umkmId!)
      .listen((data) {
        print('🔄 Realtime update: ${data.length} pesanan');
        _loadPesanan();
      });
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.idUser;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final umkm = await _umkmService.getUmkmByUserId(userId);
      if (umkm == null) throw Exception('UMKM tidak ditemukan');

      _umkmId = umkm.idUmkm;
      await _loadPesanan();
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPesanan() async {
    if (_umkmId == null) return;

    try {
      print('🔄 Loading pesanan for UMKM: $_umkmId');
      final pesanan = await _pesananService.getPesananByUmkm(umkmId: _umkmId!);
      
      if (mounted) {
        setState(() {
          _allPesanan = pesanan;
          _filterPesanan();
          _isLoading = false;
        });
        print('✅ UI updated: ${_allPesanan.length} total, ${_filteredPesanan.length} filtered');
      }
    } catch (e) {
      print('❌ Error loading pesanan: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>?> _loadRatingForPesanan(String idPesanan, String idUser) async {
    try {
      // Cek cache dulu
      if (_ratingsCache.containsKey(idPesanan)) {
        return _ratingsCache[idPesanan];
      }
      
      // Fetch dari database
      final rating = await _supabase
          .from('rating_reviews')
          .select('rating, review_text, foto_ulasan, target_type, created_at')
          .eq('id_pesanan', idPesanan)
          .eq('id_user', idUser)
          .eq('target_type', 'produk')
          .maybeSingle();
      
      // Simpan ke cache
      if (rating != null) {
        _ratingsCache[idPesanan] = rating;
      }
      
      return rating;
    } catch (e) {
      print('❌ Error load rating: $e');
      return null;
    }
  }

  void _onTabChanged() {
    _filterPesanan();
  }


  void _filterPesanan() {
    switch (_tabController.index) {
      case 0: // Semua
        _filteredPesanan = _allPesanan;
        break;
      case 1: // Baru
        _filteredPesanan = _allPesanan.where((p) => 
          p.statusPesanan == 'menunggu_konfirmasi' || 
          p.statusPesanan == 'menunggu_pembayaran'
        ).toList();
        break;
      case 2: // Diproses
        _filteredPesanan = _allPesanan.where((p) => 
          p.statusPesanan == 'diproses'
        ).toList();
        break;
      case 3: // Siap
        _filteredPesanan = _allPesanan.where((p) => 
          p.statusPesanan == 'siap_kirim'
        ).toList();
        break;
      case 4: // Mencari/Kirim
        _filteredPesanan = _allPesanan.where((p) => 
          p.statusPesanan == 'mencari_driver' ||
          p.statusPesanan == 'dalam_pengiriman'
        ).toList();
        break;
      case 5: // Selesai
        _filteredPesanan = _allPesanan.where((p) => 
          p.statusPesanan == 'selesai' || 
          p.statusPesanan == 'dibatalkan'
        ).toList();
        break;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // ✨ MODERN HEADER dengan Gradient Cerah
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF9800), // Orange 500 - Lebih cerah
                    Color(0xFFFF6F00), // Orange 900 - Vibrant
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF9800).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsets.only(left: 24, bottom: 16),
                title: Text(
                  'Pesanan Masuk',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                background: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(left: 24, top: 16, right: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola Pesanan Anda',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
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
          
          // TAB BAR
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Color(0xFFFF6F00),
                indicatorWeight: 3,
                labelColor: Color(0xFFFF6F00),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: [
                  Tab(text: 'Semua (${_allPesanan.length})'),
                  Tab(text: 'Baru (${_allPesanan.where((p) => p.statusPesanan == 'menunggu_konfirmasi' || p.statusPesanan == 'menunggu_pembayaran').length})'),
                  Tab(text: 'Proses (${_allPesanan.where((p) => p.statusPesanan == 'diproses').length})'),
                  Tab(text: 'Siap (${_allPesanan.where((p) => p.statusPesanan == 'siap_kirim').length})'),
                  Tab(text: 'Kirim (${_allPesanan.where((p) => p.statusPesanan == 'mencari_driver' || p.statusPesanan == 'dalam_pengiriman').length})'),
                  Tab(text: 'Selesai'),
                ],
              ),
            ),
          ),
          
          // CONTENT
          _isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFFFF9800)),
                    ),
                  ),
                )
              : _filteredPesanan.isEmpty
                  ? SliverFillRemaining(child: _buildEmpty())
                  : SliverPadding(
                      padding: EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildPesananCard(_filteredPesanan[index]);
                          },
                          childCount: _filteredPesanan.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined, 
              size: 64, 
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Tidak ada pesanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pesanan akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesananCard(PesananUmkmModel pesanan) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header dengan gradient
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  pesanan.statusColor.withOpacity(0.1),
                  pesanan.statusColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [pesanan.statusColor, pesanan.statusColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: pesanan.statusColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    pesanan.statusBadge,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    '#${pesanan.idPesanan.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF59E0B).withOpacity(0.1), Color(0xFFD97706).withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person_outline, size: 20, color: Color(0xFFD97706)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pesanan.customerName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            pesanan.customerPhone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Delivery method
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pesanan.metodePengiriman == 'driver' 
                          ? Icons.delivery_dining 
                          : Icons.shopping_bag_outlined,
                        size: 20,
                        color: pesanan.metodePengiriman == 'driver' 
                          ? Colors.blue.shade600 
                          : Colors.green.shade600,
                      ),
                      SizedBox(width: 8),
                      Text(
                        pesanan.metodePengiriman == 'driver' 
                          ? 'Diantar Driver' 
                          : 'Ambil Sendiri',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade200),
                SizedBox(height: 16),
                
                // Products summary
                Text(
                  'Pesanan (${pesanan.items.length} item)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                ...pesanan.items.take(2).map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.namaProduk} (${item.jumlah}x)',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ),
                      Text(
                        _formatCurrency(item.subtotal),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                )),
                if (pesanan.items.length > 2)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '+${pesanan.items.length - 2} item lainnya',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                SizedBox(height: 16),
                
                // Total dengan highlight
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF59E0B).withOpacity(0.1), Color(0xFFD97706).withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Spacer(),
                      Text(
                        _formatCurrency(pesanan.totalHarga),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions
                SizedBox(height: 16),
                _buildActions(pesanan),
                if (pesanan.statusPesanan == 'selesai') ...[
                  SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey.shade200),
                  SizedBox(height: 16),
                  _buildRatingSection(pesanan),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(PesananUmkmModel pesanan) {
    switch (pesanan.statusPesanan) {
      case 'menunggu_konfirmasi':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _rejectPesanan(pesanan),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Tolak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _acceptPesanan(pesanan),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Color(0xFFF59E0B),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Terima',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
        
      case 'diproses':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markAsReady(pesanan),
            icon: Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              'Tandai Siap',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
        
      case 'siap_kirim':
        if (pesanan.metodePengiriman == 'driver') {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _cariDriver(pesanan),
              icon: Icon(Icons.local_shipping_outlined, size: 20),
              label: Text(
                'Cari Driver',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _selesaikanAmbilSendiri(pesanan),
              icon: Icon(Icons.check_circle, size: 20),
              label: Text(
                'Selesaikan Pesanan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }
        
      case 'mencari_driver':
      case 'dalam_pengiriman':
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  pesanan.statusPesanan == 'mencari_driver'
                      ? 'Mencari driver tersedia...'
                      : 'Driver sedang mengantar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              // ✅ Icon chat — hide jika driver = user UMKM ini
              if (pesanan.statusPesanan == 'dalam_pengiriman') ...[
                SizedBox(width: 8),
                FutureBuilder<bool>(
                  future: _isDriverSameUser(pesanan.idPesanan),
                  builder: (context, snapshot) {
                    final isSameUser = snapshot.data ?? true;
                    if (isSameUser) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => _openChatWithDriver(pesanan),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
        
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildRatingSection(PesananUmkmModel pesanan) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadRatingForPesanan(pesanan.idPesanan, pesanan.idUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        
        final ratingData = snapshot.data;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                SizedBox(width: 6),
                Text(
                  'Rating & Ulasan Customer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            if (ratingData != null)
              _buildDisplayedRating(ratingData)
            else
              _buildNoRatingYet(),
          ],
        );
      },
    );
  }

  Widget _buildDisplayedRating(Map<String, dynamic> ratingData) {
    final rating = ratingData['rating'] ?? 0;
    final reviewText = ratingData['review_text'] ?? '';
    final fotoUlasan = ratingData['foto_ulasan'];
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF59E0B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFF59E0B).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bintang
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 18,
                color: index < rating ? Colors.amber : Colors.grey[300],
              );
            }),
          ),
          
          // Ulasan
          if (reviewText.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              '"$reviewText"',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Foto ulasan
          if (fotoUlasan != null && fotoUlasan is List && fotoUlasan.isNotEmpty) ...[
            SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fotoUlasan.length > 4 ? 4 : fotoUlasan.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
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
          
          // Timestamp
          SizedBox(height: 8),
          Text(
            'Diberikan pada ${_formatDateTime(ratingData['created_at'])}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRatingYet() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.star_border, color: Colors.grey.shade400, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Belum ada rating dari customer',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================
  
  Future<void> _acceptPesanan(PesananUmkmModel pesanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Terima Pesanan?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Setelah diterima, Anda harus memproses pesanan ini.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF59E0B),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Terima', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog('Menerima pesanan...');

    try {
      final success = await _pesananService.acceptPesanan(pesanan.idPesanan);
      
      _dismissLoadingDialog();
      
      if (success && mounted) {
        _showSuccessMessage('Pesanan berhasil diterima! 🎉');
        await _loadPesanan(); // Auto refresh
      } else {
        throw Exception('Gagal menerima pesanan');
      }
    } catch (e) {
      _dismissLoadingDialog();
      print('❌ Error accept: $e');
      _showErrorMessage('Gagal menerima pesanan');
    }
  }

  Future<void> _rejectPesanan(PesananUmkmModel pesanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.cancel, color: Colors.red.shade600, size: 28),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tolak Pesanan?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Pesanan akan dibatalkan dan customer akan menerima notifikasi.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Tolak', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog('Menolak pesanan...');

    try {
      final success = await _pesananService.rejectPesanan(pesanan.idPesanan);
      
      _dismissLoadingDialog();
      
      if (success && mounted) {
        _showInfoMessage('Pesanan ditolak');
        await _loadPesanan(); // Auto refresh
      } else {
        throw Exception('Gagal menolak pesanan');
      }
    } catch (e) {
      _dismissLoadingDialog();
      print('❌ Error reject: $e');
      _showErrorMessage('Gagal menolak pesanan');
    }
  }

  Future<void> _markAsReady(PesananUmkmModel pesanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_circle, color: Colors.blue.shade600, size: 28),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tandai Siap?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pastikan pesanan sudah dikemas dan siap dikirim.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Setelah ini:\n'
                '• Jika delivery: Anda bisa cari driver\n'
                '• Jika ambil sendiri: Tandai selesai saat customer ambil',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ya, Siap', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog('Menandai pesanan siap...');

    try {
      final success = await _pesananService.markAsReady(pesanan.idPesanan);
      
      _dismissLoadingDialog();
      
      if (success && mounted) {
        _showSuccessMessage('Pesanan ditandai siap! ✨');
        await _loadPesanan(); // Auto refresh
      } else {
        throw Exception('Gagal menandai siap');
      }
    } catch (e) {
      _dismissLoadingDialog();
      print('❌ Error tandai siap: $e');
      _showErrorMessage('Gagal menandai siap');
    }
  }

  Future<void> _cariDriver(PesananUmkmModel pesanan) async {
    // 1. Validasi pembayaran
    if (pesanan.paymentMethod != 'cash' && pesanan.paymentStatus != 'paid') {
      _showWarningMessage('Customer belum menyelesaikan pembayaran!');
      return;
    }
    
    // 2. Show loading
    _showLoadingDialog('Memulai pencarian driver...');
    
    try {
      // 3. Update status ke mencari_driver
      final success = await _pesananService.startSearchingDriver(pesanan.idPesanan);
      
      // ✅ PENTING: Cek success TANPA langsung throw error
      if (!success) {
        _dismissLoadingDialog();
        _showErrorMessage('Gagal memulai pencarian. Periksa koneksi internet Anda.');
        return;
      }
      
      // 4. Get fresh pesanan data
      final updatedPesananJson = await _pesananService.getPesananById(pesanan.idPesanan);
      
      // Dismiss loading
      _dismissLoadingDialog();
      
      if (updatedPesananJson == null) {
        _showErrorMessage('Gagal memuat data pesanan');
        return;
      }
      
      // 5. Show success message
      _showSuccessMessage('Pencarian driver dimulai! 🚗');
      
      // 6. Auto refresh
      await _loadPesanan();
      
      // 7. Show dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UmkmSearchingDialog(
            pesananData: updatedPesananJson,
            onCancel: () {
              Navigator.pop(context);
              _loadPesanan();
            },
          ),
        );
        
        await _loadPesanan();
      }
      
    } catch (e) {
      _dismissLoadingDialog();
      print('❌ Error cari driver: $e');
      
      // ✅ JANGAN TAMPILKAN ERROR jika status sudah berubah
      final currentPesanan = _allPesanan.firstWhere(
        (p) => p.idPesanan == pesanan.idPesanan,
        orElse: () => pesanan,
      );
      
      // Hanya show error jika BENAR-BENAR GAGAL
      if (currentPesanan.statusPesanan != 'mencari_driver') {
        _showErrorMessage('Terjadi kesalahan saat mencari driver');
      }
    }
  }

  Future<void> _selesaikanAmbilSendiri(PesananUmkmModel pesanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shopping_bag, color: Colors.green.shade600, size: 28),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Customer Sudah Ambil?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pastikan customer sudah mengambil pesanan di toko.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.green.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembayaran akan masuk ke saldo wallet Anda',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ya, Selesai', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog('Memproses pesanan...');

    try {
      // 1. Update status pesanan
      final success = await _pesananService.completeAmbilSendiri(pesanan.idPesanan);
      
      if (!success) throw Exception('Gagal update status');
      
      // 2. Credit UMKM earnings (via pesanan_service)
      final pesananService = PesananService();
      await pesananService.completeUmkmOrderWithoutDriver(pesanan.idPesanan);
      
      _dismissLoadingDialog();
      
      if (mounted) {
        _showSuccessMessage('Pesanan selesai! Pembayaran sudah masuk 💰');
        await _loadPesanan(); // Auto refresh
      }
    } catch (e) {
      _dismissLoadingDialog();
      print('❌ Error selesaikan: $e');
      _showErrorMessage('Gagal menyelesaikan pesanan');
    }
  }

  // ==================== UI HELPERS ====================
  
  void _showLoadingDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                ),
                SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _dismissLoadingDialog() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  void _showWarningMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  void _showInfoMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _isDriverSameUser(String idPesanan) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final result = await _supabase
          .from('pengiriman')
          .select('id_driver')
          .eq('id_pesanan', idPesanan)
          .maybeSingle();
      return result?['id_driver'] == currentUserId;
    } catch (e) {
      return true; // default hide jika error
    }
  }

  Future<void> _openChatWithDriver(PesananUmkmModel pesanan) async {
    try {
      // Ambil ID driver dari tabel pengiriman
      final pengiriman = await _supabase
          .from('pengiriman')
          .select('id_driver')
          .eq('id_pesanan', pesanan.idPesanan)
          .maybeSingle();

      if (pengiriman == null || pengiriman['id_driver'] == null) {
        _showWarningMessage('Data driver tidak ditemukan');
        return;
      }

      final driverId = pengiriman['id_driver'] as String;
      final umkmUserId = _supabase.auth.currentUser?.id;

      if (umkmUserId == null) {
        _showErrorMessage('Sesi tidak valid');
        return;
      }

      final room = await _chatService.createOrGetRoom(
        context: ChatContext.umkmDriver,
        participantIds: [umkmUserId, driverId],
        participantRoles: {
          umkmUserId: 'umkm',
          driverId: 'driver',
        },
        orderId: pesanan.idPesanan,
      );

      if (room == null) {
        _showErrorMessage('Gagal membuka chat');
        return;
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            roomId: room.id,
            room: room,
            currentUserId: umkmUserId,
            currentUserRole: 'umkm',
          ),
        ),
      );
    } catch (e) {
      print('❌ Error open chat driver: $e');
      _showErrorMessage('Gagal membuka chat: ${e.toString()}');
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }
}


  class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
    _SliverAppBarDelegate(this._tabBar);

    final TabBar _tabBar;

    @override
    double get minExtent => _tabBar.preferredSize.height;
    @override
    double get maxExtent => _tabBar.preferredSize.height;

    @override
    Widget build(
        BuildContext context, double shrinkOffset, bool overlapsContent) {
      return Container(
        color: Colors.white,
        child: _tabBar,
      );
    }

    @override
    bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
      return false;
    }
  }