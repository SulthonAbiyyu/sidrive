class Validators {
  /// Validasi NIM
  static String? nim(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIM tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]{8,12}$').hasMatch(value)) {
      return 'Format NIM tidak valid';
    }
    return null;
  }

  /// Validasi Nama
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama terlalu pendek';
    }
    return null;
  }

  /// Validasi Nomor Telepon
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
      return 'Nomor telepon tidak valid';
    }
    return null;
  }

  /// Validasi Password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Validasi Konfirmasi Password
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != password) {
      return 'Password tidak sama';
    }
    return null;
  }
}
