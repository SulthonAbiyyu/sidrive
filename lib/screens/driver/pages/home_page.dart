import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/core/utils/time_helper.dart';
import 'package:sidrive/core/widgets/wallet_display_widget.dart';
import 'package:sidrive/services/wallet_service.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/notifikasi_provider.dart';
import 'package:sidrive/core/widgets/wallet_actions.dart';

class HomePage extends StatefulWidget {
  final bool isOnline;
  final VoidCallback onToggle;
  final Map<String, dynamic>? driverData;
  final int pesananCount;
  final VoidCallback? onRefreshData;

  const HomePage({
    Key? key,
    required this.isOnline,
    required this.onToggle,
    this.driverData,
    this.pesananCount = 0,
    this.onRefreshData,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final WalletService _walletService = WalletService();
  
  // State variables
  Map<String, dynamic>? _todayStats;
  bool _isLoadingStats = true;
  String _greeting = TimeHelper.getGreeting();
  double _driverBalance = 0.0;
  bool _isLoadingBalance = true;
  
  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  // Timer
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadTodayStats();
    _loadDriverBalance();
    _startGreetingTimer();
  }
  
  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverData != widget.driverData) {
      if (mounted) setState(() {});
    }
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

  void _startGreetingTimer() {
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final newGreeting = TimeHelper.getGreeting();
      if (mounted && newGreeting != _greeting) {
        setState(() {
          _greeting = newGreeting;
        });
      }
    });
  }

  Future<void> _loadDriverBalance() async {
    if (widget.driverData == null) return;
    
    setState(() => _isLoadingBalance = true);
    
    try {
      final userId = widget.driverData!['id_user'] as String?;
      if (userId != null) {
        final balance = await _walletService.getBalance(userId);
        if (mounted) {
          setState(() {
            _driverBalance = balance;
            _isLoadingBalance = false;
          });
        }
      }
    } catch (e) {
      print('Error loading driver balance: $e');
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _loadTodayStats() async {
    if (widget.driverData == null) return;
    
    setState(() => _isLoadingStats = true);
    
    try {
      final driverId = widget.driverData!['id_driver'] as String?;
      if (driverId == null) {
        setState(() => _isLoadingStats = false);
        return;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final response = await supabase
          .from('pengiriman')
          .select('*, pesanan!inner(*)')
          .eq('id_driver', driverId)
          .eq('status_pengiriman', 'selesai')
          .gte('waktu_selesai', startOfDay.toIso8601String())
          .lte('waktu_selesai', endOfDay.toIso8601String());

      int totalPesanan = response.length;
      double totalPendapatan = 0;
      double totalJarak = 0;

      for (var item in response) {
        final pesanan = item['pesanan'];
        if (pesanan != null) {
          final ongkir = pesanan['ongkir'] ?? 0;
          final jarak = pesanan['jarak_km'] ?? 0;
          
          totalPendapatan += ongkir is int ? ongkir.toDouble() : (ongkir as double);
          totalJarak += jarak is int ? jarak.toDouble() : (jarak as double);
        }
      }

      Duration onlineTime = Duration.zero;
      final lastUpdate = widget.driverData!['last_location_update'];
      if (lastUpdate != null && widget.isOnline) {
        final lastUpdateTime = DateTime.parse(lastUpdate);
        if (lastUpdateTime.isAfter(startOfDay)) {
          onlineTime = now.difference(lastUpdateTime);
        }
      }

      if (mounted) {
        setState(() {
          _todayStats = {
            'total_pesanan': totalPesanan,
            'total_pendapatan': totalPendapatan,
            'total_jarak': totalJarak,
            'online_time': onlineTime,
          };
          _isLoadingStats = false;
        });
      }

    } catch (e) {
      print('Error load stats: $e');
      if (mounted) {
        setState(() {
          _todayStats = {
            'total_pesanan': 0,
            'total_pendapatan': 0.0,
            'total_jarak': 0.0,
            'online_time': Duration.zero,
          };
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild key based on vehicle
    final activeVehicles = widget.driverData?['active_vehicles'] as List? ?? [];
    final vehicleKey = activeVehicles.isEmpty ? 'no-vehicle' : activeVehicles.first['id_kendaraan']?.toString() ?? 'unknown';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BACKGROUND (Static Full Screen)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF047857)], 
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. LAYOUT
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // --- FIXED HEADER ---
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Bar: Name & Toggle
                        _buildTopBar(context),
                        
                        SizedBox(height: 10), // Reduced from 16
                        
                        // Wallet Widget (Fixed)
                        _isLoadingBalance
                            ? _buildLoadingWallet()
                            : WalletDisplayWidget(
                                balance: _driverBalance,
                                userRole: 'driver',
                                onTapTopUp: () => _handleTopUp(context),
                                onTapHistory: () => Navigator.pushNamed(context, '/wallet/history'),
                                onTapWithdraw: () => _handleWithdraw(context),
                              ),
                        
                        SizedBox(height: 10), // Reduced from 20 to lift bottom sheet
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
                      key: ValueKey(vehicleKey),
                      onRefresh: () async {
                        await _loadTodayStats();
                        await _loadDriverBalance();
                      },
                      color: const Color(0xFF10B981),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveMobile.wp(context, 5),
                          vertical: 16, // Reduced from 24
                        ),
                        child: Column(
                          children: [
                             // Drag Handle
                             Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                             SizedBox(height: 12), // Reduced from 24

                             // Stats Row
                             SizedBox(
                               height: 70, 
                               child: _buildCompactStatsRow(context),
                             ),
                             
                             SizedBox(height: 10), // Reduced from 16

                             // Today Summary
                             _buildTodaySummaryCard(context),
                             
                             SizedBox(height: 10), // Reduced from 16
                             
                             // Quick Actions
                             SizedBox(
                               height: 70,
                               child: _buildQuickActions(context),
                             ),

                             // Extra space for bottom safe area
                             SizedBox(height: 20),
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
      )
    );
  }
  
  // --- SUB WIDGETS ---

  Widget _buildTopBar(BuildContext context) {
    final nama = widget.driverData?['nama'] as String? ?? 'Driver';
    
    // Vehicle Info
    final activeVehicles = widget.driverData?['active_vehicles'] as List? ?? [];
    final activeVehicleTypes = widget.driverData?['active_vehicle_types'] as List? ?? [];
    String vehicleInfo = 'Belum ada kendaraan aktif';
    IconData vehicleIcon = Icons.directions_car;

    if (activeVehicles.isNotEmpty) {
      if (activeVehicles.length == 1) {
        final vehicle = activeVehicles.first;
        final jenis = vehicle['jenis_kendaraan']?.toString().toUpperCase() ?? 'MOTOR';
        final plat = vehicle['plat_nomor']?.toString() ?? '';
        vehicleInfo = plat.isNotEmpty ? '$jenis - $plat' : jenis;
        vehicleIcon = jenis == 'MOTOR' ? Icons.two_wheeler : Icons.directions_car;
      } else {
        final types = activeVehicleTypes.map((t) => t.toString().toUpperCase()).join(' + ');
        vehicleInfo = types.isNotEmpty ? types : 'Multi Kendaraan';
        vehicleIcon = Icons.commute;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min, 
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Name & Vehicle (Stylish)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: ResponsiveMobile.scaledSP(12),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        nama,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveMobile.scaledSP(24),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      
                      // Modern Vehicle Badge (Glassmorphism)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(vehicleIcon, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                vehicleInfo,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right: Modern Toggle & Notif
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Modern Toggle Button
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.isOnline ? Colors.white : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.isOnline ? Color(0xFF00880F) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.isOnline ? 'ONLINE' : 'OFF',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isOnline ? Colors.white : Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                             Container(
                               height: 24,
                               width: 24,
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: widget.isOnline ? Color(0xFF00880F) : Colors.white,
                                 boxShadow: [
                                   if (!widget.isOnline)
                                     BoxShadow(
                                       color: Colors.black12,
                                       blurRadius: 4,
                                     )
                                 ]
                               ),
                               child: Icon(
                                 widget.isOnline ? Icons.power_settings_new : Icons.power_off,
                                 size: 14,
                                 color: widget.isOnline ? Colors.white : Colors.grey,
                               ),
                             ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                     Consumer<NotifikasiProvider>(
                    builder: (context, notifProvider, child) {
                      final unreadCount = notifProvider.unreadCount;
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/notifikasi'),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                               padding: EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.2),
                                 shape: BoxShape.circle,
                               ),
                               child: Icon(Icons.notifications_outlined, color: Colors.white, size: 20)
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF00880F), width: 1.5)
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingWallet() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  // Helper for TopUp
  void _handleTopUp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DriverTopUpChoiceBottomSheet(
        userId: widget.driverData!['id_user'],
        userName: widget.driverData!['nama'] ?? 'Driver',
        userEmail: widget.driverData!['email'] ?? '',
        userPhone: widget.driverData!['no_telp'] ?? '',
        driverId: widget.driverData!['id_driver'],
        onSuccess: (amount) {
          _loadDriverBalance();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Top up berhasil!'), backgroundColor: Color(0xFF00880F)),
          );
        },
      ),
    );
  }

  // Helper for Withdraw
  void _handleWithdraw(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WithdrawBottomSheet(
        userId: widget.driverData!['id_user'],
        currentBalance: _driverBalance,
      ),
    );
  }

  Widget _buildCompactStatsRow(BuildContext context) {
    final cashOrderCount = widget.driverData?['jumlah_order_belum_setor'] ?? 0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: _buildMiniStatCard(
            icon: Icons.shopping_bag_outlined,
            label: 'Order Aktif',
            value: '${widget.pesananCount}',
            color: Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: _buildCompactCashOrderCard(cashOrderCount),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: 8),
              Expanded(
                 child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.black87
                      ),
                    ),
                 ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCashOrderCard(int cashOrderCount) {
    Color statusColor;
    String statusText;
    
    if (cashOrderCount < 3) {
      statusColor = const Color(0xFF00880F);
      statusText = 'Aman';
    } else if (cashOrderCount < 5) {
      statusColor = Colors.orange;
      statusText = 'Limit';
    } else {
      statusColor = Colors.red;
      statusText = 'Penuh!';
    }

    return Container(
       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Rounded
        border: Border.all(color: statusColor.withOpacity(0.3)),
         boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            radius: 18,
            child: Icon(Icons.payments_outlined, color: statusColor, size: 18),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cash Limit ($cashOrderCount/5)', 
                   style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  statusText, 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryCard(BuildContext context) {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_todayStats == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.grey[700], size: 18),
              SizedBox(width: 8),
              Text(
                'Performa Hari Ini',
                style: TextStyle(
                  fontSize: 13, // Slightly smaller
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Pendapatan',
                CurrencyFormatter.formatCompact(_todayStats!['total_pendapatan']),
                const Color(0xFF00880F),
              ),
              _buildVerticalDivider(),
              _buildSummaryItem(
                'Selesai',
                '${_todayStats!['total_pesanan']}',
                Colors.blue,
              ),
              _buildVerticalDivider(),
              _buildSummaryItem(
                'Online',
                TimeHelper.formatDuration(_todayStats!['online_time']),
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.shade300,
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            context, 
            icon: Icons.history, 
            label: 'Riwayat', 
            onTap: () => Navigator.pushNamed(context, '/history')
          )
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildActionBtn(
            context, 
            icon: Icons.bar_chart, 
            label: 'Performa', 
            onTap: () => Navigator.pushNamed(context, '/performance')
          )
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildActionBtn(
            context, 
            icon: Icons.help_outline, 
            label: 'Bantuan', 
            onTap: () {}
          )
        ),
      ],
    );
  }
  
  Widget _buildActionBtn(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00880F), size: 22),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}