// ============================================================================
// KTM_VERIFICATION_MODEL.DART
// Model untuk handle KTM verification request
// ============================================================================

class KtmVerificationModel {
  final String id;
  final String? idUser; // ✅ NULLABLE for pre-registration support
  final String nim;
  final String fotoKtmUrl;
  final String? extractedName;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  KtmVerificationModel({
    required this.id,
    this.idUser, // ✅ Optional parameter for pre-registration
    required this.nim,
    required this.fotoKtmUrl,
    this.extractedName,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  // From JSON
  factory KtmVerificationModel.fromJson(Map<String, dynamic> json) {
    return KtmVerificationModel(
      id: json['id'] as String,
      idUser: json['id_user'] as String?, // ✅ Safe cast to nullable
      nim: json['nim'] as String,
      fotoKtmUrl: json['foto_ktm_url'] as String,
      extractedName: json['extracted_name'] as String?,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'] as String) 
          : null,
      reviewedBy: json['reviewed_by'] as String?,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': idUser,
      'nim': nim,
      'foto_ktm_url': fotoKtmUrl,
      'extracted_name': extractedName,
      'status': status,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
    };
  }

  // Copy with
  KtmVerificationModel copyWith({
    String? id,
    String? idUser,
    String? nim,
    String? fotoKtmUrl,
    String? extractedName,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return KtmVerificationModel(
      id: id ?? this.id,
      idUser: idUser ?? this.idUser,
      nim: nim ?? this.nim,
      fotoKtmUrl: fotoKtmUrl ?? this.fotoKtmUrl,
      extractedName: extractedName ?? this.extractedName,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}