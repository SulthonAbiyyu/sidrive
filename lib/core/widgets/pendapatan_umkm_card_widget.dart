// lib/core/widgets/pendapatan_umkm_card_widget.dart
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class PendapatanUmkmCardWidget extends StatelessWidget {
  final double totalPenjualan;
  final double totalPendapatan;
  final int totalPesanan;
  final int totalProdukTerjual;
  final String periode;

  const PendapatanUmkmCardWidget({
    Key? key,
    required this.totalPenjualan,
    required this.totalPendapatan,
    required this.totalPesanan,
    required this.totalProdukTerjual,
    required this.periode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(18)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(10)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: ResponsiveMobile.scaledFont(24),
                ),
              ),
              ResponsiveMobile.hSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendapatan UMKM',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      periode,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(12),
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          ResponsiveMobile.vSpace(20),

          // Total Pendapatan (BERSIH)
          Text(
            'Pendapatan Bersih',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(13),
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          ResponsiveMobile.vSpace(4),
          Text(
            'Rp ${_formatCurrency(totalPendapatan)}',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(32),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),

          ResponsiveMobile.vSpace(4),
          Text(
            '90% dari Rp ${_formatCurrency(totalPenjualan)}',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(11),
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          ResponsiveMobile.vSpace(20),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Total Pesanan',
                  value: totalPesanan.toString(),
                ),
              ),
              ResponsiveMobile.hSpace(12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Produk Terjual',
                  value: totalProdukTerjual.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: ResponsiveMobile.scaledFont(20)),
          ResponsiveMobile.vSpace(8),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(10),
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}