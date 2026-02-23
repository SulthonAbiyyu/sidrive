// ============================================================================
// TIME_HELPER.DART
// Helper untuk format waktu & durasi
// ============================================================================

class TimeHelper {
  /// Get greeting berdasarkan waktu sekarang
  static String getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 5 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  /// Format duration menjadi string (contoh: "3 jam 25 menit", "45 menit", "0 menit")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      if (minutes > 0) {
        return '$hours jam $minutes menit';
      } else {
        return '$hours jam';
      }
    } else if (minutes > 0) {
      return '$minutes menit';
    } else {
      return '0 menit';
    }
  }

  /// Format timestamp menjadi string tanggal (contoh: "24 Des 2025")
  static String formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Format timestamp menjadi string waktu (contoh: "14:30")
  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format timestamp menjadi string lengkap (contoh: "24 Des 2025, 14:30")
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)}, ${formatTime(date)}';
  }

  /// Hitung selisih waktu dari sekarang (contoh: "5 menit lalu", "2 jam lalu", "3 hari lalu")
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}