// lib/pages/customer/umkm_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/providers/cart_provider.dart';
import 'package:sidrive/services/umkm_service.dart';
import 'package:sidrive/models/produk_model.dart';
import 'package:sidrive/screens/customer/pages/produk_detail_page.dart';
import 'package:sidrive/screens/customer/pages/cart_page.dart';

class UmkmTab extends StatefulWidget {
  const UmkmTab({super.key});

  @override
  State<UmkmTab> createState() => _UmkmTabState();
}

class _UmkmTabState extends State<UmkmTab> with AutomaticKeepAliveClientMixin {
  final _umkmService = UmkmService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  
  List<ProdukModel> _allProduk = [];
  List<ProdukModel> _filteredProduk = [];
  String? _selectedKategori;
  String _sortBy = 'terbaru';
  bool _isLoading = true;

  final List<String> _kategoriList = [
    'Semua',
    'Makanan',
    'Minuman',
    'Snack',
    'Kue',
    'Lauk',
    'Lainnya',
  ];

  // Define Color Palette
  final Color _primaryBlue = const Color(0xFF2563EB); // Darker Blue
  final Color _accentBlue = const Color(0xFF3B82F6);  // Lighter Blue

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProduk();
    // Optional: _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProduk() async {
    setState(() => _isLoading = true);

    try {
      final produk = await _umkmService.searchProduk(
        sortBy: _getSortField(_sortBy),
        ascending: _sortBy == 'termurah',
      );

      if (mounted) {
        setState(() {
          _allProduk = produk;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error load produk: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getSortField(String sortBy) {
    switch (sortBy) {
      case 'terlaris':
        return 'total_terjual';
      case 'termurah':
      case 'termahal':
        return 'harga_produk';
      case 'rating':
        return 'rating_produk';
      default:
        return 'created_at';
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProduk = _allProduk.where((produk) {
        // Filter kategori
        if (_selectedKategori != null && 
            _selectedKategori != 'Semua' && 
            produk.kategoriDisplay.toLowerCase() != _selectedKategori!.toLowerCase()) {
          return false;
        }

        // Filter search
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          return produk.namaProduk.toLowerCase().contains(query);
        }

        return true;
      }).toList();

      // Sort logic tambahan jika API sorting terbatas
      if (_sortBy == 'termahal') {
        _filteredProduk.sort((a, b) => b.hargaProduk.compareTo(a.hargaProduk));
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveMobile.scaledR(24)),
        ),
      ),
      padding: ResponsiveMobile.allScaledPadding(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: ResponsiveMobile.scaledW(40),
              height: ResponsiveMobile.scaledH(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ResponsiveMobile.vSpace(20),
          
          Text(
            'Urutkan',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveMobile.vSpace(12),
          
          ...[
            {'label': 'Terbaru', 'value': 'terbaru'},
            {'label': 'Terlaris', 'value': 'terlaris'},
            {'label': 'Harga Termurah', 'value': 'termurah'},
            {'label': 'Harga Termahal', 'value': 'termahal'},
            {'label': 'Rating Tertinggi', 'value': 'rating'},
          ].map((sort) => RadioListTile<String>(
                title: Text(sort['label']!),
                value: sort['value']!,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                  _applyFilters();
                },
                activeColor: _primaryBlue,
                contentPadding: EdgeInsets.zero,
              )).toList(),
          
          ResponsiveMobile.vSpace(12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50ish background
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          _buildSearchBar(),
          _buildKategoriChips(),
          _buildProductGrid(),
        ],
      ),
      floatingActionButton: _buildCartFAB(),
    );
  }

  // ✅ APP BAR GRADIENT BLUE + PATTERN
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      expandedHeight: 80,
      backgroundColor: _primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // 1. Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentBlue, _primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // 2. Decorative Patterns
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              top: 20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(6)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.storefront_rounded, size: ResponsiveMobile.scaledFont(20), color: Colors.white),
          ),
          ResponsiveMobile.hSpace(10),
          Text(
            'UMKM Mahasiswa',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: ResponsiveMobile.scaledW(8)),
          child: IconButton(
            icon: Icon(Icons.tune_rounded, size: ResponsiveMobile.scaledFont(24), color: Colors.white),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter & Sort',
          ),
        ),
      ],
    );
  }

  // ✅ SEARCH BAR TERINTEGRASI
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          // Background Extension
          Container(
            height: ResponsiveMobile.scaledH(30), 
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
          
          // Search Box
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(16)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Cari produk favoritmu...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400, 
                    fontSize: ResponsiveMobile.scaledSP(14)
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: _accentBlue),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveMobile.scaledW(16),
                    vertical: ResponsiveMobile.scaledH(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CATEGORY CHIPS MODERN
  Widget _buildKategoriChips() {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFFF8FAFC),
        padding: EdgeInsets.fromLTRB(
          ResponsiveMobile.scaledW(16),
          ResponsiveMobile.scaledH(20),
          ResponsiveMobile.scaledW(16),
          ResponsiveMobile.scaledH(12), // Sedikit tambah padding bawah agar bayangan tidak terpotong
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none, // Penting agar bayangan (shadow) tidak terpotong
          child: Row(
            children: _kategoriList.map((kategori) {
              final isSelected = _selectedKategori == kategori ||
                  (kategori == 'Semua' && _selectedKategori == null);

              return Padding(
                padding: EdgeInsets.only(right: ResponsiveMobile.scaledW(10)),
                // Bungkus dengan Theme untuk memaksa menghilangkan efek splash oranye
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent, // Hilangkan splash oranye
                    highlightColor: Colors.transparent, // Hilangkan highlight oranye
                  ),
                  child: ChoiceChip(
                    label: Text(kategori),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: ResponsiveMobile.captionSize(context),
                      letterSpacing: 0.3,
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedKategori = kategori == 'Semua' ? null : kategori;
                      });
                      _applyFilters();
                    },
                    // Desain Visual
                    showCheckmark: false, // Hilangkan icon centang agar lebih bersih
                    elevation: isSelected ? 4 : 0, // Tambah bayangan saat dipilih
                    pressElevation: 0,
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF3B82F6), // Warna Biru (_accentBlue)
                    
                    // Bentuk Kapsul yang lebih modern
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100), // Full rounded
                      side: BorderSide(
                        color: isSelected 
                            ? Colors.transparent 
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    // Material 3 spec fix (kadang ada tint warna aneh)
                    surfaceTintColor: Colors.transparent, 
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.scaledW(12),
                      vertical: ResponsiveMobile.scaledH(8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ✅ PRODUCT GRID
  Widget _buildProductGrid() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: _primaryBlue)),
      );
    }

    if (_filteredProduk.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: ResponsiveMobile.scaledFont(64),
                color: Colors.grey.shade300,
              ),
              ResponsiveMobile.vSpace(16),
              Text(
                'Produk tidak ditemukan',
                style: TextStyle(
                  fontSize: ResponsiveMobile.titleSize(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: ResponsiveMobile.allScaledPadding(16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: ResponsiveMobile.scaledH(12),
        crossAxisSpacing: ResponsiveMobile.scaledW(12),
        childCount: _filteredProduk.length,
        itemBuilder: (context, index) {
          return _buildProductCard(_filteredProduk[index]);
        },
      ),
    );
  }

  // ✅ PRODUCT CARD
  Widget _buildProductCard(ProdukModel produk) {
    final isInCart = context.watch<CartProvider>().isInCart(produk.idProduk);
    
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
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ResponsiveMobile.scaledR(16)),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: produk.fotoProduk != null && produk.fotoProduk!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: produk.fotoProduk!.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade50,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade50,
                              child: Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade300),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade50,
                            child: Icon(Icons.image_rounded, color: Colors.grey.shade300),
                          ),
                  ),
                ),
                
                // Badge Terlaris (Keep Red for Hot Item)
                if (produk.totalTerjual > 10)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveMobile.scaledW(8),
                        vertical: ResponsiveMobile.scaledH(4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            'Terlaris',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveMobile.captionSize(context) - 3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Cart indicator (Blue)
                if (isInCart)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(ResponsiveMobile.scaledW(6)),
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: ResponsiveMobile.scaledFont(14),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Info
            Padding(
              padding: ResponsiveMobile.allScaledPadding(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produk.namaProduk,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.bodySize(context),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                  ResponsiveMobile.vSpace(6),
                  
                  // Rating & Sold
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade400),
                      SizedBox(width: 2),
                      Text(
                        produk.totalRating > 0 ? produk.ratingProduk.toStringAsFixed(1) : '0.0',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.captionSize(context),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 1,
                        height: 10,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: Text(
                          '${produk.totalTerjual} terjual',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: ResponsiveMobile.captionSize(context),
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  ResponsiveMobile.vSpace(8),
                  
                  // Price (Blue)
                  Text(
                    CurrencyFormatter.formatRupiahWithPrefix(produk.hargaProduk),
                    style: TextStyle(
                      fontSize: ResponsiveMobile.bodySize(context) + 1,
                      fontWeight: FontWeight.w800,
                      color: _primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ BLUE FAB
  Widget _buildCartFAB() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.itemCount == 0) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
          },
          backgroundColor: _primaryBlue,
          elevation: 4,
          highlightElevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_bag_outlined, color: Colors.white),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          label: Text(
            CurrencyFormatter.formatCompact(cart.totalPrice),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}