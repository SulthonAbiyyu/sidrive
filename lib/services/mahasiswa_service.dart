// ============================================================================
// MAHASISWA_SERVICE.DART - PRODUCTION READY
// ============================================================================
// Service layer untuk manage data mahasiswa dengan validasi ketat
// Features:
// - Dynamic angkatan generation (auto-update setiap tahun)
// - Professional validation
// - Detailed error handling
// - Optimized queries
// ============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/config/constants.dart';
import 'package:sidrive/models/mahasiswa_model.dart';

class MahasiswaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // CREATE - Tambah mahasiswa baru
  // ============================================================================
  Future<MahasiswaModel> createMahasiswa({
    required String nim,
    required String namaLengkap,
    String? programStudi,
    String? fakultas,
    String? angkatan,
    String statusMahasiswa = 'aktif',
  }) async {
    try {
      debugPrint('➕ [MahasiswaService] Creating mahasiswa: NIM=$nim');
      
      // ✅ VALIDASI: Cek apakah NIM sudah ada
      final existing = await _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .select('nim')
          .eq('nim', nim)
          .maybeSingle();

      if (existing != null) {
        debugPrint('❌ [MahasiswaService] NIM already exists: $nim');
        throw Exception('NIM $nim sudah terdaftar di database');
      }

      // ✅ VALIDASI: Cek panjang NIM
      if (nim.length != 12) {
        debugPrint('❌ [MahasiswaService] Invalid NIM length: ${nim.length}');
        throw Exception('NIM harus 12 digit');
      }

      // ✅ VALIDASI: Cek NIM hanya angka
      if (!RegExp(r'^[0-9]+$').hasMatch(nim)) {
        debugPrint('❌ [MahasiswaService] NIM contains non-numeric characters');
        throw Exception('NIM hanya boleh berisi angka');
      }

      // ✅ VALIDASI: Cek angkatan valid (jika diisi)
      if (angkatan != null && angkatan.isNotEmpty) {
        final validAngkatanList = getValidAngkatanList();
        if (!validAngkatanList.contains(angkatan)) {
          debugPrint('❌ [MahasiswaService] Invalid angkatan: $angkatan');
          throw Exception('Angkatan tidak valid. Harus antara ${validAngkatanList.last} - ${validAngkatanList.first}');
        }
      }

      // ✅ INSERT DATA
      debugPrint('📤 [MahasiswaService] Inserting data to database...');
      final response = await _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .insert({
            'nim': nim,
            'nama_lengkap': namaLengkap,
            'program_studi': programStudi,
            'fakultas': fakultas,
            'angkatan': angkatan,
            'status_mahasiswa': statusMahasiswa,
          })
          .select()
          .single();

      debugPrint('✅ [MahasiswaService] Mahasiswa created successfully');
      return MahasiswaModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('❌ [MahasiswaService] Postgrest error: ${e.code} - ${e.message}');
      if (e.code == '23505') {
        throw Exception('NIM $nim sudah terdaftar');
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('❌ [MahasiswaService] Create error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // READ - Get all mahasiswa dengan filter & pagination
  // ============================================================================
  Future<List<MahasiswaModel>> getAllMahasiswa({
    String? searchQuery,
    String? filterFakultas,
    String? filterAngkatan,
    String? filterStatus,
    int? limit,
    int? offset,
  }) async {
    try {
      debugPrint('🔍 [MahasiswaService] Getting mahasiswa list...');
      debugPrint('   Search: $searchQuery');
      debugPrint('   Filters: Fakultas=$filterFakultas, Angkatan=$filterAngkatan, Status=$filterStatus');
      debugPrint('   Pagination: limit=$limit, offset=$offset');
      
      // Build query
      dynamic query = _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .select();

      // FILTER: Search by NIM or Nama
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('nim.ilike.%$searchQuery%,nama_lengkap.ilike.%$searchQuery%');
      }

      // FILTER: By Fakultas
      if (filterFakultas != null && filterFakultas.isNotEmpty && filterFakultas != 'Semua') {
        query = query.eq('fakultas', filterFakultas);
      }

      // FILTER: By Angkatan
      if (filterAngkatan != null && filterAngkatan.isNotEmpty && filterAngkatan != 'Semua') {
        query = query.eq('angkatan', filterAngkatan);
      }

      // FILTER: By Status
      if (filterStatus != null && filterStatus.isNotEmpty && filterStatus != 'Semua') {
        query = query.eq('status_mahasiswa', filterStatus);
      }

      // SORT - Terbaru dulu
      query = query.order('nim', ascending: false);

      // PAGINATION
      if (offset != null && limit != null) {
        query = query.range(offset, offset + limit - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }

      // Execute
      final response = await query;
      
      // Convert to List
      final List<dynamic> data = response as List;

      // Convert to model
      final result = data.map((json) => MahasiswaModel.fromJson(json as Map<String, dynamic>)).toList();
      
      debugPrint('✅ [MahasiswaService] Loaded ${result.length} mahasiswa');
      return result;
          
    } catch (e) {
      debugPrint('❌ [MahasiswaService] Error getAllMahasiswa: $e');
      throw Exception('Error get mahasiswa: ${e.toString()}');
    }
  }

  // ============================================================================
  // READ - Get mahasiswa by ID
  // ============================================================================
  Future<MahasiswaModel?> getMahasiswaById(String idMahasiswa) async {
    try {
      debugPrint('🔍 [MahasiswaService] Getting mahasiswa by ID: $idMahasiswa');
      
      final response = await _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .select()
          .eq('id_mahasiswa', idMahasiswa)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ [MahasiswaService] Mahasiswa not found: $idMahasiswa');
        return null;
      }
      
      debugPrint('✅ [MahasiswaService] Mahasiswa found');
      return MahasiswaModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [MahasiswaService] Error getMahasiswaById: $e');
      throw Exception('Error get mahasiswa by ID: ${e.toString()}');
    }
  }

  // ============================================================================
  // READ - Get mahasiswa by NIM
  // ============================================================================
  Future<MahasiswaModel?> getMahasiswaByNim(String nim) async {
    try {
      debugPrint('🔍 [MahasiswaService] Getting mahasiswa by NIM: $nim');
      
      final response = await _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .select()
          .eq('nim', nim)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ [MahasiswaService] Mahasiswa not found: $nim');
        return null;
      }
      
      debugPrint('✅ [MahasiswaService] Mahasiswa found');
      return MahasiswaModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [MahasiswaService] Error getMahasiswaByNim: $e');
      throw Exception('Error get mahasiswa by NIM: ${e.toString()}');
    }
  }

  // ============================================================================
  // UPDATE - Update data mahasiswa
  // ============================================================================
  Future<MahasiswaModel> updateMahasiswa({
    required String idMahasiswa,
    String? nim,
    String? namaLengkap,
    String? programStudi,
    String? fakultas,
    String? angkatan,
    String? statusMahasiswa,
  }) async {
    try {
      debugPrint('🔄 [MahasiswaService] Updating mahasiswa: ID=$idMahasiswa');
      
      // ✅ CEK: Mahasiswa exists
      final existing = await getMahasiswaById(idMahasiswa);
      if (existing == null) {
        debugPrint('❌ [MahasiswaService] Mahasiswa not found: $idMahasiswa');
        throw Exception('Mahasiswa dengan ID $idMahasiswa tidak ditemukan');
      }

      // ✅ VALIDASI: Jika NIM diubah, cek uniqueness
      if (nim != null && nim != existing.nim) {
        final duplicate = await getMahasiswaByNim(nim);
        if (duplicate != null) {
          debugPrint('❌ [MahasiswaService] NIM already exists: $nim');
          throw Exception('NIM $nim sudah terdaftar');
        }

        // Validasi panjang NIM
        if (nim.length != 12) {
          debugPrint('❌ [MahasiswaService] Invalid NIM length: ${nim.length}');
          throw Exception('NIM harus 12 digit');
        }

        // Validasi NIM hanya angka
        if (!RegExp(r'^[0-9]+$').hasMatch(nim)) {
          debugPrint('❌ [MahasiswaService] NIM contains non-numeric characters');
          throw Exception('NIM hanya boleh berisi angka');
        }
      }

      // ✅ VALIDASI: Cek angkatan valid (jika diubah)
      if (angkatan != null && angkatan.isNotEmpty) {
        final validAngkatanList = getValidAngkatanList();
        if (!validAngkatanList.contains(angkatan)) {
          debugPrint('❌ [MahasiswaService] Invalid angkatan: $angkatan');
          throw Exception('Angkatan tidak valid. Harus antara ${validAngkatanList.last} - ${validAngkatanList.first}');
        }
      }

      // ✅ BUILD UPDATE DATA (hanya field yang diubah)
      final Map<String, dynamic> updateData = {};
      
      if (nim != null) updateData['nim'] = nim;
      if (namaLengkap != null) updateData['nama_lengkap'] = namaLengkap;
      if (programStudi != null) updateData['program_studi'] = programStudi;
      if (fakultas != null) updateData['fakultas'] = fakultas;
      if (angkatan != null) updateData['angkatan'] = angkatan;
      if (statusMahasiswa != null) updateData['status_mahasiswa'] = statusMahasiswa;

      if (updateData.isEmpty) {
        debugPrint('⚠️ [MahasiswaService] No data to update');
        throw Exception('Tidak ada data yang diubah');
      }

      debugPrint('📤 [MahasiswaService] Updating ${updateData.length} fields...');
      
      // ✅ UPDATE
      final response = await _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .update(updateData)
          .eq('id_mahasiswa', idMahasiswa)
          .select()
          .single();

      debugPrint('✅ [MahasiswaService] Mahasiswa updated successfully');
      return MahasiswaModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('❌ [MahasiswaService] Postgrest error: ${e.code} - ${e.message}');
      if (e.code == '23505') {
        throw Exception('NIM sudah terdaftar');
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('❌ [MahasiswaService] Update error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // DELETE - Hapus mahasiswa (SOFT DELETE recommended!)
  // ============================================================================
  Future<void> deleteMahasiswa(String idMahasiswa, {bool hardDelete = false}) async {
    try {
      debugPrint('🗑️ [MahasiswaService] Deleting mahasiswa: ID=$idMahasiswa (hardDelete=$hardDelete)');
      
      // ✅ CEK: Mahasiswa exists
      final existing = await getMahasiswaById(idMahasiswa);
      if (existing == null) {
        debugPrint('❌ [MahasiswaService] Mahasiswa not found: $idMahasiswa');
        throw Exception('Mahasiswa dengan ID $idMahasiswa tidak ditemukan');
      }

      if (hardDelete) {
        // HARD DELETE (permanent) - NOT RECOMMENDED
        debugPrint('⚠️ [MahasiswaService] Performing HARD DELETE (permanent)');
        await _supabase
            .from(ApiEndpoints.mahasiswaAktif)
            .delete()
            .eq('id_mahasiswa', idMahasiswa);
        debugPrint('✅ [MahasiswaService] Hard delete successful');
      } else {
        // SOFT DELETE (recommended - ubah status jadi 'nonaktif')
        debugPrint('📝 [MahasiswaService] Performing SOFT DELETE (set status nonaktif)');
        await _supabase
            .from(ApiEndpoints.mahasiswaAktif)
            .update({'status_mahasiswa': 'nonaktif'})
            .eq('id_mahasiswa', idMahasiswa);
        debugPrint('✅ [MahasiswaService] Soft delete successful');
      }
    } catch (e) {
      debugPrint('❌ [MahasiswaService] Delete error: $e');
      throw Exception('Error delete mahasiswa: ${e.toString()}');
    }
  }

  // ============================================================================
  // HELPER - Get list fakultas (untuk dropdown)
  // ============================================================================
  Future<List<String>> getFakultasList() async {
    try {
      debugPrint('🔍 [MahasiswaService] Getting fakultas list from DB...');
      
      final response = await _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .select('fakultas')
          .not('fakultas', 'is', null);

      final fakultasSet = <String>{};
      for (var item in response) {
        final fakultas = item['fakultas'] as String?;
        if (fakultas != null && fakultas.isNotEmpty) {
          fakultasSet.add(fakultas);
        }
      }

      final list = fakultasSet.toList()..sort();
      debugPrint('✅ [MahasiswaService] Found ${list.length} unique fakultas');
      return list;
    } catch (e) {
      debugPrint('❌ [MahasiswaService] Error get fakultas list: $e');
      return [];
    }
  }

  // ============================================================================
  // HELPER - Get list angkatan dari DB (untuk backward compatibility)
  // ============================================================================
  Future<List<String>> getAngkatanList() async {
    try {
      debugPrint('🔍 [MahasiswaService] Getting angkatan list from DB...');
      
      final response = await _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .select('angkatan')
          .not('angkatan', 'is', null);

      final angkatanSet = <String>{};
      for (var item in response) {
        final angkatan = item['angkatan'] as String?;
        if (angkatan != null && angkatan.isNotEmpty) {
          angkatanSet.add(angkatan);
        }
      }

      final list = angkatanSet.toList()..sort((a, b) => b.compareTo(a)); // Terbaru dulu
      debugPrint('✅ [MahasiswaService] Found ${list.length} unique angkatan from DB');
      return list;
    } catch (e) {
      debugPrint('❌ [MahasiswaService] Error get angkatan list: $e');
      return [];
    }
  }

  // ============================================================================
  // ✅ NEW METHOD - Get VALID angkatan list (DYNAMIC & AUTO-UPDATE)
  // ============================================================================
  /// Generate list angkatan yang valid untuk mahasiswa aktif
  /// Formula: Mahasiswa maksimal kuliah 14 semester (7 tahun)
  /// Range: (currentYear - 7) sampai currentYear
  /// 
  /// Contoh di tahun 2026:
  /// - Min: 2019 (mahasiswa semester 14)
  /// - Max: 2026 (mahasiswa baru)
  /// - Output: ['2026', '2025', '2024', '2023', '2022', '2021', '2020', '2019']
  /// 
  /// Auto-update setiap tahun tanpa perlu ubah kode!
  List<String> getValidAngkatanList() {
    final currentYear = DateTime.now().year;
    final minYear = currentYear - 7; // 7 tahun yang lalu (14 semester)
    final maxYear = currentYear;
    
    final List<String> years = [];
    for (int year = maxYear; year >= minYear; year--) {
      years.add(year.toString());
    }
    
    debugPrint('📅 [MahasiswaService] Generated valid angkatan: $minYear - $maxYear (${years.length} years)');
    debugPrint('   Current year: $currentYear');
    debugPrint('   Min year (semester 14): $minYear');
    debugPrint('   List: $years');
    
    return years;
  }

  // ============================================================================
  // HELPER - Get count mahasiswa
  // ============================================================================
  Future<int> getTotalMahasiswa({
    String? filterFakultas,
    String? filterAngkatan,
    String? filterStatus,
  }) async {
    try {
      debugPrint('🔢 [MahasiswaService] Getting total mahasiswa count...');
      
      // Build query
      var query = _supabase
          .from(ApiEndpoints.mahasiswaAktif)
          .select('*');

      // Apply filters
      if (filterFakultas != null && filterFakultas.isNotEmpty && filterFakultas != 'Semua') {
        query = query.eq('fakultas', filterFakultas);
      }

      if (filterAngkatan != null && filterAngkatan.isNotEmpty && filterAngkatan != 'Semua') {
        query = query.eq('angkatan', filterAngkatan);
      }

      if (filterStatus != null && filterStatus.isNotEmpty && filterStatus != 'Semua') {
        query = query.eq('status_mahasiswa', filterStatus);
      }

      // Execute query
      final response = await query;
      
      // Count manual dari hasil query
      final count = (response as List).length;
      
      debugPrint('✅ [MahasiswaService] Total mahasiswa: $count');
      return count;
      
    } catch (e) {
      debugPrint('❌ [MahasiswaService] Error getTotalMahasiswa: $e');
      return 0;
    }
  }

  // ============================================================================
  // BULK - Import mahasiswa dari list (untuk import CSV/Excel)
  // ============================================================================
  Future<Map<String, dynamic>> bulkImportMahasiswa(
    List<Map<String, dynamic>> mahasiswaList,
  ) async {
    debugPrint('📥 [MahasiswaService] Starting bulk import: ${mahasiswaList.length} items');
    
    int successCount = 0;
    int errorCount = 0;
    List<String> errors = [];

    for (var i = 0; i < mahasiswaList.length; i++) {
      try {
        final data = mahasiswaList[i];
        debugPrint('   Processing row ${i + 1}/${mahasiswaList.length}: NIM=${data['nim']}');
        
        await createMahasiswa(
          nim: data['nim'],
          namaLengkap: data['nama_lengkap'],
          programStudi: data['program_studi'],
          fakultas: data['fakultas'],
          angkatan: data['angkatan'],
          statusMahasiswa: data['status_mahasiswa'] ?? 'aktif',
        );
        
        successCount++;
        debugPrint('   ✅ Row ${i + 1} imported successfully');
      } catch (e) {
        errorCount++;
        final errorMsg = 'Row ${i + 1}: ${e.toString()}';
        errors.add(errorMsg);
        debugPrint('   ❌ Row ${i + 1} failed: $e');
      }
    }

    debugPrint('✅ [MahasiswaService] Bulk import completed');
    debugPrint('   Success: $successCount');
    debugPrint('   Failed: $errorCount');

    return {
      'success': successCount,
      'error': errorCount,
      'errors': errors,
    };
  }
}