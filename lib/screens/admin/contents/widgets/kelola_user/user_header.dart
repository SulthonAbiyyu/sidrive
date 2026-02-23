// ============================================================================
// USER_HEADER.DART
// ============================================================================

import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class UserHeader extends StatelessWidget {
  final int totalUsers;
  final int totalCustomers;
  final int totalDrivers;
  final int totalUmkm;
  final VoidCallback onRefresh;
  final Function(String?) onRoleFilter;
  final String? selectedRoleFilter;

  const UserHeader({
    super.key,
    required this.totalUsers,
    required this.totalCustomers,
    required this.totalDrivers,
    required this.totalUmkm,
    required this.onRefresh,
    required this.onRoleFilter,
    this.selectedRoleFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Total User Terdaftar: $totalUsers',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            
            // Tombol Refresh - REDESIGNED: Lebih kecil dan elegant
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Refresh',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: ResponsiveAdmin.spaceMD()),

        Row(
          children: [
            Expanded(child: _buildRoleCard('Customer', totalCustomers, Icons.person, Colors.blue, 'customer')),
            SizedBox(width: ResponsiveAdmin.spaceMD()),
            Expanded(child: _buildRoleCard('Driver', totalDrivers, Icons.motorcycle, Colors.green, 'driver')),
            SizedBox(width: ResponsiveAdmin.spaceMD()),
            Expanded(child: _buildRoleCard('UMKM', totalUmkm, Icons.store, Colors.purple, 'umkm')),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(String label, int count, IconData icon, Color color, String roleKey) {
    bool isSelected = selectedRoleFilter == roleKey;
    return InkWell(
      onTap: () => onRoleFilter(roleKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}