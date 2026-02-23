// ============================================================================
// RATING_ULASAN_MODEL.DART
// Model universal untuk rating & review (Driver, UMKM, Produk)
// ============================================================================

class RatingUlasanModel {
  final String idReview;
  final String idPesanan;
  final String idUser;
  final String targetType;  // 'driver' | 'produk'
  final String targetId;
  final int rating;
  final String? reviewText;
  final List<String>? fotoUlasan;
  final String? balasan;
  final DateTime? balasanAt;
  final String? balasanBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // ✅ TAMBAHAN: Data enriched (dari join)
  String? customerName;
  String? customerPhoto;

  RatingUlasanModel({
    required this.idReview,
    required this.idPesanan,
    required this.idUser,
    required this.targetType,
    required this.targetId,
    required this.rating,
    this.reviewText,
    this.fotoUlasan,
    this.balasan,
    this.balasanAt,
    this.balasanBy,
    required this.createdAt,
    this.updatedAt,
    this.customerName,
    this.customerPhoto,
  });

  // ============================================================================
  // FROM JSON
  // ============================================================================
  factory RatingUlasanModel.fromJson(Map<String, dynamic> json) {
    return RatingUlasanModel(
      idReview: json['id_review'],
      idPesanan: json['id_pesanan'],
      idUser: json['id_user'],
      targetType: json['target_type'],
      targetId: json['target_id'],
      rating: json['rating'],
      reviewText: json['review_text'],
      fotoUlasan: json['foto_ulasan'] != null
          ? List<String>.from(json['foto_ulasan'])
          : null,
      balasan: json['balasan'],
      balasanAt: json['balasan_at'] != null
          ? DateTime.parse(json['balasan_at'])
          : null,
      balasanBy: json['balasan_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      customerName: json['customer_name'],
      customerPhoto: json['customer_photo'],
    );
  }

  // ============================================================================
  // TO JSON
  // ============================================================================
  Map<String, dynamic> toJson() {
    return {
      'id_review': idReview,
      'id_pesanan': idPesanan,
      'id_user': idUser,
      'target_type': targetType,
      'target_id': targetId,
      'rating': rating,
      'review_text': reviewText,
      'foto_ulasan': fotoUlasan,
      'balasan': balasan,
      'balasan_at': balasanAt?.toIso8601String(),
      'balasan_by': balasanBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ============================================================================
  // HELPERS
  // ============================================================================
  bool get hasBalasan => balasan != null && balasan!.isNotEmpty;
  
  bool get hasFoto => fotoUlasan != null && fotoUlasan!.isNotEmpty;

  String get targetTypeLabel {
    switch (targetType) {
      case 'driver':
        return 'Driver';
      case 'produk':
        return 'Produk';
      case 'umkm':
        return 'Toko';
      default:
        return 'Unknown';
    }
  }

  // ✅ Copy with (untuk update data)
  RatingUlasanModel copyWith({
    String? idReview,
    String? idPesanan,
    String? idUser,
    String? targetType,
    String? targetId,
    int? rating,
    String? reviewText,
    List<String>? fotoUlasan,
    String? balasan,
    DateTime? balasanAt,
    String? balasanBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? customerPhoto,
  }) {
    return RatingUlasanModel(
      idReview: idReview ?? this.idReview,
      idPesanan: idPesanan ?? this.idPesanan,
      idUser: idUser ?? this.idUser,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      fotoUlasan: fotoUlasan ?? this.fotoUlasan,
      balasan: balasan ?? this.balasan,
      balasanAt: balasanAt ?? this.balasanAt,
      balasanBy: balasanBy ?? this.balasanBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      customerPhoto: customerPhoto ?? this.customerPhoto,
    );
  }
}