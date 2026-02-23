import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sidrive/models/mahasiswa_model.dart';
import 'package:sidrive/services/mahasiswa_service.dart';

/// Model untuk hasil validasi import
class ImportValidationResult {
  final List<MahasiswaImportItem> validItems;
  final List<MahasiswaImportItem> duplicateItems;
  final List<ImportError> errors;
  
  ImportValidationResult({
    required this.validItems,
    required this.duplicateItems,
    required this.errors,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasDuplicates => duplicateItems.isNotEmpty;
  bool get hasValidItems => validItems.isNotEmpty;
  int get totalItems => validItems.length + duplicateItems.length + errors.length;
}

/// Model untuk item yang akan diimport
class MahasiswaImportItem {
  final String namaLengkap;
  final String nim;
  final String? programStudi;
  final String? fakultas;
  final String? angkatan;
  final String statusMahasiswa;
  final int rowNumber;
  final MahasiswaModel? existingData; // Data yang sudah ada (jika duplicate)
  
  MahasiswaImportItem({
    required this.namaLengkap,
    required this.nim,
    this.programStudi,
    this.fakultas,
    this.angkatan,
    required this.statusMahasiswa,
    required this.rowNumber,
    this.existingData,
  });
  
  Map<String, dynamic> toJson() => {
    'nama_lengkap': namaLengkap,
    'nim': nim,
    'program_studi': programStudi,
    'fakultas': fakultas,
    'angkatan': angkatan,
    'status_mahasiswa': statusMahasiswa,
  };
}

/// Model untuk error import
class ImportError {
  final int rowNumber;
  final String nim;
  final String namaLengkap;
  final String errorMessage;
  
  ImportError({
    required this.rowNumber,
    required this.nim,
    required this.namaLengkap,
    required this.errorMessage,
  });
}

/// Service untuk handle import CSV mahasiswa
class MahasiswaImportService {
  final MahasiswaService _mahasiswaService;
  
  MahasiswaImportService(this._mahasiswaService);
  
  /// Pick file CSV dari device
  Future<FilePickerResult?> pickCSVFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );
      return result;
    } catch (e) {
      throw Exception('Gagal memilih file: $e');
    }
  }
  
  /// Parse CSV file dan validasi data
  Future<ImportValidationResult> parseAndValidateCSV(List<int> bytes) async {
    try {
      // Convert bytes ke string
      final csvString = utf8.decode(bytes);
      
      // Parse CSV
      final List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
      ).convert(csvString);
      
      if (csvData.isEmpty) {
        throw Exception('File CSV kosong');
      }
      
      // Validasi header
      final header = csvData[0].map((e) => e.toString().toLowerCase().trim()).toList();
      _validateHeader(header);
      
      // Get existing mahasiswa untuk cek duplikat
      final existingMahasiswa = await _mahasiswaService.getAllMahasiswa(
        filterFakultas: 'Semua',
        filterAngkatan: 'Semua', 
        filterStatus: 'Semua',
      );
      final existingNimMap = {
        for (var m in existingMahasiswa) m.nim: m
      };
      
      // Parse data rows
      final List<MahasiswaImportItem> validItems = [];
      final List<MahasiswaImportItem> duplicateItems = [];
      final List<ImportError> errors = [];
      
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        final rowNumber = i + 1;
        
        try {
          // Skip empty rows
          if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
            continue;
          }
          
          // Extract data
          final item = _extractRowData(row, header, rowNumber);
          
          // Validasi item
          final validationError = _validateItem(item);
          if (validationError != null) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              nim: item.nim,
              namaLengkap: item.namaLengkap,
              errorMessage: validationError,
            ));
            continue;
          }
          
          // Cek duplicate
          if (existingNimMap.containsKey(item.nim)) {
            duplicateItems.add(MahasiswaImportItem(
              namaLengkap: item.namaLengkap,
              nim: item.nim,
              programStudi: item.programStudi,
              fakultas: item.fakultas,
              angkatan: item.angkatan,
              statusMahasiswa: item.statusMahasiswa,
              rowNumber: rowNumber,
              existingData: existingNimMap[item.nim],
            ));
          } else {
            validItems.add(item);
          }
        } catch (e) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            nim: row.length > 1 ? row[1].toString() : 'N/A',
            namaLengkap: row.isNotEmpty ? row[0].toString() : 'N/A',
            errorMessage: 'Error parsing row: $e',
          ));
        }
      }
      
      return ImportValidationResult(
        validItems: validItems,
        duplicateItems: duplicateItems,
        errors: errors,
      );
    } catch (e) {
      throw Exception('Gagal memproses file CSV: $e');
    }
  }
  
  /// Validasi header CSV
  void _validateHeader(List<String> header) {
    final requiredColumns = ['nama_lengkap', 'nim'];
    
    for (final column in requiredColumns) {
      if (!header.any((h) => h.contains(column.replaceAll('_', '')))) {
        throw Exception('Header CSV tidak valid. Kolom "$column" diperlukan.');
      }
    }
  }
  
  /// Extract data dari row CSV
  MahasiswaImportItem _extractRowData(
    List<dynamic> row,
    List<String> header,
    int rowNumber,
  ) {
    String? getValue(String columnName) {
      final index = header.indexWhere((h) => 
        h.contains(columnName.replaceAll('_', ''))
      );
      if (index == -1 || index >= row.length) return null;
      final value = row[index].toString().trim();
      return value.isEmpty ? null : value;
    }
    
    return MahasiswaImportItem(
      namaLengkap: getValue('nama_lengkap') ?? getValue('nama') ?? '',
      nim: getValue('nim') ?? '',
      programStudi: getValue('program_studi') ?? getValue('prodi'),
      fakultas: getValue('fakultas'),
      angkatan: getValue('angkatan'),
      statusMahasiswa: getValue('status') ?? 'aktif',
      rowNumber: rowNumber,
    );
  }
  
  /// Validasi data item
  String? _validateItem(MahasiswaImportItem item) {
    if (item.namaLengkap.isEmpty) {
      return 'Nama lengkap tidak boleh kosong';
    }
    
    if (item.nim.isEmpty) {
      return 'NIM tidak boleh kosong';
    }
    
    if (item.nim.length < 5) {
      return 'NIM tidak valid (minimal 5 karakter)';
    }
    
    // Validasi status
    final validStatuses = ['aktif', 'nonaktif', 'lulus', 'cuti'];
    if (!validStatuses.contains(item.statusMahasiswa.toLowerCase())) {
      return 'Status tidak valid. Gunakan: ${validStatuses.join(", ")}';
    }
    
    return null;
  }
  
  /// Import mahasiswa (create/update)
  Future<ImportResult> importMahasiswa({
    required List<MahasiswaImportItem> items,
    required bool replaceExisting,
  }) async {
    int successCount = 0;
    int failedCount = 0;
    final List<String> failedItems = [];
    
    for (final item in items) {
      try {
        if (replaceExisting && item.existingData != null) {
          // Update existing
          await _mahasiswaService.updateMahasiswa(
            idMahasiswa: item.existingData!.idMahasiswa,
            nim: item.nim,
            namaLengkap: item.namaLengkap,
            programStudi: item.programStudi,
            fakultas: item.fakultas,
            angkatan: item.angkatan,
            statusMahasiswa: item.statusMahasiswa,
          );
        } else {
          // Create new
          await _mahasiswaService.createMahasiswa(
            nim: item.nim,
            namaLengkap: item.namaLengkap,
            programStudi: item.programStudi,
            fakultas: item.fakultas,
            angkatan: item.angkatan,
            statusMahasiswa: item.statusMahasiswa,
          );
        }
        successCount++;
      } catch (e) {
        failedCount++;
        failedItems.add('${item.nim} - ${item.namaLengkap}: $e');
      }
    }
    
    return ImportResult(
      successCount: successCount,
      failedCount: failedCount,
      failedItems: failedItems,
    );
  }
  
  /// Generate template CSV
  String generateCSVTemplate() {
    const header = 'nama_lengkap,nim,program_studi,fakultas,angkatan,status_mahasiswa';
    const example1 = 'John Doe,12345678,Teknik Informatika,Teknik,2023,aktif';
    const example2 = 'Jane Smith,87654321,Manajemen,Ekonomi,2022,aktif';
    
    return '$header\n$example1\n$example2';
  }
}

/// Model untuk hasil import
class ImportResult {
  final int successCount;
  final int failedCount;
  final List<String> failedItems;
  
  ImportResult({
    required this.successCount,
    required this.failedCount,
    required this.failedItems,
  });
  
  bool get hasFailures => failedCount > 0;
  bool get allSuccess => failedCount == 0 && successCount > 0;
}