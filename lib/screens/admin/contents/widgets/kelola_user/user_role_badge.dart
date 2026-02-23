// ============================================================================
// USER_ROLE_BADGE.DART
// Badge untuk menampilkan role user dengan status (active/pending/rejected)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class UserRoleBadge extends StatelessWidget {
  final String role;
  final String status;
  final bool isCompact;

  const UserRoleBadge({
    super.key,
    required this.role,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getRoleConfig(role, status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveAdmin.spaceXS() + (isCompact ? 2 : 4),
        vertical: ResponsiveAdmin.spaceXS() - (isCompact ? 1 : 0),
      ),
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS() + 2),
        border: status == 'pending_verification'
            ? Border.all(color: config['borderColor'], width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'],
            size: isCompact ? 10 : 12,
            color: config['textColor'],
          ),
          if (!isCompact) ...[
            SizedBox(width: ResponsiveAdmin.spaceXS() - 2),
            Text(
              config['label'],
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontSmall() - (isCompact ? 2 : 1),
                fontWeight: FontWeight.w600,
                color: config['textColor'],
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getRoleConfig(String role, String status) {
    // Define base colors per role
    final Map<String, Map<String, dynamic>> roleColors = {
      'customer': {
        'icon': Icons.shopping_bag_rounded,
        'label': 'Customer',
        'activeColor': const Color(0xFF3B82F6),
        'activeBg': const Color(0xFFDBEAFE),
        'pendingColor': const Color(0xFF6B7280),
        'pendingBg': const Color(0xFFF3F4F6),
        'rejectedColor': const Color(0xFFDC2626),
        'rejectedBg': const Color(0xFFFEE2E2),
      },
      'driver': {
        'icon': Icons.directions_bike_rounded,
        'label': 'Driver',
        'activeColor': const Color(0xFF10B981),
        'activeBg': const Color(0xFFD1FAE5),
        'pendingColor': const Color(0xFFF59E0B),
        'pendingBg': const Color(0xFFFEF3C7),
        'rejectedColor': const Color(0xFFDC2626),
        'rejectedBg': const Color(0xFFFEE2E2),
      },
      'umkm': {
        'icon': Icons.store_rounded,
        'label': 'UMKM',
        'activeColor': const Color(0xFF8B5CF6),
        'activeBg': const Color(0xFFEDE9FE),
        'pendingColor': const Color(0xFFF59E0B),
        'pendingBg': const Color(0xFFFEF3C7),
        'rejectedColor': const Color(0xFFDC2626),
        'rejectedBg': const Color(0xFFFEE2E2),
      },
    };

    final roleConfig = roleColors[role] ?? roleColors['customer']!;

    switch (status) {
      case 'active':
        return {
          'icon': roleConfig['icon'],
          'label': roleConfig['label'],
          'bgColor': roleConfig['activeBg'],
          'textColor': roleConfig['activeColor'],
          'borderColor': roleConfig['activeColor'],
        };
      case 'pending_verification':
        return {
          'icon': roleConfig['icon'],
          'label': '${roleConfig['label']} (Pending)',
          'bgColor': roleConfig['pendingBg'],
          'textColor': roleConfig['pendingColor'],
          'borderColor': roleConfig['pendingColor'],
        };
      case 'rejected':
        return {
          'icon': Icons.block_rounded,
          'label': '${roleConfig['label']} (Ditolak)',
          'bgColor': roleConfig['rejectedBg'],
          'textColor': roleConfig['rejectedColor'],
          'borderColor': roleConfig['rejectedColor'],
        };
      default:
        return {
          'icon': Icons.help_outline_rounded,
          'label': role,
          'bgColor': const Color(0xFFF3F4F6),
          'textColor': const Color(0xFF6B7280),
          'borderColor': const Color(0xFF6B7280),
        };
    }
  }
}