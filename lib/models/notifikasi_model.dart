// ============================================================================
// NOTIFIKASI MODEL
// Model untuk data notifikasi dari database
// ============================================================================

class NotifikasiModel {
  final String idNotifikasi;
  final String idUser;
  final String judul;
  final String pesan;
  final String jenis; // sistem, pesanan, pembayaran, withdrawal, promo
  final String status; // read, unread
  final DateTime tanggalNotifikasi;
  final DateTime createdAt;

  NotifikasiModel({
    required this.idNotifikasi,
    required this.idUser,
    required this.judul,
    required this.pesan,
    required this.jenis,
    required this.status,
    required this.tanggalNotifikasi,
    required this.createdAt,
  });

  // From JSON (dari Supabase)
  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'] ?? '',
      idUser: json['id_user'] ?? '',
      judul: json['judul'] ?? '',
      pesan: json['pesan'] ?? '',
      jenis: json['jenis'] ?? 'sistem',
      status: json['status'] ?? 'unread',
      tanggalNotifikasi: json['tanggal_notifikasi'] != null
          ? DateTime.parse(json['tanggal_notifikasi'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id_notifikasi': idNotifikasi,
      'id_user': idUser,
      'judul': judul,
      'pesan': pesan,
      'jenis': jenis,
      'status': status,
      'tanggal_notifikasi': tanggalNotifikasi.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with
  NotifikasiModel copyWith({
    String? idNotifikasi,
    String? idUser,
    String? judul,
    String? pesan,
    String? jenis,
    String? status,
    DateTime? tanggalNotifikasi,
    DateTime? createdAt,
  }) {
    return NotifikasiModel(
      idNotifikasi: idNotifikasi ?? this.idNotifikasi,
      idUser: idUser ?? this.idUser,
      judul: judul ?? this.judul,
      pesan: pesan ?? this.pesan,
      jenis: jenis ?? this.jenis,
      status: status ?? this.status,
      tanggalNotifikasi: tanggalNotifikasi ?? this.tanggalNotifikasi,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper: Check if unread
  bool get isUnread => status == 'unread';

  // Helper: Get icon based on jenis
  String get iconPath {
    switch (jenis) {
      case 'pesanan':
        return '📦';
      case 'pembayaran':
        return '💳';
      case 'withdrawal':
        return '💰';
      case 'promo':
        return '🎉';
      case 'sistem':
      default:
        return '🔔';
    }
  }

  // Helper: Get time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(tanggalNotifikasi);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    }
  }
}