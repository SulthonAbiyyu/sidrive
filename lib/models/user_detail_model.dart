// ============================================================================
// USER_DETAIL_MODEL.DART
// Model lengkap untuk user dengan semua role data (customer, driver, umkm)
// ============================================================================

import 'package:sidrive/models/user_model.dart';
import 'package:sidrive/models/user_role_model.dart';

class UserDetailModel {
  final UserModel user;
  final List<UserRoleModel> roles;
  
  // Customer Statistics
  final int totalOrderOjek;
  final int totalOrderUmkm;
  final double totalSpending;
  final int totalOrderSelesai;
  final int totalOrderDibatalkan;
  
  // Driver Statistics (null jika bukan driver)
  final String? idDriver;
  final String? statusDriver;
  final double? ratingDriver;
  final int? totalRatingDriver;
  final int? jumlahPesananSelesaiDriver;
  final double? totalPendapatanDriver;
  final String? activeVehicleType;
  final int? jumlahOrderBelumSetor;
  final double? totalCashPending;
  
  // UMKM Statistics (null jika bukan UMKM)
  final String? idUmkm;
  final String? namaToko;
  final String? statusToko;
  final double? ratingToko;
  final int? totalRatingUmkm;
  final double? totalPenjualan;
  final int? jumlahProdukTerjual;
  final String? kategoriToko;
  final String? fotoToko;
  
  // Wallet & Finance
  final double saldoWallet;
  final double totalTopup;
  final String? namaBank;
  final String? nomorRekening;
  final String? namaRekening;

  UserDetailModel({
    required this.user,
    required this.roles,
    this.totalOrderOjek = 0,
    this.totalOrderUmkm = 0,
    this.totalSpending = 0,
    this.totalOrderSelesai = 0,
    this.totalOrderDibatalkan = 0,
    this.idDriver,
    this.statusDriver,
    this.ratingDriver,
    this.totalRatingDriver,
    this.jumlahPesananSelesaiDriver,
    this.totalPendapatanDriver,
    this.activeVehicleType,
    this.jumlahOrderBelumSetor,
    this.totalCashPending,
    this.idUmkm,
    this.namaToko,
    this.statusToko,
    this.ratingToko,
    this.totalRatingUmkm,
    this.totalPenjualan,
    this.jumlahProdukTerjual,
    this.kategoriToko,
    this.fotoToko,
    this.saldoWallet = 0,
    this.totalTopup = 0,
    this.namaBank,
    this.nomorRekening,
    this.namaRekening,
  });

  // Helper: Check if user has specific role
  bool hasRole(String role) {
    return roles.any((r) => r.role == role && r.isActive);
  }

  // Helper: Get role status
  String? getRoleStatus(String role) {
    final userRole = roles.firstWhere(
      (r) => r.role == role && r.isActive,
      orElse: () => UserRoleModel(
        idUserRole: '',
        idUser: '',
        role: '',
        status: '',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );
    return userRole.role.isEmpty ? null : userRole.status;
  }

  // Helper: Get active roles list
  List<String> get activeRoles {
    return roles
        .where((r) => r.isActive && r.isRoleActive)
        .map((r) => r.role)
        .toList();
  }

  // Helper: Get pending roles list
  List<String> get pendingRoles {
    return roles
        .where((r) => r.isActive && r.status == 'pending_verification')
        .map((r) => r.role)
        .toList();
  }

  // From JSON (dari query kompleks join)
  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    // Parse user data
    final user = UserModel.fromJson(json);

    // Parse roles (jika ada di JSON)
    List<UserRoleModel> roles = [];
    if (json['user_roles'] != null) {
      roles = (json['user_roles'] as List)
          .map((r) => UserRoleModel.fromJson(r))
          .toList();
    }

    return UserDetailModel(
      user: user,
      roles: roles,
      // Customer stats
      totalOrderOjek: json['total_order_ojek'] ?? 0,
      totalOrderUmkm: json['total_order_umkm'] ?? 0,
      totalSpending: (json['total_spending'] ?? 0).toDouble(),
      totalOrderSelesai: json['total_order_selesai'] ?? 0,
      totalOrderDibatalkan: json['total_order_dibatalkan'] ?? 0,
      // Driver stats
      idDriver: json['id_driver'],
      statusDriver: json['status_driver'],
      ratingDriver: json['rating_driver'] != null 
          ? (json['rating_driver'] as num).toDouble() 
          : null,
      totalRatingDriver: json['total_rating_driver'],
      jumlahPesananSelesaiDriver: json['jumlah_pesanan_selesai_driver'],
      totalPendapatanDriver: json['total_pendapatan_driver'] != null
          ? (json['total_pendapatan_driver'] as num).toDouble()
          : null,
      activeVehicleType: json['active_vehicle_type'],
      jumlahOrderBelumSetor: json['jumlah_order_belum_setor'],
      totalCashPending: json['total_cash_pending'] != null
          ? (json['total_cash_pending'] as num).toDouble()
          : null,
      // UMKM stats
      idUmkm: json['id_umkm'],
      namaToko: json['nama_toko'],
      statusToko: json['status_toko'],
      ratingToko: json['rating_toko'] != null
          ? (json['rating_toko'] as num).toDouble()
          : null,
      totalRatingUmkm: json['total_rating_umkm'],
      totalPenjualan: json['total_penjualan'] != null
          ? (json['total_penjualan'] as num).toDouble()
          : null,
      jumlahProdukTerjual: json['jumlah_produk_terjual'],
      kategoriToko: json['kategori_toko'],
      fotoToko: json['foto_toko'],
      // Wallet
      saldoWallet: (json['saldo_wallet'] ?? 0).toDouble(),
      totalTopup: (json['total_topup'] ?? 0).toDouble(),
      namaBank: json['nama_bank'],
      nomorRekening: json['nomor_rekening'],
      namaRekening: json['nama_rekening'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      ...user.toJson(),
      'user_roles': roles.map((r) => r.toJson()).toList(),
      'total_order_ojek': totalOrderOjek,
      'total_order_umkm': totalOrderUmkm,
      'total_spending': totalSpending,
      'total_order_selesai': totalOrderSelesai,
      'total_order_dibatalkan': totalOrderDibatalkan,
      'id_driver': idDriver,
      'status_driver': statusDriver,
      'rating_driver': ratingDriver,
      'total_rating_driver': totalRatingDriver,
      'jumlah_pesanan_selesai_driver': jumlahPesananSelesaiDriver,
      'total_pendapatan_driver': totalPendapatanDriver,
      'active_vehicle_type': activeVehicleType,
      'jumlah_order_belum_setor': jumlahOrderBelumSetor,
      'total_cash_pending': totalCashPending,
      'id_umkm': idUmkm,
      'nama_toko': namaToko,
      'status_toko': statusToko,
      'rating_toko': ratingToko,
      'total_rating_umkm': totalRatingUmkm,
      'total_penjualan': totalPenjualan,
      'jumlah_produk_terjual': jumlahProdukTerjual,
      'kategori_toko': kategoriToko,
      'foto_toko': fotoToko,
      'saldo_wallet': saldoWallet,
      'total_topup': totalTopup,
      'nama_bank': namaBank,
      'nomor_rekening': nomorRekening,
      'nama_rekening': namaRekening,
    };
  }
}