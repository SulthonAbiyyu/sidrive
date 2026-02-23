// ============================================================================
// UMKM_MODEL.DART
// Model untuk data UMKM (Penjual/Toko)
// ============================================================================
import 'package:latlong2/latlong.dart';

class UmkmModel {
  final String idUmkm;
  final String idUser;
  final String namaToko;
  final String alamatToko;
  final String? alamatTokoLengkap;
  final String? deskripsiToko;
  final String? fotoToko;
  final double ratingToko;
  final int totalRating;
  final String statusToko; // 'buka', 'tutup'
  final double totalPenjualan;
  final int jumlahProdukTerjual;
  final String? namaBank;
  final String? namaRekening;
  final String? nomorRekening;
  final String? lokasiToko; // POINT geometry
  final LatLng? lokasiTokoLatLng;
  final String? jamBuka; // TIME
  final String? jamTutup; // TIME
  final String? kategoriToko;
  final List<String>? fotoProdukSample;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UmkmModel({
    required this.idUmkm,
    required this.idUser,
    required this.namaToko,
    required this.alamatToko,
    this.alamatTokoLengkap,
    this.deskripsiToko,
    this.fotoToko,
    required this.ratingToko,
    required this.totalRating,
    required this.statusToko,
    required this.totalPenjualan,
    required this.jumlahProdukTerjual,
    this.namaBank,
    this.namaRekening,
    this.nomorRekening,
    this.lokasiToko,
    this.lokasiTokoLatLng,
    this.jamBuka,
    this.jamTutup,
    this.kategoriToko,
    this.fotoProdukSample,
    required this.createdAt,
    this.updatedAt,
  });


  factory UmkmModel.fromJson(Map<String, dynamic> json) {
    LatLng? parsedLokasi;
    
    if (json['lokasi_toko'] != null) {
      try {
        final lokasiData = json['lokasi_toko'];
        
        // 🔥 DEBUGGING - Lihat format aslinya
        print('🗺️ Raw lokasi_toko: $lokasiData');
        print('🗺️ Type: ${lokasiData.runtimeType}');
        
        // Case 1: Jika berupa String "POINT(lng lat)"
        if (lokasiData is String) {
          final pointStr = lokasiData.toString();
          final coordinates = pointStr
              .replaceAll('POINT(', '')
              .replaceAll(')', '')
              .trim()
              .split(' ');
          
          if (coordinates.length == 2) {
            final lng = double.parse(coordinates[0]);
            final lat = double.parse(coordinates[1]);
            parsedLokasi = LatLng(lat, lng);
            print('✅ Parsed from String: $parsedLokasi');
          }
        }
        // Case 2: Jika berupa Map (GeoJSON format)
        else if (lokasiData is Map) {
          // Format GeoJSON: {"type": "Point", "coordinates": [lng, lat]}
          if (lokasiData['coordinates'] != null) {
            final coords = lokasiData['coordinates'] as List;
            if (coords.length == 2) {
              final lng = (coords[0] as num).toDouble();
              final lat = (coords[1] as num).toDouble();
              parsedLokasi = LatLng(lat, lng);
              print('✅ Parsed from GeoJSON: $parsedLokasi');
            }
          }
        }
      } catch (e, stackTrace) {
        print('⚠️ Error parsing lokasi_toko: $e');
        print('Stack: $stackTrace');
      }
    }


    return UmkmModel(
      idUmkm: json['id_umkm'] as String,
      idUser: json['id_user'] as String,
      namaToko: json['nama_toko'] as String,
      alamatToko: json['alamat_toko'] as String,
      alamatTokoLengkap: json['alamat_toko_lengkap'] as String?,
      deskripsiToko: json['deskripsi_toko'] as String?,
      fotoToko: json['foto_toko'] as String?,
      ratingToko: (json['rating_toko'] ?? 0).toDouble(),
      totalRating: json['total_rating'] as int? ?? 0,
      statusToko: json['status_toko'] as String? ?? 'tutup',
      totalPenjualan: (json['total_penjualan'] ?? 0).toDouble(),
      jumlahProdukTerjual: json['jumlah_produk_terjual'] as int? ?? 0,
      namaBank: json['nama_bank'] as String?,
      namaRekening: json['nama_rekening'] as String?,
      nomorRekening: json['nomor_rekening'] as String?,
      lokasiToko: json['lokasi_toko']?.toString(),
      lokasiTokoLatLng: parsedLokasi,
      jamBuka: json['jam_buka']?.toString(),
      jamTutup: json['jam_tutup']?.toString(),
      kategoriToko: json['kategori_toko'] as String?,
      fotoProdukSample: json['foto_produk_sample'] != null
          ? List<String>.from(json['foto_produk_sample'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_umkm': idUmkm,
      'id_user': idUser,
      'nama_toko': namaToko,
      'alamat_toko': alamatToko,
      'alamat_toko_lengkap': alamatTokoLengkap,
      'deskripsi_toko': deskripsiToko,
      'foto_toko': fotoToko,
      'rating_toko': ratingToko,
      'total_rating': totalRating,
      'status_toko': statusToko,
      'total_penjualan': totalPenjualan,
      'jumlah_produk_terjual': jumlahProdukTerjual,
      'nama_bank': namaBank,
      'nama_rekening': namaRekening,
      'nomor_rekening': nomorRekening,
      'lokasi_toko': lokasiToko,
      'jam_buka': jamBuka,
      'jam_tutup': jamTutup,
      'kategori_toko': kategoriToko,
      'foto_produk_sample': fotoProdukSample,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UmkmModel copyWith({
    String? idUmkm,
    String? idUser,
    String? namaToko,
    String? alamatToko,
    String? alamatTokoLengkap,
    String? deskripsiToko,
    String? fotoToko,
    double? ratingToko,
    int? totalRating,
    String? statusToko,
    double? totalPenjualan,
    int? jumlahProdukTerjual,
    String? namaBank,
    String? namaRekening,
    String? nomorRekening,
    String? lokasiToko,
    LatLng? lokasiTokoLatLng,
    String? jamBuka,
    String? jamTutup,
    String? kategoriToko,
    List<String>? fotoProdukSample,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UmkmModel(
      idUmkm: idUmkm ?? this.idUmkm,
      idUser: idUser ?? this.idUser,
      namaToko: namaToko ?? this.namaToko,
      alamatToko: alamatToko ?? this.alamatToko,
      alamatTokoLengkap: alamatTokoLengkap ?? this.alamatTokoLengkap,
      deskripsiToko: deskripsiToko ?? this.deskripsiToko,
      fotoToko: fotoToko ?? this.fotoToko,
      ratingToko: ratingToko ?? this.ratingToko,
      totalRating: totalRating ?? this.totalRating,
      statusToko: statusToko ?? this.statusToko,
      totalPenjualan: totalPenjualan ?? this.totalPenjualan,
      jumlahProdukTerjual: jumlahProdukTerjual ?? this.jumlahProdukTerjual,
      namaBank: namaBank ?? this.namaBank,
      namaRekening: namaRekening ?? this.namaRekening,
      nomorRekening: nomorRekening ?? this.nomorRekening,
      lokasiToko: lokasiToko ?? this.lokasiToko,
      lokasiTokoLatLng: lokasiTokoLatLng ?? this.lokasiTokoLatLng,
      jamBuka: jamBuka ?? this.jamBuka,
      jamTutup: jamTutup ?? this.jamTutup,
      kategoriToko: kategoriToko ?? this.kategoriToko,
      fotoProdukSample: fotoProdukSample ?? this.fotoProdukSample,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper: apakah toko sedang buka?
  bool get isBuka => statusToko == 'buka';

  // Helper: format jam operasional
  String get jamOperasional {
    if (jamBuka == null || jamTutup == null) return 'Belum diatur';
    return '$jamBuka - $jamTutup';
  }

  // Helper: rating text
  String get ratingText {
    if (totalRating == 0) return 'Belum ada rating';
    return '${ratingToko.toStringAsFixed(1)} ($totalRating ulasan)';
  }
}