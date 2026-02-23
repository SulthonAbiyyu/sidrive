// ============================================================================
// CHAT SERVICE - FIXED UNTUK ARSITEKTUR ACTUAL
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import 'chat_activation_service.dart';
import 'chat_validation_service.dart';

class ChatService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  final _activationService = ChatActivationService();
  final _validationService = ChatValidationService();

  SupabaseClient getSupabase() {
    return _supabase;
  }

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _roomsChannel;

  // ========================================================================
  // ROOM MANAGEMENT
  // ========================================================================

  Future<ChatRoom?> createOrGetRoom({
    required ChatContext context,
    required List<String> participantIds,
    required Map<String, String> participantRoles,
    String? orderId,
    String? productId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('💬 Creating/Getting chat room...');
      print('   Context: $context');
      print('   Participants: $participantIds');
      print('   Order ID: $orderId');

      // 1. Check existing room
      final existingRoom = await _findExistingRoom(
        context: context,
        participantIds: participantIds,
        orderId: orderId,
        productId: productId,
      );

      if (existingRoom != null) {
        print('✅ Chat room already exists: ${existingRoom.id}');
        return existingRoom;
      }

      // 2. Check activation (customer-driver only)
      bool isActive = true;
      String? activationReason;

      if (context == ChatContext.customerDriver && orderId != null) {
        final activationCheck = await _activationService.checkChatEnabled(
          idPesanan: orderId,
        );
        isActive = activationCheck['isEnabled'] as bool;
        activationReason = activationCheck['reason'] as String?;
      }

      // 3. Create new room
      final roomId = _uuid.v4();
      final now = DateTime.now().toUtc();

      final roomData = {
        'id': roomId,
        'context': context.toString().split('.').last,
        'participant_ids': participantIds,
        'participant_roles': participantRoles,
        'id_pesanan': orderId,
        'id_produk': productId,
        'metadata': metadata,
        'is_active': isActive,
        'activation_reason': activationReason,
        'unread_count': {for (var id in participantIds) id: 0},
        'created_at': now.toIso8601String(),
      };

      // ✅ RPC: bypass RLS untuk INSERT chat_rooms
      final created = await _supabase.rpc('create_chat_room', params: {
        'p_id':               roomId,
        'p_context':          context.toString().split('.').last,
        'p_participant_ids':  participantIds,
        'p_participant_roles': participantRoles,
        'p_order_id':         orderId,
        'p_product_id':       productId,
        'p_metadata':         metadata,
        'p_is_active':        isActive,
        'p_activation_reason': activationReason,
      });

      print('✅ Chat room created: $roomId');
      print('   Active: $isActive');

      // Ambil dari hasil RPC jika ada, fallback ke roomData lokal
      if ((created as List).isNotEmpty) {
        return ChatRoom.fromJson(created.first);
      }
      return ChatRoom.fromJson(roomData);
    } catch (e, stackTrace) {
      print('❌ Error creating chat room: $e');
      print('Stack: $stackTrace');
      return null;
    }
  }

  /// ✅ RPC: bypass RLS untuk cari existing room
  Future<ChatRoom?> _findExistingRoom({
    required ChatContext context,
    required List<String> participantIds,
    String? orderId,
    String? productId,
  }) async {
    try {
      print('🔍 Searching existing room...');
      print('   Context: $context');
      print('   Order ID: $orderId');
      print('   Product ID: $productId');

      final results = await _supabase.rpc('find_existing_room', params: {
        'p_context':    context.toString().split('.').last,
        'p_order_id':   orderId,
        'p_product_id': productId,
      });

      print('   Found ${(results as List).length} potential rooms');

      // Manual filter untuk exact match participants
      for (var roomData in results) {
        final roomParticipants = List<String>.from(roomData['participant_ids'] ?? []);
        roomParticipants.sort();
        final sortedInput = List<String>.from(participantIds)..sort();
        if (roomParticipants.length == sortedInput.length &&
            roomParticipants.every((id) => sortedInput.contains(id))) {
          print('✅ Found existing room: ${roomData['id']}');
          return ChatRoom.fromJson(roomData);
        }
      }

      print('❌ No existing room found');
      return null;
    } catch (e) {
      print('❌ Error finding room: $e');
      return null;
    }
  }

  Future<List<ChatRoom>> getUserChatRooms(String userId) async {
    try {
      print('📋 Getting chat rooms for user: $userId');
      // ✅ RPC: bypass RLS
      final result = await _supabase
          .rpc('get_user_chat_rooms', params: {'p_user_id': userId});
      final rooms = (result as List)
          .map((json) => ChatRoom.fromJson(json))
          .toList();
      print('✅ Found ${rooms.length} chat rooms');
      return rooms;
    } catch (e, stackTrace) {
      print('❌ Error getting chat rooms: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  /// Khusus admin CS: ambil semua room customerSupport (bypass RLS)
  Future<List<ChatRoom>> getCustomerSupportRooms() async {
    try {
      print('📋 Getting all customerSupport rooms for admin');
      // ✅ RPC: bypass RLS
      final result = await _supabase.rpc('get_customer_support_rooms');
      final rooms = (result as List)
          .map((json) => ChatRoom.fromJson(json))
          .toList();
      print('✅ Found ${rooms.length} CS rooms');
      return rooms;
    } catch (e, stackTrace) {
      print('❌ Error getting CS rooms: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateRoomActivation(String roomId) async {
    try {
      final roomList = await _supabase
          .rpc('get_chat_room_by_id', params: {'p_room_id': roomId});
      if ((roomList as List).isEmpty) {
        return {'isActive': false, 'reason': 'Room tidak ditemukan'};
      }
      final room = roomList.first;

      if (room['context'] != 'customerDriver' || room['id_pesanan'] == null) {
        return {'isActive': true, 'reason': 'Chat aktif'};
      }

      final activationCheck = await _activationService.checkChatEnabled(
        idPesanan: room['id_pesanan'],
      );

      // ✅ RPC: bypass RLS untuk UPDATE is_active
      await _supabase.rpc('update_room_activation_status', params: {
        'p_room_id':   roomId,
        'p_is_active': activationCheck['isEnabled'],
        'p_reason':    activationCheck['reason'],
      });

      // ✅ FIXED: Normalize key ke 'isActive' agar konsisten dengan seluruh app
      // ChatActivationService menggunakan 'isEnabled', tapi ChatRoomPage pakai 'isActive'
      return {
        'isActive': activationCheck['isEnabled'],
        'reason': activationCheck['reason'],
        'driverProgress': activationCheck['driverProgress'],
        'requiredProgress': activationCheck['requiredProgress'],
        'progressPercent': activationCheck['progressPercent'],
      };
    } catch (e) {
      print('❌ Error updating activation: $e');
      return {'isActive': false, 'reason': 'Error: $e'};
    }
  }

  // ========================================================================
  // MESSAGE MANAGEMENT
  // ========================================================================

  Future<ChatMessage?> sendMessage({
    required String roomId,
    required String senderId,
    required String senderRole,
    required MessageType type,
    String? textContent,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('📤 Sending message to room: $roomId');

      // ✅ RPC: bypass RLS untuk baca chat_rooms
      final roomList = await _supabase
          .rpc('get_chat_room_by_id', params: {'p_room_id': roomId});
      if ((roomList as List).isEmpty) {
        print('❌ Chat room not found');
        return null;
      }
      final room = roomList.first;

      if (room['is_active'] == false) {
        print('❌ Chat room not active');
        return null;
      }

      if (room['context'] == 'customerUmkm' && textContent != null) {
        final isValid = _validationService.validateMessage(textContent);
        if (!isValid) {
          print('❌ Message contains blocked content');
          throw Exception('Pesan mengandung nomor telepon. Harap hubungi melalui platform.');
        }
      }

      final messageId = _uuid.v4();
      final now = DateTime.now().toUtc();

      final messageData = {
        'id': messageId,
        'room_id': roomId,
        'sender_id': senderId,
        'sender_role': senderRole,
        'message_type': type.toString().split('.').last,
        'text_content': textContent,
        'image_url': imageUrl,
        'metadata': metadata,
        'status': MessageStatus.sent.toString().split('.').last,
        'created_at': now.toIso8601String(),
      };

      // ✅ RPC: bypass RLS untuk INSERT chat_messages
      final inserted = await _supabase.rpc('insert_chat_message', params: {
        'p_id':           messageId,
        'p_room_id':      roomId,
        'p_sender_id':    senderId,
        'p_sender_role':  senderRole,
        'p_message_type': type.toString().split('.').last,
        'p_text_content': textContent,
        'p_image_url':    imageUrl,
        'p_metadata':     metadata,
      });
      await _updateRoomAfterMessage(roomId, senderId, textContent ?? 'Gambar');

      print('✅ Message sent: $messageId');
      // Gunakan data dari RPC jika ada, fallback ke lokal
      if ((inserted as List).isNotEmpty) {
        return ChatMessage.fromJson(inserted.first);
      }
      return ChatMessage.fromJson(messageData);
    } catch (e, stackTrace) {
      print('❌ Error sending message: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  Future<ChatMessage?> sendTextMessage({
    required String roomId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    return sendMessage(
      roomId: roomId,
      senderId: senderId,
      senderRole: senderRole,
      type: MessageType.text,
      textContent: text,
    );
  }

  Future<ChatMessage?> sendProductReply({
    required String roomId,
    required String senderId,
    required String senderRole,
    required String productId,
    required String productName,
    required String productImage,
    required int productPrice,
    String? additionalText,
  }) async {
    return sendMessage(
      roomId: roomId,
      senderId: senderId,
      senderRole: senderRole,
      type: MessageType.productReply,
      textContent: additionalText,
      metadata: {
        'product_id': productId,
        'product_name': productName,
        'product_image': productImage,
        'product_price': productPrice,
      },
    );
  }

  Future<List<ChatMessage>> getMessages(String roomId, {int limit = 50}) async {
    try {
      print('📊 Getting messages for room: $roomId');
      // ✅ RPC: bypass RLS
      final result = await _supabase
          .rpc('get_chat_messages', params: {'p_room_id': roomId, 'p_limit': limit});
      final messages = (result as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList()
          .reversed
          .toList();
      print('✅ Found ${messages.length} messages');
      return messages;
    } catch (e, stackTrace) {
      print('❌ Error getting messages: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  Future<void> markAsRead(String roomId, String userId) async {
    try {
      // ✅ RPC: bypass RLS untuk update unread_count
      await _supabase.rpc('reset_unread_count', params: {
        'p_room_id': roomId,
        'p_user_id': userId,
      });
      // ✅ RPC: bypass RLS untuk UPDATE status pesan
      await _supabase.rpc('update_messages_read_status', params: {
        'p_room_id': roomId,
        'p_user_id': userId,
      });
      print('✅ Messages marked as read for user: $userId');
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  Future<void> _updateRoomAfterMessage(
    String roomId,
    String senderId,
    String lastMessage,
  ) async {
    try {
      // ✅ RPC: bypass RLS untuk update last_message + unread_count
      await _supabase.rpc('update_room_last_message', params: {
        'p_room_id':      roomId,
        'p_last_message': lastMessage,
        'p_sender_id':    senderId,
      });
    } catch (e) {
      print('❌ Error updating room: $e');
    }
  }

  // ========================================================================
  // PARTICIPANT INFO - ✅ FIXED: Query tabel USERS
  // ========================================================================

  Future<List<ParticipantInfo>> getParticipantsInfo(List<String> userIds) async {
    try {
      print('👥 Getting participants info for: $userIds');

      // ✅ RPC: bypass RLS tabel users
      final result = await _supabase
          .rpc('get_users_info', params: {'p_user_ids': userIds});

      final participants = (result as List).map((json) {
        return ParticipantInfo(
          userId: json['id_user'],
          role: json['role'],
          name: json['nama'],
          avatarUrl: json['foto_profil'],
          phoneNumber: json['no_telp'],
        );
      }).toList();

      print('✅ Found ${participants.length} participants');
      return participants;
    } catch (e, stackTrace) {
      print('❌ Error getting participants: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  // ========================================================================
  // REALTIME SUBSCRIPTIONS
  // ========================================================================

  void subscribeToMessages(String roomId, Function(ChatMessage) onMessage) {
    // ✅ Gunakan removeChannel (bukan unsubscribe) agar benar-benar bersih
    if (_messagesChannel != null) {
      _supabase.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }

    final channelName = 'msg-$roomId-${DateTime.now().millisecondsSinceEpoch}';

    _messagesChannel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            print('📨 New message received in room: $roomId');
            final message = ChatMessage.fromJson(payload.newRecord);
            onMessage(message);
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('✅ Messages channel CONFIRMED: $channelName');
          } else if (status == RealtimeSubscribeStatus.channelError) {
            print('❌ Messages channel error: $error');
          } else {
            print('🔄 Messages channel status: $status');
          }
        });

    print('🔴 Subscribing to messages: $channelName');
  }

  // =========================================================================
  // SUBSCRIBE ALL CS MESSAGES (untuk provider-level badge & list update)
  // =========================================================================
  RealtimeChannel? _allCsMessagesChannel;

  void subscribeToAllCsMessages(Function(Map<String, dynamic>) onNewMessage) {
    // ✅ Unsubscribe dulu dan tunggu benar-benar mati sebelum re-subscribe
    if (_allCsMessagesChannel != null) {
      _supabase.removeChannel(_allCsMessagesChannel!);
      _allCsMessagesChannel = null;
    }

    // ✅ Gunakan timestamp di nama channel agar tidak konflik dengan channel lama
    final channelName = 'cs-messages-global-${DateTime.now().millisecondsSinceEpoch}';

    _allCsMessagesChannel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            print('📨 [CS Global] New message detected: ${payload.newRecord['room_id']}');
            onNewMessage(payload.newRecord);
          },
        )
        .subscribe((status, [error]) {
          // ✅ Callback subscribe - log status untuk debug
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('✅ [CS Global] Realtime subscription CONFIRMED: $channelName');
          } else if (status == RealtimeSubscribeStatus.channelError) {
            print('❌ [CS Global] Channel error: $error → retry in 3s');
            // Auto retry setelah error
            Future.delayed(const Duration(seconds: 3), () {
              subscribeToAllCsMessages(onNewMessage);
            });
          } else if (status == RealtimeSubscribeStatus.timedOut) {
            print('⏱️ [CS Global] Timeout → retry in 5s');
            Future.delayed(const Duration(seconds: 5), () {
              subscribeToAllCsMessages(onNewMessage);
            });
          } else {
            print('🔄 [CS Global] Status: $status');
          }
        });

    print('🔴 [CS Global] Subscribing to all CS messages: $channelName');
  }

  void unsubscribeAllCsMessages() {
    if (_allCsMessagesChannel != null) {
      _supabase.removeChannel(_allCsMessagesChannel!);
      _allCsMessagesChannel = null;
    }
    print('🔴 [CS Global] Unsubscribed from all CS messages');
  }

  void subscribeToRoomUpdates(String userId, Function(ChatRoom) onUpdate) {
    // ✅ Gunakan removeChannel agar benar-benar bersih
    if (_roomsChannel != null) {
      _supabase.removeChannel(_roomsChannel!);
      _roomsChannel = null;
    }

    final channelName = 'rooms-$userId-${DateTime.now().millisecondsSinceEpoch}';

    // ✅ Listen INSERT (room baru) DAN UPDATE (last_message berubah)
    _roomsChannel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_rooms',
          callback: (payload) {
            print('🔄 Room inserted (new)');
            final room = ChatRoom.fromJson(payload.newRecord);
            if (room.participantIds.contains(userId)) {
              onUpdate(room);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_rooms',
          callback: (payload) {
            print('🔄 Room updated');
            final room = ChatRoom.fromJson(payload.newRecord);
            if (room.participantIds.contains(userId)) {
              onUpdate(room);
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('✅ Rooms channel CONFIRMED: $channelName');
          } else if (status == RealtimeSubscribeStatus.channelError) {
            print('❌ Rooms channel error: $error');
          } else {
            print('🔄 Rooms channel status: $status');
          }
        });

    print('🔴 Subscribing to room updates: $channelName');
  }

  /// Hanya unsubscribe channel pesan (dipanggil saat keluar dari ChatRoomPage)
  void unsubscribeMessages() {
    if (_messagesChannel != null) {
      _supabase.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }
    print('🔴 Unsubscribed from messages channel');
  }

  /// Hanya unsubscribe channel room (dipanggil saat keluar dari ChatListPage)
  void unsubscribeRooms() {
    if (_roomsChannel != null) {
      _supabase.removeChannel(_roomsChannel!);
      _roomsChannel = null;
    }
    print('🔴 Unsubscribed from rooms channel');
  }

  void unsubscribeAll() {
    if (_messagesChannel != null) {
      _supabase.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }
    if (_roomsChannel != null) {
      _supabase.removeChannel(_roomsChannel!);
      _roomsChannel = null;
    }
    if (_allCsMessagesChannel != null) {
      _supabase.removeChannel(_allCsMessagesChannel!);
      _allCsMessagesChannel = null;
    }
    print('🔴 Unsubscribed from all channels');
  }

  // ========================================================================
  // UTILITY METHODS
  // ========================================================================

  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final rooms = await getUserChatRooms(userId);
      return rooms.fold<int>(
        0,
        (sum, room) => sum + room.getUnreadCount(userId),
      );
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      // ✅ RPC: bypass RLS DELETE chat_messages
      await _supabase.rpc('delete_chat_messages_by_room', params: {'p_room_id': roomId});
      // ✅ RPC: bypass RLS DELETE chat_rooms
      await _supabase.rpc('delete_chat_room', params: {'p_room_id': roomId});
      print('✅ Room deleted: $roomId');
    } catch (e) {
      print('❌ Error deleting room: $e');
    }
  }

  Future<List<ChatMessage>> searchMessages(String roomId, String query) async {
    try {
      // ✅ RPC: bypass RLS
      final result = await _supabase.rpc('search_chat_messages', params: {
        'p_room_id': roomId,
        'p_query':   query,
      });
      return (result as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error searching messages: $e');
      return [];
    }
  }

  void dispose() {
    unsubscribeAll();
  }
}