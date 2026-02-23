// ============================================================================
// USER_TRANSACTION_MODEL.DART
// Model untuk riwayat transaksi user (customer, driver, umkm)
// ============================================================================

class UserTransactionModel {
  final String idPesanan;
  final String idUser;
  final String jenis; // 'ojek' atau 'umkm'
  final String statusPesanan;
  final double totalHarga;
  final double? ongkir;
  final String? jenisKendaraan;
  final DateTime tanggalPesanan;
  final DateTime? waktuSelesai;
  final String? paymentMethod;
  final String? paymentStatus;

  // Untuk UMKM orders
  final String? idUmkm;
  final String? namaToko;
  final String? metodePengiriman;

  // Untuk Driver delivery
  final String? idDriver;
  final String? namaDriver;
  final double? jarakKm;
  final double? kompensasiDriver;

  // Rating
  final double? rating;
  final String? reviewText;

  // Nama customer — dari join users(nama) di getDriverDeliveries & getUmkmOrders
  // Key JSON: 'customer_name'
  final String? namaCustomer;

  UserTransactionModel({
    required this.idPesanan,
    required this.idUser,
    required this.jenis,
    required this.statusPesanan,
    required this.totalHarga,
    this.ongkir,
    this.jenisKendaraan,
    required this.tanggalPesanan,
    this.waktuSelesai,
    this.paymentMethod,
    this.paymentStatus,
    this.idUmkm,
    this.namaToko,
    this.metodePengiriman,
    this.idDriver,
    this.namaDriver,
    this.jarakKm,
    this.kompensasiDriver,
    this.rating,
    this.reviewText,
    this.namaCustomer,
  });

  factory UserTransactionModel.fromJson(Map<String, dynamic> json) {
    return UserTransactionModel(
      idPesanan: json['id_pesanan'],
      idUser: json['id_user'],
      jenis: json['jenis'],
      statusPesanan: json['status_pesanan'],
      totalHarga: (json['total_harga'] ?? 0).toDouble(),
      ongkir: json['ongkir'] != null ? (json['ongkir'] as num).toDouble() : null,
      jenisKendaraan: json['jenis_kendaraan'],
      tanggalPesanan: DateTime.parse(json['tanggal_pesanan']),
      waktuSelesai: json['waktu_selesai'] != null
          ? DateTime.parse(json['waktu_selesai'])
          : null,
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      idUmkm: json['id_umkm'],
      namaToko: json['nama_toko'],
      metodePengiriman: json['metode_pengiriman'],
      idDriver: json['id_driver'],
      namaDriver: json['nama_driver'],
      jarakKm: json['jarak_km'] != null
          ? (json['jarak_km'] as num).toDouble()
          : null,
      kompensasiDriver: json['kompensasi_driver'] != null
          ? (json['kompensasi_driver'] as num).toDouble()
          : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewText: json['review_text'],
      namaCustomer: json['customer_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pesanan': idPesanan,
      'id_user': idUser,
      'jenis': jenis,
      'status_pesanan': statusPesanan,
      'total_harga': totalHarga,
      'ongkir': ongkir,
      'jenis_kendaraan': jenisKendaraan,
      'tanggal_pesanan': tanggalPesanan.toIso8601String(),
      'waktu_selesai': waktuSelesai?.toIso8601String(),
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'id_umkm': idUmkm,
      'nama_toko': namaToko,
      'metode_pengiriman': metodePengiriman,
      'id_driver': idDriver,
      'nama_driver': namaDriver,
      'jarak_km': jarakKm,
      'kompensasi_driver': kompensasiDriver,
      'rating': rating,
      'review_text': reviewText,
      'customer_name': namaCustomer,
    };
  }
}