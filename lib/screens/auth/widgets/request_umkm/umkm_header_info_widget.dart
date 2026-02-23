import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class UmkmHeaderInfoWidget extends StatelessWidget {
  const UmkmHeaderInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: ResponsiveMobile.allScaledPadding(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
            ),
            child: Icon(
              Icons.store_rounded,
              color: Colors.white,
              size: ResponsiveMobile.scaledFont(24),
            ),
          ),
          ResponsiveMobile.hSpace(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lengkapi data toko dan upload dokumen untuk proses verifikasi. Setelah disetujui admin, Anda dapat mulai berjualan.',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.captionSize(context),
                    height: 1.5,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}