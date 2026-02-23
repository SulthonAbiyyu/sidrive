// ============================================================================
// USER_CARD.DART - REDESIGNED V3 dengan Menu Hapus yang Aman
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/models/user_detail_model.dart';
import 'package:sidrive/providers/user_provider.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'package:intl/intl.dart';
import 'user_role_badge.dart';
import 'customer_detail_screen.dart';
import 'driver_detail_screen.dart';
import 'umkm_detail_screen.dart';

class UserCard extends StatelessWidget {
  final UserDetailModel user;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  void _navigateToRoleDetail(BuildContext context, String role) {
    Widget screen;
    
    switch (role) {
      case 'customer':
        screen = CustomerDetailScreen(user: user);
        break;
      case 'driver':
        screen = DriverDetailScreen(user: user);
        break;
      case 'umkm':
        screen = UmkmDetailScreen(user: user);
        break;
      default:
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Column(
        children: [
          // BAGIAN ATAS: Menu (kiri atas) + Foto (kiri tengah) + Info (kanan tengah) + Wallet (kanan atas)
          // Expanded: profil section mengambil sisa ruang setelah badge+footer
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // MAIN CONTENT AREA — paddingTop 28 agar profil & nama tidak bertabrakan dengan titik tiga/wallet
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 36, 14, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // FOTO PROFILE (KIRI)
                      _buildAvatar(),

                      const SizedBox(width: 12),

                      // INFO (KANAN)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.user.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.user.nim,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 11, color: Color(0xFF9CA3AF)),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    user.user.noTelp.isNotEmpty ? user.user.noTelp : '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // MENU BUTTON (POJOK KIRI ATAS) — top: 4 naik sedikit
                Positioned(
                  top: 4,
                  left: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: Color(0xFF374151),
                        ),
                      ),
                      color: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (value) => _handleMenuAction(context, value),
                      itemBuilder: (context) => [
                        // ═══════════════════════════════════════════════════
                        // BAGIAN 1: HAPUS USER (DANGER ZONE)
                        // ═══════════════════════════════════════════════════
                        PopupMenuItem(
                          value: 'delete_user',
                          height: 48,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.delete_forever_rounded,
                                    size: 20,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Hapus User',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                      Text(
                                        'Hapus semua data user',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF991B1B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ═══════════════════════════════════════════════════
                        // DIVIDER - Pemisah antara hapus user dan hapus role
                        // ═══════════════════════════════════════════════════
                        const PopupMenuDivider(height: 16),
                        
                        // LABEL SECTION - Hapus Role
                        const PopupMenuItem(
                          enabled: false,
                          height: 32,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'HAPUS ROLE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9CA3AF),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        // ═══════════════════════════════════════════════════
                        // BAGIAN 2: HAPUS ROLE SPESIFIK (Conditional)
                        // ═══════════════════════════════════════════════════
                        
                        // Hapus Role Customer
                        if (user.hasRole('customer'))
                          PopupMenuItem(
                            value: 'delete_role_customer',
                            height: 44,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 16,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Hapus Role Customer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Hapus Role Driver
                        if (user.hasRole('driver'))
                          PopupMenuItem(
                            value: 'delete_role_driver',
                            height: 44,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.motorcycle_outlined,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Hapus Role Driver',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Hapus Role UMKM
                        if (user.hasRole('umkm'))
                          PopupMenuItem(
                            value: 'delete_role_umkm',
                            height: 44,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.store_outlined,
                                    size: 16,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Hapus Role UMKM',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Jika tidak ada role yang bisa dihapus
                        if (!user.hasRole('customer') && !user.hasRole('driver') && !user.hasRole('umkm'))
                          const PopupMenuItem(
                            enabled: false,
                            height: 44,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Tidak ada role aktif',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // WALLET (POJOK KANAN ATAS)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          NumberFormat.compact(locale: 'id_ID').format(user.saldoWallet),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BAGIAN TENGAH BAWAH: Role Badges
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Column(
              children: [
                // LABEL PETUNJUK
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Klik role untuk melihat detail',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ROLE BADGES
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: user.roles
                      .where((r) => r.isActive)
                      .map((r) => Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _navigateToRoleDetail(context, r.role),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    UserRoleBadge(
                                      role: r.role,
                                      status: r.status,
                                      isCompact: false,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 12,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // FOOTER STATS
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(ResponsiveAdmin.radiusMD()),
                bottomRight: Radius.circular(ResponsiveAdmin.radiusMD()),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(Icons.shopping_bag_outlined, '${user.totalOrderSelesai}'),
                Container(width: 1, height: 20, color: Colors.grey[300]),
                _buildStatItem(Icons.local_shipping_outlined, '${user.jumlahPesananSelesaiDriver ?? 0}'),
                Container(width: 1, height: 20, color: Colors.grey[300]),
                _buildStatItem(Icons.store_outlined, '${user.jumlahProdukTerjual ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HANDLE MENU ACTIONS
  // ═══════════════════════════════════════════════════════════════════════
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'delete_user':
        _showDeleteUserConfirmation(context);
        break;
      case 'delete_role_customer':
        _showDeleteRoleConfirmation(context, 'customer', 'Customer', const Color(0xFF3B82F6));
        break;
      case 'delete_role_driver':
        _showDeleteRoleConfirmation(context, 'driver', 'Driver', const Color(0xFF10B981));
        break;
      case 'delete_role_umkm':
        _showDeleteRoleConfirmation(context, 'umkm', 'UMKM', const Color(0xFF8B5CF6));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DIALOG: DELETE USER (HIGH RISK)
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _showDeleteUserConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Hapus User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                    child: Text(
                      user.user.nama.isNotEmpty ? user.user.nama[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.user.nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          user.user.nim,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // WARNING CRITICAL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'PERINGATAN KRITIS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Menghapus user akan MENGHAPUS SEMUA data berikut:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildWarningItem('Semua role (Customer, Driver, UMKM)'),
                  _buildWarningItem('Riwayat transaksi & pesanan'),
                  _buildWarningItem('Data toko & produk UMKM'),
                  _buildWarningItem('Data kendaraan & pengiriman'),
                  _buildWarningItem('Saldo wallet & riwayat topup'),
                  _buildWarningItem('Rating & review'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.block_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'TINDAKAN INI TIDAK DAPAT DIBATALKAN!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ya, Hapus User',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await _performDeleteUser(context);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DIALOG: DELETE ROLE (MEDIUM RISK)
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _showDeleteRoleConfirmation(
    BuildContext context,
    String role,
    String roleLabel,
    Color roleColor,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: roleColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hapus Role $roleLabel',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menghapus role "$roleLabel" dari user ${user.user.nama}?',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data terkait role ini akan tetap ada, tetapi user tidak dapat mengakses fitur role ini lagi.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
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
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Ya, Hapus Role'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await _performDeleteRole(context, role, roleLabel);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PERFORM DELETE USER
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _performDeleteUser(BuildContext context) async {
    // Show loading dialog that cannot be dismissed
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Prevent back button dismiss
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menghapus user...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final provider = context.read<UserProvider>();
      await provider.deleteUser(userId: user.user.idUser);
      
      // ✅ CRITICAL: Close loading dialog on success
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User berhasil dihapus'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // ✅ CRITICAL: Close loading dialog on error too!
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus user: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PERFORM DELETE ROLE
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _performDeleteRole(BuildContext context, String role, String roleLabel) async {
    try {
      final provider = context.read<UserProvider>();
      await provider.deleteRole(userId: user.user.idUser, role: role);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role $roleLabel berhasil dihapus'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus role: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════
  
  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.close_rounded,
            color: Color(0xFFDC2626),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String val) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 5),
          Text(
            val,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: user.user.fotoProfil != null
            ? Image.network(
                user.user.fotoProfil!,
                fit: BoxFit.cover,
                cacheWidth: 150,
                cacheHeight: 150,
                errorBuilder: (ctx, _, __) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        user.user.nama.isNotEmpty ? user.user.nama[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6366F1),
        ),
      ),
    );
  }
}