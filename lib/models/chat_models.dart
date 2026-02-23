// ============================================================================
// CHAT MODELS - Universal untuk semua konteks chat
// ============================================================================

import 'package:flutter/material.dart';

/// 🎯 CHAT CONTEXT - Tipe komunikasi
enum ChatContext {
  customerDriver,    // Customer <-> Driver (order ojek)
  customerUmkm,      // Customer <-> UMKM (order produk)
  umkmDriver,        // UMKM <-> Driver (delivery)
  groupOrder,        // Customer <-> UMKM <-> Driver (group chat)
  customerSupport,   // Customer/Driver/UMKM <-> Admin CS (bantuan)
}

/// 📦 CHAT ROOM MODEL
class ChatRoom {
  final String id;
  final ChatContext context;
  final List<String> participantIds;
  final Map<String, String> participantRoles; // userId -> role
  final String? orderId;          // Untuk context order
  final String? productId;        // Untuk context product
  final Map<String, dynamic>? metadata; // Data tambahan (produk, jarak, dll)
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount; // userId -> count
  final bool isActive;            // Chat aktif atau tidak
  final String? activationReason; // Alasan chat dinonaktifkan
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatRoom({
    required this.id,
    required this.context,
    required this.participantIds,
    required this.participantRoles,
    this.orderId,
    this.productId,
    this.metadata,
    this.lastMessage,
    this.lastMessageAt,
    Map<String, int>? unreadCount,
    this.isActive = true,
    this.activationReason,
    required this.createdAt,
    this.updatedAt,
  }) : unreadCount = unreadCount ?? {};

  /// Parse dari Supabase
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      context: ChatContext.values.firstWhere(
        (e) => e.toString().split('.').last == json['context'],
        orElse: () => ChatContext.customerDriver,
      ),
      participantIds: List<String>.from(json['participant_ids'] ?? []),
      participantRoles: Map<String, String>.from(json['participant_roles'] ?? {}),
      orderId: json['id_pesanan'],
      productId: json['id_produk'],
      metadata: json['metadata'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: Map<String, int>.from(json['unread_count'] ?? {}),
      isActive: json['is_active'] ?? true,
      activationReason: json['activation_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'context': context.toString().split('.').last,
      'participant_ids': participantIds,
      'participant_roles': participantRoles,
      'id_pesanan': orderId,
      'id_produk': productId,
      'metadata': metadata,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'is_active': isActive,
      'activation_reason': activationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get other participant (untuk 1-on-1 chat)
  String? getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Get unread count untuk user tertentu
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Copy with method untuk update
  ChatRoom copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    Map<String, int>? unreadCount,
    bool? isActive,
    String? activationReason,
  }) {
    return ChatRoom(
      id: id,
      context: context,
      participantIds: participantIds,
      participantRoles: participantRoles,
      orderId: orderId,
      productId: productId,
      metadata: metadata,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      activationReason: activationReason ?? this.activationReason,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// 💬 CHAT MESSAGE MODEL
enum MessageType {
  text,
  image,
  productReply,  // Reply produk
  orderInfo,     // Info pesanan
  systemInfo,    // Pesan system (driver sudah dekat, dll)
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderRole;
  final MessageType type;
  final String? textContent;
  final String? imageUrl;
  final Map<String, dynamic>? metadata; // Untuk product info, order info, dll
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderRole,
    required this.type,
    this.textContent,
    this.imageUrl,
    this.metadata,
    this.status = MessageStatus.sending,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      senderRole: json['sender_role'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['message_type'],
        orElse: () => MessageType.text,
      ),
      textContent: json['text_content'],
      imageUrl: json['image_url'],
      metadata: json['metadata'],
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'message_type': type.toString().split('.').last,
      'text_content': textContent,
      'image_url': imageUrl,
      'metadata': metadata,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  /// Check apakah pesan dari user saat ini
  bool isMine(String currentUserId) => senderId == currentUserId;

  /// Copy with untuk update status
  ChatMessage copyWith({
    MessageStatus? status,
    DateTime? updatedAt,
  }) {
    return ChatMessage(
      id: id,
      roomId: roomId,
      senderId: senderId,
      senderRole: senderRole,
      type: type,
      textContent: textContent,
      imageUrl: imageUrl,
      metadata: metadata,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted,
    );
  }
}

/// 👤 PARTICIPANT INFO (untuk UI)
class ParticipantInfo {
  final String userId;
  final String role;
  final String name;
  final String? avatarUrl;
  final String? phoneNumber;
  final bool isOnline;
  final DateTime? lastSeen;

  ParticipantInfo({
    required this.userId,
    required this.role,
    required this.name,
    this.avatarUrl,
    this.phoneNumber,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      userId: json['id'] ?? json['id_user'],
      role: json['role'],
      name: json['nama_lengkap'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      phoneNumber: json['no_telp'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
    );
  }
}

/// 🎨 CHAT THEME (untuk UI consistency)
class ChatTheme {
  static const Color myBubbleColor = Color(0xFFFF85A1);
  static const Color otherBubbleColor = Color(0xFFF0F0F0);
  static const Color systemMessageColor = Color(0xFFE3F2FD);
  static const Color productReplyBorder = Color(0xFFFF85A1);
  
  static Color getBubbleColor(bool isMine) {
    return isMine ? myBubbleColor : otherBubbleColor;
  }
  
  static Color getTextColor(bool isMine) {
    return isMine ? Colors.white : Colors.black87;
  }
}

/// 📊 CHAT STATISTICS (untuk analytics)
class ChatStats {
  final int totalMessages;
  final int unreadMessages;
  final DateTime? lastActivity;
  final double responseTime; // Average response time in minutes

  ChatStats({
    required this.totalMessages,
    required this.unreadMessages,
    this.lastActivity,
    this.responseTime = 0,
  });
}