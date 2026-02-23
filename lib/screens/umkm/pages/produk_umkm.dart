// ============================================================================
// PRODUK_UMKM.DART - REDESIGNED & OPTIMIZED
// ✅ No overflow issues
// ✅ Clean header with integrated "Tambah" button
// ✅ Modern search bar
// ✅ Fully responsive with ResponsiveMobile
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/umkm_service.dart';
import 'package:sidrive/services/product_storage_service.dart';
import 'package:sidrive/models/produk_model.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/screens/umkm/pages/add_edit_produk_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';



class ProdukUmkm extends StatefulWidget {
  const ProdukUmkm({super.key});

  @override
  State<ProdukUmkm> createState() => _ProdukUmkmState();
}

class _ProdukUmkmState extends State<ProdukUmkm> {
  final _umkmService = UmkmService();
  final _storageService = ProductStorageService();
  final _searchController = TextEditingController();
  
  List<ProdukModel> _allProduk = [];
  List<ProdukModel> _filteredProduk = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'semua';
  String _sortBy = 'terbaru';
  
  String? _idUmkm;

  bool _isStokMenipis(ProdukModel p) => p.stok > 0 && p.stok <= 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final umkm = await _umkmService.getUmkmByUserId(userId);
      
      if (umkm == null) {
        setState(() {
          _isLoading = false;
          _idUmkm = null;
        });
        return;
      }

      _idUmkm = umkm.idUmkm;
      final produkList = await _umkmService.getProdukByUmkmId(umkm.idUmkm);

      setState(() {
        _allProduk = produkList;
        _filteredProduk = produkList;
        _isLoading = false;
      });

      _applyFilter();

    } catch (e) {
      print('❌ [PRODUK_UMKM] Error load data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredProduk = _allProduk.where((produk) {
        final matchSearch = _searchQuery.isEmpty ||
            produk.namaProduk.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (produk.deskripsiProduk?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        final matchStatus = _filterStatus == 'semua' ||
            (_filterStatus == 'aktif' && produk.isAvailable) ||
            (_filterStatus == 'nonaktif' && !produk.isAvailable);
            (_filterStatus == 'stok_menipis' && _isStokMenipis(produk));

        return matchSearch && matchStatus;
      }).toList();

      switch (_sortBy) {
        case 'harga_terendah':
          _filteredProduk.sort((a, b) => a.hargaProduk.compareTo(b.hargaProduk));
          break;
        case 'harga_tertinggi':
          _filteredProduk.sort((a, b) => b.hargaProduk.compareTo(a.hargaProduk));
          break;
        case 'stok':
          _filteredProduk.sort((a, b) => a.stok.compareTo(b.stok));
          break;
        case 'terbaru':
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _idUmkm == null ? _buildNoTokoState() : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: Color(0xFFF59E0B),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildSearchSection()),
                      SliverToBoxAdapter(child: _buildFilterChips()),
                      SliverToBoxAdapter(child: _buildSortBar()),
                      _filteredProduk.isEmpty
                          ? SliverFillRemaining(child: _buildEmptyState())
                          : _buildProductGrid(),
                      SliverToBoxAdapter(child: SizedBox(height: ResponsiveMobile.scaledH(20))),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ============================================================================
  // HEADER WITH INTEGRATED "TAMBAH" BUTTON
  // ============================================================================

  Widget _buildHeader() {
    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.currentUser?.nama ?? 'Mitra UMKM';
    
    // Get time-based greeting
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFFB84D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ResponsiveMobile.scaledR(24)),
          bottomRight: Radius.circular(ResponsiveMobile.scaledR(24)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -10,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(20),
                vertical: ResponsiveMobile.scaledH(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Greeting & Action Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: ResponsiveMobile.scaledFont(13),
                            ),
                          ),
                          Text(
                            userName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveMobile.scaledFont(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          color: Colors.white,
                          size: ResponsiveMobile.scaledFont(20),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveMobile.scaledH(16)),
                  
                  // Product Count
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola Produk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveMobile.scaledFont(22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveMobile.scaledH(4)),
                      Text(
                        '${_allProduk.length} produk terdaftar',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: ResponsiveMobile.scaledFont(13),
                        ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveMobile.scaledH(10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // SEARCH SECTION
  // ============================================================================

  Widget _buildSearchSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        ResponsiveMobile.scaledW(16),
        ResponsiveMobile.scaledH(16),
        ResponsiveMobile.scaledW(16),
        ResponsiveMobile.scaledH(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilter();
        },
        style: TextStyle(
          fontSize: ResponsiveMobile.scaledFont(14),
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: ResponsiveMobile.scaledFont(14),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Color(0xFFF59E0B),
            size: ResponsiveMobile.scaledFont(22),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.grey.shade400,
                    size: ResponsiveMobile.scaledFont(20),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFilter();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveMobile.scaledW(16),
            vertical: ResponsiveMobile.scaledH(12),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // FILTER CHIPS
  // ============================================================================

  Widget _buildFilterChips() {
    return Container(
      margin: EdgeInsets.only(
        left: ResponsiveMobile.scaledW(16),
        right: ResponsiveMobile.scaledW(16),
        bottom: ResponsiveMobile.scaledH(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Semua', 'semua', _allProduk.length),
            SizedBox(width: ResponsiveMobile.scaledW(10)),
            _buildFilterChip('Aktif', 'aktif', _allProduk.where((p) => p.isAvailable).length),
            SizedBox(width: ResponsiveMobile.scaledW(10)),
            _buildFilterChip('Nonaktif', 'nonaktif', _allProduk.where((p) => !p.isAvailable).length),
            SizedBox(width: ResponsiveMobile.scaledW(8)),
            _buildFilterChip('Stok Menipis','stok_menipis',_allProduk.where((p) => p.stok <= 5).length,color: Colors.orange,),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    int count, {
    Color? color,
  }) {
    final isSelected = _filterStatus == value;

    return GestureDetector(
      onTap: () {
        setState(() => _filterStatus = value);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.scaledW(14),
          vertical: ResponsiveMobile.scaledH(8),
        ),
        decoration: BoxDecoration(
          color: isSelected
            ? (color ?? Color(0xFFF59E0B))
            : Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
          border: Border.all(
            color: isSelected
              ? (color ?? Color(0xFFF59E0B))
              : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFFF59E0B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: ResponsiveMobile.scaledFont(13),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: ResponsiveMobile.scaledW(6)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(6),
                vertical: ResponsiveMobile.scaledH(2),
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: ResponsiveMobile.scaledFont(11),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // SORT BAR
  // ============================================================================

  Widget _buildSortBar() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveMobile.scaledW(16),
        vertical: ResponsiveMobile.scaledH(8),
      ),
      child: Row(
        children: [ 
          // SORT SECTION (Expanded)
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(12),
                vertical: ResponsiveMobile.scaledH(8),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    color: Colors.grey.shade600,
                    size: ResponsiveMobile.scaledFont(18),
                  ),
                  SizedBox(width: ResponsiveMobile.scaledW(8)),
                  Text(
                    'Urutkan:',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: ResponsiveMobile.scaledFont(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: ResponsiveMobile.scaledW(8)),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFFF59E0B),
                          size: ResponsiveMobile.scaledFont(20),
                        ),
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: ResponsiveMobile.scaledFont(12),
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortBy = value);
                            _applyFilter();
                          }
                        },
                        items: [
                          DropdownMenuItem(value: 'terbaru', child: Text('Terbaru')),
                          DropdownMenuItem(value: 'harga_terendah', child: Text('Harga Terendah')),
                          DropdownMenuItem(value: 'harga_tertinggi', child: Text('Harga Tertinggi')),
                          DropdownMenuItem(value: 'stok', child: Text('Stok Terendah')),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.scaledW(8),
                      vertical: ResponsiveMobile.scaledH(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
                    ),
                    child: Text(
                      '${_filteredProduk.length}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: ResponsiveMobile.scaledFont(11),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: ResponsiveMobile.scaledW(12)),

          // TOMBOL TAMBAH PRODUK (Compact)
          Material(
            color: Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
            child: InkWell(
              onTap: _navigateToAddProduk,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveMobile.scaledW(14),
                  vertical: ResponsiveMobile.scaledH(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: ResponsiveMobile.scaledFont(18),
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(4)),
                    Text(
                      'Tambah',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveMobile.scaledFont(12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PRODUCT GRID
  // ============================================================================

  Widget _buildProductGrid() {
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

  Widget _buildProductCard(ProdukModel produk) {
    return GestureDetector(
      onTap: () => _showQuickActionsBottomSheet(produk),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ResponsiveMobile.scaledR(12)),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: produk.fotoProduk != null && produk.fotoProduk!.isNotEmpty
                        ? Image.network(
                            produk.fotoProduk!.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),
                
                // Action Button - Top Left (lebih kecil)
                Positioned(
                  top: 6,
                  left: 6,
                  child: GestureDetector(
                    onTap: () => _showQuickActionsBottomSheet(produk),
                    child: Container(
                      padding: EdgeInsets.all(ResponsiveMobile.scaledW(4)),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                        size: ResponsiveMobile.scaledFont(12),
                      ),
                    ),
                  ),
                ),
                
                // Photo Count Badge (lebih kecil)
                if (produk.fotoProduk != null && produk.fotoProduk!.length > 1)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveMobile.scaledW(4),
                        vertical: ResponsiveMobile.scaledH(2),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: ResponsiveMobile.scaledFont(8),
                          ),
                          SizedBox(width: ResponsiveMobile.scaledW(2)),
                          Text(
                            '${produk.fotoProduk!.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveMobile.scaledFont(7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Info (padding lebih kecil)
            Padding(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name (font lebih kecil)
                  Text(
                    produk.namaProduk,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(11),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveMobile.scaledH(4)),
                  
                  // Status & Category (lebih kecil)
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveMobile.scaledW(4),
                          vertical: ResponsiveMobile.scaledH(1),
                        ),
                        decoration: BoxDecoration(
                          color: produk.isAvailable ? Colors.green.shade600 : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          produk.isAvailable ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveMobile.scaledFont(7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveMobile.scaledW(3)),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveMobile.scaledW(4),
                            vertical: ResponsiveMobile.scaledH(1),
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            produk.kategoriDisplay,
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledFont(7),
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveMobile.scaledH(4)),
                  
                  // Stock (lebih kecil)
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: ResponsiveMobile.scaledFont(10),
                        color: produk.stok < 5 ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                      SizedBox(width: ResponsiveMobile.scaledW(3)),
                      Text(
                        'Stok: ${produk.stok}',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(8),
                          fontWeight: FontWeight.bold,
                          color: produk.stok < 5 ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveMobile.scaledH(5)),
                  
                  // Price (lebih kecil)
                  Text(
                    CurrencyFormatter.formatRupiahWithPrefix(produk.hargaProduk),
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(11),
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF59E0B),
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

  
  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: ResponsiveMobile.scaledFont(32),
            color: Colors.grey.shade400,
          ),
          SizedBox(height: ResponsiveMobile.scaledH(4)),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(10),
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // STATES
  // ============================================================================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B)),
            strokeWidth: 3,
          ),
          SizedBox(height: ResponsiveMobile.scaledH(16)),
          Text(
            'Memuat produk...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: ResponsiveMobile.scaledFont(14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                    ResponsiveMobile.scaledH(200), // Sesuaikan dengan tinggi header + filter
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(32)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(32)),
                decoration: BoxDecoration(
                  color: Color(0xFFF59E0B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchQuery.isNotEmpty || _filterStatus != 'semua'
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_outlined,
                  size: ResponsiveMobile.scaledFont(64),
                  color: Color(0xFFF59E0B),
                ),
              ),
              
                SizedBox(height: ResponsiveMobile.scaledH(24)),
              
                Text(
                  _searchQuery.isNotEmpty || _filterStatus != 'semua'
                      ? 'Tidak Ditemukan'
                      : 'Belum Ada Produk',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                SizedBox(height: ResponsiveMobile.scaledH(8)),
                
                Text(
                  _searchQuery.isNotEmpty || _filterStatus != 'semua'
                      ? 'Coba ubah filter atau kata kunci pencarian'
                      : 'Mulai jualan dengan menambahkan produk pertama Anda',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(14),
                    color: Colors.grey.shade600,
                    height: 1.5,
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

  Widget _buildNoTokoState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF59E0B).withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(32)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveMobile.scaledW(40)),
                  decoration: BoxDecoration(
                    color: Color(0xFFF59E0B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store_outlined,
                    size: ResponsiveMobile.scaledFont(80),
                    color: Color(0xFFF59E0B),
                  ),
                ),
                
                SizedBox(height: ResponsiveMobile.scaledH(32)),
                
                Text(
                  'Toko Belum Dibuat',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(24),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                SizedBox(height: ResponsiveMobile.scaledH(12)),
                
                Text(
                  'Buat toko terlebih dahulu untuk mulai\nmengelola dan menjual produk Anda',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(14),
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: ResponsiveMobile.scaledH(32)),
                
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/umkm/setup-toko'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.scaledW(28),
                      vertical: ResponsiveMobile.scaledH(16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.store_rounded, size: ResponsiveMobile.scaledFont(24)),
                  label: Text(
                    'Setup Toko Sekarang',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // BOTTOM SHEET & ACTIONS
  // ============================================================================

  void _showQuickActionsBottomSheet(ProdukModel produk) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ResponsiveMobile.scaledR(24)),
            topRight: Radius.circular(ResponsiveMobile.scaledR(24)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: ResponsiveMobile.scaledH(12)),
                width: ResponsiveMobile.scaledW(40),
                height: ResponsiveMobile.scaledH(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(2)),
                ),
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(20)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                      child: produk.fotoProduk != null && produk.fotoProduk!.isNotEmpty
                          ? Image.network(
                              produk.fotoProduk!.first,
                              width: ResponsiveMobile.scaledW(60),
                              height: ResponsiveMobile.scaledW(60),
                              fit: BoxFit.cover,
                            )
                          : _buildImagePlaceholder(),
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produk.namaProduk,
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledFont(15),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: ResponsiveMobile.scaledH(4)),
                          Text(
                            produk.hargaFormatted,
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledFont(13),
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              
              _buildActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit Produk',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditProduk(produk);
                },
              ),
              
              _buildActionTile(
                icon: produk.isAvailable ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                label: produk.isAvailable ? 'Nonaktifkan Produk' : 'Aktifkan Produk',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _toggleProdukStatus(produk);
                },
              ),
              
              _buildActionTile(
                icon: Icons.content_copy_outlined,
                label: 'Duplikat Produk',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _duplicateProduk(produk);
                },
              ),
              
              Divider(height: 1, color: Colors.grey.shade200),
              
              _buildActionTile(
                icon: Icons.delete_outline,
                label: 'Hapus Produk',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _deleteProduk(produk);
                },
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveMobile.scaledW(20),
            vertical: ResponsiveMobile.scaledH(14),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(10)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveMobile.scaledFont(22),
                ),
              ),
              SizedBox(width: ResponsiveMobile.scaledW(14)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: ResponsiveMobile.scaledFont(16),
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // NAVIGATION & ACTIONS
  // ============================================================================

  Future<void> _navigateToAddProduk() async {
    if (_idUmkm == null) {
      _showError('Toko belum di-setup');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditProdukScreen()),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToEditProduk(ProdukModel produk) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditProdukScreen(produk: produk)),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _toggleProdukStatus(ProdukModel produk) async {
    final newStatus = !produk.isAvailable;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: ResponsiveMobile.scaledW(20),
              height: ResponsiveMobile.scaledW(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            SizedBox(width: ResponsiveMobile.scaledW(12)),
            Text('Memproses...'),
          ],
        ),
        duration: Duration(seconds: 30),
        backgroundColor: Colors.blue.shade700,
      ),
    );

    final success = await _umkmService.toggleProdukAktif(
      produk.idProduk,
      newStatus,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newStatus ? Icons.check_circle : Icons.visibility_off,
                color: Colors.white,
              ),
              SizedBox(width: ResponsiveMobile.scaledW(12)),
              Expanded(
                child: Text(newStatus ? '✅ Produk diaktifkan' : '⏸️ Produk dinonaktifkan'),
              ),
            ],
          ),
          backgroundColor: newStatus ? Colors.green.shade600 : Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
          ),
        ),
      );

      _loadData();
    } else {
      _showError('Gagal mengubah status produk');
    }
  }

  Future<void> _duplicateProduk(ProdukModel produk) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        title: Row(
          children: [
            Icon(Icons.content_copy, color: Colors.purple.shade600),
            SizedBox(width: ResponsiveMobile.scaledW(8)),
            Text('Duplikat Produk?'),
          ],
        ),
        content: Text(
          'Produk "${produk.namaProduk}" akan diduplikat dengan nama "Copy - ${produk.namaProduk}"',
          style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text('Duplikat'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.purple.shade600),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(16)),
              Text(
                'Menduplikat produk...',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      if (_idUmkm == null) throw Exception('Toko tidak ditemukan');

      final newProduk = await _umkmService.addProduk(
        idUmkm: _idUmkm!,
        namaProduk: 'Copy - ${produk.namaProduk}',
        deskripsiProduk: produk.deskripsiProduk,
        hargaProduk: produk.hargaProduk,
        stokProduk: produk.stok,
        kategoriProduk: produk.kategoriProduk,
        fotoProduk: produk.fotoProduk ?? [],
        beratGram: produk.beratGram,
        waktuPersiapanMenit: produk.waktuPersiapanMenit,
      );

      if (mounted) Navigator.pop(context);

      if (newProduk != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Produk berhasil diduplikat'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
            ),
          ),
        );

        _loadData();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError('Gagal menduplikat produk: $e');
    }
  }

  Future<void> _deleteProduk(ProdukModel produk) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            SizedBox(width: ResponsiveMobile.scaledW(8)),
            Text('Hapus Produk?'),
          ],
        ),
        content: Text(
          'Produk "${produk.namaProduk}" akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      if (produk.fotoProduk != null && produk.fotoProduk!.isNotEmpty) {
        await _storageService.deleteMultipleProductPhotos(produk.fotoProduk!);
      }

      final success = await _umkmService.deleteProduk(produk.idProduk);

      if (mounted) Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Produk berhasil dihapus'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
            ),
          ),
        );

        _loadData();
      } else {
        _showError('Gagal menghapus produk');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: ResponsiveMobile.scaledW(12)),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        ),
      ),
    );
  }
}