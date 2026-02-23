// lib/pages/customer/home_customer_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui'; 

// Providers
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/providers/notifikasi_provider.dart';
import 'package:sidrive/providers/cart_provider.dart';

// Services
import 'package:sidrive/services/wallet_service.dart';
import 'package:sidrive/services/umkm_service.dart';

// Models
import 'package:sidrive/models/produk_model.dart';

// Utils & Widgets
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/core/widgets/wallet_display_widget.dart';
import 'package:sidrive/core/widgets/wallet_actions.dart';
import 'package:sidrive/screens/customer/pages/produk_detail_page.dart';

class HomeTab extends StatefulWidget {
  final Function(int)? onSwitchTab;

  const HomeTab({Key? key, this.onSwitchTab}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  // Services
  final WalletService _walletService = WalletService();
  final UmkmService _umkmService = UmkmService();

  // State Variables
  double _balance = 0.0;
  bool _isLoadingBalance = true;
  
  List<ProdukModel> _products = [];
  bool _isLoadingProducts = true;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // ✅ COLOR PALETTE (Customer Blue Theme)
  final Color _primaryBlue = const Color(0xFF2563EB); // Royal Blue
  final Color _bgGradientTop = const Color(0xFF1E40AF); // Deep Blue
  final Color _bgGradientBot = const Color(0xFF3B82F6); // Bright Blue

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadData();
  }

  void _initAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadBalance(),
      _loadProducts(),
    ]);
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId != null) {
        final balance = await _walletService.getBalance(userId);
        if (mounted) {
          setState(() {
            _balance = balance;
            _isLoadingBalance = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _umkmService.searchProduk(
        sortBy: 'created_at',
        ascending: false,
      );
      
      if (mounted) {
        setState(() {
          _products = products.take(12).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  // 🔥 ACTION HANDLERS
  void _showOjekSelectionDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
            child: Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pilih Kendaraan',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledSP(18),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  ResponsiveMobile.vSpace(16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVehicleOption(
                          icon: Icons.two_wheeler_rounded,
                          label: 'Motor',
                          color: Colors.green,
                          gradientColors: [Colors.green.shade400, Colors.green.shade600],
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/order/ojek', arguments: 'motor');
                          },
                        ),
                      ),
                      ResponsiveMobile.hSpace(16),
                      Expanded(
                        child: _buildVehicleOption(
                          icon: Icons.directions_car_rounded,
                          label: 'Mobil',
                          color: _primaryBlue,
                          gradientColors: [const Color(0xFF3B82F6), _primaryBlue],
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/order/ojek', arguments: 'mobil');
                          },
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
    );
  }

  Widget _buildVehicleOption({
    required IconData icon,
    required String label,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ResponsiveMobile.scaledH(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(10)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradientColors),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: Icon(icon, color: Colors.white, size: ResponsiveMobile.scaledW(24)),
            ),
            ResponsiveMobile.vSpace(8),
            Text(label, style: TextStyle(fontSize: ResponsiveMobile.scaledSP(13), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showTopUpBottomSheet() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopUpBottomSheet(
        userId: user.idUser,
        userName: user.nama,
        userEmail: user.email,
        userPhone: user.noTelp,
        onSuccess: (amount) => _loadBalance(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BACKGROUND (Blue Gradient)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgGradientTop, _bgGradientBot],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. MAIN LAYOUT
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // --- HEADER SECTION (Fixed, Natural Wallet Size) ---
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: ResponsiveMobile.horizontalPadding(context, 5).copyWith(
                      top: ResponsiveMobile.scaledH(8), 
                      bottom: ResponsiveMobile.scaledH(16), 
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Bar
                        _buildTopBar(context, user),

                        ResponsiveMobile.vSpace(16),

                        // Wallet Widget (✅ ORIGINAL SIZE / NO FORCED HEIGHT)
                        _isLoadingBalance
                            ? _buildLoadingWallet()
                            : WalletDisplayWidget(
                                balance: _balance,
                                onTapTopUp: _showTopUpBottomSheet,
                                onTapHistory: () => Navigator.pushNamed(context, '/wallet/history'),
                                onTapWithdraw: () {
                                  if (user != null) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => WithdrawBottomSheet(
                                        userId: user.idUser,
                                        currentBalance: _balance,
                                      ),
                                    );
                                  }
                                },
                              ),
                      ],
                    ),
                  ),
                ),

                // --- EXPANDED WHITE BODY ---
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(ResponsiveMobile.scaledR(24)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      color: _primaryBlue,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        // ✅ Padding atas minimal agar konten langsung terlihat
                        padding: EdgeInsets.fromLTRB(
                          0, 
                          ResponsiveMobile.scaledH(12), 
                          0, 
                          ResponsiveMobile.bottomSafeArea(context) + 20
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag Handle
                            Center(
                              child: Container(
                                width: ResponsiveMobile.scaledW(36),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            
                            ResponsiveMobile.vSpace(12),

                            // 🔹 LAYANAN / MENU CEPAT
                            Padding(
                              padding: ResponsiveMobile.horizontalPadding(context, 5),
                              child: Text(
                                'Layanan Utama',
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledSP(15), 
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            
                            ResponsiveMobile.vSpace(10), // Reduced gap
                            
                            // Grid Layanan
                            Padding(
                              padding: ResponsiveMobile.horizontalPadding(context, 5),
                              child: _buildServiceRow(),
                            ),

                            ResponsiveMobile.vSpace(20), // Reduced gap

                            // 🔹 REKOMENDASI PRODUK
                            Padding(
                              padding: ResponsiveMobile.horizontalPadding(context, 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rekomendasi',
                                    style: TextStyle(
                                      fontSize: ResponsiveMobile.scaledSP(15),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (widget.onSwitchTab != null) {
                                        widget.onSwitchTab!(1);
                                      } else {
                                        Navigator.pushNamed(context, '/main/umkm');
                                      }
                                    },
                                    child: Text(
                                      'Lihat Semua',
                                      style: TextStyle(
                                        fontSize: ResponsiveMobile.scaledSP(12),
                                        color: _primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            ResponsiveMobile.vSpace(10),

                            // Product Grid
                            Padding(
                              padding: ResponsiveMobile.horizontalPadding(context, 5),
                              child: _buildProductGrid(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildTopBar(BuildContext context, dynamic user) {
    // ✅ SMART FONT SIZING
    final String displayName = user?.nama ?? 'Pelanggan';
    final double nameFontSize = displayName.length > 20 
        ? ResponsiveMobile.scaledSP(16)  // Kecilkan jika > 20 huruf
        : ResponsiveMobile.scaledSP(20); // Normal

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang,',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: ResponsiveMobile.scaledSP(10),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: nameFontSize, 
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        
        // Notification Button (Glassmorphism & Fixed Badge Position)
        Consumer<NotifikasiProvider>(
          builder: (context, notifProvider, child) {
            final unreadCount = notifProvider.unreadCount;
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/notifikasi'),
              child: Container(
                width: ResponsiveMobile.scaledW(44),
                height: ResponsiveMobile.scaledW(44),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Icon(
                        Icons.notifications_outlined, 
                        color: Colors.white, 
                        size: ResponsiveMobile.scaledW(24)
                      ),
                    ),
                    // ✅ BADGE POSITION FIX (Digeser ke kanan atas)
                    if (unreadCount > 0)
                      Positioned(
                        top: 2,    
                        right: 2,  
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 10,
                            minHeight: 10,
                          ),
                          // Optional: Show count or just dot
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingWallet() {
    return Container(
      width: double.infinity,
      height: 160, 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  // Compact Service Row
  Widget _buildServiceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildServiceCard(
          icon: Icons.two_wheeler_rounded,
          title: 'Pesan\nOjek',
          color: _primaryBlue,
          onTap: _showOjekSelectionDialog,
        ),
        _buildServiceCard(
          icon: Icons.store_mall_directory_rounded,
          title: 'Belanja\nUMKM',
          color: Colors.orange,
          onTap: () {
            // ✅ NAVIGASI KE HALAMAN UMKM (Tab Index 1)
            if (widget.onSwitchTab != null) {
              widget.onSwitchTab!(1);
            } else {
              Navigator.pushNamed(context, '/main/umkm');
            }
          },
        ),
        _buildServiceCard(
          icon: Icons.restore_rounded,
          title: 'Riwayat\nRefund',
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, '/refund-history'),
        ),
        _buildServiceCard(
          icon: Icons.support_agent_rounded,
          title: 'Pusat\nBantuan',
          color: Colors.purple,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Ukuran dinamis namun lebih kecil (compact) agar muat
    final cardWidth = (ResponsiveMobile.screenWidth(context) - ResponsiveMobile.scaledW(80)) / 4;
    
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: cardWidth,
            height: cardWidth, 
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)), // Squircle
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                // ✅ ICON SIZE DIKECILKAN DIKIT UNTUK KOMPAK
                child: Icon(icon, color: color, size: ResponsiveMobile.scaledW(20)),
              ),
            ),
          ),
        ),
        ResponsiveMobile.vSpace(6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledSP(10), // Font kecil rapi
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: _primaryBlue),
      ));
    }

    if (_products.isEmpty) {
      return Container(
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade300),
            ResponsiveMobile.vSpace(8),
            Text('Belum ada produk', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: ResponsiveMobile.scaledW(10),
        mainAxisSpacing: ResponsiveMobile.scaledH(10),
        // ✅ Aspect Ratio 0.72 = Cards sedikit lebih pendek dari sebelumnya agar muat lebih banyak
        childAspectRatio: 0.72, 
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_products[index]);
      },
    );
  }

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
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(ResponsiveMobile.scaledR(12))),
                  child: AspectRatio(
                    aspectRatio: 1, // Tetap kotak agar rapi
                    child: produk.fotoProduk != null && produk.fotoProduk!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: produk.fotoProduk!.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey.shade50),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          )
                        : Container(color: Colors.grey.shade100, child: Icon(Icons.image, color: Colors.grey.shade300)),
                  ),
                ),
                if (isInCart)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: _primaryBlue, shape: BoxShape.circle),
                      child: const Icon(Icons.shopping_bag, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            
            // Info Area (Compact & Clean)
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      produk.namaProduk,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(11),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        height: 1.1,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              produk.ratingProduk.toStringAsFixed(1),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                            const Spacer(),
                            Text(
                              '${produk.totalTerjual} terjual',
                              style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        ResponsiveMobile.vSpace(2),
                        Text(
                          CurrencyFormatter.formatRupiahWithPrefix(produk.hargaProduk),
                          style: TextStyle(
                            fontSize: ResponsiveMobile.scaledSP(12),
                            fontWeight: FontWeight.w800,
                            color: _primaryBlue,
                          ),
                        ),
                      ],
                    )
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