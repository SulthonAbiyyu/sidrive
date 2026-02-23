import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class OrderUtils {
  // Format currency
  static String formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Show max distance dialog
  static void showMaxDistanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        title: Text(
          'Jarak Melebihi Batas',
          style: TextStyle(fontSize: ResponsiveMobile.titleSize(context)),
        ),
        content: Text(
          'Maaf, jarak maksimal adalah 10 km. Silakan pilih tujuan yang lebih dekat.',
          style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
            ),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: ResponsiveMobile.titleSize(context)),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
            ),
          ),
        ],
      ),
    );
  }

  // Show timeout dialog
  static void showTimeoutDialog(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: ResponsiveMobile.scaledFont(28),
            ),
            SizedBox(width: ResponsiveMobile.scaledW(12)),
            Expanded(
              child: Text(
                'Driver Tidak Ditemukan',
                style: TextStyle(fontSize: ResponsiveMobile.titleSize(context)),
              ),
            ),
          ],
        ),
        content: Text(
          'Maaf, tidak ada driver yang tersedia saat ini. Silakan coba lagi.',
          style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: Size(
                double.infinity,
                ResponsiveMobile.minTouchTargetSize(context),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              ),
            ),
            child: Text(
              'Coba Lagi',
              style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
            ),
          ),
        ],
      ),
    );
  }

  // Show cancel confirm dialog
  static Future<bool?> showCancelConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        title: Text(
          'Batalkan Pesanan?',
          style: TextStyle(fontSize: ResponsiveMobile.titleSize(context)),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini?',
          style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Tidak',
              style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
              ),
            ),
            child: Text(
              'Ya, Batalkan',
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
