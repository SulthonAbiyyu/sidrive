// ============================================================================
// USER_MODEL.DART  
// Model class untuk data user dari database
// ============================================================================

class UserModel {
  final String idUser;
  final String nim;
  final String nama;
  final String email;
  final String noTelp;
  final String? fotoProfil;
  final String role; // 'customer', 'driver', 'umkm', 'admin'
  final String status; // 'active', 'pending_verification', 'suspended'
  final bool isVerified;
  final String? alamat;
  final DateTime? tanggalLahir;
  final String? jenisKelamin;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? activeVehicle;
  final String? jenisKendaraan;


  UserModel({
    required this.idUser,
    required this.nim,
    required this.nama,
    required this.email,
    required this.noTelp,
    this.fotoProfil,
    required this.role,
    required this.status,
    required this.isVerified,
    this.alamat,
    this.tanggalLahir,
    this.jenisKelamin,
    required this.createdAt,
    this.lastLogin,
    this.activeVehicle,     
    this.jenisKendaraan,
    
  });

  // From JSON (dari Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: json['id_user'],
      nim: json['nim'],
      nama: json['nama'],
      email: json['email'],
      noTelp: json['no_telp'],
      fotoProfil: json['foto_profil'],
      role: json['role'],
      status: json['status'],
      isVerified: json['is_verified'] ?? false,
      alamat: json['alamat'],
      tanggalLahir: json['tanggal_lahir'] != null 
          ? DateTime.parse(json['tanggal_lahir']) 
          : null,
      jenisKelamin: json['jenis_kelamin'],
      createdAt: DateTime.parse(json['created_at']),
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      activeVehicle: json['active_vehicle'],
      jenisKendaraan: json['jenis_kendaraan'],
    );
  }

  // To JSON (untuk insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nim': nim,
      'nama': nama,
      'email': email,
      'no_telp': noTelp,
      'foto_profil': fotoProfil,
      'role': role,
      'status': status,
      'is_verified': isVerified,
      'alamat': alamat,
      'tanggal_lahir': tanggalLahir?.toIso8601String(),
      'jenis_kelamin': jenisKelamin,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'active_vehicle': activeVehicle,
      'jenis_kendaraan': jenisKendaraan,
    };
  }

  // Copy with (untuk update partial)
  UserModel copyWith({
    String? idUser,
    String? nim,
    String? nama,
    String? email,
    String? noTelp,
    String? fotoProfil,
    String? role,
    String? status,
    bool? isVerified,
    String? alamat,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? activeVehicle,
    String? jenisKendaraan,

  }) {
    return UserModel(
      idUser: idUser ?? this.idUser,
      nim: nim ?? this.nim,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      noTelp: noTelp ?? this.noTelp,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      role: role ?? this.role,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      alamat: alamat ?? this.alamat,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      activeVehicle: activeVehicle ?? this.activeVehicle,
      jenisKendaraan: jenisKendaraan ?? this.jenisKendaraan,
    );
  }
}
