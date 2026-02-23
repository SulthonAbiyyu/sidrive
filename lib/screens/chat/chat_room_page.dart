// ============================================================================
// UNIVERSAL CHAT ROOM PAGE
// Bisa digunakan untuk SEMUA konteks chat
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/models/chat_models.dart';
import 'package:sidrive/screens/chat/widgets/message_bubble.dart';
import 'package:sidrive/screens/chat/widgets/chat_input.dart';
import 'package:sidrive/screens/chat/widgets/product_reply_card.dart';
import 'package:sidrive/screens/chat/widgets/chat_activation_banner.dart';


// ✅ WIB (UTC+7) timezone helper - eksplisit tanpa tergantung timezone device
DateTime _toWib(DateTime dt) => dt.toUtc().add(const Duration(hours: 7));

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final ChatRoom? room;
  final String currentUserId;
  final String currentUserRole;
  
  // Optional: Auto-send product reply saat masuk
  final Map<String, dynamic>? productData;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    this.room,
    required this.currentUserId,
    required this.currentUserRole,
    this.productData,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _chatService = ChatService();
  final _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  ChatRoom? _room;
  ParticipantInfo? _otherParticipant;
  bool _isLoading = true;
  bool _isSending = false;
  Map<String, dynamic>? _activationStatus;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadRoom();
    await _loadMessages();
    await _loadParticipant();
    await _checkActivation();
    
    // Mark as read
    await _chatService.markAsRead(widget.roomId, widget.currentUserId);
    
    // Subscribe to real-time messages
    _chatService.subscribeToMessages(widget.roomId, _onNewMessage);
    
    // Auto-send product reply jika ada
    if (widget.productData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendProductReply();
      });
    }
    
    setState(() => _isLoading = false);

    // ✅ Scroll ke pesan terbaru (bawah) setelah widget selesai render
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _loadRoom() async {
    if (widget.room != null) {
      _room = widget.room;
    } else {
      // Load room from database
      final rooms = await _chatService.getUserChatRooms(widget.currentUserId);
      // ✅ FIXED: tambah orElse agar tidak crash jika room tidak ditemukan
      final found = rooms.where((r) => r.id == widget.roomId);
      _room = found.isNotEmpty ? found.first : null;
    }
  }

  Future<void> _loadMessages() async {
    _messages = await _chatService.getMessages(widget.roomId);
  }

  Future<void> _loadParticipant() async {
    if (_room == null) return;
    
    final otherUserId = _room!.getOtherParticipantId(widget.currentUserId);
    if (otherUserId == null || otherUserId.isEmpty) return;
    
    final participants = await _chatService.getParticipantsInfo([otherUserId]);
    if (participants.isNotEmpty) {
      _otherParticipant = participants.first;
    }
  }

  Future<void> _checkActivation() async {
    if (_room?.context != ChatContext.customerDriver) {
      _activationStatus = {'isActive': true};
      return;
    }
    
    _activationStatus = await _chatService.updateRoomActivation(widget.roomId);
  }

  void _onNewMessage(ChatMessage message) {
    if (mounted) {
      setState(() {
        // ✅ FIX REALTIME: Dedup - jangan tambah jika sudah ada (dari send langsung)
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
        }
      });

      _scrollToBottom();

      if (!message.isMine(widget.currentUserId)) {
        _chatService.markAsRead(widget.roomId, widget.currentUserId);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;

    if (_activationStatus?['isActive'] == false) {
      _showActivationError();
      return;
    }

    setState(() => _isSending = true);

    try {
      final sent = await _chatService.sendTextMessage(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        senderRole: widget.currentUserRole,
        text: text.trim(),
      );

      // ✅ FIX REALTIME: Langsung tambah ke UI dari return value, tidak tunggu realtime
      if (sent != null && mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == sent.id)) {
            _messages.add(sent);
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendProductReply() async {
    if (widget.productData == null || _isSending) return;
    
    setState(() => _isSending = true);
    
    try {
      await _chatService.sendProductReply(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        senderRole: widget.currentUserRole,
        productId: widget.productData!['id'],
        productName: widget.productData!['name'],
        productImage: widget.productData!['image'],
        productPrice: widget.productData!['price'],
      );
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showActivationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_activationStatus?['reason'] ?? 'Chat belum aktif'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _chatService.unsubscribeMessages(); // ✅ hanya messages channel, tidak bunuh rooms channel
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Activation banner (jika chat belum aktif)
          if (_activationStatus?['isActive'] == false)
            ChatActivationBanner(
              reason: _activationStatus?['reason'] ?? '',
              progress: _activationStatus?['driverProgress'] ?? 0.0,
            ),
          
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),
          
          // Input area
          ChatInput(
            onSend: _sendMessage,
            enabled: _activationStatus?['isActive'] != false && !_isSending,
            context: _room?.context ?? ChatContext.customerDriver,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFFF85A1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20.r,
            backgroundColor: Colors.white,
            backgroundImage: _otherParticipant?.avatarUrl != null
                ? NetworkImage(_otherParticipant!.avatarUrl!)
                : null,
            child: _otherParticipant?.avatarUrl == null
                ? Text(
                    _otherParticipant?.name[0].toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: const Color(0xFFFF85A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          
          // Name & role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherParticipant?.name ?? 'User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getRoleName(_otherParticipant?.role ?? ''),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Context indicator
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _getContextIcon(),
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.isMine(widget.currentUserId);
        
        // Show date separator if needed
        bool showDate = false;
        if (index == 0) {
          showDate = true;
        } else {
          final prevMessage = _messages[index - 1];
          final prevWib = _toWib(prevMessage.createdAt);
          final currWib = _toWib(message.createdAt);
          final prevDate = DateTime(prevWib.year, prevWib.month, prevWib.day);
          final currentDate = DateTime(currWib.year, currWib.month, currWib.day);
          showDate = !prevDate.isAtSameMomentAs(currentDate);
        }
        
        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.createdAt),
            
            // Message bubble
            if (message.type == MessageType.productReply)
              ProductReplyCard(
                message: message,
                isMine: isMine,
              )
            else
              MessageBubble(
                message: message,
                isMine: isMine,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final wibNow = _toWib(DateTime.now().toUtc());
    final wibDate = _toWib(date);
    final today = DateTime(wibNow.year, wibNow.month, wibNow.day);
    final messageDate = DateTime(wibDate.year, wibDate.month, wibDate.day);
    
    String dateText;
    if (messageDate.isAtSameMomentAs(today)) {
      dateText = 'Hari ini';
    } else if (messageDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dateText = 'Kemarin';
    } else {
      dateText = '${wibDate.day}/${wibDate.month}/${wibDate.year}';
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
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
            size: 80.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            'Belum ada pesan',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Mulai percakapan dengan mengirim pesan',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return 'Pelanggan';
      case 'driver':
        return 'Driver';
      case 'umkm':
        return 'UMKM';
      default:
        return role;
    }
  }

  String _getContextIcon() {
    switch (_room?.context) {
      case ChatContext.customerDriver:
        return '🏍️';
      case ChatContext.customerUmkm:
        return '🛍️';
      case ChatContext.umkmDriver:
        return '📦';
      case ChatContext.groupOrder:
        return '👥';
      case ChatContext.customerSupport:
        return '🎧';
      default:
        return '💬';  
    }
  }
}