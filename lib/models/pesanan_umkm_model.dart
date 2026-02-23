import 'package:flutter/material.dart';

class PesananUmkmModel {
  final String idPesanan;
  final String idUser;
  final String customerName;
  final String customerPhone;
  final String alamatTujuan;
  final String statusPesanan;
  final String paymentMethod;
  final String paymentStatus;
  final String metodePengiriman;
  final String? jenisKendaraan;
  final double subtotal;
  final double ongkir;
  final String? catatan;
  final DateTime tanggalPesanan;
  final List<DetailPesananItem> items;

  PesananUmkmModel({
    required this.idPesanan,
    required this.idUser,
    required this.customerName,
    required this.customerPhone,
    required this.alamatTujuan,
    required this.statusPesanan,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.metodePengiriman,
    this.jenisKendaraan,
    required this.subtotal,
    required this.ongkir,
    this.catatan,
    required this.tanggalPesanan,
    required this.items,
  });

  // ✅ Total harga HANYA dari items (tanpa ongkir)
  // Perhitungan internal: jumlahkan semua subtotal dari detail_pesanan
  // Contoh: Ikan Mujaer (2x) + Bakso (1x) = total dari ketiga item tersebut
  double get totalHarga {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  factory PesananUmkmModel.fromJson(Map<String, dynamic> json) {
    List<DetailPesananItem> itemsList = [];
    if (json['detail_pesanan'] != null) {
      itemsList = (json['detail_pesanan'] as List)
          .map((item) => DetailPesananItem.fromJson(item))
          .toList();
    }

    return PesananUmkmModel(
      idPesanan: json['id_pesanan'],
      idUser: json['id_user'],
      customerName: json['users']?['nama'] ?? 'Unknown',
      customerPhone: json['users']?['no_telp'] ?? '-',
      alamatTujuan: json['alamat_tujuan'] ?? '-',
      statusPesanan: json['status_pesanan'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      metodePengiriman: json['metode_pengiriman'] ?? 'driver',
      jenisKendaraan: json['jenis_kendaraan'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      ongkir: (json['ongkir'] ?? 0).toDouble(),
      catatan: json['catatan'],
      tanggalPesanan: DateTime.parse(json['tanggal_pesanan']),
      items: itemsList,
    );
  }

  String get statusBadge {
    switch (statusPesanan) {
      case 'menunggu_pembayaran': return 'BAYAR';
      case 'menunggu_konfirmasi': return 'BARU';
      case 'diproses': return 'PROSES';
      case 'siap_kirim': return 'SIAP';
      case 'mencari_driver': return 'CARI DRIVER';
      case 'dalam_pengiriman': return 'KIRIM';
      case 'selesai': return 'SELESAI';
      case 'dibatalkan': return 'BATAL';
      default: return statusPesanan.toUpperCase();
    }
  }

  Color get statusColor {
    switch (statusPesanan) {
      case 'menunggu_pembayaran': return Color(0xFFFF9800); // Orange
      case 'menunggu_konfirmasi': return Color(0xFF2196F3); // Blue
      case 'diproses': return Color(0xFF9C27B0); // Purple
      case 'siap_kirim': return Color(0xFF3F51B5); // Indigo 
      case 'mencari_driver': return Color(0xFFFFB300); // Amber 
      case 'dalam_pengiriman': return Color(0xFF4CAF50); // Green
      case 'selesai': return Color(0xFF4CAF50); // Green
      case 'dibatalkan': return Color(0xFF757575); // Grey
      case 'gagal': return Color(0xFFF44336); // Red 
      default: return Color(0xFF9E9E9E);
    }
  }
}

class DetailPesananItem {
  final String namaProduk;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;
  final String? catatanItem;

  DetailPesananItem({
    required this.namaProduk,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.catatanItem,
  });

  factory DetailPesananItem.fromJson(Map<String, dynamic> json) {
    return DetailPesananItem(
      namaProduk: json['nama_produk'] ?? '',
      jumlah: json['jumlah'] ?? 0,
      hargaSatuan: (json['harga_satuan'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      catatanItem: json['catatan_item'],
    );
  }
}