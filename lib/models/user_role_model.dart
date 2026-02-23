// ============================================================================
// USER_ROLE_MODEL.DART  
// Model untuk table user_roles (multi-role system)
// 1 user bisa punya banyak role: customer, driver, umkm
// ============================================================================

class UserRoleModel {
  final String idUserRole;
  final String idUser;
  final String role; // 'customer', 'driver', 'umkm'
  final String status; // 'pending_verification', 'active', 'rejected'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserRoleModel({
    required this.idUserRole,
    required this.idUser,
    required this.role,
    required this.status,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  // From JSON (dari Supabase)
  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      idUserRole: json['id_user_role'],
      idUser: json['id_user'],
      role: json['role'],
      status: json['status'] ?? 'pending_verification',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // To JSON (untuk insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id_user_role': idUserRole,
      'id_user': idUser,
      'role': role,
      'status': status,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Copy with
  UserRoleModel copyWith({
    String? idUserRole,
    String? idUser,
    String? role,
    String? status,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRoleModel(
      idUserRole: idUserRole ?? this.idUserRole,
      idUser: idUser ?? this.idUser,
      role: role ?? this.role,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper: Check if role is active
  bool get isRoleActive => status == 'active' && isActive;
}
