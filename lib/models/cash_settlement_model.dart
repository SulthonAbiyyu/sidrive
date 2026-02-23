// ============================================================================
// CASH SETTLEMENT MODEL
// ============================================================================

class CashSettlementModel {
  final String idSettlement;
  final String idDriver;
  final String driverUserId;
  final String driverNama;
  final String driverNim;
  final String driverPhone;
  final double jumlahCash;
  final double jumlahTopup;
  final String? buktiTopupUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String? idAdmin;
  final String? catatanAdmin;
  final DateTime tanggalPengajuan;
  final DateTime? tanggalDiproses;
  final int jumlahOrderBelumSetor;
  final double totalCashPending;
  final List<Map<String, String>>? vehicles; // [{jenis_kendaraan, plat_nomor}]

  CashSettlementModel({
    required this.idSettlement,
    required this.idDriver,
    required this.driverUserId,
    required this.driverNama,
    required this.driverNim,
    required this.driverPhone,
    required this.jumlahCash,
    required this.jumlahTopup,
    this.buktiTopupUrl,
    required this.status,
    this.idAdmin,
    this.catatanAdmin,
    required this.tanggalPengajuan,
    this.tanggalDiproses,
    required this.jumlahOrderBelumSetor,
    required this.totalCashPending,
    this.vehicles,
  });

  factory CashSettlementModel.fromJson(Map<String, dynamic> json) {
    // Parse vehicles dari JSONB
    List<Map<String, String>>? vehiclesList;
    if (json['vehicles'] != null) {
      final vehiclesData = json['vehicles'] as List;
      vehiclesList = vehiclesData.map((v) => {
        'jenis_kendaraan': v['jenis_kendaraan'].toString(),
        'plat_nomor': v['plat_nomor'].toString(),
      }).toList();
    }

    return CashSettlementModel(
      idSettlement: json['id_settlement'],
      idDriver: json['id_driver'],
      driverUserId: json['driver_user_id'],
      driverNama: json['driver_nama'] ?? 'Unknown',
      driverNim: json['driver_nim'] ?? '',
      driverPhone: json['driver_phone'] ?? '',
      jumlahCash: (json['jumlah_cash'] as num).toDouble(),
      jumlahTopup: (json['jumlah_topup'] as num).toDouble(),
      buktiTopupUrl: json['bukti_topup_url'],
      status: json['status'],
      idAdmin: json['id_admin'],
      catatanAdmin: json['catatan_admin'],
      tanggalPengajuan: DateTime.parse(json['tanggal_pengajuan']),
      tanggalDiproses: json['tanggal_diproses'] != null
          ? DateTime.parse(json['tanggal_diproses'])
          : null,
      jumlahOrderBelumSetor: json['jumlah_order_belum_setor'] ?? 0,
      totalCashPending: (json['total_cash_pending'] ?? 0).toDouble(),
      vehicles: vehiclesList,
    );
  }

  String get vehicleInfo {
    if (vehicles == null || vehicles!.isEmpty) return 'Tidak ada kendaraan';
    if (vehicles!.length == 1) {
      return '${vehicles![0]['jenis_kendaraan']?.toUpperCase()} - ${vehicles![0]['plat_nomor']}';
    }
    return vehicles!.map((v) => v['jenis_kendaraan']?.toUpperCase()).join(' + ');
  }
}

// ============================================================================
// ADMIN WALLET STATS MODEL
// ============================================================================

class AdminWalletStats {
  final double totalCashMasuk;
  final int totalSettlementApproved;
  final int totalSettlementRejected;
  final int pendingCount;

  AdminWalletStats({
    required this.totalCashMasuk,
    required this.totalSettlementApproved,
    required this.totalSettlementRejected,
    required this.pendingCount,
  });

  factory AdminWalletStats.fromJson(Map<String, dynamic> json) {
    return AdminWalletStats(
      totalCashMasuk: (json['total_cash_masuk'] ?? 0).toDouble(),
      totalSettlementApproved: json['total_settlement_approved'] ?? 0,
      totalSettlementRejected: json['total_settlement_rejected'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
    );
  }

  factory AdminWalletStats.empty() {
    return AdminWalletStats(
      totalCashMasuk: 0,
      totalSettlementApproved: 0,
      totalSettlementRejected: 0,
      pendingCount: 0,
    );
  }
}