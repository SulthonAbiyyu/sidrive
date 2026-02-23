// lib/screens/admin/contents/widgets/penarikan_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// PENARIKAN CARD - COMPACT & MODERN VERSION
/// ✅ Content lebih kecil, muat lebih banyak data
/// ✅ Button tidak jumbo, proporsional
/// ✅ Layout lebih efisien
/// ============================================================================

class PenarikanCard extends StatelessWidget {
  final dynamic penarikan;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PenarikanCard({
    super.key,
    required this.penarikan,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return Container(
      padding: const EdgeInsets.all(16), // ✅ Lebih compact dari 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User & Amount
          Row(
            children: [
              // Avatar (smaller)
              Container(
                width: 40, // ✅ Dari 48 jadi 40
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    penarikan.nama?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16, // ✅ Dari 20 jadi 16
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name
              Expanded(
                child: Text(
                  penarikan.nama ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14, // ✅ Lebih kecil
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Amount & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(penarikan.jumlah ?? 0),
                    style: const TextStyle(
                      fontSize: 16, // ✅ Dari 20 jadi 16
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE047)),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 9, // ✅ Lebih kecil
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFCA8A04),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE5E7EB), height: 1),
          const SizedBox(height: 12),

          // Bank Info (2 columns, compact)
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.account_balance,
                  'Bank',
                  penarikan.namaBank ?? '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  Icons.credit_card,
                  'Rekening',
                  penarikan.nomorRekening ?? '-',
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.person,
                  'Atas Nama',
                  penarikan.namaRekening ?? '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  Icons.access_time,
                  'Tanggal',
                  dateFormat.format(penarikan.tanggalPengajuan ?? DateTime.now()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons (COMPACT)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 14), // ✅ Icon kecil
                  label: const Text(
                    'Tolak',
                    style: TextStyle(fontSize: 12), // ✅ Text kecil
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 10), // ✅ Padding kecil
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_rounded, size: 14), // ✅ Icon kecil
                  label: const Text(
                    'Setujui & Upload',
                    style: TextStyle(fontSize: 12), // ✅ Text kecil
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10), // ✅ Padding kecil
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)), // ✅ Icon kecil
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10, // ✅ Lebih kecil
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11, // ✅ Lebih kecil
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}