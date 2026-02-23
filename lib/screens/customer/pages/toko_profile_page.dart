// lib/screens/customer/pages/toko_profile_page.dart
// ============================================================================
// 🏪 TOKO PROFILE PAGE
// Halaman untuk melihat profil toko / UMKM lengkap
// ============================================================================

import 'package:flutter/material.dart';
import 'package:sidrive/models/umkm_model.dart';
import 'package:sidrive/models/produk_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/screens/customer/pages/produk_detail_page.dart';

class TokoProfilePage extends StatefulWidget {
  final UmkmModel umkmData;

  const TokoProfilePage({Key? key, required this.umkmData}) : super(key: key);

  @override
  State<TokoProfilePage> createState() => _TokoProfilePageState();
}

class _TokoProfilePageState extends State<TokoProfilePage> {
  final _supabase = Supabase.instance.client;
  List<ProdukModel> _produkList = [];
  bool _isLoading = true;

  final Color _primaryColor = const Color(0xFFFF6B9D);

  @override
  void initState() {
    super.initState();
    _loadProdukToko();
  }

  Future<void> _loadProdukToko() async {
    try {
      final result = await _supabase
          .from('produk')
          .select('*')
          .eq('id_umkm', widget.umkmData.idUmkm)
          .eq('is_available', true)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _produkList = result.map((json) => ProdukModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error load produk toko: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildTokoHeader()),
          SliverToBoxAdapter(child: _buildTokoStats()),
          SliverToBoxAdapter(child: _buildTokoInfo()),
          SliverToBoxAdapter(child: _buildProdukSection()),
          if (_isLoading)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildProductCard(_produkList[index]);
                  },
                  childCount: _produkList.length,
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
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
      title: Text(
        'Profil Toko',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildTokoHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: widget.umkmData.fotoToko != null
                  ? DecorationImage(
                      image: NetworkImage(widget.umkmData.fotoToko!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: widget.umkmData.fotoToko == null
                ? Icon(Icons.store, size: 40, color: Colors.grey)
                : null,
          ),
          SizedBox(height: 16),
          Text(
            widget.umkmData.namaToko,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.umkmData.alamatToko,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokoStats() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.star_rounded,
              value: widget.umkmData.ratingToko.toStringAsFixed(1),
              label: 'Rating',
              color: Colors.amber,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[200],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.shopping_bag_outlined,
              value: '${widget.umkmData.jumlahProdukTerjual}',
              label: 'Terjual',
              color: Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[200],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.inventory_2_outlined,
              value: '${_produkList.length}',
              label: 'Produk',
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTokoInfo() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Toko',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          if (widget.umkmData.deskripsiToko?.isNotEmpty == true) ...[
            _buildInfoRow(Icons.description, widget.umkmData.deskripsiToko!),
            SizedBox(height: 8),
          ],
          _buildInfoRow(
            Icons.access_time,
            widget.umkmData.jamOperasional,
          ),
          SizedBox(height: 8),
          _buildInfoRow(
            widget.umkmData.isBuka ? Icons.store : Icons.store_mall_directory,
            widget.umkmData.isBuka ? 'Sedang Buka' : 'Tutup',
            color: widget.umkmData.isBuka ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.grey[700],
              fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProdukSection() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.shopping_bag_outlined, color: _primaryColor, size: 20),
          SizedBox(width: 8),
          Text(
            'Semua Produk (${_produkList.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProdukModel produk) {
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[100],
              ),
              child: produk.fotoProduk?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: produk.fotoProduk!.first,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Icon(Icons.image, size: 40, color: Colors.grey),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      produk.namaProduk,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.format(produk.hargaProduk),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber),
                            SizedBox(width: 2),
                            Text(
                              produk.ratingProduk.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${produk.totalTerjual} terjual',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
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
}