// lib/screens/driver/widgets/request_driver/driver_header_info_widget.dart
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class DriverHeaderInfoWidget extends StatelessWidget {
  const DriverHeaderInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: ResponsiveMobile.allScaledPadding(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade300,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.info_rounded,
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
                  'Informasi Penting',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.bodySize(context) + 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade900,
                  ),
                ),
                ResponsiveMobile.vSpace(6),
                Text(
                  'Pilih jenis kendaraan yang ingin didaftarkan, lalu lengkapi data dan upload dokumen untuk proses verifikasi.',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.captionSize(context),
                    height: 1.5,
                    color: Colors.blue.shade800,
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