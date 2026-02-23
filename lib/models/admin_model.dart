// ============================================================================
// ADMIN MODEL
// Model untuk data admin (extends dari user data)
// ============================================================================

class AdminModel {
  final String idAdmin;
  final String idUser;
  final String level; // 'admin', 'super_admin'
  final bool isActive;
  final DateTime createdAt;
  final double? totalCashMasuk;
  final int? totalSettlementApproved;
  final int? totalSettlementRejected;
  
  // Data user (join dari users table)
  final String nim;
  final String nama;
  final String email;
  final String? fotoProfil;
  final String username;

  AdminModel({
    required this.idAdmin,
    required this.idUser,
    required this.level,
    required this.isActive,
    required this.createdAt,
    required this.nim,
    required this.nama,
    required this.email,
    this.fotoProfil,
    required this.username,
    this.totalCashMasuk,
    this.totalSettlementApproved,
    this.totalSettlementRejected,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      idAdmin: json['id_admin'] ?? '',
      idUser: json['id_user'] ?? '',
      level: json['level'] ?? 'admin',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      nim: json['nim'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      fotoProfil: json['foto_profil'],
      username: json['username'] ?? '',

      totalCashMasuk: json['total_cash_masuk'] != null 
        ? (json['total_cash_masuk'] as num).toDouble() 
        : null,
      totalSettlementApproved: json['total_settlement_approved'],
      totalSettlementRejected: json['total_settlement_rejected'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_admin': idAdmin,
      'id_user': idUser,
      'level': level,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'nim': nim,
      'nama': nama,
      'email': email,
      'foto_profil': fotoProfil,
      'username': username,
    };
  }
}

// ============================================================================
// DASHBOARD SUMMARY MODEL
// Model untuk summary data di dashboard admin
// ============================================================================
class DashboardSummary {
  final int totalUsersActive;
  final int totalDriversOnline;
  final int totalUmkmOpen;
  final int totalPesananToday;
  final double totalRevenueToday;
  final double totalAdminFee;

  DashboardSummary({
    required this.totalUsersActive,
    required this.totalDriversOnline,
    required this.totalUmkmOpen,
    required this.totalPesananToday,
    required this.totalRevenueToday,
    required this.totalAdminFee,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalUsersActive: json['total_users_active'] ?? 0,
      totalDriversOnline: json['total_drivers_online'] ?? 0,
      totalUmkmOpen: json['total_umkm_open'] ?? 0,
      totalPesananToday: json['total_pesanan_today'] ?? 0,
      totalRevenueToday: (json['total_revenue_today'] ?? 0).toDouble(),
      totalAdminFee: (json['total_admin_fee'] ?? 0).toDouble(),
    );
  }

  factory DashboardSummary.empty() {
    return DashboardSummary(
      totalUsersActive: 0,
      totalDriversOnline: 0,
      totalUmkmOpen: 0,
      totalPesananToday: 0,
      totalRevenueToday: 0,
      totalAdminFee: 0,
    );
  }
}

// ============================================================================
// DRIVER VERIFICATION MODEL - UPDATED untuk Multi-Vehicle
// ============================================================================
class DriverVerification {
  final String idDriver;
  final String idUser;
  final String nama;
  final String nim;
  final String noTelp;
  final String email;
  final String idVehicle;
  final String jenisKendaraan;
  final String platNomor;
  final String merkKendaraan;
  final String warnaKendaraan;
  final String? fotoSTNK;
  final String? fotoSIM;
  final String? fotoKendaraan;
  final String statusVerifikasi;
  final String? userRoleStatus;
  final String? namaBank;
  final String? nomorRekening;
  final String? namaRekening;
  final String? alasanPenolakan;
  final DateTime createdAt;

  DriverVerification({
    required this.idDriver,
    required this.idUser,
    required this.nama,
    required this.nim,
    required this.noTelp,
    required this.email,
    required this.idVehicle,
    required this.jenisKendaraan,
    required this.platNomor,
    required this.merkKendaraan,
    required this.warnaKendaraan,
    this.fotoSTNK,
    this.fotoSIM,
    this.fotoKendaraan,
    required this.statusVerifikasi,
    this.userRoleStatus,
    this.namaBank,
    this.nomorRekening,
    this.namaRekening,
    this.alasanPenolakan,
    required this.createdAt,
  });

  factory DriverVerification.fromJson(Map<String, dynamic> json) {
    return DriverVerification(
      idDriver: json['id_driver'] ?? '',
      idUser: json['id_user'] ?? '',
      nama: json['nama'] ?? '',
      nim: json['nim'] ?? '',
      noTelp: json['no_telp'] ?? '',
      email: json['email'] ?? '',
      idVehicle: json['id_vehicle'] ?? '',
      jenisKendaraan: json['jenis_kendaraan'] ?? '',
      platNomor: json['plat_nomor'] ?? '',
      merkKendaraan: json['merk_kendaraan'] ?? '',
      warnaKendaraan: json['warna_kendaraan'] ?? '',
      fotoSTNK: json['foto_stnk'],
      fotoSIM: json['foto_sim'],
      fotoKendaraan: json['foto_kendaraan'],
      statusVerifikasi: json['status_verifikasi'] ?? 'pending',
      userRoleStatus: json['user_role_status'],
      namaBank: json['nama_bank'],
      nomorRekening: json['nomor_rekening'],
      namaRekening: json['nama_rekening'],
      alasanPenolakan: json['alasan_penolakan'],
      createdAt: json['tanggal_daftar'] != null
          ? DateTime.parse(json['tanggal_daftar'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_driver': idDriver,
      'id_user': idUser,
      'nama': nama,
      'nim': nim,
      'no_telp': noTelp,
      'email': email,
      'id_vehicle': idVehicle,
      'jenis_kendaraan': jenisKendaraan,
      'plat_nomor': platNomor,
      'merk_kendaraan': merkKendaraan,
      'warna_kendaraan': warnaKendaraan,
      'foto_stnk': fotoSTNK,
      'foto_sim': fotoSIM,
      'foto_kendaraan': fotoKendaraan,
      'status_verifikasi': statusVerifikasi,
      'user_role_status': userRoleStatus,
      'nama_bank': namaBank,
      'nomor_rekening': nomorRekening,
      'nama_rekening': namaRekening,
      'alasan_penolakan': alasanPenolakan,
      'tanggal_daftar': createdAt.toIso8601String(),
    };
  }
}

// ============================================================================
// UMKM VERIFICATION MODEL
// Model untuk data UMKM yang pending verification
// ============================================================================
class UmkmVerification {
  final String idUmkm;
  final String idUser;
  final String nim;
  final String nama;
  final String noTelp;
  final String namaToko;
  final String? kategoriToko;
  final String alamatToko;
  final String? alamatTokoLengkap;  // ✅ TAMBAH INI
  final String? lokasiToko;
  final String? deskripsiToko;
  final String? fotoToko;
  final List<String>? fotoProdukSample;
  final String? jamBuka;
  final String? jamTutup;
  final String? namaBank;
  final String? nomorRekening;
  final String? namaRekening;
  final DateTime createdAt;
  final String roleStatus;


  UmkmVerification({
    required this.idUmkm,
    required this.idUser,
    required this.nim,
    required this.nama,
    required this.noTelp,
    required this.namaToko,
    this.kategoriToko,
    required this.alamatToko,
    this.lokasiToko,
    this.alamatTokoLengkap,
    this.deskripsiToko,
    this.fotoToko,
    this.fotoProdukSample,
    this.jamBuka,
    this.jamTutup,
    this.namaBank,
    this.nomorRekening,
    this.namaRekening,
    required this.createdAt,
    required this.roleStatus,
  });

  factory UmkmVerification.fromJson(Map<String, dynamic> json) {
    // Parse foto_produk_sample array
    List<String>? fotoProduk;
    if (json['foto_produk_sample'] != null) {
      if (json['foto_produk_sample'] is List) {
        fotoProduk = (json['foto_produk_sample'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return UmkmVerification(
      idUmkm: json['id_umkm'] ?? '',
      idUser: json['id_user'] ?? '',
      nim: json['nim'] ?? '',
      nama: json['nama'] ?? '',
      noTelp: json['no_telp'] ?? '',
      namaToko: json['nama_toko'] ?? '',
      kategoriToko: json['kategori_toko'],
      alamatToko: json['alamat_toko'] ?? '',
      alamatTokoLengkap: json['alamat_toko_lengkap'],  
      lokasiToko: json['lokasi_toko'],
      deskripsiToko: json['deskripsi_toko'],
      fotoToko: json['foto_toko'],
      fotoProdukSample: fotoProduk,
      jamBuka: json['jam_buka'],
      jamTutup: json['jam_tutup'],
      namaBank: json['nama_bank'],
      nomorRekening: json['nomor_rekening'],
      namaRekening: json['nama_rekening'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      roleStatus: json['role_status'] ?? 'pending_verification',
    );
  }
}

// ============================================================================
// PENARIKAN SALDO MODEL
// Model untuk penarikan saldo driver/UMKM
// ============================================================================
class PenarikanSaldo {
  final String idPenarikan;
  final String idUser;
  final String nim;
  final String nama;
  final String role; // driver atau umkm
  final double jumlah;
  final String? namaBank;
  final String? nomorRekening;
  final String? namaRekening;
  final String status; // pending, approved, rejected
  final DateTime tanggalPengajuan;
  final DateTime? tanggalDiproses;

  PenarikanSaldo({
    required this.idPenarikan,
    required this.idUser,
    required this.nim,
    required this.nama,
    required this.role,
    required this.jumlah,
    this.namaBank,
    this.nomorRekening,
    this.namaRekening,
    required this.status,
    required this.tanggalPengajuan,
    this.tanggalDiproses,
  });

  factory PenarikanSaldo.fromJson(Map<String, dynamic> json) {
    return PenarikanSaldo(
      idPenarikan: json['id_penarikan'] ?? '',
      idUser: json['id_user'] ?? '',
      nim: json['nim'] ?? '',
      nama: json['nama'] ?? '',
      role: json['role'] ?? '',
      jumlah: (json['jumlah'] ?? 0).toDouble(),
      namaBank: json['nama_bank'],
      nomorRekening: json['nomor_rekening'],
      namaRekening: json['nama_rekening'],
      status: json['status'] ?? 'pending',
      tanggalPengajuan: json['tanggal_pengajuan'] != null 
          ? DateTime.parse(json['tanggal_pengajuan']) 
          : DateTime.now(),
      tanggalDiproses: json['tanggal_diproses'] != null 
          ? DateTime.parse(json['tanggal_diproses']) 
          : null,
    );
  }
}