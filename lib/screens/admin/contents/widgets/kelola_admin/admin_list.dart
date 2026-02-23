import 'package:flutter/material.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'admin_card.dart';

class AdminList extends StatelessWidget {
  final List<AdminModel> adminList;
  final bool isLoading;
  final String searchQuery;
  final bool hasActiveFilters;
  final Future<void> Function() onRefresh;
  final Function(AdminModel) onEdit;
  final Function(AdminModel) onDelete;

  const AdminList({
    super.key,
    required this.adminList,
    required this.isLoading,
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              strokeWidth: 2.5,
            ),
            SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
            Text(
              'Memuat data admin...',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontCaption() + 1,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (adminList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
            Text(
              'Tidak ada data admin',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody(),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: ResponsiveAdmin.spaceXS()),
            Text(
              searchQuery.isNotEmpty || hasActiveFilters
                  ? 'Coba ubah filter atau kata kunci pencarian'
                  : 'Klik "Tambah Admin" untuk menambah data',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontCaption() + 1,
                color: const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: adminList.length,
        separatorBuilder: (_, __) => SizedBox(height: ResponsiveAdmin.spaceXS() + 4),
        itemBuilder: (context, index) {
          return AdminCard(
            admin: adminList[index],
            onEdit: () => onEdit(adminList[index]),
            onDelete: () => onDelete(adminList[index]),
          );
        },
      ),
    );
  }
}