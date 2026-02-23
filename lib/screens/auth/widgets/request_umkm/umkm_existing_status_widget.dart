import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class UmkmExistingStatusWidget extends StatelessWidget {
  final String status;
  final VoidCallback onBack;

  const UmkmExistingStatusWidget({
    super.key,
    required this.status,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    
    return Center(
      child: Padding(
        padding: ResponsiveMobile.horizontalPadding(context, 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: ResponsiveMobile.allScaledPadding(24),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.check_circle_rounded : Icons.schedule_rounded,
                size: ResponsiveMobile.scaledFont(64),
                color: isActive ? Colors.green.shade600 : Colors.orange.shade600,
              ),
            ),
            ResponsiveMobile.vSpace(24),
            Text(
              isActive ? 'Toko Sudah Aktif' : 'Toko Sudah Terdaftar',
              style: TextStyle(
                fontSize: ResponsiveMobile.titleSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveMobile.vSpace(12),
            Text(
              isActive
                  ? 'Toko UMKM Anda sudah aktif dan dapat digunakan untuk berjualan.'
                  : 'Toko UMKM Anda sedang dalam proses verifikasi. Silakan tunggu notifikasi dari admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context),
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            ResponsiveMobile.vSpace(32),
            SizedBox(
              width: ResponsiveMobile.wp(context, 60),
              child: ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveMobile.scaledH(14),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}