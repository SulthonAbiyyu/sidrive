// ============================================================================
// KTM_VERIFICATION_SERVICE.DART - MINIMAL FIX
// ✅ HANYA FIX ERROR: response.isEmpty (bukan response == null)
// ✅ TAMBAH LOGGING DETAIL untuk debugging
// ============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/models/ktm_verification_model.dart';
import 'dart:io';

class KtmVerificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'ktm_verification_requests';
  static const String _bucketName = 'ktm-photos';

  // ============================================================================
  // ✅ FIXED: Check KTM verification status by NIM
  // ============================================================================
  Future<Map<String, dynamic>?> checkStatusByNim(String nim) async {
    try {
      debugPrint('🔍 [KTM_SERVICE] ================================');
      debugPrint('🔍 [KTM_SERVICE] Checking status for NIM: $nim');

      final response = await _supabase
          .from(_tableName)
          .select('id, status, rejection_reason, created_at')
          .eq('nim', nim)
          .order('created_at', ascending: false);

      debugPrint('📊 [KTM_SERVICE] Response: $response');

      // ✅ FIX: response adalah List, bukan nullable
      if (response.isEmpty) {
        debugPrint('ℹ️ [KTM_SERVICE] No verification found for NIM: $nim');
        return null;
      }

      final records = response as List;
      debugPrint('✅ [KTM_SERVICE] Found ${records.length} record(s) for NIM: $nim');

      // Debug setiap record
      for (int i = 0; i < records.length; i++) {
        debugPrint('   Record $i: status=${records[i]['status']}, created=${records[i]['created_at']}');
      }

      // Prioritas 1: kalau ada approved, langsung return
      final approved = records.where((r) => r['status'] == 'approved').toList();
      if (approved.isNotEmpty) {
        debugPrint('✅ [KTM_SERVICE] APPROVED found!');
        return {'status': 'approved', 'rejection_reason': null, 'id': approved.first['id']};
      }

      // Prioritas 2: kalau ada rejected, return yang terbaru
      final rejected = records.where((r) => r['status'] == 'rejected').toList();
      if (rejected.isNotEmpty) {
        debugPrint('❌ [KTM_SERVICE] REJECTED found! Reason: ${rejected.first['rejection_reason']}');
        return {
          'status': 'rejected',
          'rejection_reason': rejected.first['rejection_reason'],
          'id': rejected.first['id'],
        };
      }

      // Prioritas 3: pending terbaru
      debugPrint('⏳ [KTM_SERVICE] PENDING found!');
      return {'status': 'pending', 'rejection_reason': null, 'id': records.first['id']};

    } catch (e, stackTrace) {
      debugPrint('❌ [KTM_SERVICE] Error checking status: $e');
      debugPrint('Stack: $stackTrace');
      return null;
    }
  }

  // ============================================================================
  // CREATE - Submit KTM verification request
  // ============================================================================
  Future<KtmVerificationModel> submitVerificationRequest({
    String? idUser,
    required String nim,
    required File ktmPhoto,
    String? extractedName,
  }) async {
    try {
      debugPrint('📤 [KTM_SERVICE] Submitting verification request...');
      debugPrint('   User ID: ${idUser ?? "NULL (pre-registration)"}');
      debugPrint('   NIM: $nim');

      // 1. Upload foto ke storage
      final photoUrl = await _uploadKtmPhoto(idUser ?? nim, ktmPhoto);
      debugPrint('✅ [KTM_SERVICE] Photo uploaded: $photoUrl');

      // 2. Insert request ke database
      final response = await _supabase.from(_tableName).insert({
        'id_user': idUser,
        'nim': nim,
        'foto_ktm_url': photoUrl,
        'extracted_name': extractedName,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      debugPrint('✅ [KTM_SERVICE] Request submitted successfully');
      return KtmVerificationModel.fromJson(response);
    } catch (e, stackTrace) {
      debugPrint('❌ [KTM_SERVICE] Error submitting request: $e');
      debugPrint('Stack: $stackTrace');
      throw Exception('Gagal submit verifikasi KTM: ${e.toString()}');
    }
  }

  // ============================================================================
  // UPLOAD - Upload foto KTM ke Supabase Storage
  // ============================================================================
  Future<String> _uploadKtmPhoto(String? userId, File photo) async {
    try {
      final String uploadId = userId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final String fileName = '${uploadId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '$uploadId/$fileName';

      debugPrint('📤 [KTM_SERVICE] Uploading photo to storage...');
      debugPrint('   Bucket: $_bucketName');
      debugPrint('   Path: $filePath');

      await _supabase.storage
          .from(_bucketName)
          .upload(filePath, photo, fileOptions: const FileOptions(upsert: true));

      final String publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      debugPrint('✅ [KTM_SERVICE] Photo uploaded successfully');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error uploading photo: $e');
      throw Exception('Gagal upload foto: ${e.toString()}');
    }
  }

  // ============================================================================
  // READ - Get user's verification request
  // ============================================================================
  Future<KtmVerificationModel?> getUserVerificationRequest(String userId) async {
    try {
      debugPrint('🔍 [KTM_SERVICE] Getting verification request for user: $userId');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id_user', userId)
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ [KTM_SERVICE] No verification request found');
        return null;
      }

      debugPrint('✅ [KTM_SERVICE] Verification request found: ${response['status']}');
      return KtmVerificationModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error getting request: $e');
      return null;
    }
  }

  // ============================================================================
  // READ - Get verification request by NIM
  // ============================================================================
  Future<KtmVerificationModel?> getVerificationRequestByNim(String nim) async {
    try {
      debugPrint('🔍 [KTM_SERVICE] Getting verification request by NIM: $nim');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('nim', nim)
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ [KTM_SERVICE] No verification request found for NIM: $nim');
        return null;
      }

      debugPrint('✅ [KTM_SERVICE] Verification request found: ${response['status']}');
      return KtmVerificationModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error getting request by NIM: $e');
      return null;
    }
  }

  // ============================================================================
  // READ - Get verification request by ID (for admin)
  // ============================================================================
  Future<KtmVerificationModel?> getUserVerificationRequestById(String requestId) async {
    try {
      debugPrint('🔍 [KTM_SERVICE] Getting verification request by ID: $requestId');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', requestId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ [KTM_SERVICE] No verification request found with ID: $requestId');
        return null;
      }

      debugPrint('✅ [KTM_SERVICE] Verification request found: ${response['status']}');
      return KtmVerificationModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error getting request by ID: $e');
      return null;
    }
  }
  
  // Alias untuk backward compatibility
  Future<KtmVerificationModel?> getVerificationByNim(String nim) async {
    try {
      debugPrint('🔍 [KTM_SERVICE] Getting verification request by NIM: $nim');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('nim', nim)
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ [KTM_SERVICE] No verification request found for NIM: $nim');
        return null;
      }

      debugPrint('✅ [KTM_SERVICE] Verification request found: ${response['status']}');
      return KtmVerificationModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error getting request by NIM: $e');
      return null;
    }
  }
  
  // ============================================================================
  // READ - Get pending requests (for admin)
  // ============================================================================
  Future<List<KtmVerificationModel>> getPendingRequests() async {
    try {
      debugPrint('🔍 [KTM_SERVICE] Getting pending requests...');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final requests = (response as List)
          .map((json) => KtmVerificationModel.fromJson(json))
          .toList();

      debugPrint('✅ [KTM_SERVICE] Found ${requests.length} pending requests');
      return requests;
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error getting pending requests: $e');
      return [];
    }
  }

  // ============================================================================
  // UPDATE - Approve request (admin only)
  // ============================================================================
  Future<void> approveRequest(String requestId, String adminId) async {
    try {
      debugPrint('✅ [KTM_SERVICE] Approving request: $requestId');

      // 1. Get request detail to know the NIM
      final request = await getUserVerificationRequestById(requestId);
      if (request == null) {
        throw Exception('Request not found');
      }

      // 2. Approve this request
      await _supabase.from(_tableName).update({
        'status': 'approved',
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': adminId,
      }).eq('id', requestId);

      debugPrint('✅ [KTM_SERVICE] Request approved successfully');

      // 3. Auto-delete other pending/rejected requests with same NIM
      await _deleteDuplicateRequests(request.nim, requestId);

    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error approving request: $e');
      throw Exception('Gagal approve request: ${e.toString()}');
    }
  }

  // ============================================================================
  // Delete duplicate requests (keep only the approved one)
  // ============================================================================
  Future<void> _deleteDuplicateRequests(String nim, String keepRequestId) async {
    try {
      debugPrint('🗑️ [KTM_SERVICE] Deleting duplicate requests for NIM: $nim');

      // Get all requests with same NIM except the one we're keeping
      final duplicates = await _supabase
          .from(_tableName)
          .select('id, foto_ktm_url')
          .eq('nim', nim)
          .neq('id', keepRequestId);

      if (duplicates.isEmpty) {
        debugPrint('ℹ️ [KTM_SERVICE] No duplicates found');
        return;
      }

      debugPrint('🗑️ [KTM_SERVICE] Found ${(duplicates as List).length} duplicates');

      // Delete photos from storage and records from database
      for (final dup in duplicates) {
        try {
          // Delete photo from storage
          if (dup['foto_ktm_url'] != null) {
            await deleteKtmPhoto(dup['foto_ktm_url']);
          }
          
          // Delete record from database
          await _supabase.from(_tableName).delete().eq('id', dup['id']);
          
          debugPrint('   ✅ Deleted duplicate: ${dup['id']}');
        } catch (e) {
          debugPrint('   ⚠️ Error deleting duplicate ${dup['id']}: $e');
          // Continue dengan duplicates lainnya
        }
      }

      debugPrint('✅ [KTM_SERVICE] All duplicates deleted');
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error deleting duplicates: $e');
      // Don't throw error, duplicate deletion is not critical
    }
  }

  // ============================================================================
  // UPDATE - Reject request (admin only)
  // ============================================================================
  Future<void> rejectRequest(
    String requestId,
    String adminId,
    String reason,
  ) async {
    try {
      debugPrint('❌ [KTM_SERVICE] Rejecting request: $requestId');
      debugPrint('   Reason: $reason');

      await _supabase.from(_tableName).update({
        'status': 'rejected',
        'rejection_reason': reason,
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': adminId,
      }).eq('id', requestId);

      debugPrint('✅ [KTM_SERVICE] Request rejected successfully');
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error rejecting request: $e');
      throw Exception('Gagal reject request: ${e.toString()}');
    }
  }

  // ============================================================================
  // DELETE - Delete request
  // ============================================================================
  Future<void> deleteRequest(String requestId) async {
    try {
      debugPrint('🗑️ [KTM_SERVICE] Deleting request: $requestId');

      await _supabase.from(_tableName).delete().eq('id', requestId);

      debugPrint('✅ [KTM_SERVICE] Request deleted successfully');
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error deleting request: $e');
      throw Exception('Gagal delete request: ${e.toString()}');
    }
  }

  // ============================================================================
  // HELPER - Check if user has pending request
  // ============================================================================
  Future<bool> hasPendingRequest(String userId) async {
    try {
      final request = await getUserVerificationRequest(userId);
      return request != null && request.isPending;
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error checking pending request: $e');
      return false;
    }
  }

  // ============================================================================
  // HELPER - Delete KTM photo from storage
  // ============================================================================
  Future<void> deleteKtmPhoto(String photoUrl) async {
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      final bucketIndex = pathSegments.indexOf('object');
      if (bucketIndex == -1 || bucketIndex + 2 >= pathSegments.length) {
        debugPrint('⚠️ [KTM_SERVICE] Invalid photo URL format');
        return;
      }

      final filePath = pathSegments.sublist(bucketIndex + 2).join('/');
      
      debugPrint('🗑️ [KTM_SERVICE] Deleting photo: $filePath');

      await _supabase.storage.from(_bucketName).remove([filePath]);

      debugPrint('✅ [KTM_SERVICE] Photo deleted successfully');
    } catch (e) {
      debugPrint('❌ [KTM_SERVICE] Error deleting photo: $e');
      // Don't throw error, photo deletion is not critical
    }
  }
}