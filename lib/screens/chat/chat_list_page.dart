// ============================================================================
// CHAT LIST PAGE - COMPLETE WITH ALL FIXES
// ✅ Auto-hide temporary chats (customer-driver, umkm-driver)
// ✅ Keep permanent chats (customer-umkm)
// ✅ Swipe to delete
// ✅ Realtime order status updates
// ✅ FIXED: PostgresChangeEvent error
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/models/chat_models.dart';
import 'chat_room_page.dart';
import 'package:intl/intl.dart';

// ✅ WIB (UTC+7) timezone helper
DateTime _toWib(DateTime dt) => dt.toUtc().add(const Duration(hours: 7));

class ChatListPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const ChatListPage({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _chatService = ChatService();
  
  List<ChatRoom> _rooms = [];
  Map<String, ParticipantInfo> _participantsCache = {};
  Map<String, OrderStatusCache> _orderStatusCache = {};  // ✅ Cache dengan expire time
  bool _isLoading = true;
  
  // ✅ Realtime subscriptions
  RealtimeChannel? _orderStatusSubscription;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    
    // Subscribe to room updates
    _chatService.subscribeToRoomUpdates(widget.currentUserId, _onRoomUpdate);
    
    // ✅ Subscribe to order status changes
    _subscribeToOrderUpdates();
  }

  // ✅ SUBSCRIBE TO ORDER STATUS UPDATES
  void _subscribeToOrderUpdates() {
    if (_orderStatusSubscription != null) {
      _chatService.getSupabase().removeChannel(_orderStatusSubscription!);
      _orderStatusSubscription = null;
    }

    final channelName = 'order-status-${DateTime.now().millisecondsSinceEpoch}';
    _orderStatusSubscription = _chatService.getSupabase()
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'pesanan',
          callback: (payload) {
            final newStatus = payload.newRecord['status_pesanan'];
            if (newStatus == 'selesai' || newStatus == 'dibatalkan') {
              print('📊 Order status changed to: $newStatus, refreshing chat list...');
              _loadRooms();
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('✅ Order status channel CONFIRMED: $channelName');
          } else if (status == RealtimeSubscribeStatus.channelError) {
            print('❌ Order status channel error: $error');
          }
        });
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    
    // Get all rooms
    final allRooms = await _chatService.getUserChatRooms(widget.currentUserId);
    
    // ✅ FILTER: Hide temporary chats from completed orders
    final activeRooms = <ChatRoom>[];
    
    for (var room in allRooms) {
      // Customer-UMKM chat = PERMANENT (always show)
      if (room.context == ChatContext.customerUmkm) {
        activeRooms.add(room);
        continue;
      }
      
      // Customer-Driver & UMKM-Driver = TEMPORARY (check order status)
      if (room.orderId != null) {
        final orderStatus = await _checkOrderStatus(room.orderId!);
        
        // Only show if order is still active
        if (orderStatus != 'selesai' && orderStatus != 'dibatalkan') {
          activeRooms.add(room);
        } else {
          print('🗑️ Hiding completed order chat: ${room.orderId}');
        }
      } else {
        // Room without order (shouldn't happen, but include anyway)
        activeRooms.add(room);
      }
    }
    
    _rooms = activeRooms;
    
    // Load participants info
    final allParticipantIds = _rooms
        .expand((room) => room.participantIds)
        .where((id) => id != widget.currentUserId)
        .toSet()
        .toList();
    
    if (allParticipantIds.isNotEmpty) {
      final participants = await _chatService.getParticipantsInfo(allParticipantIds);
      _participantsCache = {
        for (var p in participants) p.userId: p,
      };
    }
    
    setState(() => _isLoading = false);
  }

  // ✅ CHECK ORDER STATUS (with cache & expire time)
  Future<String?> _checkOrderStatus(String orderId) async {
    // Check cache first
    if (_orderStatusCache.containsKey(orderId)) {
      final cached = _orderStatusCache[orderId]!;
      
      // Cache valid for 5 minutes
      if (DateTime.now().difference(cached.cachedAt).inMinutes < 5) {
        return cached.status;
      }
    }
    
    // Query database
    try {
      final result = await _chatService.getSupabase()
          .from('pesanan')
          .select('status_pesanan')
          .eq('id_pesanan', orderId)
          .single();
      
      final status = result['status_pesanan'] as String?;
      
      // Update cache
      _orderStatusCache[orderId] = OrderStatusCache(
        status: status,
        cachedAt: DateTime.now(),
      );
      
      return status;
    } catch (e) {
      print('❌ Error checking order status: $e');
      return null;
    }
  }

  void _onRoomUpdate(ChatRoom room) {
    if (mounted) {
      setState(() {
        final index = _rooms.indexWhere((r) => r.id == room.id);
        if (index != -1) {
          _rooms[index] = room;
          // Re-sort by last message
          _rooms.sort((a, b) {
            final aTime = a.lastMessageAt ?? a.createdAt;
            final bTime = b.lastMessageAt ?? b.createdAt;
            return bTime.compareTo(aTime);
          });
        }
      });
    }
  }

  void _openChatRoom(ChatRoom room) async {
    // ✅ Reset unread badge lokal SEBELUM masuk room agar badge langsung hilang
    final idx = _rooms.indexWhere((r) => r.id == room.id);
    if (idx != -1 && _rooms[idx].getUnreadCount(widget.currentUserId) > 0) {
      setState(() {
        _rooms[idx] = _rooms[idx].copyWith(
          unreadCount: {..._rooms[idx].unreadCount, widget.currentUserId: 0},
        );
      });
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          roomId: room.id,
          room: room,
          currentUserId: widget.currentUserId,
          currentUserRole: widget.currentUserRole,
        ),
      ),
    );
    
    // ✅ Resubscribe room updates setelah kembali (channel mati saat di room page)
    if (mounted) {
      _chatService.subscribeToRoomUpdates(widget.currentUserId, _onRoomUpdate);
      _loadRooms();
    }
  }

  @override
  void dispose() {
    if (_orderStatusSubscription != null) {
      _chatService.getSupabase().removeChannel(_orderStatusSubscription!);
      _orderStatusSubscription = null;
    }
    _chatService.unsubscribeRooms(); // ✅ hanya room channel, tidak bunuh messages channel
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFF85A1),
        title: const Text(
          'Pesan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Total unread badge
          StreamBuilder<int>(
            stream: _getUnreadCountStream(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox();
              
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: const Color(0xFFFF85A1),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? _buildEmptyState()
              : _buildChatList(),
    );
  }

  Widget _buildChatList() {
    return RefreshIndicator(
      onRefresh: _loadRooms,
      child: ListView.separated(
        itemCount: _rooms.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 80.w,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final room = _rooms[index];
          final otherUserId = room.getOtherParticipantId(widget.currentUserId);
          final participant = _participantsCache[otherUserId];
          final unreadCount = room.getUnreadCount(widget.currentUserId);
          
          return _buildChatTile(room, participant, unreadCount);
        },
      ),
    );
  }

  // ✅ CHAT TILE WITH SWIPE TO DELETE
  Widget _buildChatTile(ChatRoom room, ParticipantInfo? participant, int unreadCount) {
    final lastMessageTime = room.lastMessageAt;
    final timeText = lastMessageTime != null
        ? _formatTime(lastMessageTime)
        : '';
    
    return Dismissible(
      key: Key(room.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete,
              color: Colors.white,
              size: 32.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                const Text('Hapus Chat'),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus chat dengan ${participant?.name ?? "pengguna ini"}? Semua pesan akan hilang.',
              style: TextStyle(fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        // Delete room
        try {
          await _chatService.deleteRoom(room.id);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat berhasil dihapus'),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          // Refresh list
          _loadRooms();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menghapus chat: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          
          // Restore item
          setState(() {});
        }
      },
      child: InkWell(
        onTap: () => _openChatRoom(room),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          color: unreadCount > 0 ? const Color(0xFFFFF5F7) : Colors.white,
          child: Row(
            children: [
              // Avatar with context badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: const Color(0xFFFF85A1).withOpacity(0.1),
                    backgroundImage: participant?.avatarUrl != null
                        ? NetworkImage(participant!.avatarUrl!)
                        : null,
                    child: participant?.avatarUrl == null
                        ? Text(
                            participant?.name[0].toUpperCase() ?? 'U',
                            style: TextStyle(
                              color: const Color(0xFFFF85A1),
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp,
                            ),
                          )
                        : null,
                  ),
                  
                  // Context badge (emoji)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _getContextEmoji(room.context),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(width: 12.w),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participant?.name ?? 'User',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: unreadCount > 0 
                                  ? FontWeight.w700 
                                  : FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        if (timeText.isNotEmpty)
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: unreadCount > 0 
                                  ? const Color(0xFFFF85A1) 
                                  : Colors.grey.shade600,
                              fontWeight: unreadCount > 0 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    // Last message & unread badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.lastMessage ?? 'Belum ada pesan',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: unreadCount > 0 
                                  ? Colors.black87 
                                  : Colors.grey.shade600,
                              fontWeight: unreadCount > 0 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        if (unreadCount > 0) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF85A1),
                                  Color(0xFFFF6B9D),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            constraints: BoxConstraints(minWidth: 20.w),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Activation status (jika chat belum aktif)
                    if (!room.isActive) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14.sp,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              room.activationReason ?? 'Chat belum aktif',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 100.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 24.h),
          Text(
            'Belum ada percakapan',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Pesan akan muncul di sini saat Anda\nmulai chat dengan ${_getRoleTarget()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final wibNow = _toWib(DateTime.now().toUtc());
    final wibTime = _toWib(time);
    final today = DateTime(wibNow.year, wibNow.month, wibNow.day);
    final messageDate = DateTime(wibTime.year, wibTime.month, wibTime.day);
    
    if (messageDate.isAtSameMomentAs(today)) {
      return DateFormat('HH:mm').format(wibTime);
    } else if (messageDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Kemarin';
    } else if (wibNow.difference(messageDate).inDays < 7) {
      return DateFormat('EEE', 'id').format(wibTime);
    } else {
      return DateFormat('dd/MM').format(wibTime);
    }
  }

  String _getContextEmoji(ChatContext context) {
    switch (context) {
      case ChatContext.customerDriver:
        return '🏍️';
      case ChatContext.customerUmkm:
        return '🛒';
      case ChatContext.umkmDriver:
        return '📦';
      case ChatContext.groupOrder:
        return '👥';
      case ChatContext.customerSupport:
        return '🎧';
    }
  }

  String _getRoleTarget() {
    switch (widget.currentUserRole.toLowerCase()) {
      case 'customer':
        return 'driver atau UMKM';
      case 'driver':
        return 'customer atau UMKM';
      case 'umkm':
        return 'customer atau driver';
      default:
        return 'pengguna lain';
    }
  }

  Stream<int> _getUnreadCountStream() async* {
    while (true) {
      final count = await _chatService.getTotalUnreadCount(widget.currentUserId);
      yield count;
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}

// ✅ ORDER STATUS CACHE CLASS
class OrderStatusCache {
  final String? status;
  final DateTime cachedAt;

  OrderStatusCache({
    required this.status,
    required this.cachedAt,
  });
}