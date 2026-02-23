import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class MahasiswaHeader extends StatelessWidget {
  final int totalItems;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const MahasiswaHeader({
    super.key,
    required this.totalItems,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
          ),
          
          SizedBox(width: ResponsiveAdmin.spaceSM() + 4),
          
          // Title & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Mahasiswa',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontH4(),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: ResponsiveAdmin.spaceXS() - 2),
                Text(
                  '$totalItems mahasiswa terdaftar',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontSmall(),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              // Refresh Button
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF6B7280),
                  padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 2),
                  minimumSize: const Size(32, 32),
                ),
                tooltip: 'Refresh Data',
              ),
              
              SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
              
              // Tambah Button
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(
                  'Tambah Mahasiswa',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontCaption() + 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveAdmin.spaceSM() + 6,
                    vertical: ResponsiveAdmin.spaceXS() + 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                  ),
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}