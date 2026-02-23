// lib/models/pendapatan_umkm_model.dart
class PendapatanUmkmModel {
  final double totalPenjualan;        // Subtotal produk (sebelum fee)
  final double totalPendapatan;       // 90% dari subtotal (setelah fee 10%)
  final int totalPesanan;
  final int totalProdukTerjual;
  final double totalOngkir;           // Total ongkir (jika pakai driver)
  final double totalFeeAdmin;         // 10% dari subtotal
  final List<Map<String, dynamic>> listPesanan;

  PendapatanUmkmModel({
    required this.totalPenjualan,
    required this.totalPendapatan,
    required this.totalPesanan,
    required this.totalProdukTerjual,
    required this.totalOngkir,
    required this.totalFeeAdmin,
    required this.listPesanan,
  });

  factory PendapatanUmkmModel.empty() {
    return PendapatanUmkmModel(
      totalPenjualan: 0,
      totalPendapatan: 0,
      totalPesanan: 0,
      totalProdukTerjual: 0,
      totalOngkir: 0,
      totalFeeAdmin: 0,
      listPesanan: [],
    );
  }

  factory PendapatanUmkmModel.fromJson(Map<String, dynamic> json) {
    return PendapatanUmkmModel(
      totalPenjualan: (json['total_penjualan'] ?? 0).toDouble(),
      totalPendapatan: (json['total_pendapatan'] ?? 0).toDouble(),
      totalPesanan: json['total_pesanan'] ?? 0,
      totalProdukTerjual: json['total_produk_terjual'] ?? 0,
      totalOngkir: (json['total_ongkir'] ?? 0).toDouble(),
      totalFeeAdmin: (json['total_fee_admin'] ?? 0).toDouble(),
      listPesanan: List<Map<String, dynamic>>.from(json['list_pesanan'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_penjualan': totalPenjualan,
      'total_pendapatan': totalPendapatan,
      'total_pesanan': totalPesanan,
      'total_produk_terjual': totalProdukTerjual,
      'total_ongkir': totalOngkir,
      'total_fee_admin': totalFeeAdmin,
      'list_pesanan': listPesanan,
    };
  }
}