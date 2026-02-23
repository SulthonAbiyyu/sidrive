// lib/pages/umkm/homepage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/widgets/wallet_display_widget.dart';
import 'package:sidrive/services/wallet_service.dart';
import 'package:sidrive/providers/notifikasi_provider.dart';
import 'package:sidrive/core/widgets/wallet_actions.dart';
import 'package:sidrive/services/umkm_service.dart';
import 'package:sidrive/models/umkm_model.dart';

class HomeUmkm extends StatefulWidget {
  const HomeUmkm({super.key});

  @override
  State<HomeUmkm> createState() => _HomeUmkmState();
}

class _HomeUmkmState extends State<HomeUmkm> with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  final UmkmService _umkmService = UmkmService();
  
  double _umkmBalance = 0.0;
  bool _isLoadingBalance = true;
  bool _isLoadingUmkm = true;
  UmkmModel? _umkmData;
  
  // ✅ NEW: Counter untuk pesanan dan produk
  int _activePesananCount = 0;
  int _totalProdukCount = 0;
  bool _isLoadingCounts = true;

  // Animation
  AnimationController? _animController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadBalance();
    _loadUmkmData();
  }

  void _initAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController!, curve: Curves.easeOut),
    );
    
    _animController!.forward();
  }

  void _ensureAnimationInitialized() {
    if (_animController == null) {
      _initAnimation();
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
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
            _umkmBalance = balance;
            _isLoadingBalance = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading UMKM balance: $e');
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _loadUmkmData() async {
    setState(() => _isLoadingUmkm = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId != null) {
        final umkm = await _umkmService.getUmkmByUserId(userId);
        if (mounted) {
          setState(() {
            _umkmData = umkm;
            _isLoadingUmkm = false;
          });
          
          // ✅ Load counts setelah umkm data berhasil dimuat
          if (umkm != null) {
            _loadCounts(umkm.idUmkm);
          }
        }
      }
    } catch (e) {
      print('❌ Error loading UMKM data: $e');
      if (mounted) setState(() => _isLoadingUmkm = false);
    }
  }

  Future<void> _loadCounts(String idUmkm) async {
    setState(() => _isLoadingCounts = true);
    
    try {
      final counts = await _umkmService.getDashboardCounts(idUmkm);
      
      if (mounted) {
        setState(() {
          _activePesananCount = counts['active_pesanan'] ?? 0;
          _totalProdukCount = counts['total_produk'] ?? 0;
          _isLoadingCounts = false;
        });
      }
      
      print('✅ Counts loaded - Pesanan: $_activePesananCount, Produk: $_totalProdukCount');
    } catch (e) {
      print('❌ Error loading counts: $e');
      if (mounted) setState(() => _isLoadingCounts = false);
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadBalance(),
      _loadUmkmData(),
    ]);
  }

  void _showTopUpBottomSheet() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User tidak ditemukan'), backgroundColor: Colors.red),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopUpBottomSheet( // Changed to TopUpBottomSheet directly
        userId: user.idUser,
        userName: user.nama,
        userEmail: user.email,
        userPhone: user.noTelp,
        onSuccess: (amount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Top up berhasil! Saldo bertambah Rp${amount.toStringAsFixed(0)}'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _loadBalance();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureAnimationInitialized(); // Ensure animation logic is safe
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final roleDetails = authProvider.getRoleDetails('umkm');
    final roleStatus = roleDetails?.status ?? 'unknown';
    final isPending = roleStatus == 'pending_verification';
    final isRejected = roleStatus == 'rejected';
    final isApproved = roleStatus == 'active';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BACKGROUND (Static Full Screen Orange)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)], 
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. LAYOUT
          FadeTransition(
            opacity: _fadeAnimation!,
            child: Column(
              children: [
                // --- FIXED HEADER ---
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Bar
                       _buildTopBar(context, user),

                        SizedBox(height: 16),

                        // Wallet Widget (Fixed)
                        _isLoadingBalance
                            ? _buildLoadingWallet()
                            : WalletDisplayWidget(
                                balance: _umkmBalance,
                                userRole: 'umkm',
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
                                          currentBalance: _umkmBalance,
                                        ),
                                      );
                                   }
                                },
                              ),

                         SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // --- SCROLLABLE BODY ---
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))]
                    ),
                    child: RefreshIndicator(
                      onRefresh: _refreshData,
                      color: const Color(0xFFF59E0B),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             // Drag Handle
                             Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                             SizedBox(height: 20),

                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  // ❌ PENDING BANNER
                                  if (isPending) _buildPendingBanner(context),
                                  if (isPending) ResponsiveMobile.vSpace(16),
                    
                                  // ❌ REJECTED BANNER
                                  if (isRejected) _buildRejectedBanner(context),
                                  if (isRejected) ResponsiveMobile.vSpace(16),
                    
                                  // ✅ SETUP TOKO BANNER
                                  if (isApproved && _umkmData == null && !_isLoadingUmkm)
                                    _buildSetupTokoBanner(context),
                                  if (isApproved && _umkmData == null && !_isLoadingUmkm)
                                    ResponsiveMobile.vSpace(16),

                                  // TOKO INFO (Jika sudah setup)
                                  if (_umkmData != null) ...[
                                    _buildTokoInfo(),
                                    ResponsiveMobile.vSpace(24),
                                  ],
                    
                                  // Quick Stats
                                  _buildQuickStats(),
                                ],
                              ),
                            ),
              
                            ResponsiveMobile.vSpace(32),
              
                            // Quick Actions Title
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Menu Cepat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
              
                            ResponsiveMobile.vSpace(16),
              
                            // Horizontal Actions List
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isApproved && _umkmData != null) ...[
                                    _buildMenuCard(
                                      icon: Icons.inventory_2_rounded,
                                      title: 'Produk',
                                      color: Colors.blue,
                                      onTap: () {
                                        Navigator.pushNamed(context, '/umkm/produk');
                                      },
                                    ),
                                    SizedBox(width: 16),
                                    _buildMenuCard(
                                      icon: Icons.store_rounded,
                                      title: 'Profil Toko',
                                      color: Colors.orange,
                                      onTap: () {
                                          Navigator.pushNamed(context, '/umkm/profil-toko')
                                            .then((_) => _loadUmkmData());
                                      },
                                    ),
                                    SizedBox(width: 16),
                                    _buildMenuCard(
                                      icon: Icons.insights_rounded,
                                      title: 'Laporan',
                                      color: Colors.purple,
                                      onTap: () {},
                                    ),
                                    SizedBox(width: 16),
                                    // ✅ UPDATED: Pesanan dengan badge
                                    _buildMenuCardWithBadge(
                                      icon: Icons.shopping_bag_rounded,
                                      title: 'Pesanan',
                                      color: Colors.red,
                                      badgeCount: _activePesananCount,
                                      onTap: () {
                                        Navigator.pushNamed(context, '/umkm/pesanan')
                                            .then((_) {
                                          // Refresh counts setelah kembali dari halaman pesanan
                                          if (_umkmData != null) {
                                            _loadCounts(_umkmData!.idUmkm);
                                          }
                                        });
                                      },
                                    ),
                                  ] else ...[
                                     _buildMenuCard(
                                      icon: Icons.store_outlined,
                                      title: 'Setup',
                                      color: Colors.green,
                                      onTap: () {
                                         Navigator.pushNamed(context, '/umkm/setup-toko')
                                            .then((result) {
                                          if (result == true) {
                                            _loadUmkmData();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                  
                                  if (isPending) ...[
                                     SizedBox(width: 16),
                                     _buildMenuCard(
                                      icon: Icons.upload_file,
                                      title: 'Dokumen',
                                      color: Colors.orange,
                                      onTap: () => Navigator.pushNamed(context, '/request/umkm'),
                                    ),
                                  ],

                                   SizedBox(width: 16),
                                   _buildMenuCard(
                                      icon: Icons.help_outline_rounded,
                                      title: 'Bantuan',
                                      color: Colors.teal,
                                      onTap: () {},
                                    ),
                                ],
                              ),
                            ),

                             SizedBox(height: 40),
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

  // --- SUB WIDGETS ---

  Widget _buildTopBar(BuildContext context, dynamic user) {
     return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // ✅ UPDATED: Auto perkecil nama jika terlalu panjang
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     'DASHBOARD UMKM',
                     style: TextStyle(
                       color: Colors.white.withOpacity(0.9),
                       fontSize: 12,
                       fontWeight: FontWeight.w600,
                       letterSpacing: 1.2,
                     ),
                   ),
                   SizedBox(height: 4),
                   LayoutBuilder(
                     builder: (context, constraints) {
                       final userName = user?.nama ?? 'Mitra UMKM';
                       final textSpan = TextSpan(
                         text: userName,
                         style: TextStyle(
                           fontSize: 24,
                           fontWeight: FontWeight.w800,
                           letterSpacing: -0.5,
                           color: Colors.white,
                         ),
                       );
                       
                       final textPainter = TextPainter(
                         text: textSpan,
                         maxLines: 1,
                         textDirection: TextDirection.ltr,
                       )..layout(maxWidth: constraints.maxWidth);
                       
                       final isOverflow = textPainter.didExceedMaxLines;
                       
                       return Text(
                         userName,
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: isOverflow ? 18 : 24,
                           fontWeight: FontWeight.w800,
                           letterSpacing: -0.5,
                           height: isOverflow ? 1.2 : null,
                         ),
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                       );
                     },
                   ),
                 ],
               ),
             ),
             SizedBox(width: 12),
             Consumer<NotifikasiProvider>(
                builder: (context, notifProvider, child) {
                  final unreadCount = notifProvider.unreadCount;
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notifikasi'),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.2),
                         shape: BoxShape.circle,
                         border: Border.all(color: Colors.white.withOpacity(0.3))
                      ),
                      child: Stack( // Notification content
                        clipBehavior: Clip.none,
                         children: [
                            Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                             if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5)
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                         ]
                      )
                    ),
                  );
                },
              ),
          ],
     );
  }

  Widget _buildTokoInfo() {
    if (_umkmData == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ UPDATED: Optimized auto resize for nama toko
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textSpan = TextSpan(
                          text: _umkmData!.namaToko,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                        
                        final textPainter = TextPainter(
                          text: textSpan,
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                        )..layout(maxWidth: constraints.maxWidth);
                        
                        final isOverflow = textPainter.didExceedMaxLines;
                        
                        return Text(
                          _umkmData!.namaToko,
                          style: TextStyle(
                            fontSize: isOverflow ? 15 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: isOverflow ? 1.2 : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _umkmData!.isBuka
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _umkmData!.isBuka ? 'BUKA' : 'TUTUP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _umkmData!.jamOperasional,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
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
            ],
          ),
          SizedBox(height: 20),
          Divider(height: 1, color: Colors.grey.shade200),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStat('⭐', _umkmData!.ratingToko.toStringAsFixed(1), 'Rating'),
              _buildContainerDivider(),
              _buildSimpleStat('📦', _umkmData!.jumlahProdukTerjual.toString(), 'Terjual'),
              _buildContainerDivider(),
              _buildSimpleStat('💬', _umkmData!.totalRating.toString(), 'Ulasan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContainerDivider() {
     return Container(height: 30, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildSimpleStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
        SizedBox(height: 4),
        Text('$emoji $label', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLoadingWallet() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  // ✅ UPDATED: Quick Stats dengan data real
  Widget _buildQuickStats() {
    final hasSetup = _umkmData != null;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'Pesanan',
            value: hasSetup 
                ? (_isLoadingCounts ? '...' : _activePesananCount.toString())
                : '-',
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Produk',
            value: hasSetup 
                ? (_isLoadingCounts ? '...' : _totalProdukCount.toString())
                : '-',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupTokoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
             padding: EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
             child: Icon(Icons.store_outlined, color: Colors.orange.shade700, size: 24)
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Akun Disetujui! 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 16)),
                SizedBox(height: 2),
                Text('Setup toko Anda agar bisa berjualan.', style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
              ],
            ),
          ),
           Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange.shade700),
        ],
      ),
    );
  }
   
  // EXISTING MENU CARD
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
       color: Colors.transparent,
       child: InkWell(
         onTap: onTap,
         borderRadius: BorderRadius.circular(20),
         child: Container(
           width: 85, // Fixed width for uniformity
           padding: EdgeInsets.symmetric(vertical: 16),
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Colors.grey.shade200),
             boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: Offset(0, 4)
                )
             ]
           ),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Container(
                 padding: EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: color.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(icon, color: color, size: 24),
               ),
               SizedBox(height: 12),
               Text(
                 title,
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 12,
                   fontWeight: FontWeight.bold,
                   color: Colors.black87,
                 ),
               ),
             ],
           ),
         ),
       ),
    );
  }

  // ✅ NEW: Menu card dengan badge untuk pesanan
  Widget _buildMenuCardWithBadge({
    required IconData icon,
    required String title,
    required Color color,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return Material(
       color: Colors.transparent,
       child: InkWell(
         onTap: onTap,
         borderRadius: BorderRadius.circular(20),
         child: Container(
           width: 85,
           padding: EdgeInsets.symmetric(vertical: 16),
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Colors.grey.shade200),
             boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: Offset(0, 4)
                )
             ]
           ),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Stack(
                 clipBehavior: Clip.none,
                 children: [
                   Container(
                     padding: EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: color.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(icon, color: color, size: 24),
                   ),
                   // ✅ Badge untuk pesanan masuk
                   if (badgeCount > 0)
                     Positioned(
                       right: -4,
                       top: -4,
                       child: Container(
                         padding: EdgeInsets.all(4),
                         constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                         decoration: BoxDecoration(
                           color: Colors.red,
                           shape: BoxShape.circle,
                           border: Border.all(color: Colors.white, width: 2)
                         ),
                         child: Text(
                           badgeCount > 9 ? '9+' : '$badgeCount',
                           style: TextStyle(
                             color: Colors.white, 
                             fontSize: 9, 
                             fontWeight: FontWeight.bold,
                             height: 1.0,
                           ),
                           textAlign: TextAlign.center,
                         ),
                       ),
                     ),
                 ],
               ),
               SizedBox(height: 12),
               Text(
                 title,
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 12,
                   fontWeight: FontWeight.bold,
                   color: Colors.black87,
                 ),
               ),
             ],
           ),
         ),
       ),
    );
  }

  Widget _buildPendingBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(child: Text('Akun sedang diverifikasi admin.', style: TextStyle(color: Colors.orange.shade900, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner(BuildContext context) {
     return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 12),
          Expanded(child: Text('Akun ditolak. Silakan hubungi admin.', style: TextStyle(color: Colors.red.shade900, fontSize: 12))),
        ],
      ),
    );
  }
}