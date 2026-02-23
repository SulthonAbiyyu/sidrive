// ============================================================================
// UMKM_DETAIL_SCREEN.DART
// Halaman detail khusus untuk role UMKM dengan UI/UX clean & modern
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/models/user_detail_model.dart';
import 'package:sidrive/providers/user_provider.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'package:intl/intl.dart';

class UmkmDetailScreen extends StatefulWidget {
  final UserDetailModel user;

  const UmkmDetailScreen({super.key, required this.user});

  @override
  State<UmkmDetailScreen> createState() => _UmkmDetailScreenState();
}

class _UmkmDetailScreenState extends State<UmkmDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserDetail(widget.user.user.idUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildUserInfoCard(),
                SizedBox(height: ResponsiveAdmin.spaceMD()),
                _buildStatsGrid(),
                SizedBox(height: ResponsiveAdmin.spaceMD()),
                _buildProductsList(),
                SizedBox(height: ResponsiveAdmin.spaceMD()),
                _buildRatings(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF8B5CF6),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'UMKM Detail',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                bottom: -30,
                child: Icon(
                  Icons.store_rounded,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8B5CF6), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipOval(
              child: widget.user.user.fotoProfil != null
                  ? Image.network(
                      widget.user.user.fotoProfil!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(),
                    )
                  : _buildInitials(),
            ),
          ),
          SizedBox(width: ResponsiveAdmin.spaceMD()),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.user.nama,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: ResponsiveAdmin.spaceXS()),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      widget.user.user.nim,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      widget.user.user.noTelp,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Wallet
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.compact(locale: 'id_ID').format(widget.user.saldoWallet),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Saldo',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        // Gunakan data dari user model langsung
        final productsSold = widget.user.jumlahProdukTerjual ?? 0;
        final avgRating = widget.user.ratingToko ?? 0.0;
        final totalRatings = widget.user.totalRatingUmkm ?? 0;
        
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Produk',
                    '0', // Bisa ditambahkan nanti ke model
                    Icons.inventory_2_rounded,
                    const Color(0xFF8B5CF6),
                  ),
                ),
                SizedBox(width: ResponsiveAdmin.spaceMD()),
                Expanded(
                  child: _buildStatCard(
                    'Produk Terjual',
                    '$productsSold',
                    Icons.shopping_cart_checkout_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveAdmin.spaceMD()),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Rating Toko',
                    avgRating.toStringAsFixed(1),
                    Icons.star_rounded,
                    const Color(0xFFF59E0B),
                  ),
                ),
                SizedBox(width: ResponsiveAdmin.spaceMD()),
                Expanded(
                  child: _buildStatCard(
                    'Total Ulasan',
                    '$totalRatings',
                    Icons.comment_rounded,
                    const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: ResponsiveAdmin.spaceSM()),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
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
          const Text(
            'Daftar Produk',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: ResponsiveAdmin.spaceSM()),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Daftar produk akan ditampilkan di sini',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'API produk UMKM belum tersedia',
                    style: TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatings() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final ratings = provider.selectedUmkmReviews;

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
              const Text(
                'Ulasan Pelanggan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: ResponsiveAdmin.spaceSM()),
              if (ratings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Belum ada ulasan',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                )
              else
                ...ratings.take(5).map((rating) => _buildRatingItem(rating)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingItem(dynamic rating) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveAdmin.spaceXS() + 4),
      padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
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
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.parse(rating['created_at'])),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          if (rating['review_text'] != null) ...[
            const SizedBox(height: 6),
            Text(
              rating['review_text'],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitials() {
    return Container(
      color: const Color(0xFF8B5CF6).withOpacity(0.1),
      child: Center(
        child: Text(
          widget.user.user.nama[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
    );
  }
}