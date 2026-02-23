// ============================================================================
// USER_LIST.DART
// List widget untuk menampilkan daftar user
// ============================================================================

import 'package:flutter/material.dart';
import 'package:sidrive/models/user_detail_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'user_card.dart';

class UserList extends StatelessWidget {
  final List<UserDetailModel> userList;
  final bool isLoading;
  final String searchQuery;
  final bool hasActiveFilters;
  final Future<void> Function() onRefresh;
  final Function(UserDetailModel) onUserTap;

  const UserList({
    super.key,
    required this.userList,
    required this.isLoading,
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.onRefresh,
    required this.onUserTap,
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
            SizedBox(height: ResponsiveAdmin.spaceSM()),
            Text(
              'Memuat data user...',
              style: TextStyle(
                fontSize: 12, // ✅ Dikecilkan
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (userList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 32, // ✅ Dikecilkan
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: ResponsiveAdmin.spaceSM()),
            Text(
              'Tidak ada data user',
              style: TextStyle(
                fontSize: 13, // ✅ Dikecilkan
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: ResponsiveAdmin.spaceXS()),
            Text(
              searchQuery.isNotEmpty || hasActiveFilters
                  ? 'Coba ubah filter atau kata kunci pencarian'
                  : 'Belum ada user terdaftar',
              style: TextStyle(
                fontSize: 11, // ✅ Dikecilkan
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
        itemCount: userList.length,
        separatorBuilder: (_, __) => SizedBox(height: ResponsiveAdmin.spaceXS()), // ✅ Dikecilkan
        itemBuilder: (context, index) {
          return UserCard(
            user: userList[index],
            onTap: () => onUserTap(userList[index]),
          );
        },
      ),
    );
  }
}