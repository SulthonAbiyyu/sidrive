import 'package:flutter/material.dart';
import 'package:provider/provider.dart';        
import 'package:sidrive/providers/admin_provider.dart'; 

class ModernSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onMenuTap;
  final String adminName;
  final String? adminAvatar;
  final ValueNotifier<double> sidebarWidthNotifier;

  const ModernSidebar({
    super.key,
    required this.selectedIndex,
    required this.onMenuTap,
    required this.adminName,
    this.adminAvatar,
    required this.sidebarWidthNotifier,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _avatarSizeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    _widthAnimation = Tween<double>(
      begin: 80,
      end: 280,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ))..addListener(() {
      widget.sidebarWidthNotifier.value = _widthAnimation.value;
    });

    _avatarSizeAnimation = Tween<double>(
      begin: 20,
      end: 24,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Sidebar Container
            Positioned(
              left: 16,
              top: 16,
              bottom: 16,
              child: Container(
                width: _widthAnimation.value,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ✅ Logo dihapus - Menu dimulai dari atas
                    // Menu Items langsung dari atas
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildMenuItems(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Admin Avatar (tetap di bawah)
                    _buildAdminAvatar(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Expand/Collapse Button
            Positioned(
              left: _widthAnimation.value + 16,
              top: MediaQuery.of(context).size.height / 2 - 28,
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  width: 28,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isExpanded 
                        ? Icons.chevron_left_rounded 
                        : Icons.chevron_right_rounded,
                    color: const Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItems() {
    // ✅ listen: true agar badge otomatis update saat provider notify
    final adminProvider = Provider.of<AdminProvider>(context, listen: true);
    final isSuperAdmin = adminProvider.currentAdmin?.level == 'super_admin';

    // ── Badge dinamis dari AdminProvider ─────────────────────────────────────
    final driverBadge     = adminProvider.pendingDrivers.length;
    final umkmBadge       = adminProvider.pendingUmkm.length;
    final penarikanBadge  = adminProvider.pendingPenarikan.length;
    final settlementBadge = adminProvider.pendingSettlements.length;
    final refundBadge     = adminProvider.pendingRefundCount;
    final ktmBadge        = adminProvider.pendingKtmVerifications.length;
    // ✅ Badge CS Chat - update realtime dari CsChatAdminContent via AdminProvider
    final csChatBadge     = adminProvider.csChatUnreadCount;
    // ─────────────────────────────────────────────────────────────────────────
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 0: Statistik
        _buildMenuItem(Icons.bar_chart_rounded, 'Statistik', 0),

        // 1: Live Chat CS - badge unread dari customer
        _buildMenuItem(
          Icons.headset_mic_rounded,
          'Live Chat CS',
          1,
          badge: csChatBadge > 0 ? csChatBadge : null,
        ),

        // 2: Admin (HANYA SUPER_ADMIN)
        if (isSuperAdmin)
          _buildMenuItem(Icons.admin_panel_settings_rounded, 'Admin', 2),

        // 3 / 2: Mahasiswa
        _buildMenuItem(
          Icons.school_rounded,
          'Mahasiswa',
          isSuperAdmin ? 3 : 2,
        ),

        // 4 / 3: Kelola User
        _buildMenuItem(
          Icons.groups_rounded,
          'Kelola User',
          isSuperAdmin ? 4 : 3,
        ),

        // 5 / 4: Kelola Tarif
        _buildMenuItem(
          Icons.local_atm_rounded,
          'Kelola Tarif',
          isSuperAdmin ? 5 : 4,
        ),

        // 6 / 5: KTM Verification
        _buildMenuItem(
          Icons.badge_outlined,
          'KTM Verification',
          isSuperAdmin ? 6 : 5,
          badge: ktmBadge > 0 ? ktmBadge : null,
        ),

        // 7 / 6: Driver
        _buildMenuItem(
          Icons.two_wheeler_rounded,
          'Driver',
          isSuperAdmin ? 7 : 6,
          badge: driverBadge > 0 ? driverBadge : null,
        ),

        // 8 / 7: UMKM
        _buildMenuItem(
          Icons.storefront_rounded,
          'UMKM',
          isSuperAdmin ? 8 : 7,
          badge: umkmBadge > 0 ? umkmBadge : null,
        ),

        // 9 / 8: Penarikan
        _buildMenuItem(
          Icons.account_balance_wallet_rounded,
          'Penarikan',
          isSuperAdmin ? 9 : 8,
          badge: penarikanBadge > 0 ? penarikanBadge : null,
        ),

        // 10 / 9: Settlement
        _buildMenuItem(
          Icons.payments_rounded,
          'Settlement',
          isSuperAdmin ? 10 : 9,
          badge: settlementBadge > 0 ? settlementBadge : null,
        ),

        // 11 / 10: Refund
        _buildMenuItem(
          Icons.replay_rounded,
          'Refund',
          isSuperAdmin ? 11 : 10,
          badge: refundBadge > 0 ? refundBadge : null,
        ),

        // 12 / 11: Pengaturan
        _buildMenuItem(
          Icons.settings_rounded,
          'Pengaturan',
          isSuperAdmin ? 12 : 11,
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index, {int? badge}) {
    final isSelected = widget.selectedIndex == index;
    // Text hanya muncul ketika animasi sudah 70% selesai
    final showText = _animationController.value > 0.7;
    final textOpacity = ((_animationController.value - 0.7) / 0.3).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onMenuTap(index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF6366F1).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Icon with Badge
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        color: isSelected 
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF6B7280),
                        size: 22,
                      ),
                      if (badge != null && badge > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              badge > 9 ? '9+' : badge.toString(),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Label - hanya muncul ketika animasi hampir selesai
                if (showText) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Opacity(
                      opacity: textOpacity,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected 
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF374151),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
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

  Widget _buildAdminAvatar() {
    return CircleAvatar(
      radius: _avatarSizeAnimation.value,
      backgroundImage: widget.adminAvatar != null 
          ? NetworkImage(widget.adminAvatar!) 
          : null,
      backgroundColor: const Color(0xFFF3F4F6),
      child: widget.adminAvatar == null
          ? Icon(
              Icons.person_rounded,
              color: const Color(0xFF6B7280),
              size: _avatarSizeAnimation.value * 1.2,
            )
          : null,
    );
  }
}