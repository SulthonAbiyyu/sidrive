import 'package:flutter/material.dart';

class CustomerTrackingConstants {
  // ========================================================================
  // STATUS TIMELINE - OJEK (PENGIRIMAN STATUS)
  // Ini untuk tracking saat sudah ada driver (status_pengiriman)
  // ========================================================================
  static final List<Map<String, dynamic>> statusTimeline = [
    {'status': 'diterima', 'label': 'Diterima', 'icon': Icons.check_circle},
    {'status': 'menuju_pickup', 'label': 'Menuju Jemput', 'icon': Icons.directions_car},
    {'status': 'sampai_pickup', 'label': 'Tiba Jemput', 'icon': Icons.location_on},
    {'status': 'customer_naik', 'label': 'Customer Naik', 'icon': Icons.person},
    {'status': 'perjalanan', 'label': 'Perjalanan', 'icon': Icons.local_shipping},
    {'status': 'sampai_tujuan', 'label': 'Tiba Tujuan', 'icon': Icons.place},
    {'status': 'selesai', 'label': 'Selesai', 'icon': Icons.done_all},
  ];

  // ========================================================================
  // STATUS TIMELINE - UMKM DELIVERY (PENGIRIMAN STATUS)
  // Ini untuk tracking saat sudah ada driver (status_pengiriman)
  // ========================================================================
  static List<Map<String, dynamic>> getUmkmDeliverySteps() {
    return [
      {'status': 'diterima', 'label': 'Diterima', 'icon': Icons.check_circle},
      {'status': 'menuju_pickup', 'label': 'Menuju Toko', 'icon': Icons.directions_car},
      {'status': 'sampai_pickup', 'label': 'Tiba di Toko', 'icon': Icons.store},
      {'status': 'customer_naik', 'label': 'Ambil Barang', 'icon': Icons.shopping_bag},
      {'status': 'perjalanan', 'label': 'Kirim ke Anda', 'icon': Icons.local_shipping},
      {'status': 'sampai_tujuan', 'label': 'Tiba Tujuan', 'icon': Icons.place},
      {'status': 'selesai', 'label': 'Selesai', 'icon': Icons.done_all},
    ];
  }

  // ========================================================================
  // ✅ NEW: STATUS PESANAN TIMELINE - UMKM ORDER
  // Ini untuk tracking SEBELUM ada driver (status_pesanan)
  // ========================================================================
  static List<Map<String, dynamic>> getUmkmOrderSteps({required bool hasDriver}) {
    if (hasDriver) {
      // ✅ UMKM dengan driver - 7 steps
      return [
        {
          'status': 'menunggu_pembayaran',
          'label': 'Menunggu Pembayaran',
          'icon': Icons.payment,
          'description': 'Silakan selesaikan pembayaran',
          'color': Colors.orange,
        },
        {
          'status': 'menunggu_konfirmasi',
          'label': 'Menunggu Konfirmasi Toko',
          'icon': Icons.store_outlined,
          'description': 'Toko sedang memproses pesanan',
          'color': Colors.blue,
        },
        {
          'status': 'diproses',
          'label': 'Pesanan Diproses',
          'icon': Icons.kitchen,
          'description': 'Toko sedang menyiapkan pesanan',
          'color': Colors.purple,
        },
        // ✅ NEW STEP: siap_kirim
        {
          'status': 'siap_kirim',
          'label': 'Siap Dikirim',
          'icon': Icons.inventory_2,
          'description': 'Pesanan siap, sedang mencari driver',
          'color': Colors.indigo,
        },
        {
          'status': 'mencari_driver',
          'label': 'Mencari Driver',
          'icon': Icons.search,
          'description': 'Mencari driver terdekat',
          'color': Colors.amber,
        },
        {
          'status': 'dalam_pengiriman',
          'label': 'Dalam Pengiriman',
          'icon': Icons.local_shipping,
          'description': 'Driver sedang mengantarkan pesanan',
          'color': Colors.green,
        },
        {
          'status': 'selesai',
          'label': 'Selesai',
          'icon': Icons.done_all,
          'description': 'Pesanan telah selesai',
          'color': Colors.green,
        },
      ];
    } else {
      // ✅ UMKM ambil sendiri - 5 steps
      return [
        {
          'status': 'menunggu_pembayaran',
          'label': 'Menunggu Pembayaran',
          'icon': Icons.payment,
          'description': 'Silakan selesaikan pembayaran',
          'color': Colors.orange,
        },
        {
          'status': 'menunggu_konfirmasi',
          'label': 'Menunggu Konfirmasi Toko',
          'icon': Icons.store_outlined,
          'description': 'Toko sedang memproses pesanan',
          'color': Colors.blue,
        },
        {
          'status': 'diproses',
          'label': 'Pesanan Diproses',
          'icon': Icons.kitchen,
          'description': 'Toko sedang menyiapkan pesanan',
          'color': Colors.purple,
        },
        // ✅ NEW STEP: siap_kirim untuk ambil sendiri
        {
          'status': 'siap_kirim',
          'label': 'Siap Diambil',
          'icon': Icons.inventory_2,
          'description': 'Pesanan siap diambil di toko',
          'color': Colors.indigo,
        },
        {
          'status': 'selesai',
          'label': 'Selesai',
          'icon': Icons.done_all,
          'description': 'Pesanan telah diambil',
          'color': Colors.green,
        },
      ];
    }
  }

  // ========================================================================
  // GET STATUS LABEL (SUPPORT OJEK & UMKM DELIVERY)
  // Ini untuk status_pengiriman (setelah driver accept)
  // ========================================================================
  static String getStatusLabel(String status, {bool isUmkm = false}) {
    if (isUmkm) {
      switch (status) {
        case 'diterima':
          return 'Driver Ditemukan';
        case 'menuju_pickup':
          return 'Driver Menuju Toko';
        case 'sampai_pickup':
          return 'Driver di Toko';
        case 'customer_naik':
          return 'Barang Diambil';
        case 'perjalanan':
          return 'Dalam Pengiriman';
        case 'sampai_tujuan':
          return 'Sampai Tujuan';
        case 'selesai':
          return 'Pesanan Selesai';
        default:
          return 'Status Tidak Diketahui';
      }
    }
    
    // Ojek labels (existing)
    switch (status) {
      case 'diterima':
        return 'Driver Ditemukan';
      case 'menuju_pickup':
        return 'Driver Menuju Lokasi';
      case 'sampai_pickup':
        return 'Driver Telah Tiba';
      case 'customer_naik':
        return 'Perjalanan Dimulai';
      case 'perjalanan':
        return 'Dalam Perjalanan';
      case 'sampai_tujuan':
        return 'Sampai di Tujuan';
      case 'selesai':
        return 'Pesanan Selesai';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  // ========================================================================
  // ✅ NEW: GET ORDER STATUS LABEL (UNTUK STATUS_PESANAN)
  // Ini untuk status sebelum ada driver
  // ========================================================================
  static String getOrderStatusLabel(String status, {required bool hasDriver}) {
    switch (status) {
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'menunggu_konfirmasi':
        return 'Menunggu Konfirmasi Toko';
      case 'diproses':
        return 'Pesanan Diproses';
      case 'siap_kirim':
        return hasDriver ? 'Siap Dikirim' : 'Siap Diambil';
      case 'mencari_driver':
        return 'Mencari Driver';
      case 'dalam_pengiriman':
        return 'Dalam Pengiriman';
      case 'selesai':
        return hasDriver ? 'Pesanan Selesai' : 'Siap Diambil';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  // ========================================================================
  // ✅ NEW: GET ORDER STATUS DESCRIPTION
  // ========================================================================
  static String getOrderStatusDescription(String status, {required bool hasDriver}) {
    switch (status) {
      case 'menunggu_pembayaran':
        return 'Silakan selesaikan pembayaran untuk melanjutkan pesanan';
      case 'menunggu_konfirmasi':
        return 'Toko sedang memproses pesanan Anda. Mohon tunggu konfirmasi';
      case 'diproses':
        return 'Toko sedang menyiapkan pesanan Anda';
      // ✅ ADD THIS:
      case 'siap_kirim':
        return hasDriver 
            ? 'Pesanan sudah siap, sedang mencari driver untuk mengantarkan pesanan'
            : 'Pesanan sudah siap diambil di toko. Tunjukkan kode pesanan Anda';
      case 'mencari_driver':
        return 'Sedang mencari driver terdekat untuk mengantarkan pesanan';
      case 'dalam_pengiriman':
        return 'Driver sedang dalam perjalanan mengantarkan pesanan Anda';
      case 'selesai':
        return hasDriver 
            ? 'Pesanan telah selesai. Terima kasih!' 
            : 'Pesanan telah diambil. Terima kasih!';
      case 'dibatalkan':
        return 'Pesanan telah dibatalkan';
      default:
        return '';
    }
  }

  // ========================================================================
  // ✅ NEW: GET ORDER STATUS ICON
  // ========================================================================
  static IconData getOrderStatusIcon(String status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return Icons.payment;
      case 'menunggu_konfirmasi':
        return Icons.store_outlined;
      case 'diproses':
        return Icons.kitchen;
      // ✅ ADD THIS:
      case 'siap_kirim':
        return Icons.inventory_2;
      case 'mencari_driver':
        return Icons.search;
      case 'dalam_pengiriman':
        return Icons.local_shipping;
      case 'selesai':
        return Icons.done_all;
      case 'dibatalkan':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // ========================================================================
  // ✅ NEW: GET ORDER STATUS COLOR
  // ========================================================================
  static Color getOrderStatusColor(String status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return Colors.orange;
      case 'menunggu_konfirmasi':
        return Colors.blue;
      case 'diproses':
        return Colors.purple;
      // ✅ ADD THIS:
      case 'siap_kirim':
        return Colors.indigo;
      case 'mencari_driver':
        return Colors.amber;
      case 'dalam_pengiriman':
        return Colors.green;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ========================================================================
  // CURRENCY FORMATTER
  // ========================================================================
  static String formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}