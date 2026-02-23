class ProdukModel {
  final String idProduk;
  final String idUmkm;
  final String namaProduk;
  final String? deskripsiProduk;
  final double hargaProduk;
  final String kategoriProduk;
  final int stok;
  final bool isAvailable;
  final List<String>? fotoProduk;
  final double ratingProduk;
  final int totalRating;
  final int totalTerjual;
  final int waktuPersiapanMenit;
  final int? beratGram;
  final String? allowedDriverType; 
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProdukModel({
    required this.idProduk,
    required this.idUmkm,
    required this.namaProduk,
    this.deskripsiProduk,
    required this.hargaProduk,
    required this.kategoriProduk,
    required this.stok,
    required this.isAvailable,
    this.fotoProduk,
    required this.ratingProduk,
    required this.totalRating,
    required this.totalTerjual,
    required this.waktuPersiapanMenit,
    this.beratGram,
    this.allowedDriverType, 
    required this.createdAt,
    this.updatedAt,
  });

  factory ProdukModel.fromJson(Map<String, dynamic> json) {
    return ProdukModel(
      idProduk: json['id_produk'],
      idUmkm: json['id_umkm'],
      namaProduk: json['nama_produk'],
      deskripsiProduk: json['deskripsi_produk'],
      hargaProduk: (json['harga_produk'] ?? 0).toDouble(),
      kategoriProduk: json['kategori_produk'] ?? json['kategori'] ?? 'lainnya',
      stok: json['stok'] ?? 0,
      isAvailable: json['is_available'] ?? false,
      fotoProduk: json['foto_produk'] != null ? List<String>.from(json['foto_produk']) : null,
      ratingProduk: (json['rating_produk'] ?? 0).toDouble(),
      totalRating: json['total_rating'] ?? 0,
      totalTerjual: json['total_terjual'] ?? 0,
      waktuPersiapanMenit: json['waktu_persiapan_menit'] ?? 15,
      beratGram: json['berat_gram'],
      allowedDriverType: json['allowed_driver_type'], 
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_produk': idProduk,
      'id_umkm': idUmkm,
      'nama_produk': namaProduk,
      'deskripsi_produk': deskripsiProduk,
      'harga_produk': hargaProduk,
      'kategori_produk': kategoriProduk,
      'stok': stok,
      'is_available': isAvailable,
      'foto_produk': fotoProduk,
      'rating_produk': ratingProduk,
      'total_rating': totalRating,
      'total_terjual': totalTerjual,
      'waktu_persiapan_menit': waktuPersiapanMenit,
      'berat_gram': beratGram,
      'allowed_driver_type': allowedDriverType, 
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProdukModel copyWith({
    String? idProduk,
    String? idUmkm,
    String? namaProduk,
    String? deskripsiProduk,
    double? hargaProduk,
    String? kategoriProduk,
    int? stok,
    bool? isAvailable,
    List<String>? fotoProduk,
    double? ratingProduk,
    int? totalRating,
    int? totalTerjual,
    int? waktuPersiapanMenit,
    int? beratGram,
    String? allowedDriverType, 
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProdukModel(
      idProduk: idProduk ?? this.idProduk,
      idUmkm: idUmkm ?? this.idUmkm,
      namaProduk: namaProduk ?? this.namaProduk,
      deskripsiProduk: deskripsiProduk ?? this.deskripsiProduk,
      hargaProduk: hargaProduk ?? this.hargaProduk,
      kategoriProduk: kategoriProduk ?? this.kategoriProduk,
      stok: stok ?? this.stok,
      isAvailable: isAvailable ?? this.isAvailable,
      fotoProduk: fotoProduk ?? this.fotoProduk,
      ratingProduk: ratingProduk ?? this.ratingProduk,
      totalRating: totalRating ?? this.totalRating,
      totalTerjual: totalTerjual ?? this.totalTerjual,
      waktuPersiapanMenit: waktuPersiapanMenit ?? this.waktuPersiapanMenit,
      beratGram: beratGram ?? this.beratGram,
      allowedDriverType: allowedDriverType ?? this.allowedDriverType, 
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isReady => isAvailable && stok > 0;
  String get hargaFormatted => 'Rp${hargaProduk.toStringAsFixed(0)}';
  String get ratingText {
    if (totalRating == 0) return 'Belum ada rating';
    return '${ratingProduk.toStringAsFixed(1)} ($totalRating)';
  }
  String get stokText {
    if (stok == 0) return 'Habis';
    if (stok < 10) return 'Stok $stok';
    return 'Tersedia';
  }
  String get kategoriDisplay {
    return kategoriProduk[0].toUpperCase() + kategoriProduk.substring(1);
  }
}