// ============================================================================
// USER_DETAIL_SCREEN.DART
// Detail lengkap user dengan tab Customer, Driver, UMKM
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/models/user_detail_model.dart';
import 'package:sidrive/providers/user_provider.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'package:intl/intl.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_user/user_role_badge.dart';

class UserDetailScreen extends StatefulWidget {
  final UserDetailModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Load detail data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserDetail(widget.user.user.idUser);
    });

    // Setup tabs based on user roles
    final tabs = <String>['Info'];
    if (widget.user.hasRole('customer')) tabs.add('Customer');
    if (widget.user.hasRole('driver')) tabs.add('Driver');
    if (widget.user.hasRole('umkm')) tabs.add('UMKM');

    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    context.read<UserProvider>().clearSelectedUser();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildUserHeader(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Detail User'),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      margin: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
              image: widget.user.user.fotoProfil != null
                  ? DecorationImage(
                      image: NetworkImage(widget.user.user.fotoProfil!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.user.user.fotoProfil == null
                ? Center(
                    child: Text(
                      widget.user.user.nama[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: ResponsiveAdmin.spaceSM() + 4),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.user.nama,
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontH4(),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: ResponsiveAdmin.spaceXS() - 2),
                Text(
                  'NIM: ${widget.user.user.nim} • ${widget.user.user.noTelp}',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontSmall(),
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: ResponsiveAdmin.spaceXS()),
                Wrap(
                  spacing: ResponsiveAdmin.spaceXS() - 2,
                  runSpacing: ResponsiveAdmin.spaceXS() - 2,
                  children: widget.user.roles
                      .where((r) => r.isActive)
                      .map((r) => UserRoleBadge(role: r.role, status: r.status))
                      .toList(),
                ),
              ],
            ),
          ),

          // Saldo Wallet
          Container(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Saldo Wallet',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontSmall(),
                    color: const Color(0xFF166534),
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(widget.user.saldoWallet),
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontBody() + 2,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = <String>['Info'];
    if (widget.user.hasRole('customer')) tabs.add('Customer');
    if (widget.user.hasRole('driver')) tabs.add('Driver');
    if (widget.user.hasRole('umkm')) tabs.add('UMKM');

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: tabs.map((label) => Tab(text: label)).toList(),
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorColor: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildTabContent() {
    final tabs = <Widget>[_buildInfoTab()];
    if (widget.user.hasRole('customer')) tabs.add(_buildCustomerTab());
    if (widget.user.hasRole('driver')) tabs.add(_buildDriverTab());
    if (widget.user.hasRole('umkm')) tabs.add(_buildUmkmTab());

    return TabBarView(
      controller: _tabController,
      children: tabs,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB: INFO
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: 'Informasi Pribadi',
            items: [
              _buildInfoRow('Email', widget.user.user.email),
              _buildInfoRow('No. Telp', widget.user.user.noTelp),
              _buildInfoRow('Alamat', widget.user.user.alamat ?? '-'),
              _buildInfoRow('Tanggal Lahir', widget.user.user.tanggalLahir != null
                  ? DateFormat('dd MMMM yyyy', 'id_ID').format(widget.user.user.tanggalLahir!)
                  : '-'),
              _buildInfoRow('Jenis Kelamin', widget.user.user.jenisKelamin ?? '-'),
            ],
          ),
          SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
          _buildInfoSection(
            title: 'Informasi Akun',
            items: [
              _buildInfoRow('Status', widget.user.user.status.toUpperCase()),
              _buildInfoRow('Verifikasi', widget.user.user.isVerified ? 'Terverifikasi' : 'Belum Terverifikasi'),
              _buildInfoRow('Bergabung', DateFormat('dd MMMM yyyy', 'id_ID').format(widget.user.user.createdAt)),
              _buildInfoRow('Login Terakhir', widget.user.user.lastLogin != null
                  ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(widget.user.user.lastLogin!)
                  : '-'),
            ],
          ),
          if (widget.user.namaBank != null) ...[
            SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
            _buildInfoSection(
              title: 'Informasi Rekening',
              items: [
                _buildInfoRow('Bank', widget.user.namaBank!),
                _buildInfoRow('No. Rekening', widget.user.nomorRekening ?? '-'),
                _buildInfoRow('Nama Rekening', widget.user.namaRekening ?? '-'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB: CUSTOMER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCustomerTab() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Order',
                      '${widget.user.totalOrderOjek + widget.user.totalOrderUmkm}',
                      Icons.shopping_cart_rounded,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(width: ResponsiveAdmin.spaceSM()),
                  Expanded(
                    child: _buildStatCard(
                      'Selesai',
                      '${widget.user.totalOrderSelesai}',
                      Icons.check_circle_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: ResponsiveAdmin.spaceSM()),
                  Expanded(
                    child: _buildStatCard(
                      'Total Spending',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(widget.user.totalSpending),
                      Icons.payments_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveAdmin.spaceMD()),

              // Transaction History
              _buildSectionTitle('Riwayat Transaksi'),
              SizedBox(height: ResponsiveAdmin.spaceSM()),
              ...provider.selectedUserTransactions.map((tx) => _buildTransactionCard(tx)),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB: DRIVER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildDriverTab() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pesanan Selesai',
                      '${widget.user.jumlahPesananSelesaiDriver ?? 0}',
                      Icons.delivery_dining_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: ResponsiveAdmin.spaceSM()),
                  Expanded(
                    child: _buildStatCard(
                      'Rating',
                      '${widget.user.ratingDriver?.toStringAsFixed(1) ?? '0.0'} ⭐',
                      Icons.star_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  SizedBox(width: ResponsiveAdmin.spaceSM()),
                  Expanded(
                    child: _buildStatCard(
                      'Pendapatan',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(widget.user.totalPendapatanDriver ?? 0),
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveAdmin.spaceMD()),

              // Delivery History
              _buildSectionTitle('Riwayat Pengiriman'),
              SizedBox(height: ResponsiveAdmin.spaceSM()),
              ...provider.selectedDriverDeliveries.map((tx) => _buildTransactionCard(tx)),

              SizedBox(height: ResponsiveAdmin.spaceMD()),

              // Ratings Received
              _buildSectionTitle('Ulasan Diterima'),
              SizedBox(height: ResponsiveAdmin.spaceSM()),
              ...provider.selectedDriverRatings.map((rating) => _buildRatingCard(rating)),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB: UMKM
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildUmkmTab() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UMKM Info
              if (widget.user.namaToko != null)
                Container(
                  padding: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
                    boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
                  ),
                  child: Row(
                    children: [
                      if (widget.user.fotoToko != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                          child: Image.network(
                            widget.user.fotoToko!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      SizedBox(width: ResponsiveAdmin.spaceSM()),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.namaToko!,
                              style: TextStyle(
                                fontSize: ResponsiveAdmin.fontBody() + 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Kategori: ${widget.user.kategoriToko ?? '-'}',
                              style: TextStyle(
                                fontSize: ResponsiveAdmin.fontSmall(),
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              'Status: ${widget.user.statusToko ?? '-'}',
                              style: TextStyle(
                                fontSize: ResponsiveAdmin.fontSmall(),
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: ResponsiveAdmin.spaceMD()),

              // UMKM Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Produk Terjual',
                      '${widget.user.jumlahProdukTerjual ?? 0}',
                      Icons.shopping_bag_rounded,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(width: ResponsiveAdmin.spaceSM()),
                  Expanded(
                    child: _buildStatCard(
                      'Rating Toko',
                      '${widget.user.ratingToko?.toStringAsFixed(1) ?? '0.0'} ⭐',
                      Icons.star_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  SizedBox(width: ResponsiveAdmin.spaceSM()),
                  Expanded(
                    child: _buildStatCard(
                      'Total Penjualan',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(widget.user.totalPenjualan ?? 0),
                      Icons.payments_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveAdmin.spaceMD()),

              // Order History
              _buildSectionTitle('Riwayat Pesanan'),
              SizedBox(height: ResponsiveAdmin.spaceSM()),
              ...provider.selectedUmkmOrders.map((tx) => _buildTransactionCard(tx)),

              SizedBox(height: ResponsiveAdmin.spaceMD()),

              // Reviews Received
              _buildSectionTitle('Ulasan Diterima'),
              SizedBox(height: ResponsiveAdmin.spaceSM()),
              ...provider.selectedUmkmReviews.map((review) => _buildRatingCard(review)),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontBody(),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: ResponsiveAdmin.spaceSM()),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveAdmin.spaceXS()),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontSmall(),
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontSmall(),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ResponsiveAdmin.fontBody() + 2,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: ResponsiveAdmin.spaceXS()),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontBody() + 4,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontSmall(),
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveAdmin.spaceXS() + 4),
      padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${tx.idPesanan.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontBody(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveAdmin.spaceXS() + 2,
                  vertical: ResponsiveAdmin.spaceXS() - 2,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(tx.statusPesanan).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS()),
                ),
                child: Text(
                  tx.statusPesanan,
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontSmall() - 1,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(tx.statusPesanan),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveAdmin.spaceXS()),
          Text(
            DateFormat('dd MMM yyyy, HH:mm').format(tx.tanggalPesanan),
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontSmall(),
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(tx.totalHarga),
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontBody(),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveAdmin.spaceXS() + 4),
      padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  index < (rating['rating'] ?? 0)
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 16,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.parse(rating['created_at'])),
                style: TextStyle(
                  fontSize: ResponsiveAdmin.fontSmall(),
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          if (rating['review_text'] != null) ...[
            SizedBox(height: ResponsiveAdmin.spaceXS()),
            Text(
              rating['review_text'],
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontSmall(),
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF10B981);
      case 'dibatalkan':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }
}