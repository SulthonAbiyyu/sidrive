// ============================================================================
// DRIVER_MODEL.DART
// Model untuk tabel drivers (SETELAH MIGRATION)
// Kolom jenis_kendaraan, plat_nomor, dll sudah DIHAPUS dari tabel ini
// Sekarang pindah ke tabel driver_vehicles
// ============================================================================

import 'driver_vehicle_model.dart';

class DriverModel {
  final String idDriver;
  final String idUser;
  final String statusDriver; // 'offline', 'online', 'on_trip'
  final double ratingDriver;
  final int totalRating;
  final int jumlahPesananSelesai;
  final double saldoTersedia;
  final double totalPendapatan;
  final String? namaBank;
  final String? namaRekening;
  final String? nomorRekening;
  final String? currentLocation; // Geometry/Point
  final DateTime? lastLocationUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOnline;
  final String? activeVehicleType; // 'motor' atau 'mobil' - kendaraan yang sedang aktif
  
  // Optional: Data kendaraan jika di-JOIN
  final List<DriverVehicleModel>? vehicles;

  DriverModel({
    required this.idDriver,
    required this.idUser,
    required this.statusDriver,
    required this.ratingDriver,
    required this.totalRating,
    required this.jumlahPesananSelesai,
    required this.saldoTersedia,
    required this.totalPendapatan,
    this.namaBank,
    this.namaRekening,
    this.nomorRekening,
    this.currentLocation,
    this.lastLocationUpdate,
    required this.createdAt,
    required this.updatedAt,
    required this.isOnline,
    this.activeVehicleType,
    this.vehicles,
  });

  // From JSON (dari Supabase)
  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      idDriver: json['id_driver'],
      idUser: json['id_user'],
      statusDriver: json['status_driver'] ?? 'offline',
      ratingDriver: (json['rating_driver'] ?? 0).toDouble(),
      totalRating: json['total_rating'] ?? 0,
      jumlahPesananSelesai: json['jumlah_pesanan_selesai'] ?? 0,
      saldoTersedia: (json['saldo_tersedia'] ?? 0).toDouble(),
      totalPendapatan: (json['total_pendapatan'] ?? 0).toDouble(),
      namaBank: json['nama_bank'],
      namaRekening: json['nama_rekening'],
      nomorRekening: json['nomor_rekening'],
      currentLocation: json['current_location'],
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isOnline: json['is_online'] ?? false,
      activeVehicleType: json['active_vehicle_type'],
      vehicles: json['vehicles'] != null
          ? (json['vehicles'] as List)
              .map((v) => DriverVehicleModel.fromJson(v))
              .toList()
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id_driver': idDriver,
      'id_user': idUser,
      'status_driver': statusDriver,
      'rating_driver': ratingDriver,
      'total_rating': totalRating,
      'jumlah_pesanan_selesai': jumlahPesananSelesai,
      'saldo_tersedia': saldoTersedia,
      'total_pendapatan': totalPendapatan,
      'nama_bank': namaBank,
      'nama_rekening': namaRekening,
      'nomor_rekening': nomorRekening,
      'current_location': currentLocation,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_online': isOnline,
      'active_vehicle_type': activeVehicleType,
    };
  }

  // Copy with
  DriverModel copyWith({
    String? idDriver,
    String? idUser,
    String? statusDriver,
    double? ratingDriver,
    int? totalRating,
    int? jumlahPesananSelesai,
    double? saldoTersedia,
    double? totalPendapatan,
    String? namaBank,
    String? namaRekening,
    String? nomorRekening,
    String? currentLocation,
    DateTime? lastLocationUpdate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    String? activeVehicleType,
    List<DriverVehicleModel>? vehicles,
  }) {
    return DriverModel(
      idDriver: idDriver ?? this.idDriver,
      idUser: idUser ?? this.idUser,
      statusDriver: statusDriver ?? this.statusDriver,
      ratingDriver: ratingDriver ?? this.ratingDriver,
      totalRating: totalRating ?? this.totalRating,
      jumlahPesananSelesai: jumlahPesananSelesai ?? this.jumlahPesananSelesai,
      saldoTersedia: saldoTersedia ?? this.saldoTersedia,
      totalPendapatan: totalPendapatan ?? this.totalPendapatan,
      namaBank: namaBank ?? this.namaBank,
      namaRekening: namaRekening ?? this.namaRekening,
      nomorRekening: nomorRekening ?? this.nomorRekening,
      currentLocation: currentLocation ?? this.currentLocation,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      activeVehicleType: activeVehicleType ?? this.activeVehicleType,
      vehicles: vehicles ?? this.vehicles,
    );
  }

  // Helper methods
  bool get hasApprovedVehicle => vehicles?.any((v) => v.isApproved) ?? false;
  bool get hasMotor => vehicles?.any((v) => v.isMotor && v.isApproved) ?? false;
  bool get hasMobil => vehicles?.any((v) => v.isMobil && v.isApproved) ?? false;
  bool get hasBothVehicles => hasMotor && hasMobil;
  
  DriverVehicleModel? get activeVehicle {
    if (activeVehicleType == null || vehicles == null) return null;
    return vehicles!.firstWhere(
      (v) => v.jenisKendaraan == activeVehicleType && v.isApproved,
      orElse: () => vehicles!.first,
    );
  }
}