// lib/screens/customer/pages/produk_detail_page.dart
// ============================================================================
// 🎨 REDESIGN COMPLETE - PRODUK DETAIL PAGE (TikTok/Shopee Style)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';
import 'package:sidrive/models/produk_model.dart';
import 'package:sidrive/models/cart_model.dart';
import 'package:sidrive/providers/cart_provider.dart';
import 'package:sidrive/services/umkm_service.dart';
import 'package:sidrive/models/umkm_model.dart';
import 'package:sidrive/screens/customer/pages/cart_page.dart';
import 'package:sidrive/screens/customer/pages/toko_profile_page.dart';


class ProdukDetailPage extends StatefulWidget {
  final ProdukModel produk;

  const ProdukDetailPage({Key? key, required this.produk}) : super(key: key);

  @override
  State<ProdukDetailPage> createState() => _ProdukDetailPageState();
}

class _ProdukDetailPageState extends State<ProdukDetailPage> {
  final _umkmService = UmkmService();
  final _supabase = Supabase.instance.client;
  
  int _currentImageIndex = 0;
  int _quantity = 1;
  UmkmModel? _umkmData;
  bool _isAddingToCart = false;
  
  // ✅ State untuk data baru
  List<ProdukModel> _sameTokoProduk = [];
  List<ProdukModel> _rekomendasiProduk = [];
  Map<String, dynamic> _ratingStats = {};
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;

  final Color _primaryColor = const Color(0xFFFF6B9D);
  final Color _accentColor = const Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadUmkmData();
    _loadSameTokoProduk();
    _loadRekomendasiProduk();
    _loadReviewsData();
  }

  Future<void> _loadUmkmData() async {
    try {
      final umkm = await _umkmService.getUmkmById(widget.produk.idUmkm);
      if (mounted) {
        setState(() {
          _umkmData = umkm;
        });
      }
    } catch (e) {
      debugPrint('❌ Error load UMKM: $e');
    }
  }

  Future<void> _loadSameTokoProduk() async {
    try {
      final result = await _supabase
          .from('produk')
          .select('*')
          .eq('id_umkm', widget.produk.idUmkm)
          .neq('id_produk', widget.produk.idProduk)
          .eq('is_available', true)
          .limit(10);
      
      if (mounted) {
        setState(() {
          _sameTokoProduk = result.map((json) => ProdukModel.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Error load same toko produk: $e');
    }
  }

  Future<void> _loadRekomendasiProduk() async {
    try {
      final result = await _supabase
          .from('produk')
          .select('*')
          .eq('kategori_produk', widget.produk.kategoriProduk)
          .neq('id_umkm', widget.produk.idUmkm)
          .neq('id_produk', widget.produk.idProduk)
          .eq('is_available', true)
          .limit(10);
      
      if (mounted) {
        setState(() {
          _rekomendasiProduk = result.map((json) => ProdukModel.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Error load rekomendasi: $e');
    }
  }

  Future<void> _loadReviewsData() async {
    try {
      final reviews = await _supabase
          .from('rating_reviews')
          .select('''
            *,
            users:id_user (nama)
          ''')
          .eq('target_type', 'produk')
          .eq('target_id', widget.produk.idProduk)
          .order('created_at', ascending: false)
          .limit(20);
      
      Map<String, dynamic> stats = {
        'total': reviews.length,
        'average': 0.0,
        'star_5': 0,
        'star_4': 0,
        'star_3': 0,
        'star_2': 0,
        'star_1': 0,
      };
      
      if (reviews.isNotEmpty) {
        int totalRating = 0;
        for (var review in reviews) {
          final rating = review['rating'] as int;
          totalRating += rating;
          stats['star_$rating']++;
        }
        stats['average'] = totalRating / reviews.length;
      }
      
      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(reviews);
          _ratingStats = stats;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error load reviews: $e');
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }
  
  Future<void> _addToCart() async {
    if (_quantity > widget.produk.stok) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Stok Tidak Cukup',
        message: 'Stok tersedia hanya ${widget.produk.stok} item',
      );
      return;
    }

    setState(() => _isAddingToCart = true);

    final cartItem = CartItem(
      idProduk: widget.produk.idProduk,
      namaProduk: widget.produk.namaProduk,
      hargaProduk: widget.produk.hargaProduk,
      fotoProduk: widget.produk.fotoProduk?.first,
      idUmkm: widget.produk.idUmkm,
      namaToko: _umkmData?.namaToko ?? 'Toko',
      quantity: _quantity,
      stokTersedia: widget.produk.stok,
    );

    final success = await context.read<CartProvider>().addItem(cartItem);

    setState(() => _isAddingToCart = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Berhasil ditambahkan ke keranjang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Lihat',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ),
      );
    } else if (mounted) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Gagal Menambahkan',
        message: 'Stok tidak mencukupi atau produk sudah ada di keranjang',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCompactImageCarousel()),
          SliverToBoxAdapter(child: _buildModernProductInfo()),
          SliverToBoxAdapter(child: _buildTags()),
          SliverToBoxAdapter(child: _buildSameTokoProduk()),
          SliverToBoxAdapter(child: _buildTokoInfo()),
          SliverToBoxAdapter(child: _buildRatingSection()),
          SliverToBoxAdapter(child: _buildDeskripsiSection()),
          SliverToBoxAdapter(child: _buildRekomendasiSection()),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.share_outlined, color: Colors.black87, size: 20),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 20),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.itemCount == 0) return const SizedBox.shrink();
                  
                  return Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '${cart.itemCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
          },
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCompactImageCarousel() {
    final images = widget.produk.fotoProduk ?? [];
    if (images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      );
    }

    return Container(
      height: 280,
      color: Colors.white,
      child: Stack(
        children: [
          CarouselSlider.builder(
            itemCount: images.length,
            itemBuilder: (context, index, realIndex) {
              return Container(
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.error, size: 40),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 280,
              viewportFraction: 1.0,
              enableInfiniteScroll: images.length > 1,
              onPageChanged: (index, reason) {
                setState(() => _currentImageIndex = index);
              },
            ),
          ),
          
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((entry) {
                  return Container(
                    width: _currentImageIndex == entry.key ? 24 : 8,
                    height: 8,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentImageIndex == entry.key
                          ? _primaryColor
                          : Colors.white.withOpacity(0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernProductInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                CurrencyFormatter.format(widget.produk.hargaProduk),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
              Spacer(),
              if (_ratingStats['total'] != null && _ratingStats['total'] > 0) ...[
                Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                SizedBox(width: 4),
                Text(
                  _ratingStats['average'].toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  ' (${_ratingStats['total']})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          
          SizedBox(height: 10),
          
          Text(
            widget.produk.namaProduk,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              _buildInfoChip(
                Icons.inventory_2_outlined,
                'Stok: ${widget.produk.stok}',
                Colors.blue,
              ),
              SizedBox(width: 8),
              _buildInfoChip(
                Icons.shopping_bag_outlined,
                'Terjual: ${widget.produk.totalTerjual}',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(
                (color.red * 0.7).toInt(),
                (color.green * 0.7).toInt(),
                (color.blue * 0.7).toInt(),
                1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildTag(Icons.category, widget.produk.kategoriDisplay),
          _buildTag(Icons.timer, '${widget.produk.waktuPersiapanMenit} menit'),
          if (widget.produk.beratGram != null)
            _buildTag(Icons.scale, '${widget.produk.beratGram}g'),
          if (widget.produk.isAvailable)
            _buildTag(Icons.check_circle, 'Tersedia', Colors.green),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, [Color? color]) {
    final tagColor = color ?? _accentColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tagColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tagColor),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(
                (tagColor.red * 0.7).toInt(),
                (tagColor.green * 0.7).toInt(),
                (tagColor.blue * 0.7).toInt(),
                1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSameTokoProduk() {
    if (_sameTokoProduk.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.store, color: _primaryColor, size: 18),
                SizedBox(width: 6),
                Text(
                  'Produk Lain di Toko Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _sameTokoProduk.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_sameTokoProduk[index], isCompact: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokoInfo() {
    if (_umkmData == null) {
      return Container(
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return InkWell(
      onTap: () {
        // TODO: Navigasi ke halaman profile toko
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TokoProfilePage(umkmData: _umkmData!),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: _umkmData!.fotoToko != null
                    ? DecorationImage(
                        image: NetworkImage(_umkmData!.fotoToko!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[200],
              ),
              child: _umkmData!.fotoToko == null
                  ? Icon(Icons.store, size: 25, color: Colors.grey)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _umkmData!.namaToko,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _umkmData!.alamatToko,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 6),
              Text(
                'Rating & Ulasan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          if (_isLoadingReviews)
            Center(child: CircularProgressIndicator())
          else if (_ratingStats['total'] == 0)
            _buildNoReviews()
          else ...[
            _buildRatingStats(),
            SizedBox(height: 20),
            Divider(height: 1),
            SizedBox(height: 12),
            _buildReviewsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingStats() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              _ratingStats['average'].toStringAsFixed(1),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                height: 1,
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Colors.amber,
                );
              }),
            ),
            SizedBox(height: 3),
            Text(
              '${_ratingStats['total']} ulasan',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        SizedBox(width: 24),
        
        Expanded(
          child: Column(
            children: [
              for (int i = 5; i >= 1; i--)
                _buildRatingBar(i, _ratingStats['star_$i'] ?? 0, _ratingStats['total']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int star, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(
            '$star',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 3),
          Icon(Icons.star, size: 12, color: Colors.amber),
          SizedBox(width: 6),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ulasan Customer',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        ..._reviews.take(5).map((review) => _buildReviewItem(review)),
        
        if (_reviews.length > 5)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton(
                onPressed: () {},
                child: Text('Lihat Semua Ulasan (${_reviews.length})'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    final reviewText = review['review_text'] ?? '';
    final userName = review['users']['nama'] as String;
    final fotoUlasan = review['foto_ulasan'];
    
    final sensoredName = userName.length > 3 
        ? userName.substring(0, 3) + '***'
        : userName + '***';
    
    return Container(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: Text(
                  userName[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensoredName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 12,
                            color: Colors.amber,
                          );
                        }),
                        SizedBox(width: 6),
                        Text(
                          _formatReviewDate(review['created_at']),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (reviewText.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              reviewText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ],
          
          if (fotoUlasan != null && fotoUlasan is List && fotoUlasan.isNotEmpty) ...[
            SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fotoUlasan.length > 5 ? 5 : fotoUlasan.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showPhotoViewer(fotoUlasan, index),
                    child: Container(
                      margin: EdgeInsets.only(right: 6),
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        image: DecorationImage(
                          image: NetworkImage(fotoUlasan[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
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

  Widget _buildNoReviews() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 50, color: Colors.grey[300]),
          SizedBox(height: 12),
          Text(
            'Belum ada ulasan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Jadilah yang pertama memberikan ulasan!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeskripsiSection() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: _primaryColor, size: 18),
              SizedBox(width: 6),
              Text(
                'Deskripsi Produk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              widget.produk.deskripsiProduk?.isEmpty ?? true
                  ? 'Tidak ada deskripsi'
                  : widget.produk.deskripsiProduk!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekomendasiSection() {
    if (_rekomendasiProduk.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.explore_outlined, color: _accentColor, size: 18),
                SizedBox(width: 6),
                Text(
                  'Produk Serupa Lainnya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _rekomendasiProduk.length > 6 ? 6 : _rekomendasiProduk.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_rekomendasiProduk[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProdukModel produk, {bool isCompact = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProdukDetailPage(produk: produk),
          ),
        );
      },
      child: Container(
        width: isCompact ? 130 : null,
        margin: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
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
            Container(
              height: isCompact ? 90 : 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                color: Colors.grey[100],
              ),
              child: produk.fotoProduk?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      child: CachedNetworkImage(
                        imageUrl: produk.fotoProduk!.first,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image,
                          size: 35,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Icon(Icons.image, size: 35, color: Colors.grey),
            ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      produk.namaProduk,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(produk.hargaProduk),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (_quantity > 1) {
                        setState(() => _quantity--);
                      }
                    },
                    child: Icon(Icons.remove, size: 18),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (_quantity < widget.produk.stok) {
                        setState(() => _quantity++);
                      }
                    },
                    child: Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 10),
            
            Expanded(
              child: ElevatedButton(
                onPressed: _isAddingToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isAddingToCart
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Tambah ke Keranjang',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReviewDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays < 1) return 'Hari ini';
      if (diff.inDays == 1) return 'Kemarin';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
      return '${(diff.inDays / 30).floor()} bulan lalu';
    } catch (e) {
      return '';
    }
  }

  void _showPhotoViewer(List<dynamic> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoViewerPage(
          photos: photos.map((e) => e.toString()).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// ============================================================================
// PHOTO VIEWER PAGE - Untuk melihat foto ulasan fullscreen
// ============================================================================
class _PhotoViewerPage extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoViewerPage({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.photos[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Close button
          SafeArea(
            child: Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // Photo counter
          if (widget.photos.length > 1)
            SafeArea(
              child: Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}