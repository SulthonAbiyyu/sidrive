// ============================================================================
// CUSTOMER SUPPORT SERVICE
// Service khusus untuk fitur Live Chat antara user dan admin/CS
// ============================================================================
// Cara kerja:
//   1. Cari user dengan role 'admin' DAN status 'active' di tabel users
//   2. Buat/ambil chat_room dengan context 'customerSupport'
//   3. Room selalu is_active = true (tidak butuh activation check)
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/models/chat_models.dart';

class CustomerSupportService {
  final _supabase = Supabase.instance.client;
  final _chatService = ChatService();

  // =========================================================================
  // FIND ACTIVE ADMIN USER ID
  // Query tabel users untuk mencari akun admin yang status-nya 'active'
  //
  // PENTING: Filter status = 'active' wajib ada.
  // Dari hasil DB diketahui ada 3 admin:
  //   - Admin UMSIDA Connect → active       ✅ (yang akan dipilih)
  //   - Super Admin          → pending_verification  ❌ skip
  //   - Matchaby             → pending_verification  ❌ skip
  // =========================================================================
  Future<String?> getAdminUserId() async {
    try {
      print('🔍 [CS] Mencari admin aktif...');

      final result = await _supabase
          .from('users')
          .select('id_user, nama, status')
          .eq('role', 'admin')
          .eq('status', 'active')       // ✅ Hanya admin yang sudah active
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (result == null) {
        print('❌ [CS] Tidak ada admin aktif ditemukan');
        return null;
      }

      print('✅ [CS] Admin aktif: ${result['nama']} (${result['id_user']})');
      return result['id_user'] as String;
    } catch (e) {
      print('❌ [CS] Error getAdminUserId: $e');
      return null;
    }
  }

  // =========================================================================
  // CREATE OR GET CUSTOMER SUPPORT ROOM
  // Buat atau ambil room CS antara user (customer/driver/umkm) dan admin
  //
  // CATATAN PENTING:
  //   - Context: ChatContext.customerSupport
  //   - is_active selalu TRUE (tidak masuk ChatActivationService
  //     karena kondisi di chat_service.dart hanya cek customerDriver)
  //   - Tidak perlu id_pesanan / id_produk
  //   - Setiap user hanya punya 1 room CS dengan admin (persistent)
  // =========================================================================
  Future<CustomerSupportRoomResult> createOrGetSupportRoom({
    required String userId,
    required String userRole,
  }) async {
    try {
      print('💬 [CS] createOrGetSupportRoom untuk user: $userId (role: $userRole)');

      // 1. Cari admin ID yang aktif
      final adminId = await getAdminUserId();
      if (adminId == null) {
        return CustomerSupportRoomResult.error(
          'Tim customer service sedang tidak tersedia. Silakan coba lagi nanti.',
        );
      }

      // 2. Buat/ambil room via ChatService yang sudah ada
      //    chat_service.dart: createOrGetRoom akan:
      //    - Cek existing room dulu (tidak akan duplikat)
      //    - Buat baru jika belum ada
      //    - is_active = true karena bukan customerDriver + tidak ada orderId
      final room = await _chatService.createOrGetRoom(
        context: ChatContext.customerSupport,
        participantIds: [userId, adminId],
        participantRoles: {
          userId: userRole,
          adminId: 'admin',
        },
        // orderId: null  → tidak perlu, CS tidak terkait pesanan
        // productId: null → tidak perlu
      );

      if (room == null) {
        return CustomerSupportRoomResult.error(
          'Gagal membuat sesi chat. Silakan coba lagi.',
        );
      }

      print('✅ [CS] Room CS berhasil: ${room.id}');
      return CustomerSupportRoomResult.success(
        room: room,
        adminId: adminId,
      );
    } catch (e) {
      print('❌ [CS] Error createOrGetSupportRoom: $e');
      return CustomerSupportRoomResult.error('Error: $e');
    }
  }
}

// ============================================================================
// RESULT WRAPPER
// ============================================================================
class CustomerSupportRoomResult {
  final bool isSuccess;
  final ChatRoom? room;
  final String? adminId;
  final String? errorMessage;

  CustomerSupportRoomResult._({
    required this.isSuccess,
    this.room,
    this.adminId,
    this.errorMessage,
  });

  factory CustomerSupportRoomResult.success({
    required ChatRoom room,
    required String adminId,
  }) {
    return CustomerSupportRoomResult._(
      isSuccess: true,
      room: room,
      adminId: adminId,
    );
  }

  factory CustomerSupportRoomResult.error(String message) {
    return CustomerSupportRoomResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}