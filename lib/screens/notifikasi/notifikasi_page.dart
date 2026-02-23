// ============================================================================
// NOTIFIKASI PAGE
// Halaman untuk menampilkan list notifikasi
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/providers/notifikasi_provider.dart';
import 'package:sidrive/models/notifikasi_model.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/screens/notifikasi/notifikasi_card.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  String _selectedFilter = 'Semua';

  final List<String> _filterOptions = [
    'Semua',
    'Belum Dibaca',
    'Sistem',
    'Pesanan',
    'Pembayaran',
    'Withdrawal',
    'Promo',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifikasi();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifikasi() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.idUser;

    if (userId != null) {
      await context.read<NotifikasiProvider>().loadNotifikasi(userId);
      
      // Start listening for real-time updates
      if (mounted) {
        context.read<NotifikasiProvider>().startListening(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.currentUser?.idUser;

    if (userId == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: Text('User tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final notifProvider = context.watch<NotifikasiProvider>();

    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: ResponsiveMobile.subtitleSize(context),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (notifProvider.unreadCount > 0)
            Text(
              '${notifProvider.unreadCount} belum dibaca',
              style: TextStyle(
                fontSize: ResponsiveMobile.captionSize(context),
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: [
        // Mark all as read
        if (notifProvider.unreadCount > 0)
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            tooltip: 'Tandai semua dibaca',
            onPressed: () => _markAllAsRead(),
          ),
        
        // Filter menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
          tooltip: 'Filter',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
          ),
          onSelected: (value) {
            setState(() {
              _selectedFilter = value;
            });
          },
          itemBuilder: (context) => _filterOptions.map((filter) {
            return PopupMenuItem<String>(
              value: filter,
              child: Row(
                children: [
                  if (_selectedFilter == filter)
                    Icon(Icons.check, size: ResponsiveMobile.scaledFont(18)),
                  if (_selectedFilter == filter)
                    ResponsiveMobile.hSpace(8),
                  Text(filter),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final notifProvider = context.watch<NotifikasiProvider>();

    if (notifProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    if (notifProvider.errorMessage != null) {
      return _buildErrorState(notifProvider.errorMessage!);
    }

    final filteredNotif = _getFilteredNotifikasi(notifProvider);

    if (filteredNotif.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifikasi,
      color: Colors.blue.shade600,
      child: ListView.builder(
        padding: ResponsiveMobile.allScaledPadding(16),
        itemCount: filteredNotif.length,
        itemBuilder: (context, index) {
          final notif = filteredNotif[index];
          return NotifikasiCard(
            notifikasi: notif,
            onTap: () => _onNotifTap(notif),
            onDelete: () => _deleteNotifikasi(notif.idNotifikasi),
          );
        },
      ),
    );
  }

  List<NotifikasiModel> _getFilteredNotifikasi(NotifikasiProvider provider) {
    switch (_selectedFilter) {
      case 'Belum Dibaca':
        return provider.unreadNotifikasi;
      case 'Sistem':
        return provider.getNotifikasiByJenis('sistem');
      case 'Pesanan':
        return provider.getNotifikasiByJenis('pesanan');
      case 'Pembayaran':
        return provider.getNotifikasiByJenis('pembayaran');
      case 'Withdrawal':
        return provider.getNotifikasiByJenis('withdrawal');
      case 'Promo':
        return provider.getNotifikasiByJenis('promo');
      default:
        return provider.notifikasi;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: ResponsiveMobile.horizontalPadding(context, 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: ResponsiveMobile.allScaledPadding(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: ResponsiveMobile.scaledFont(64),
                color: Colors.grey.shade400,
              ),
            ),
            ResponsiveMobile.vSpace(24),
            Text(
              _selectedFilter == 'Semua' 
                  ? 'Belum Ada Notifikasi' 
                  : 'Tidak Ada Notifikasi $_selectedFilter',
              style: TextStyle(
                fontSize: ResponsiveMobile.titleSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveMobile.vSpace(12),
            Text(
              _selectedFilter == 'Semua'
                  ? 'Notifikasi Anda akan muncul di sini'
                  : 'Coba filter lain atau refresh halaman',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: ResponsiveMobile.horizontalPadding(context, 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveMobile.scaledFont(64),
              color: Colors.red.shade400,
            ),
            ResponsiveMobile.vSpace(16),
            Text(
              'Gagal Memuat Notifikasi',
              style: TextStyle(
                fontSize: ResponsiveMobile.titleSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            ResponsiveMobile.vSpace(8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveMobile.captionSize(context),
                color: Colors.grey.shade600,
              ),
            ),
            ResponsiveMobile.vSpace(24),
            ElevatedButton.icon(
              onPressed: _loadNotifikasi,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveMobile.scaledW(24),
                  vertical: ResponsiveMobile.scaledH(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onNotifTap(NotifikasiModel notif) async {
    // Mark as read
    if (notif.isUnread) {
      await context.read<NotifikasiProvider>().markAsRead(notif.idNotifikasi);
    }

    // Show detail dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => _buildDetailDialog(notif),
      );
    }
  }

  Widget _buildDetailDialog(NotifikasiModel notif) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
      ),
      child: Padding(
        padding: ResponsiveMobile.allScaledPadding(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              notif.judul,
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context) + 2,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            ResponsiveMobile.vSpace(8),
            
            // Time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: ResponsiveMobile.scaledFont(14),
                  color: Colors.grey.shade500,
                ),
                ResponsiveMobile.hSpace(4),
                Text(
                  notif.timeAgo,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.captionSize(context),
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            
            ResponsiveMobile.vSpace(16),
            
            // Body
            Container(
              padding: ResponsiveMobile.allScaledPadding(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                notif.pesan,
                style: TextStyle(
                  fontSize: ResponsiveMobile.bodySize(context),
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            
            ResponsiveMobile.vSpace(24),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveMobile.scaledH(14),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.idUser;

    if (userId != null) {
      final success = await context.read<NotifikasiProvider>().markAllAsRead(userId);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sudah dibaca'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotifikasi(String notifId) async {
    final success = await context.read<NotifikasiProvider>().deleteNotifikasi(notifId);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi dihapus'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }
}