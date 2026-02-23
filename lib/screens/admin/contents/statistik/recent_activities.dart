import 'package:flutter/material.dart';

class RecentActivities extends StatelessWidget {
  const RecentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'type': 'driver',
        'message': 'Driver baru terdaftar',
        'name': 'Ahmad Rizki',
        'time': '2 menit lalu',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'type': 'umkm',
        'message': 'UMKM baru terdaftar',
        'name': 'Warung Pak Budi',
        'time': '15 menit lalu',
        'icon': Icons.store_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'type': 'order',
        'message': 'Pesanan selesai',
        'name': 'Order #1847',
        'time': '1 jam lalu',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'type': 'withdrawal',
        'message': 'Penarikan disetujui',
        'name': 'Rp 500.000',
        'time': '2 jam lalu',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'type': 'driver',
        'message': 'Driver diverifikasi',
        'name': 'Budi Santoso',
        'time': '3 jam lalu',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFF10B981),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Aktivitas Terkini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...activities.map((activity) => _buildActivityItem(
                message: activity['message'] as String,
                name: activity['name'] as String,
                time: activity['time'] as String,
                icon: activity['icon'] as IconData,
                color: activity['color'] as Color,
              )),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String message,
    required String name,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}