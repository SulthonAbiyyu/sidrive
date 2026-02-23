// PESANAN MODEL - Model untuk order ojek/UMKM
class PesananModel {
  final String idPesanan;
  final String idCustomer;
  final String? idDriver;
  final String? idUmkm;
  final String jenisPesanan; // 'ojek' atau 'umkm'
  final String? jenisKendaraan; // 'motor' atau 'mobil' (untuk ojek)
  final String lokasiJemput;
  final String lokasiAntar;
  final double? jarakKm;
  final double totalHarga;
  final String metodeBayar;
  final String statusPesanan; // 'pending', 'accepted', 'on_going', 'completed', 'cancelled'
  final String statusPembayaran; // 'unpaid', 'paid'
  final String? catatan;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PesananModel({
    required this.idPesanan,
    required this.idCustomer,
    this.idDriver,
    this.idUmkm,
    required this.jenisPesanan,
    this.jenisKendaraan,
    required this.lokasiJemput,
    required this.lokasiAntar,
    this.jarakKm,
    required this.totalHarga,
    required this.metodeBayar,
    required this.statusPesanan,
    required this.statusPembayaran,
    this.catatan,
    required this.createdAt,
    this.updatedAt,
  });

  factory PesananModel.fromJson(Map<String, dynamic> json) {
    return PesananModel(
      idPesanan: json['id_pesanan'],
      idCustomer: json['id_customer'],
      idDriver: json['id_driver'],
      idUmkm: json['id_umkm'],
      jenisPesanan: json['jenis_pesanan'],
      jenisKendaraan: json['jenis_kendaraan'],
      lokasiJemput: json['lokasi_jemput'],
      lokasiAntar: json['lokasi_antar'],
      jarakKm: json['jarak_km']?.toDouble(),
      totalHarga: json['total_harga'].toDouble(),
      metodeBayar: json['metode_bayar'],
      statusPesanan: json['status_pesanan'],
      statusPembayaran: json['status_pembayaran'],
      catatan: json['catatan'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pesanan': idPesanan,
      'id_customer': idCustomer,
      'id_driver': idDriver,
      'id_umkm': idUmkm,
      'jenis_pesanan': jenisPesanan,
      'jenis_kendaraan': jenisKendaraan,
      'lokasi_jemput': lokasiJemput,
      'lokasi_antar': lokasiAntar,
      'jarak_km': jarakKm,
      'total_harga': totalHarga,
      'metode_bayar': metodeBayar,
      'status_pesanan': statusPesanan,
      'status_pembayaran': statusPembayaran,
      'catatan': catatan,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
