// ============================================================================
// KELOLA_USER_CONTENT.DART - UPDATED
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/user_provider.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_user/user_header.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_user/user_detail_screen.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_user/user_card.dart';

class KelolaUserContent extends StatefulWidget {
  const KelolaUserContent({super.key});

  @override
  State<KelolaUserContent> createState() => _KelolaUserContentState();
}

class _KelolaUserContentState extends State<KelolaUserContent> {
  // Variabel untuk menyimpan jumlah statistik 'asli' sebelum difilter
  int? _cachedCustomerCount;
  int? _cachedDriverCount;
  int? _cachedUmkmCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      child: Consumer<UserProvider>(
        builder: (context, provider, _) {
          
          // LOGIC FIX: Update cache hanya jika TIDAK sedang filter.
          // Jika sedang filter, gunakan angka terakhir yang disimpan.
          if (provider.roleFilter == null) {
            _cachedCustomerCount = _countRole(provider, 'customer');
            _cachedDriverCount = _countRole(provider, 'driver');
            _cachedUmkmCount = _countRole(provider, 'umkm');
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. HEADER (Statistik)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveAdmin.spaceMD()),
                  child: UserHeader(
                    totalUsers: provider.totalItems,
                    totalCustomers: _cachedCustomerCount ?? 0,
                    totalDrivers: _cachedDriverCount ?? 0,
                    totalUmkm: _cachedUmkmCount ?? 0,
                    onRefresh: () {
                      // Reset cache saat refresh
                      setState(() {
                        _cachedCustomerCount = null;
                        _cachedDriverCount = null;
                        _cachedUmkmCount = null;
                      });
                      provider.loadUsers(refresh: true);
                    },
                    onRoleFilter: (role) {
                      if (provider.roleFilter == role) {
                        provider.clearFilters();
                      } else {
                        provider.filterByRole(role);
                      }
                    },
                    selectedRoleFilter: provider.roleFilter,
                  ),
                ),
              ),

              // 2. GRID CONTENT
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.userList.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(),
                )
              else
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: ResponsiveAdmin.spaceMD(),
                    mainAxisSpacing: ResponsiveAdmin.spaceMD(),
                    mainAxisExtent: 270,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = provider.userList[index];
                      return UserCard(
                        user: user,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailScreen(user: user),
                            ),
                          );
                        },
                      );
                    },
                    childCount: provider.userList.length,
                  ),
                ),

              // 3. FOOTER (Text Only)
              if (!provider.isLoading && provider.userList.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: ResponsiveAdmin.spaceLG()),
                    child: Center(
                      child: Text(
                        _getPaginationText(provider),
                        style: TextStyle(
                          fontSize: ResponsiveAdmin.fontBody(),
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _getPaginationText(UserProvider provider) {
    int start = (provider.currentPage - 1) * provider.itemsPerPage + 1;
    int end = provider.currentPage * provider.itemsPerPage;
    if (end > provider.totalItems) end = provider.totalItems;
    
    if (provider.totalItems == 0) return 'Tidak ada data';

    return "Menampilkan $start - $end dari ${provider.totalItems} data user";
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text('Tidak ada data user', style: TextStyle(color: Colors.grey[500])),
        ],  
      ),
    );
  }

  int _countRole(UserProvider provider, String role) {
    return provider.userList.where((user) => user.hasRole(role)).length;
  }
}