// ============================================================================
// USER_ROLE_MANAGEMENT_DIALOG.DART - REDESIGNED
// Dialog untuk CRUD role user dengan UI/UX yang lebih baik
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/models/user_detail_model.dart';
import 'package:sidrive/providers/user_provider.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'user_role_badge.dart';

class UserRoleManagementDialog extends StatefulWidget {
  final UserDetailModel user;

  const UserRoleManagementDialog({
    super.key,
    required this.user,
  });

  @override
  State<UserRoleManagementDialog> createState() => _UserRoleManagementDialogState();
}

class _UserRoleManagementDialogState extends State<UserRoleManagementDialog> {
  bool _isProcessing = false;
  String? _selectedNewRole;

  final List<Map<String, dynamic>> _availableRoles = [
    {'value': 'customer', 'label': 'Customer', 'icon': Icons.shopping_bag_rounded, 'color': Color(0xFF3B82F6)},
    {'value': 'driver', 'label': 'Driver', 'icon': Icons.motorcycle_rounded, 'color': Color(0xFF10B981)},
    {'value': 'umkm', 'label': 'UMKM', 'icon': Icons.store_rounded, 'color': Color(0xFF8B5CF6)},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // ✅ PUTIH BUKAN HITAM!
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
      ),
      child: Container(
        width: 600, // ✅ DIPERBESAR dari 480
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentRoles(),
                    SizedBox(height: ResponsiveAdmin.spaceLG()),
                    _buildAddRole(),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ResponsiveAdmin.radiusMD()),
          topRight: Radius.circular(ResponsiveAdmin.radiusMD()),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.manage_accounts_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: ResponsiveAdmin.spaceSM()),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelola Role User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.user.nama,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 24, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRoles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.badge_outlined,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Role Saat Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveAdmin.spaceSM()),
        
        if (widget.user.roles.where((r) => r.isActive).isEmpty)
          Container(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: ResponsiveAdmin.spaceSM()),
                const Expanded(
                  child: Text(
                    'User belum memiliki role aktif',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...widget.user.roles.where((r) => r.isActive).map((role) {
            return Container(
              margin: EdgeInsets.only(bottom: ResponsiveAdmin.spaceSM()),
              padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  UserRoleBadge(role: role.role, status: role.status, isCompact: false),
                  const Spacer(),
                  if (role.status == 'pending_verification')
                    _buildRoleActions(role.role, showApprove: true)
                  else
                    _buildRoleActions(role.role, showApprove: false),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRoleActions(String role, {required bool showApprove}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showApprove) ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _updateRoleStatus(role, 'active'),
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Setujui'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _confirmRejectRole(role),
            icon: const Icon(Icons.cancel_rounded, size: 18),
            label: const Text('Tolak'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _confirmDeleteRole(role),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Hapus Role'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddRole() {
    final existingRoles = widget.user.roles.where((r) => r.isActive).map((r) => r.role).toList();
    final availableToAdd = _availableRoles.where((r) => !existingRoles.contains(r['value'])).toList();

    if (availableToAdd.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tambah Role Baru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveAdmin.spaceSM()),
        
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedNewRole,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Pilih role yang ingin ditambahkan...',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveAdmin.spaceSM(),
                      vertical: ResponsiveAdmin.spaceSM(),
                    ),
                    isDense: true,
                  ),
                  items: availableToAdd.map<DropdownMenuItem<String>>((role) {
                    return DropdownMenuItem(
                      value: role['value'],
                      child: Row(
                        children: [
                          Icon(role['icon'], size: 18, color: role['color']),
                          SizedBox(width: ResponsiveAdmin.spaceXS()),
                          Text(role['label']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedNewRole = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(width: ResponsiveAdmin.spaceSM()),
            ElevatedButton.icon(
              onPressed: _selectedNewRole != null && !_isProcessing ? () => _confirmAddRole() : null,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveAdmin.spaceMD(),
                  vertical: ResponsiveAdmin.spaceSM() + 2,
                ),
                minimumSize: const Size(0, 44),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONFIRMATION DIALOGS - IMPROVED
  // ═══════════════════════════════════════════════════════════════════════
  
  Future<void> _confirmAddRole() async {
    if (_selectedNewRole == null) return;
    
    final roleLabel = _availableRoles.firstWhere((r) => r['value'] == _selectedNewRole)['label'];
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tambah Role',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menambahkan role "$roleLabel" untuk user ini?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedNewRole == 'customer' 
                          ? 'Role Customer akan langsung aktif'
                          : 'Role ini akan memerlukan verifikasi',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
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
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Ya, Tambahkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _addRole();
    }
  }

  Future<void> _confirmDeleteRole(String role) async {
    final roleLabel = _availableRoles.firstWhere((r) => r['value'] == role)['label'];
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hapus Role',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menghapus role "$roleLabel" dari user ini?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tindakan ini tidak dapat dibatalkan!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
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
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteRole(role);
    }
  }

  Future<void> _confirmRejectRole(String role) async {
    final roleLabel = _availableRoles.firstWhere((r) => r['value'] == role)['label'];
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tolak Role',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Anda yakin ingin menolak role "$roleLabel" untuk user ini?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateRoleStatus(role, 'rejected');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // API CALLS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _updateRoleStatus(String role, String status) async {
    setState(() => _isProcessing = true);

    try {
      final provider = context.read<UserProvider>();
      await provider.updateRoleStatus(
        userId: widget.user.user.idUser,
        role: role,
        status: status,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status role berhasil diubah menjadi $status'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteRole(String role) async {
    setState(() => _isProcessing = true);

    try {
      final provider = context.read<UserProvider>();
      await provider.deleteRole(
        userId: widget.user.user.idUser,
        role: role,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role berhasil dihapus'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus role: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _addRole() async {
    if (_selectedNewRole == null) return;

    setState(() => _isProcessing = true);

    try {
      final provider = context.read<UserProvider>();
      await provider.addRole(
        userId: widget.user.user.idUser,
        role: _selectedNewRole!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role $_selectedNewRole berhasil ditambahkan'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah role: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}