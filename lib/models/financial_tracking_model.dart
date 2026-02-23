// ============================================================================
// FINANCIAL TRACKING MODELS
// Model untuk monitoring alur keuangan setiap pesanan
// ============================================================================

class FinancialTrackingModel {
  final String idPesanan;
  final String jenisPesanan; // 'ojek' atau 'umkm'
  final DateTime tanggalPesanan;
  final double totalHarga;
  final String metodePembayaran; // 'cash', 'wallet', 'transfer'
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String statusPesanan;
  
  // Customer info
  final String customerNama;
  final String customerId;
  
  // Driver info (nullable untuk umkm tanpa driver)
  final String? driverNama;
  final String? driverId;
  
  // UMKM info (nullable untuk ojek)
  final String? umkmNama;
  final String? umkmId;
  
  // Financial breakdown
  final double adminFee;
  final double driverEarnings;
  final double umkmEarnings;
  final double adminWalletHold; // Uang yang di-hold di admin wallet
  final double totalPayout; // Total yang sudah dibayar ke driver/umkm
  
  // Status tracking
  final bool isPaidOut; // Sudah dibayar atau belum
  final DateTime? payoutDate;
  final String financialStatus; // 'ok', 'pending', 'bermasalah', 'selesai'
  final String? notes;

  FinancialTrackingModel({
    required this.idPesanan,
    required this.jenisPesanan,
    required this.tanggalPesanan,
    required this.totalHarga,
    required this.metodePembayaran,
    required this.paymentStatus,
    required this.statusPesanan,
    required this.customerNama,
    required this.customerId,
    this.driverNama,
    this.driverId,
    this.umkmNama,
    this.umkmId,
    required this.adminFee,
    required this.driverEarnings,
    required this.umkmEarnings,
    required this.adminWalletHold,
    required this.totalPayout,
    required this.isPaidOut,
    this.payoutDate,
    required this.financialStatus,
    this.notes,
  });

  factory FinancialTrackingModel.fromJson(Map<String, dynamic> json) {
    return FinancialTrackingModel(
      idPesanan: json['id_pesanan'] ?? '',
      jenisPesanan: json['jenis_pesanan'] ?? 'ojek',
      tanggalPesanan: json['tanggal_pesanan'] != null 
          ? DateTime.parse(json['tanggal_pesanan'])
          : DateTime.now(),
      totalHarga: (json['total_harga'] ?? 0).toDouble(),
      metodePembayaran: json['metode_pembayaran'] ?? 'cash',
      paymentStatus: json['payment_status'] ?? 'pending',
      statusPesanan: json['status_pesanan'] ?? '',
      customerNama: json['customer_nama'] ?? '',
      customerId: json['customer_id'] ?? '',
      driverNama: json['driver_nama'],
      driverId: json['driver_id'],
      umkmNama: json['umkm_nama'],
      umkmId: json['umkm_id'],
      adminFee: (json['admin_fee'] ?? 0).toDouble(),
      driverEarnings: (json['driver_earnings'] ?? 0).toDouble(),
      umkmEarnings: (json['umkm_earnings'] ?? 0).toDouble(),
      adminWalletHold: (json['admin_wallet_hold'] ?? 0).toDouble(),
      totalPayout: (json['total_payout'] ?? 0).toDouble(),
      isPaidOut: json['is_paid_out'] ?? false,
      payoutDate: json['payout_date'] != null 
          ? DateTime.parse(json['payout_date'])
          : null,
      financialStatus: json['financial_status'] ?? 'pending',
      notes: json['notes'],
    );
  }

  // Helper untuk mendapatkan deskripsi alur keuangan
  String get flowDescription {
    if (jenisPesanan == 'ojek') {
      return 'Customer → Admin Wallet (hold) → Driver (${isPaidOut ? "Sudah" : "Belum"} dibayar)';
    } else {
      if (driverId != null) {
        return 'Customer → Admin Wallet (hold) → UMKM + Driver (${isPaidOut ? "Sudah" : "Belum"} dibayar)';
      } else {
        return 'Customer → Admin Wallet (hold) → UMKM (${isPaidOut ? "Sudah" : "Belum"} dibayar)';
      }
    }
  }

  // Helper untuk status badge color
  String get statusColor {
    switch (financialStatus.toLowerCase()) {
      case 'ok':
      case 'selesai':
        return 'green';
      case 'pending':
        return 'orange';
      case 'bermasalah':
        return 'red';
      default:
        return 'grey';
    }
  }
}

// ============================================================================
// FINANCIAL SUMMARY MODEL
// Summary untuk dashboard financial
// ============================================================================

class FinancialSummary {
  final double totalRevenue; // Total pendapatan admin (admin fee)
  final double totalHeld; // Total yang di-hold di admin wallet
  final double totalPaidOut; // Total yang sudah dibayar ke driver/umkm
  final double totalPending; // Total pending payment
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int problemOrders;

  FinancialSummary({
    required this.totalRevenue,
    required this.totalHeld,
    required this.totalPaidOut,
    required this.totalPending,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.problemOrders,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalHeld: (json['total_held'] ?? 0).toDouble(),
      totalPaidOut: (json['total_paid_out'] ?? 0).toDouble(),
      totalPending: (json['total_pending'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      problemOrders: json['problem_orders'] ?? 0,
    );
  }

  factory FinancialSummary.empty() {
    return FinancialSummary(
      totalRevenue: 0,
      totalHeld: 0,
      totalPaidOut: 0,
      totalPending: 0,
      totalOrders: 0,
      completedOrders: 0,
      pendingOrders: 0,
      problemOrders: 0,
    );
  }
}