// ============================================================================
// USER_PAGINATION.DART
// Pagination untuk user list
// ============================================================================

import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class UserPagination extends StatelessWidget {
  final int currentPage;
  final int itemsPerPage;
  final int totalItems;
  final Function(int) onPageChanged;

  const UserPagination({
    super.key,
    required this.currentPage,
    required this.itemsPerPage,
    required this.totalItems,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / itemsPerPage).ceil();
    final startItem = currentPage * itemsPerPage + 1;
    final endItem = ((currentPage + 1) * itemsPerPage > totalItems) ? totalItems : (currentPage + 1) * itemsPerPage;

    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan $startItem - $endItem dari $totalItems',
            style: TextStyle(fontSize: ResponsiveAdmin.fontCaption() + 1, color: const Color(0xFF6B7280)),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage > 0 ? const Color(0xFFF3F4F6) : Colors.grey.shade200,
                  foregroundColor: currentPage > 0 ? const Color(0xFF6B7280) : Colors.grey.shade400,
                  padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 2),
                  minimumSize: const Size(32, 32),
                ),
              ),
              SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
              Text(
                'Halaman ${currentPage + 1} dari $totalPages',
                style: TextStyle(fontSize: ResponsiveAdmin.fontCaption() + 1, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
              IconButton(
                onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage < totalPages - 1 ? const Color(0xFFF3F4F6) : Colors.grey.shade200,
                  foregroundColor: currentPage < totalPages - 1 ? const Color(0xFF6B7280) : Colors.grey.shade400,
                  padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 2),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}