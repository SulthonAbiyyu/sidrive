// ============================================================================
// SAVED BANK ACCOUNT MODEL
// Model untuk rekening bank yang disimpan admin
// ============================================================================

class SavedBankAccount {
  final String id;
  final String idAdmin;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  SavedBankAccount({
    required this.id,
    required this.idAdmin,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.isDefault,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory SavedBankAccount.fromJson(Map<String, dynamic> json) {
    return SavedBankAccount(
      id: json['id'] ?? '',
      idAdmin: json['id_admin'] ?? '',
      bankCode: json['bank_code'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_admin': idAdmin,
      'bank_code': bankCode,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder_name': accountHolderName,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  // Masked account number untuk display (1234567890 → ****7890)
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '•••• ${accountNumber.substring(accountNumber.length - 4)}';
  }

  SavedBankAccount copyWith({
    String? id,
    String? idAdmin,
    String? bankCode,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return SavedBankAccount(
      id: id ?? this.id,
      idAdmin: idAdmin ?? this.idAdmin,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}