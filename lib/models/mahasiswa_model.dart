// ============================================================================
// MAHASISWA_MODEL.DART
// Model class untuk data mahasiswa aktif UMSIDA
// ============================================================================

class MahasiswaModel {
  final String idMahasiswa;
  final String nim;
  final String namaLengkap;
  final String? programStudi;
  final String? fakultas;
  final String? angkatan;
  final String statusMahasiswa;

  MahasiswaModel({
    required this.idMahasiswa,
    required this.nim,
    required this.namaLengkap,
    this.programStudi,
    this.fakultas,
    this.angkatan,
    required this.statusMahasiswa,
  });

  // From JSON
  factory MahasiswaModel.fromJson(Map<String, dynamic> json) {
    return MahasiswaModel(
      idMahasiswa: json['id_mahasiswa'],
      nim: json['nim'],
      namaLengkap: json['nama_lengkap'],
      programStudi: json['program_studi'],
      fakultas: json['fakultas'],
      angkatan: json['angkatan'],
      statusMahasiswa: json['status_mahasiswa'] ?? 'aktif',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id_mahasiswa': idMahasiswa,
      'nim': nim,
      'nama_lengkap': namaLengkap,
      'program_studi': programStudi,
      'fakultas': fakultas,
      'angkatan': angkatan,
      'status_mahasiswa': statusMahasiswa,
    };
  }
}
