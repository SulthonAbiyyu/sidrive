// ============================================================================
// DRIVER_VEHICLE_MODEL.DART
// Model untuk tabel driver_vehicles - 1 driver bisa punya motor DAN mobil
// ============================================================================

class DriverVehicleModel {
  final String idVehicle;
  final String idDriver;
  final String jenisKendaraan; // 'motor' atau 'mobil'
  final String platNomor;
  final String? merkKendaraan;
  final String? warnaKendaraan;
  final String? fotoStnk;
  final String? fotoSim;
  final String? fotoKendaraan;
  final String statusVerifikasi; // 'pending', 'approved', 'rejected'
  final String? alasanPenolakan;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverVehicleModel({
    required this.idVehicle,
    required this.idDriver,
    required this.jenisKendaraan,
    required this.platNomor,
    this.merkKendaraan,
    this.warnaKendaraan,
    this.fotoStnk,
    this.fotoSim,
    this.fotoKendaraan,
    required this.statusVerifikasi,
    this.alasanPenolakan,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON (dari Supabase)
  factory DriverVehicleModel.fromJson(Map<String, dynamic> json) {
    return DriverVehicleModel(
      idVehicle: json['id_vehicle'],
      idDriver: json['id_driver'],
      jenisKendaraan: json['jenis_kendaraan'],
      platNomor: json['plat_nomor'],
      merkKendaraan: json['merk_kendaraan'],
      warnaKendaraan: json['warna_kendaraan'],
      fotoStnk: json['foto_stnk'],
      fotoSim: json['foto_sim'],
      fotoKendaraan: json['foto_kendaraan'],
      statusVerifikasi: json['status_verifikasi'] ?? 'pending',
      alasanPenolakan: json['alasan_penolakan'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // To JSON (untuk insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id_vehicle': idVehicle,
      'id_driver': idDriver,
      'jenis_kendaraan': jenisKendaraan,
      'plat_nomor': platNomor,
      'merk_kendaraan': merkKendaraan,
      'warna_kendaraan': warnaKendaraan,
      'foto_stnk': fotoStnk,
      'foto_sim': fotoSim,
      'foto_kendaraan': fotoKendaraan,
      'status_verifikasi': statusVerifikasi,
      'alasan_penolakan': alasanPenolakan,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // To JSON untuk INSERT (tanpa id_vehicle, biar auto-generate)
  Map<String, dynamic> toInsertJson() {
    return {
      'id_driver': idDriver,
      'jenis_kendaraan': jenisKendaraan,
      'plat_nomor': platNomor,
      'merk_kendaraan': merkKendaraan,
      'warna_kendaraan': warnaKendaraan,
      'foto_stnk': fotoStnk,
      'foto_sim': fotoSim,
      'foto_kendaraan': fotoKendaraan,
      'status_verifikasi': statusVerifikasi,
      'is_active': isActive,
    };
  }

  // Copy with
  DriverVehicleModel copyWith({
    String? idVehicle,
    String? idDriver,
    String? jenisKendaraan,
    String? platNomor,
    String? merkKendaraan,
    String? warnaKendaraan,
    String? fotoStnk,
    String? fotoSim,
    String? fotoKendaraan,
    String? statusVerifikasi,
    String? alasanPenolakan,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverVehicleModel(
      idVehicle: idVehicle ?? this.idVehicle,
      idDriver: idDriver ?? this.idDriver,
      jenisKendaraan: jenisKendaraan ?? this.jenisKendaraan,
      platNomor: platNomor ?? this.platNomor,
      merkKendaraan: merkKendaraan ?? this.merkKendaraan,
      warnaKendaraan: warnaKendaraan ?? this.warnaKendaraan,
      fotoStnk: fotoStnk ?? this.fotoStnk,
      fotoSim: fotoSim ?? this.fotoSim,
      fotoKendaraan: fotoKendaraan ?? this.fotoKendaraan,
      statusVerifikasi: statusVerifikasi ?? this.statusVerifikasi,
      alasanPenolakan: alasanPenolakan ?? this.alasanPenolakan,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isApproved => statusVerifikasi == 'approved';
  bool get isPending => statusVerifikasi == 'pending';
  bool get isRejected => statusVerifikasi == 'rejected';
  bool get isMotor => jenisKendaraan == 'motor';
  bool get isMobil => jenisKendaraan == 'mobil';
}