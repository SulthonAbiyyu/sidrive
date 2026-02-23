// lib/widgets/wallet_display_widget.dart
// ============================================================================
// WALLET DISPLAY WIDGET - FIXED VERSION
// ✅ Top Up button di samping saldo (fix overflow)
// ✅ Riwayat & Tarik di bawah (2 button balance)
// ✅ Warna berbeda per role: Customer=Biru, Driver=Hijau, UMKM=Orange
// ✅ Design premium ala mobile banking
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';

class WalletDisplayWidget extends StatefulWidget {
  final double balance;
  final String userRole; // ✅ TAMBAHAN: 'customer', 'driver', 'umkm'
  final VoidCallback? onTapTopUp;
  final VoidCallback? onTapHistory;
  final VoidCallback? onTapWithdraw;

  const WalletDisplayWidget({
    Key? key,
    required this.balance,
    this.userRole = 'customer', 
    this.onTapTopUp,
    this.onTapHistory,
    this.onTapWithdraw,
  }) : super(key: key);

  @override
  State<WalletDisplayWidget> createState() => _WalletDisplayWidgetState();
}

class _WalletDisplayWidgetState extends State<WalletDisplayWidget>
    with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = true;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
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

  // ✅ WARNA BERDASARKAN ROLE
  List<Color> _getGradientColors() {
    switch (widget.userRole.toLowerCase()) {
      case 'driver':
        return [Color(0xFF10B981), Color(0xFF059669)]; // Hijau
      case 'umkm':
        return [Color(0xFFF59E0B), Color(0xFFD97706)]; // Orange
      default: // customer
        return [Color(0xFF3B82F6), Color(0xFF2563EB)]; // Biru
    }
  }

  Color _getAccentColor() {
    switch (widget.userRole.toLowerCase()) {
      case 'driver':
        return Color(0xFF10B981);
      case 'umkm':
        return Color(0xFFF59E0B);
      default:
        return Color(0xFF3B82F6);
    }
  }

  IconData _getRoleIcon() {
    switch (widget.userRole.toLowerCase()) {
      case 'driver':
        return Icons.local_shipping_rounded;
      case 'umkm':
        return Icons.store_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
            boxShadow: [
              BoxShadow(
                color: _getAccentColor().withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getGradientColors(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // ✅ Background Pattern (lebih elegan)
                  Positioned(
                    right: -60,
                    top: -60,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        ResponsiveMobile.vSpace(16),
                        _buildBalanceSection(),
                        ResponsiveMobile.vSpace(20),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(10)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getRoleIcon(),
                color: Colors.white,
                size: ResponsiveMobile.scaledW(22),
              ),
            ),
            ResponsiveMobile.hSpace(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Wallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveMobile.scaledSP(14),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  _getRoleLabel(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: ResponsiveMobile.scaledSP(11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isBalanceVisible = !_isBalanceVisible;
            });
          },
          child: Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
            ),
            child: Icon(
              _isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.white,
              size: ResponsiveMobile.scaledW(20),
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleLabel() {
    switch (widget.userRole.toLowerCase()) {
      case 'driver':
        return 'Driver Account';
      case 'umkm':
        return 'UMKM Account';
      default:
        return 'Customer Account';
    }
  }

  Widget _buildBalanceSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Saldo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Saldo',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: ResponsiveMobile.scaledSP(13),
                  fontWeight: FontWeight.w500,
                ),
              ),
              ResponsiveMobile.vSpace(6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _isBalanceVisible
                      ? CurrencyFormatter.format(widget.balance)
                      : '••••••••',
                  key: ValueKey(_isBalanceVisible),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveMobile.scaledSP(28),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ✅ TOP UP BUTTON (PINDAH KE SAMPING SALDO)
        if (widget.onTapTopUp != null)
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTapTopUp!();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(16),
                vertical: ResponsiveMobile.scaledH(10),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle,
                    color: _getAccentColor(),
                    size: ResponsiveMobile.scaledW(20),
                  ),
                  ResponsiveMobile.hSpace(6),
                  Text(
                    'Top Up',
                    style: TextStyle(
                      color: _getAccentColor(),
                      fontSize: ResponsiveMobile.scaledSP(13),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        // ✅ RIWAYAT BUTTON
        if (widget.onTapHistory != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.history_rounded,
              label: 'Riwayat',
              onTap: widget.onTapHistory!,
            ),
          ),
        
        if (widget.onTapHistory != null && widget.onTapWithdraw != null)
          ResponsiveMobile.hSpace(10),
        
        // ✅ TARIK SALDO BUTTON
        if (widget.onTapWithdraw != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.account_balance_rounded,
              label: 'Tarik Saldo',
              onTap: widget.onTapWithdraw!,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.scaledW(12),
          vertical: ResponsiveMobile.scaledH(12),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: ResponsiveMobile.scaledW(18),
            ),
            ResponsiveMobile.hSpace(8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveMobile.scaledSP(13),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// COMPACT WALLET WIDGET (JUGA DIUPDATE WARNA)
// ============================================================================
class CompactWalletWidget extends StatelessWidget {
  final double balance;
  final String userRole;
  final VoidCallback? onTap;

  const CompactWalletWidget({
    Key? key,
    required this.balance,
    required this.userRole,
    this.onTap,
  }) : super(key: key);

  List<Color> _getGradientColors() {
    switch (userRole.toLowerCase()) {
      case 'driver':
        return [Color(0xFF10B981), Color(0xFF059669)];
      case 'umkm':
        return [Color(0xFFF59E0B), Color(0xFFD97706)];
      default:
        return [Color(0xFF3B82F6), Color(0xFF2563EB)];
    }
  }

  Color _getAccentColor() {
    switch (userRole.toLowerCase()) {
      case 'driver':
        return Color(0xFF10B981);
      case 'umkm':
        return Color(0xFFF59E0B);
      default:
        return Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.scaledW(16),
          vertical: ResponsiveMobile.scaledH(12),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
          boxShadow: [
            BoxShadow(
              color: _getAccentColor().withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: ResponsiveMobile.scaledW(18),
              ),
            ),
            ResponsiveMobile.hSpace(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Wallet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: ResponsiveMobile.scaledSP(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveMobile.scaledSP(18),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: ResponsiveMobile.scaledW(16),
            ),
          ],
        ),
      ),
    );
  }
}