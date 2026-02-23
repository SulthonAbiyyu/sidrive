import 'package:flutter/material.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class AdminDeleteDialog extends StatelessWidget {
  final AdminModel admin;
  final VoidCallback onConfirm;

  const AdminDeleteDialog({
    super.key,
    required this.admin,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
      ),
      child: Container(
        width: 400,
        padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
            Text(
              'Hapus Admin?',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontH4(),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            SizedBox(height: ResponsiveAdmin.spaceXS() + 4),
            Text(
              'Apakah Anda yakin ingin menghapus admin ini?',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody(),
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
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
                  _buildInfoRow(Icons.person_rounded, 'Nama', admin.nama),
                  SizedBox(height: ResponsiveAdmin.spaceXS()),
                  _buildInfoRow(Icons.alternate_email_rounded, 'Username', admin.username),
                  SizedBox(height: ResponsiveAdmin.spaceXS()),
                  _buildInfoRow(Icons.email_outlined, 'Email', admin.email),
                ],
              ),
            ),
            SizedBox(height: ResponsiveAdmin.spaceMD()),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: ResponsiveAdmin.spaceSM()),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: ResponsiveAdmin.fontBody(),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: ResponsiveAdmin.spaceSM()),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: ResponsiveAdmin.fontBody(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        SizedBox(width: ResponsiveAdmin.spaceXS()),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: ResponsiveAdmin.fontSmall(),
            color: const Color(0xFF6B7280),
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}