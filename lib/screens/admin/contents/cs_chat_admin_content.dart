// ============================================================================
// CS_CHAT_ADMIN_CONTENT.DART
// Customer Service Live Chat - sisi admin (web layout)
// Layout: Master-Detail (panel kiri = list room, panel kanan = chat aktif)
// Theme: matching KTM verification content (no flutter_screenutil, fixed px)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/models/chat_models.dart';
import 'package:intl/intl.dart';

// ✅ Helper untuk konversi ke WIB (UTC+7) secara eksplisit
// Ini memastikan waktu selalu tampil dalam zona Jakarta tanpa tergantung timezone device
DateTime _toWib(DateTime dt) {
  final utc = dt.toUtc();
  return utc.add(const Duration(hours: 7));
}

String _formatTimeWib(DateTime dt) {
  return DateFormat('HH:mm').format(_toWib(dt));
}

String _formatDateTimeWib(DateTime dt) {
  final wib = _toWib(dt);
  final now = _toWib(DateTime.now().toUtc());
  final today = DateTime(now.year, now.month, now.day);
  final msgDate = DateTime(wib.year, wib.month, wib.day);
  if (msgDate.isAtSameMomentAs(today)) {
    return DateFormat('HH:mm').format(wib);
  }
  return DateFormat('dd/MM').format(wib);
}

class CsChatAdminContent extends StatefulWidget {
  const CsChatAdminContent({super.key});

  @override
  State<CsChatAdminContent> createState() => _CsChatAdminContentState();
}

class _CsChatAdminContentState extends State<CsChatAdminContent> {
  // ✅ Tidak lagi pakai ChatService sendiri untuk messages - semua lewat provider
  // Provider punya _persistentChatService untuk rooms subscription
  // DAN sekarang juga handle message subscription secara global

  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  // ✅ FocusNode untuk panel chat kanan — digunakan agar ESC bisa ditangkap saat hover
  final _chatPanelFocusNode = FocusNode();

  // Local state
  ChatRoom? _selectedRoom;
  List<ChatMessage> _messages = [];

  bool _isLoadingMessages = false;
  bool _isSending = false;
  bool _hasInputText = false;

  // Getter admin user id dari provider
  String? get _adminUserId => context.read<AdminProvider>().csChatAdminUserId;
  String get _adminRole => 'admin';

  // ChatService untuk operasi (getMessages, sendMessage, markAsRead) - pakai persistent dari provider
  ChatService get _chatService => context.read<AdminProvider>().persistentChatService;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);

    // ✅ Intercept keyboard di input field:
    // - Enter          → kirim pesan
    // - Shift + Enter  → newline (paragraf baru)
    // - ESC            → close room
    _inputFocusNode.onKeyEvent = (node, event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;

      // ESC → close room
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _closeRoom();
        return KeyEventResult.handled;
      }

      // Enter tanpa Shift → kirim pesan
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        final isShift = HardwareKeyboard.instance.isShiftPressed;
        if (!isShift) {
          _sendMessage();
          return KeyEventResult.handled;
        }
        // Shift+Enter → biarkan Flutter insert newline secara default
        return KeyEventResult.ignored;
      }

      return KeyEventResult.ignored;
    };

    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    // ✅ Beri tahu provider bahwa tidak ada widget yang menerima callback sekarang
    // (subscription di provider TETAP jalan - hanya callback dihapus)
    if (mounted) {
      context.read<AdminProvider>().setActiveRoom(null);
    }
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _chatPanelFocusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final hasText = _inputController.text.trim().isNotEmpty;
    if (hasText != _hasInputText) setState(() => _hasInputText = hasText);
  }

  // ============================================================================
  // INITIALIZE
  // ============================================================================
  Future<void> _initialize() async {
    if (!mounted) return;

    final adminProvider = context.read<AdminProvider>();

    // Jika provider belum init CS Chat (misalnya pertama kali buka dari menu chat langsung)
    if (!adminProvider.csChatInitialized) {
      await adminProvider.startCsChatRealtime();
    }

    // ✅ Jika provider punya active room (user buka chat sebelumnya, pindah halaman, lalu balik)
    // restore messages dan re-register callback agar realtime kembali jalan ke widget ini
    if (adminProvider.activeRoomId != null) {
      final activeRoomId = adminProvider.activeRoomId!;
      final roomIdx = adminProvider.csChatRooms.indexWhere((r) => r.id == activeRoomId);
      if (roomIdx != -1) {
        final room = adminProvider.csChatRooms[roomIdx];
        setState(() {
          _selectedRoom = room;
          _messages = List.from(adminProvider.activeRoomMessages);
          _isLoadingMessages = false;
        });
        // Re-register callback
        adminProvider.setActiveRoom(activeRoomId, onNewMessage: _onNewMessage);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }

    if (mounted) setState(() {}); // Trigger rebuild untuk tampilkan data dari provider
  }

  Future<void> _loadRooms() async {
    // ✅ Delegate ke provider
    await context.read<AdminProvider>().refreshCsChatRooms();
  }

  // ============================================================================
  // SELECT ROOM → LOAD MESSAGES
  // ============================================================================
  Future<void> _selectRoom(ChatRoom room) async {
    if (_selectedRoom?.id == room.id) return;

    setState(() {
      _selectedRoom = room;
      _messages = [];
      _isLoadingMessages = true;
    });

    final adminUserId = _adminUserId;
    if (adminUserId == null) return;

    final adminProvider = context.read<AdminProvider>();

    // ✅ Set active room di provider DULU sebelum load messages
    // Ini agar pesan baru yang datang selama loading langsung masuk ke _messages
    adminProvider.setActiveRoom(room.id, onNewMessage: _onNewMessage);

    // Load messages dari DB
    final messages = await adminProvider.loadRoomMessages(room.id);
    await _chatService.markAsRead(room.id, adminUserId);

    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoadingMessages = false;
      });

      // Update room di provider dengan unread = 0
      final updatedRoom = room.copyWith(
        unreadCount: {...room.unreadCount, adminUserId: 0},
      );
      adminProvider.updateCsRoomLocally(updatedRoom);

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _onNewMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final adminUserId = _adminUserId;
    if (adminUserId != null && !message.isMine(adminUserId)) {
      // Tandai sudah dibaca di DB
      _chatService.markAsRead(_selectedRoom!.id, adminUserId);
      // ✅ Update provider agar badge sidebar = 0 (admin sedang baca room ini)
      if (_selectedRoom != null) {
        final updatedRoom = _selectedRoom!.copyWith(
          unreadCount: {..._selectedRoom!.unreadCount, adminUserId: 0},
        );
        context.read<AdminProvider>().updateCsRoomLocally(updatedRoom);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  // ============================================================================
  // SEND MESSAGE
  // ============================================================================
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    final adminUserId = _adminUserId;
    if (text.isEmpty || _isSending || _selectedRoom == null || adminUserId == null) return;

    setState(() => _isSending = true);
    _inputController.clear();
    _inputFocusNode.requestFocus();

    try {
      final sent = await _chatService.sendTextMessage(
        roomId: _selectedRoom!.id,
        senderId: adminUserId,
        senderRole: _adminRole,
        text: text,
      );

      if (sent != null && mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == sent.id)) {
            _messages.add(sent);
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        // ✅ Update lastMessage di room list provider agar sinkron
        final adminProvider = context.read<AdminProvider>();
        final roomIdx = adminProvider.csChatRooms.indexWhere((r) => r.id == _selectedRoom!.id);
        if (roomIdx != -1) {
          final updatedRoom = adminProvider.csChatRooms[roomIdx].copyWith(
            lastMessage: text,
            lastMessageAt: sent.createdAt,
          );
          adminProvider.updateCsRoomLocally(updatedRoom);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal kirim pesan: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteRoom(ChatRoom room) async {
    final adminUserId = _adminUserId;
    if (adminUserId == null) return;

    final adminProvider = context.read<AdminProvider>();
    final userId = room.getOtherParticipantId(adminUserId);
    final participant =
        userId != null ? adminProvider.csChatParticipants[userId] : null;
    final name = participant?.name ?? 'User';

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          // =========================
          // TITLE
          // =========================
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Hapus Percakapan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),

          // =========================
          // CONTENT
          // =========================
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menghapus percakapan berikut?',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Semua pesan dalam percakapan ini akan dihapus secara permanen.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // =========================
          // ACTIONS
          // =========================
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.delete_rounded, size: 14),
              label: const Text(
                'Hapus',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    await _chatService.deleteRoom(room.id);

    if (!mounted) return;

    if (adminProvider.activeRoomId == room.id) {
      adminProvider.setActiveRoom(null);
    }

    await adminProvider.refreshCsChatRooms();

    if (_selectedRoom?.id == room.id) {
      setState(() {
        _selectedRoom = null;
        _messages = [];
      });
    }
  }


  // ============================================================================
  // CLOSE ROOM (tombol X atau shortcut ESC)
  // ============================================================================
  void _closeRoom() {
    context.read<AdminProvider>().setActiveRoom(null);
    setState(() {
      _selectedRoom = null;
      _messages = [];
    });
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // ── Panel Kiri: Room List (320px) ──────────────────────────────
            SizedBox(
              width: 300,
              child: _buildRoomListPanel(),
            ),

            // ── Divider vertikal ──────────────────────────────────────────
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF3F4F6)),

            // ── Panel Kanan: Chat View ─────────────────────────────────────
            Expanded(
              child: _selectedRoom == null
                  ? _buildEmptyState()
                  : Focus(
                      // ✅ Focus widget lebih reliable di web daripada KeyboardListener
                      // autofocus: false agar tidak rebut fokus dari TextField input
                      focusNode: _chatPanelFocusNode,
                      autofocus: false,
                      canRequestFocus: true,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.escape) {
                          _closeRoom();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: MouseRegion(
                        // ✅ Saat mouse masuk panel kanan, request fokus agar ESC bisa ditangkap
                        onEnter: (_) => FocusScope.of(context).requestFocus(_chatPanelFocusNode),
                        child: _buildChatPanel(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // PANEL KIRI: ROOM LIST
  // ============================================================================
  Widget _buildRoomListPanel() {
    // ✅ Consumer agar rebuild otomatis saat provider update room list
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, _) {
        final csRooms = adminProvider.csChatRooms;
        final isLoading = !adminProvider.csChatInitialized;

        return Column(
          children: [
            // Header
            _buildListHeader(csRooms.length, isLoading),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // Room list
            Expanded(
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : csRooms.isEmpty
                      ? _buildNoConversations()
                      : RefreshIndicator(
                          onRefresh: _loadRooms,
                          child: ListView.builder(
                            itemCount: csRooms.length,
                            itemBuilder: (context, index) =>
                                _buildRoomTile(csRooms[index], adminProvider),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListHeader(int roomCount, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: Color(0xFF6366F1),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Service',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  isLoading ? 'Memuat...' : '$roomCount percakapan',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(ChatRoom room, AdminProvider adminProvider) {
    final adminUserId = _adminUserId ?? '';
    final userId = room.getOtherParticipantId(adminUserId);
    final participant = userId != null ? adminProvider.csChatParticipants[userId] : null;
    final name = participant?.name ?? 'User';
    final unread = room.getUnreadCount(adminUserId);
    final isSelected = _selectedRoom?.id == room.id;

    final lastTime = room.lastMessageAt ?? room.createdAt;
    final timeText = _formatDateTimeWib(lastTime);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectRoom(room),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6366F1).withOpacity(0.06)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
                backgroundImage: participant?.avatarUrl != null
                    ? NetworkImage(participant!.avatarUrl!)
                    : null,
                child: participant?.avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 10,
                            color: unread > 0
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.lastMessage ?? 'Belum ada pesan',
                            style: TextStyle(
                              fontSize: 11,
                              color: unread > 0
                                  ? const Color(0xFF374151)
                                  : const Color(0xFF9CA3AF),
                              fontWeight: unread > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (participant?.role != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _getRoleLabel(participant!.role),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getRoleColor(participant.role),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ✅ Tombol hapus (selalu terlihat di web, tidak perlu swipe)
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _deleteRoom(room),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                color: const Color(0xFF9CA3AF),
                hoverColor: const Color(0xFFEF4444).withOpacity(0.1),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                ),
                tooltip: 'Hapus percakapan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoConversations() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            'Belum ada percakapan',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'User akan muncul saat memulai\nlive chat dari aplikasi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PANEL KANAN: EMPTY STATE
  // ============================================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_outlined,
              size: 32,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih percakapan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Klik salah satu percakapan\ndi sebelah kiri untuk memulai',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PANEL KANAN: CHAT VIEW
  // ============================================================================
  Widget _buildChatPanel() {
    final adminProvider = context.read<AdminProvider>();
    final userId = _selectedRoom!.getOtherParticipantId(_adminUserId ?? '');
    final participant = userId != null ? adminProvider.csChatParticipants[userId] : null;
    final name = participant?.name ?? 'User';

    return Column(
      children: [
        // Chat header
        _buildChatHeader(name, participant),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),

        // Messages
        Expanded(
          child: _isLoadingMessages
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _messages.isEmpty
                  ? _buildNoChatMessages()
                  : _buildMessagesList(),
        ),

        // Input
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatHeader(String name, ParticipantInfo? participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ✅ Tombol X untuk close room (shortcut: ESC)
          IconButton(
            onPressed: _closeRoom,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: const Color(0xFF6B7280),
            hoverColor: const Color(0xFF6366F1).withOpacity(0.1),
            tooltip: 'Tutup percakapan (ESC)',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
            backgroundImage: participant?.avatarUrl != null
                ? NetworkImage(participant!.avatarUrl!)
                : null,
            child: participant?.avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                if (participant?.role != null)
                  Text(
                    _getRoleLabel(participant!.role),
                    style: TextStyle(
                      fontSize: 11,
                      color: _getRoleColor(participant.role),
                    ),
                  ),
              ],
            ),
          ),
          // Badge context
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.headset_mic, size: 12, color: Color(0xFF6366F1)),
                SizedBox(width: 4),
                Text(
                  'Live Chat CS',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ✅ Tombol hapus di header chat
          IconButton(
            onPressed: _selectedRoom != null ? () => _deleteRoom(_selectedRoom!) : null,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: const Color(0xFF9CA3AF),
            hoverColor: const Color(0xFFEF4444).withOpacity(0.1),
            tooltip: 'Hapus percakapan ini',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChatMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 36, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            'Belum ada pesan',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.isMine(_adminUserId ?? '');

        // Date separator
        bool showDate = index == 0;
        if (!showDate) {
          final prev = _messages[index - 1];
          final pd = DateTime(prev.createdAt.toLocal().year, prev.createdAt.toLocal().month, prev.createdAt.toLocal().day);
          final cd = DateTime(message.createdAt.toLocal().year, message.createdAt.toLocal().month, message.createdAt.toLocal().day);
          showDate = !pd.isAtSameMomentAs(cd);
        }

        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.createdAt),
            _buildWebMessageBubble(message, isMine),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDate.isAtSameMomentAs(today)) {
      label = 'Hari ini';
    } else if (msgDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      label = 'Kemarin';
    } else {
      label = DateFormat('dd MMM yyyy').format(date.toLocal());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Widget _buildWebMessageBubble(ChatMessage message, bool isMine) {
    const myColor = Color(0xFF6366F1);
    const otherColor = Color(0xFFF3F4F6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar user (bukan admin)
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
              child: Text(
                message.senderRole.isNotEmpty
                    ? message.senderRole[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.38,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMine ? myColor : otherColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 3),
                  bottomRight: Radius.circular(isMine ? 3 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  SelectableText(
                    message.textContent ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isMine ? Colors.white : const Color(0xFF111827),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Time + status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimeWib(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMine
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(message.status, isMine),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Avatar admin
          if (isMine) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
              child: const Icon(
                Icons.support_agent,
                size: 14,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status, bool isMine) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sending:
        icon = Icons.schedule;
        color = Colors.white.withOpacity(0.5);
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = const Color(0xFF93C5FD);
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = const Color(0xFFFCA5A5);
        break;
    }

    return Icon(icon, size: 12, color: color);
  }

  // ============================================================================
  // CHAT INPUT
  // ============================================================================
  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // TextField
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Theme(
                data: ThemeData(
                  brightness: Brightness.light,
                  inputDecorationTheme: const InputDecorationTheme(
                    fillColor: Color(0xFFF9FAFB),
                    filled: true,
                  ),
                ),
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  maxLines: null,
                  cursorColor: const Color(0xFF6366F1),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF111827),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ketik balasan...',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Color(0xFFF9FAFB),
                    filled: true,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                  onSubmitted: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          Material(
            color: _hasInputText && !_isSending
                ? const Color(0xFF6366F1)
                : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _hasInputText && !_isSending ? _sendMessage : null,
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 40,
                height: 40,
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: _hasInputText
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================
  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return 'Customer';
      case 'driver':
        return 'Driver';
      case 'umkm':
        return 'UMKM';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return const Color(0xFF3B82F6);
      case 'driver':
        return const Color(0xFF10B981);
      case 'umkm':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }
}