// ============================================================================
// ADMIN PAYOUT MODEL
// Model untuk tracking penarikan saldo admin ke rekening bank
// ============================================================================

class AdminPayoutModel {
  final String id;
  final String idAdmin;
  final String adminNama;
  final double amount;
  final String bankCode; // bca, mandiri, bni, bri, dll
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String? referenceNo; // dari Midtrans
  final String status; // pending, processing, completed, failed
  final String? notes;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;

  AdminPayoutModel({
    required this.id,
    required this.idAdmin,
    required this.adminNama,
    required this.amount,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    this.referenceNo,
    required this.status,
    this.notes,
    this.failureReason,
    required this.createdAt,
    this.processedAt,
    this.completedAt,
  });

  factory AdminPayoutModel.fromJson(Map<String, dynamic> json) {
    return AdminPayoutModel(
      id: json['id'] ?? '',
      idAdmin: json['id_admin'] ?? '',
      adminNama: json['admin_nama'] ?? 'Unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      bankCode: json['bank_code'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      referenceNo: json['reference_no'],
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      failureReason: json['failure_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_admin': idAdmin,
      'admin_nama': adminNama,
      'amount': amount,
      'bank_code': bankCode,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder_name': accountHolderName,
      'reference_no': referenceNo,
      'status': status,
      'notes': notes,
      'failure_reason': failureReason,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // Helper untuk warna status
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return '0xFF10B981'; // green
      case 'processing':
        return '0xFF3B82F6'; // blue
      case 'pending':
        return '0xFFF59E0B'; // yellow
      case 'failed':
        return '0xFFEF4444'; // red
      default:
        return '0xFF6B7280'; // gray
    }
  }

  // Helper untuk status text
  String get statusText {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Berhasil';
      case 'processing':
        return 'Diproses';
      case 'pending':
        return 'Menunggu';
      case 'failed':
        return 'Gagal';
      default:
        return status;
    }
  }

  // Copy with method untuk update
  AdminPayoutModel copyWith({
    String? id,
    String? idAdmin,
    String? adminNama,
    double? amount,
    String? bankCode,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
    String? referenceNo,
    String? status,
    String? notes,
    String? failureReason,
    DateTime? createdAt,
    DateTime? processedAt,
    DateTime? completedAt,
  }) {
    return AdminPayoutModel(
      id: id ?? this.id,
      idAdmin: idAdmin ?? this.idAdmin,
      adminNama: adminNama ?? this.adminNama,
      amount: amount ?? this.amount,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      referenceNo: referenceNo ?? this.referenceNo,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// ============================================================================
// BANK INFO
// Data bank yang supported untuk payout
// ============================================================================

class BankInfo {
  final String code;
  final String name;
  final String logoAsset; // path ke logo bank di assets

  const BankInfo({
    required this.code,
    required this.name,
    required this.logoAsset,
  });

  // List bank yang supported Midtrans
  static const List<BankInfo> supportedBanks = [
    BankInfo(code: 'bca', name: 'BCA', logoAsset: 'assets/banks/bca.png'),
    BankInfo(code: 'mandiri', name: 'Mandiri', logoAsset: 'assets/banks/mandiri.png'),
    BankInfo(code: 'bni', name: 'BNI', logoAsset: 'assets/banks/bni.png'),
    BankInfo(code: 'bri', name: 'BRI', logoAsset: 'assets/banks/bri.png'),
    BankInfo(code: 'permata', name: 'Permata', logoAsset: 'assets/banks/permata.png'),
    BankInfo(code: 'cimb', name: 'CIMB Niaga', logoAsset: 'assets/banks/cimb.png'),
    BankInfo(code: 'danamon', name: 'Danamon', logoAsset: 'assets/banks/danamon.png'),
    BankInfo(code: 'btn', name: 'BTN', logoAsset: 'assets/banks/btn.png'),
  ];

  static BankInfo? getByCode(String code) {
    try {
      return supportedBanks.firstWhere((b) => b.code == code.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}