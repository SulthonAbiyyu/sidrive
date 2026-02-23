// ============================================================================
// DETAIL_PESANAN_MODEL.DART
// Model untuk item dalam pesanan (cart items)
// ============================================================================

class DetailPesananModel {
  final String idDetail;
  final String idPesanan;
  final String idProduk;
  final String namaProduk;
  final double hargaSatuan;
  final int jumlah;
  final double subtotal;
  final String? catatanItem;
  final DateTime createdAt;

  DetailPesananModel({
    required this.idDetail,
    required this.idPesanan,
    required this.idProduk,
    required this.namaProduk,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotal,
    this.catatanItem,
    required this.createdAt,
  });

  factory DetailPesananModel.fromJson(Map<String, dynamic> json) {
    return DetailPesananModel(
      idDetail: json['id_detail'],
      idPesanan: json['id_pesanan'],
      idProduk: json['id_produk'],
      namaProduk: json['nama_produk'],
      hargaSatuan: (json['harga_satuan'] ?? 0).toDouble(),
      jumlah: json['jumlah'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      catatanItem: json['catatan_item'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_detail': idDetail,
      'id_pesanan': idPesanan,
      'id_produk': idProduk,
      'nama_produk': namaProduk,
      'harga_satuan': hargaSatuan,
      'jumlah': jumlah,
      'subtotal': subtotal,
      'catatan_item': catatanItem,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper
  String get hargaFormatted => 'Rp${hargaSatuan.toStringAsFixed(0)}';
  String get subtotalFormatted => 'Rp${subtotal.toStringAsFixed(0)}';
}