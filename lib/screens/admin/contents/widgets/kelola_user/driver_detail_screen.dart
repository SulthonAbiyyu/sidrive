// ============================================================================
// DRIVER_DETAIL_SCREEN.DART - FIXED & ENHANCED
// ============================================================================
// FIXES dari versi sebelumnya:
//   1. NoSuchMethodError 'idPengiriman'      → delivery.idPesanan (field dari UserTransactionModel)
//   2. NoSuchMethodError 'tanggalPengiriman' → delivery.tanggalPesanan (DateTime non-nullable)
//   3. rating['review_text']                 → rating['ulasan'] (key dari getDriverRatings())
//   4. _greenLight unused variable           → dihapus
//   5. Icons.id_card_rounded tidak ada       → Icons.badge_rounded
//   6. delivery.tanggalPesanan != null       → dihapus (DateTime non-nullable)
//   7. delivery.jenis?.toUpperCase()         → delivery.jenis.toUpperCase() (String non-nullable)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/models/user_detail_model.dart';
import 'package:sidrive/models/user_transaction_model.dart';
import 'package:sidrive/providers/user_provider.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'package:intl/intl.dart';

class DriverDetailScreen extends StatefulWidget {
  final UserDetailModel user;

  const DriverDetailScreen({super.key, required this.user});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Color palette
  static const _green = Color(0xFF10B981);
  static const _greenDark = Color(0xFF059669);
  static const _amber = Color(0xFFF59E0B);
  static const _blue = Color(0xFF3B82F6);
  static const _purple = Color(0xFF8B5CF6);
  static const _red = Color(0xFFEF4444);
  static const _gray50 = Color(0xFFF9FAFB);
  static const _gray100 = Color(0xFFF3F4F6);
  static const _gray200 = Color(0xFFE5E7EB);
  static const _gray500 = Color(0xFF6B7280);
  static const _gray900 = Color(0xFF111827);

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserDetail(widget.user.user.idUser);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gray50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
        ],
        body: Consumer<UserProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: _green));
            }
            return Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(provider),
                      _buildDeliveriesTab(provider),
                      _buildRatingsTab(provider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAppBar(bool innerBoxIsScrolled) {
    final user = widget.user;
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      floating: false,
      backgroundColor: _green,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: AnimatedOpacity(
          opacity: innerBoxIsScrolled ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            user.user.nama,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF064E3B), _green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative pattern
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                top: 20,
                child: Icon(
                  Icons.motorcycle_rounded,
                  size: 80,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              // Profile content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.user.nama,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.user.nim,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatusBadge(user),
                                const SizedBox(width: 8),
                                _buildDriverBadge(user),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Saldo chip
                      _buildSaldoChip(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final user = widget.user.user;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: user.fotoProfil != null
            ? Image.network(
                user.fotoProfil!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    return Container(
      color: _greenDark,
      alignment: Alignment.center,
      child: Text(
        widget.user.user.nama[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(UserDetailModel user) {
    final isActive = user.user.status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.25)
            : Colors.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.white54 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.greenAccent : Colors.orange,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Aktif' : user.user.status.replaceAll('_', ' '),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverBadge(UserDetailModel user) {
    final statusDriver = user.statusDriver ?? 'offline';
    final isOnline = statusDriver == 'active' || statusDriver == 'online';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.motorcycle_rounded,
            size: 12,
            color: isOnline ? Colors.greenAccent : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            'Driver · ${statusDriver.toUpperCase()}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaldoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            NumberFormat.compact(locale: 'id_ID')
                .format(widget.user.saldoWallet),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'Saldo',
            style: TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _green,
        unselectedLabelColor: _gray500,
        indicatorColor: _green,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Ringkasan'),
          Tab(
              icon: Icon(Icons.receipt_long_rounded, size: 18),
              text: 'Riwayat Order'),
          Tab(icon: Icon(Icons.star_rounded, size: 18), text: 'Ulasan'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: OVERVIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab(UserProvider provider) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          _buildFinancialCard(),
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          _buildVehicleInfoCard(provider),
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          _buildPersonalInfoCard(),
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          _buildCashPendingCard(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final u = widget.user;
    final totalDeliveries = u.jumlahPesananSelesaiDriver ?? 0;
    final avgRating = u.ratingDriver ?? 0.0;
    final totalRatings = u.totalRatingDriver ?? 0;
    final cashPending = u.jumlahOrderBelumSetor ?? 0;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: ResponsiveAdmin.spaceSM(),
      mainAxisSpacing: ResponsiveAdmin.spaceSM(),
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          'Total Pengiriman',
          '$totalDeliveries',
          Icons.local_shipping_rounded,
          _green,
          subtitle: 'selesai',
        ),
        _buildStatCard(
          'Rating Driver',
          avgRating.toStringAsFixed(1),
          Icons.star_rounded,
          _amber,
          subtitle: '$totalRatings ulasan',
        ),
        _buildStatCard(
          'Order Aktif',
          '0',
          Icons.pending_actions_rounded,
          _blue,
          subtitle: 'sedang berjalan',
        ),
        _buildStatCard(
          'Belum Setor',
          '$cashPending',
          Icons.payments_rounded,
          _red,
          subtitle: 'order cash',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _gray900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _gray500,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard() {
    final u = widget.user;
    return _buildSectionCard(
      title: 'Keuangan Driver',
      icon: Icons.account_balance_rounded,
      iconColor: _green,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFinanceItem(
                  'Total Pendapatan',
                  _currencyFormat.format(u.totalPendapatanDriver ?? 0),
                  Icons.trending_up_rounded,
                  _green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinanceItem(
                  'Saldo Wallet',
                  _currencyFormat.format(u.saldoWallet),
                  Icons.account_balance_wallet_rounded,
                  _blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFinanceItem(
                  'Total Top Up',
                  _currencyFormat.format(u.totalTopup),
                  Icons.add_card_rounded,
                  _purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinanceItem(
                  'Cash Pending',
                  _currencyFormat.format(u.totalCashPending ?? 0),
                  Icons.money_off_rounded,
                  _red,
                ),
              ),
            ],
          ),
          if (u.namaBank != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.credit_card_rounded,
                    size: 16, color: _gray500),
                const SizedBox(width: 8),
                Text(
                  '${u.namaBank} · ${u.nomorRekening} (${u.namaRekening})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _gray500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinanceItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _gray900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard(UserProvider provider) {
    final u = widget.user;
    return _buildSectionCard(
      title: 'Informasi Kendaraan',
      icon: Icons.directions_car_rounded,
      iconColor: _blue,
      child: Column(
        children: [
          // Active vehicle
          _buildInfoRow(
            icon: Icons.motorcycle_rounded,
            label: 'Kendaraan Aktif',
            value: u.user.activeVehicle ?? u.activeVehicleType ?? '-',
          ),
          _buildInfoRow(
            icon: Icons.category_rounded,
            label: 'Jenis Kendaraan',
            value: u.user.jenisKendaraan ?? '-',
          ),
          _buildInfoRow(
            icon: Icons.badge_rounded,
            label: 'ID Driver',
            value: u.idDriver ?? '-',
          ),
          _buildInfoRow(
            icon: Icons.verified_rounded,
            label: 'Status Driver',
            value: u.statusDriver ?? '-',
            valueColor: _statusColor(u.statusDriver),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    final u = widget.user.user;
    return _buildSectionCard(
      title: 'Informasi Pribadi',
      icon: Icons.person_rounded,
      iconColor: _purple,
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: u.email,
          ),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'No. Telepon',
            value: u.noTelp,
          ),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Alamat',
            value: u.alamat ?? '-',
          ),
          _buildInfoRow(
            icon: Icons.wc_rounded,
            label: 'Jenis Kelamin',
            value: u.jenisKelamin ?? '-',
          ),
          _buildInfoRow(
            icon: Icons.cake_outlined,
            label: 'Tanggal Lahir',
            value: u.tanggalLahir != null
                ? DateFormat('dd MMMM yyyy', 'id_ID')
                    .format(u.tanggalLahir!)
                : '-',
          ),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Bergabung',
            value: DateFormat('dd MMMM yyyy', 'id_ID').format(u.createdAt),
          ),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Login Terakhir',
            value: u.lastLogin != null
                ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                    .format(u.lastLogin!)
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildCashPendingCard() {
    final u = widget.user;
    if ((u.jumlahOrderBelumSetor ?? 0) == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFD97706), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perhatian: Ada Order Cash Belum Disetor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${u.jumlahOrderBelumSetor} order · ${_currencyFormat.format(u.totalCashPending ?? 0)} perlu disetorkan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: DELIVERIES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDeliveriesTab(UserProvider provider) {
    final deliveries = provider.selectedDriverDeliveries;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }

    if (deliveries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping_outlined,
        message: 'Belum ada riwayat pengiriman',
        subtitle: 'Driver belum menyelesaikan order',
      );
    }

    // Statistics summary
    final selesai = deliveries
        .where((d) => d.statusPesanan == 'selesai')
        .length;
    final dibatalkan = deliveries
        .where((d) => d.statusPesanan == 'dibatalkan')
        .length;
    final proses = deliveries
        .where((d) =>
            d.statusPesanan != 'selesai' && d.statusPesanan != 'dibatalkan')
        .length;

    return ListView(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      children: [
        // Summary chips
        Row(
          children: [
            _buildChip('Selesai: $selesai', _green),
            const SizedBox(width: 8),
            _buildChip('Diproses: $proses', _blue),
            const SizedBox(width: 8),
            _buildChip('Dibatalkan: $dibatalkan', _red),
          ],
        ),
        SizedBox(height: ResponsiveAdmin.spaceMD()),
        // Delivery list
        ...deliveries.map((delivery) => _buildDeliveryCard(delivery)),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ── FIX: Pakai idPesanan & tanggalPesanan, BUKAN idPengiriman/tanggalPengiriman ──
  Widget _buildDeliveryCard(UserTransactionModel delivery) {
    final status = delivery.statusPesanan;
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            delivery.jenis == 'ojek'
                                ? Icons.motorcycle_rounded
                                : Icons.shopping_bag_rounded,
                            color: _green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${delivery.idPesanan.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _gray900,
                                ),
                              ),
                              if (delivery.namaCustomer != null)
                                Text(
                                  delivery.namaCustomer!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _gray500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: _gray100),
                    const SizedBox(height: 10),
                    // Detail row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDeliveryDetail(
                            Icons.calendar_today_outlined,
                            // tanggalPesanan adalah DateTime non-nullable di UserTransactionModel
                            DateFormat('dd MMM yyyy')
                                .format(delivery.tanggalPesanan),
                          ),
                        ),
                        Expanded(
                          child: _buildDeliveryDetail(
                            Icons.payments_outlined,
                            _currencyFormat
                                .format(delivery.ongkir ?? delivery.totalHarga),
                          ),
                        ),
                        Expanded(
                          child: _buildDeliveryDetail(
                            Icons.credit_card_rounded,
                            _paymentLabel(delivery.paymentMethod),
                          ),
                        ),
                        Expanded(
                          child: _buildDeliveryDetail(
                            Icons.category_outlined,
                            // jenis adalah String non-nullable di UserTransactionModel
                            delivery.jenis.toUpperCase(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetail(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _gray500),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: _gray500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3: RATINGS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRatingsTab(UserProvider provider) {
    final ratings = provider.selectedDriverRatings;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }

    if (ratings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_border_rounded,
        message: 'Belum ada ulasan',
        subtitle: 'Driver belum menerima ulasan dari pelanggan',
      );
    }

    // Avg & distribution
    final avg = widget.user.ratingDriver ?? 0.0;
    final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in ratings) {
      final stars = (r['rating'] as num?)?.toInt() ?? 0;
      if (stars >= 1 && stars <= 5) dist[stars] = (dist[stars] ?? 0) + 1;
    }

    return ListView(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      children: [
        // Rating summary
        _buildRatingSummaryCard(avg, ratings.length, dist),
        SizedBox(height: ResponsiveAdmin.spaceMD()),
        // Reviews list
        ...ratings.map((rating) => _buildRatingCard(rating)),
      ],
    );
  }

  Widget _buildRatingSummaryCard(
      double avg, int total, Map<int, int> dist) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Row(
        children: [
          // Big number
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _gray900,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avg.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _amber,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('$total ulasan',
                  style: const TextStyle(fontSize: 12, color: _gray500)),
            ],
          ),
          const SizedBox(width: 20),
          // Distribution bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1]
                  .map((star) => _buildDistBar(star, dist[star] ?? 0, total))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistBar(int star, int count, int total) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 11, color: _gray500)),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 11, color: _amber),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: _gray100,
                valueColor: const AlwaysStoppedAnimation<Color>(_amber),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, color: _gray500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: rating['ulasan'] bukan rating['review_text']
  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final stars = (rating['rating'] as num?)?.toInt() ?? 0;
    // ✅ FIX: key 'ulasan' sesuai getDriverRatings di user_service.dart
    final ulasan = rating['ulasan'] as String?;
    final customerName = rating['customer_name'] as String?;
    final createdAt = rating['created_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (customerName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _amber,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName ?? 'Pelanggan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _gray900,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(DateTime.parse(createdAt)),
                        style: const TextStyle(fontSize: 11, color: _gray500),
                      ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: _amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (ulasan != null && ulasan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _gray50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gray200),
              ),
              child: Text(
                ulasan,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _gray900,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          const Divider(height: 1, color: _gray100),
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _gray500),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _gray500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? _gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: _gray200),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _gray500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: _gray500),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'selesai':
      case 'active':
        return _green;
      case 'dibatalkan':
      case 'suspended':
        return _red;
      case 'pending':
      case 'pending_verification':
        return _amber;
      case 'sedang_diantar':
      case 'dikonfirmasi':
        return _blue;
      default:
        return _gray500;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'pending':
        return 'Pending';
      case 'dikonfirmasi':
        return 'Dikonfirmasi';
      case 'sedang_diantar':
        return 'Diantar';
      case 'active':
        return 'Aktif';
      default:
        return status?.replaceAll('_', ' ').toUpperCase() ?? '-';
    }
  }

  String _paymentLabel(String? method) {
    switch (method) {
      case 'wallet':
        return 'Wallet';
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      default:
        return method?.toUpperCase() ?? '-';
    }
  }
}