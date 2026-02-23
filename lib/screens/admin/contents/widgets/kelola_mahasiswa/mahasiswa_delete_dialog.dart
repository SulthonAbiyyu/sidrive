import 'package:flutter/material.dart';
import 'package:sidrive/models/mahasiswa_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class MahasiswaDeleteDialog extends StatelessWidget {
  final MahasiswaModel mahasiswa;
  final Future<void> Function() onConfirm;

  const MahasiswaDeleteDialog({
    super.key,
    required this.mahasiswa,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD() + 4),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS() + 2),
            ),
            child: const Icon(
              Icons.delete_rounded,
              color: Color(0xFFEF4444),
              size: 18,
            ),
          ),
          SizedBox(width: ResponsiveAdmin.spaceSM()),
          Expanded(
            child: Text(
              'Hapus Mahasiswa',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody() + 2,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apakah Anda yakin ingin menghapus mahasiswa berikut?',
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontCaption() + 1,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: ResponsiveAdmin.spaceSM()),
          Container(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nama', mahasiswa.namaLengkap),
                SizedBox(height: ResponsiveAdmin.spaceXS()),
                _buildInfoRow('NIM', mahasiswa.nim),
                if (mahasiswa.programStudi != null) ...[
                  SizedBox(height: ResponsiveAdmin.spaceXS()),
                  _buildInfoRow('Prodi', mahasiswa.programStudi!),
                ],
              ],
            ),
          ),
          SizedBox(height: ResponsiveAdmin.spaceSM()),
          Container(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 16,
                ),
                SizedBox(width: ResponsiveAdmin.spaceXS() + 2),
                Expanded(
                  child: Text(
                    'Data mahasiswa akan dihapus secara permanen',
                    style: TextStyle(
                      fontSize: ResponsiveAdmin.fontSmall(),
                      color: const Color(0xFF991B1B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontCaption() + 1,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            await onConfirm();
          },
          icon: const Icon(Icons.delete_rounded, size: 14),
          label: Text(
            'Hapus',
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontCaption() + 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveAdmin.spaceSM() + 6,
              vertical: ResponsiveAdmin.spaceXS() + 4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
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
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}