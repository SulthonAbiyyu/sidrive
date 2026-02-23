// ============================================================================
// ADMIN PROVIDER - IMPROVED VERSION
// Added better error handling and loading states
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:sidrive/services/admin_service.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/services/customer_support_service.dart';
import 'package:sidrive/models/chat_models.dart';
import 'package:sidrive/models/cash_settlement_model.dart';
import 'package:sidrive/models/financial_tracking_model.dart';
import 'package:sidrive/models/ktm_verification_model.dart';
import 'package:sidrive/models/saved_bank_account_model.dart';


class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();

  // ===========================================================================
  // PERSISTENT CHAT SERVICE (singleton di provider level - tidak mati saat pindah halaman)
  // ===========================================================================
  final ChatService _persistentChatService = ChatService();

  // CS Chat rooms di-maintain di provider agar realtime aktif di semua halaman
  List<ChatRoom> _csChatRooms = [];
  Map<String, ParticipantInfo> _csChatParticipants = {};
  String? _csChatAdminUserId;
  bool _csChatInitialized = false;

  // ✅ GLOBAL MESSAGE SUBSCRIPTION - aktif di semua halaman, bukan hanya saat buka chat
  // Menyimpan messages dari room yang sedang aktif agar realtime jalan walaupun
  // user sedang di halaman lain (karena widget dispose → subscription mati)
  String? _activeRoomId;
  List<ChatMessage> _activeRoomMessages = [];
  Function(ChatMessage)? _activeRoomMessageCallback;

  // Getter untuk CsChatAdminContent
  List<ChatRoom> get csChatRooms => _csChatRooms;
  Map<String, ParticipantInfo> get csChatParticipants => _csChatParticipants;
  String? get csChatAdminUserId => _csChatAdminUserId;
  bool get csChatInitialized => _csChatInitialized;
  ChatService get persistentChatService => _persistentChatService;

  // Getter active room messages
  String? get activeRoomId => _activeRoomId;
  List<ChatMessage> get activeRoomMessages => List.unmodifiable(_activeRoomMessages);

  /// Set active room untuk persistent message subscription
  void setActiveRoom(String? roomId, {Function(ChatMessage)? onNewMessage}) {
    if (_activeRoomId == roomId) {
      // Hanya update callback jika room sama
      _activeRoomMessageCallback = onNewMessage;
      return;
    }
    _activeRoomId = roomId;
    _activeRoomMessageCallback = onNewMessage;
    if (roomId == null) {
      _activeRoomMessages = [];
    }
    // Polling akan otomatis push message baru ke callback setiap 4 detik
    debugPrint('✅ [CS Provider] Active room set: $roomId');
  }

  /// Load messages untuk room (dipanggil dari widget saat select room)
  Future<List<ChatMessage>> loadRoomMessages(String roomId) async {
    final messages = await _persistentChatService.getMessages(roomId);
    _activeRoomMessages = messages;
    return messages;
  }

  // ===========================================================================
  // REALTIME SUBSCRIPTIONS
  // ===========================================================================
  final List<RealtimeChannel> _realtimeChannels = [];

  // State variables
  AdminModel? _currentAdmin;
  bool _isLoading = false;
  String? _errorMessage;

  // Dashboard data
  DashboardSummary? _dashboardSummary;
  List<DriverVerification> _pendingDrivers = [];
  List<UmkmVerification> _pendingUmkm = [];
  List<PenarikanSaldo> _pendingPenarikan = [];

  // Loading states untuk tiap bagian
  bool _isLoadingDrivers = false;
  bool _isLoadingUmkm = false;
  bool _isLoadingPenarikan = false;

  // Getters
  AdminModel? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardSummary? get dashboardSummary => _dashboardSummary;
  List<DriverVerification> get pendingDrivers => _pendingDrivers;
  List<UmkmVerification> get pendingUmkm => _pendingUmkm;
  List<PenarikanSaldo> get pendingPenarikan => _pendingPenarikan;
  
  bool get isLoadingDrivers => _isLoadingDrivers;
  bool get isLoadingUmkm => _isLoadingUmkm;
  bool get isLoadingPenarikan => _isLoadingPenarikan;

  bool get isAdminLoggedIn => _currentAdmin != null;

  // ============================================================================
  // CASH SETTLEMENT STATE
  // ============================================================================
  List<CashSettlementModel> _pendingSettlements = [];
  AdminWalletStats? _walletStats;
  bool _isLoadingSettlements = false;

  List<CashSettlementModel> get pendingSettlements => _pendingSettlements;
  AdminWalletStats? get walletStats => _walletStats;
  bool get isLoadingSettlements => _isLoadingSettlements;

  // ══════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION
  // ══════════════════════════════════════════════════════════════════════════

  /// Initialize - check if admin already logged in
  Future<void> init() async {
    try {
      _currentAdmin = await _adminService.getCurrentAdmin();
      notifyListeners();
    } catch (e) {
      print('Error init admin: $e');
    }
  }

  /// Admin login with username & password (Database Auth)
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔄 Provider: Calling adminLogin...');

      final admin = await _adminService.adminLogin(
        username: username,
        password: password,
      );

      print('✅ Provider: Login success, saving admin...');
      _currentAdmin = admin;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Provider: Login failed - $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Logout admin
  Future<void> logoutAdmin() async {
    try {
      await _adminService.logoutAdmin();
      clearData();
    } catch (e) {
      print('Error logout: $e');
      clearData();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════

  /// Load dashboard summary
  Future<void> loadDashboardSummary() async {
    try {
      _setLoading(true);
      _dashboardSummary = await _adminService.getDashboardSummary();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error loading dashboard: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Refresh all dashboard data
  /// Refresh semua badge sidebar sekaligus (dipanggil saat pertama load)
  Future<void> refreshDashboard() async {
    await Future.wait([
      loadDashboardSummary(),
      loadPendingDrivers(),
      loadPendingUmkm(),
      loadPendingPenarikan(),
      loadPendingRefundCount(),
      loadPendingSettlements(),
      loadPendingKtmVerifications(),
    ]);
  }

  // ===========================================================================
  // REALTIME - AUTO UPDATE SEMUA BADGE SIDEBAR
  // ===========================================================================

  /// Subscribe realtime ke semua tabel yang mempengaruhi badge sidebar.
  /// Panggil sekali setelah login berhasil.
  void startRealtimeBadges() {
    stopRealtimeBadges(); // hindari double subscribe

    final client = Supabase.instance.client;

    // Helper: buat channel untuk 1 tabel
    void _subscribe(String channelName, String table, VoidCallback onEvent) {
      final channel = client
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (_) {
              debugPrint('🔴 Realtime [$table] changed');
              onEvent();
            },
          )
          .subscribe();
      _realtimeChannels.add(channel);
    }

    // Badge Refund → tabel pesanan
    _subscribe('rt-pesanan', 'pesanan', loadPendingRefundCount);

    // Badge Driver → tabel driver_vehicles
    _subscribe('rt-driver-vehicles', 'driver_vehicles', loadPendingDrivers);

    // Badge UMKM → tabel umkm
    _subscribe('rt-umkm', 'umkm', loadPendingUmkm);

    // Badge Penarikan → tabel withdrawal_requests
    _subscribe('rt-withdrawal', 'withdrawal_requests', loadPendingPenarikan);

    // Badge Settlement → tabel cash_settlements
    _subscribe('rt-settlement', 'cash_settlements', loadPendingSettlements);

    // Badge KTM → tabel ktm_verification_requests
    _subscribe('rt-ktm', 'ktm_verification_requests', loadPendingKtmVerifications);

    debugPrint('✅ Realtime: ${_realtimeChannels.length} badge subscriptions aktif');
  }

  // ===========================================================================
  // CS CHAT REALTIME - PERSISTENT (hidup di semua halaman, tidak mati saat pindah menu)
  // ===========================================================================

  /// Init CS Chat realtime subscription di level provider.
  Future<void> startCsChatRealtime() async {
    if (_csChatInitialized) return;

    debugPrint('🔴 [CS Realtime] Starting persistent CS chat realtime...');

    // 1. Dapatkan admin user ID
    final csService = CustomerSupportService();
    _csChatAdminUserId = await csService.getAdminUserId();
    if (_csChatAdminUserId == null) {
      debugPrint('❌ [CS Realtime] Tidak bisa dapatkan admin user ID');
      return;
    }

    // 2. Load initial rooms
    await _loadCsChatRooms();

    // 3. Subscribe ke chat_rooms UPDATE - lebih reliable dari chat_messages INSERT
    //    karena RPC update_room_last_message pasti trigger UPDATE di chat_rooms
    _persistentChatService.subscribeToRoomUpdates(
      _csChatAdminUserId!,
      _onCsRoomUpdate,
    );

    // 4. Mulai polling fallback setiap 4 detik untuk jaga-jaga realtime mati
    _startPolling();

    _csChatInitialized = true;
    debugPrint('✅ [CS Realtime] Persistent CS chat realtime aktif');
  }

  // ── POLLING FALLBACK ──────────────────────────────────────────────────────
  Timer? _pollingTimer;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_csChatAdminUserId == null) return;
      await _pollCsRooms();
      if (_activeRoomId != null) {
        await _pollActiveRoomMessages();
      }
    });
    debugPrint('✅ [CS Polling] Started polling every 4s');
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Poll rooms dari DB dan bandingkan dengan state lokal
  Future<void> _pollCsRooms() async {
    try {
      final freshRooms = await _persistentChatService.getCustomerSupportRooms();
      if (freshRooms.isEmpty) return;

      bool changed = false;

      for (final fresh in freshRooms) {
        final idx = _csChatRooms.indexWhere((r) => r.id == fresh.id);
        if (idx == -1) {
          // Room baru
          _csChatRooms.insert(0, fresh);
          _loadMissingCsParticipant(fresh);
          changed = true;
        } else {
          final existing = _csChatRooms[idx];
          final freshUnread = fresh.getUnreadCount(_csChatAdminUserId!);
          final existingUnread = existing.getUnreadCount(_csChatAdminUserId!);

          if (fresh.lastMessage != existing.lastMessage ||
              freshUnread != existingUnread ||
              fresh.lastMessageAt != existing.lastMessageAt) {
            // ✅ Jika room ini sedang aktif dibaca (activeRoomId == room.id),
            // pertahankan unreadCount lokal (0) agar badge tidak balik naik dari polling DB.
            // DB mungkin belum sinkron setelah markAsRead dipanggil.
            if (_activeRoomId == fresh.id && existingUnread == 0 && freshUnread > 0) {
              // Update lastMessage/lastMessageAt tapi JANGAN ubah unreadCount
              _csChatRooms[idx] = fresh.copyWith(
                unreadCount: existing.unreadCount, // pertahankan unread lokal = 0
              );
            } else {
              _csChatRooms[idx] = fresh;
            }
            changed = true;
          }
        }
      }

      if (changed) {
        _csChatRooms.sort((a, b) {
          final aTime = a.lastMessageAt ?? a.createdAt;
          final bTime = b.lastMessageAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
        _recalcCsChatBadge();
        notifyListeners();
        debugPrint('🔄 [CS Polling] Rooms updated, badge: $_csChatUnreadCount');
      }
    } catch (e) {
      debugPrint('❌ [CS Polling] Error polling rooms: $e');
    }
  }

  /// Poll messages untuk active room dan push ke widget jika ada yang baru
  Future<void> _pollActiveRoomMessages() async {
    if (_activeRoomId == null) return;
    try {
      final freshMessages = await _persistentChatService.getMessages(_activeRoomId!);
      if (freshMessages.isEmpty) return;

      // Cari message yang belum ada di _activeRoomMessages
      for (final msg in freshMessages) {
        if (!_activeRoomMessages.any((m) => m.id == msg.id)) {
          _activeRoomMessages.add(msg);
          _activeRoomMessageCallback?.call(msg);
          debugPrint('🔄 [CS Polling] New message pushed: ${msg.id}');
        }
      }
    } catch (e) {
      debugPrint('❌ [CS Polling] Error polling messages: $e');
    }
  }

  /// Load semua CS rooms dan participant info
  Future<void> _loadCsChatRooms() async {
    try {
      final rooms = await _persistentChatService.getCustomerSupportRooms();

      final userIds = rooms
          .map((r) => r.getOtherParticipantId(_csChatAdminUserId!) ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (userIds.isNotEmpty) {
        final participants = await _persistentChatService.getParticipantsInfo(userIds);
        _csChatParticipants = {for (var p in participants) p.userId: p};
      }

      _csChatRooms = rooms;
      _recalcCsChatBadge();
      notifyListeners();
      debugPrint('✅ [CS Realtime] Loaded ${rooms.length} CS rooms');
    } catch (e) {
      debugPrint('❌ [CS Realtime] Error loading CS rooms: $e');
    }
  }

  /// Callback saat ada room INSERT atau UPDATE dari Supabase realtime (backup dari polling)
  void _onCsRoomUpdate(ChatRoom room) {
    if (room.context != ChatContext.customerSupport) return;

    final idx = _csChatRooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      _csChatRooms[idx] = room;
    } else {
      // Room baru → tambahkan ke list
      _csChatRooms.insert(0, room);
      // Load participant info untuk room baru
      _loadMissingCsParticipant(room);
    }

    // Sort: terbaru di atas
    _csChatRooms.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    _recalcCsChatBadge();
    notifyListeners();
  }

  Future<void> _loadMissingCsParticipant(ChatRoom room) async {
    if (_csChatAdminUserId == null) return;
    final userId = room.getOtherParticipantId(_csChatAdminUserId!);
    if (userId == null || userId.isEmpty) return;
    if (_csChatParticipants.containsKey(userId)) return;

    final participants = await _persistentChatService.getParticipantsInfo([userId]);
    if (participants.isNotEmpty) {
      _csChatParticipants[userId] = participants.first;
      notifyListeners();
    }
  }

  /// Hitung ulang badge CS chat dari data rooms yang ada di provider
  void _recalcCsChatBadge() {
    if (_csChatAdminUserId == null) return;
    final total = _csChatRooms.fold<int>(
      0, (sum, r) => sum + r.getUnreadCount(_csChatAdminUserId!),
    );
    if (_csChatUnreadCount != total) {
      _csChatUnreadCount = total;
      // notifyListeners() dipanggil oleh caller
    }
  }

  /// Refresh manual CS rooms (untuk pull-to-refresh di CsChatAdminContent)
  Future<void> refreshCsChatRooms() async {
    await _loadCsChatRooms();
  }

  /// Update room di list provider (dipanggil dari CsChatAdminContent setelah markAsRead)
  void updateCsRoomLocally(ChatRoom room) {
    final idx = _csChatRooms.indexWhere((r) => r.id == room.id);
    if (idx != -1) {
      _csChatRooms[idx] = room;
      _recalcCsChatBadge();
      notifyListeners();
    }
  }

  /// Stop CS chat realtime (saat logout)
  void stopCsChatRealtime() {
    _stopPolling();
    _persistentChatService.unsubscribeRooms();
    _csChatRooms = [];
    _csChatParticipants = {};
    _csChatAdminUserId = null;
    _csChatInitialized = false;
    _activeRoomId = null;
    _activeRoomMessages = [];
    _activeRoomMessageCallback = null;
    debugPrint('🔴 [CS Realtime] Stopped');
  }

  /// Unsubscribe semua channel (panggil saat logout)
  void stopRealtimeBadges() {
    if (_realtimeChannels.isEmpty) return;
    final client = Supabase.instance.client;
    for (final ch in _realtimeChannels) {
      client.removeChannel(ch);
    }
    _realtimeChannels.clear();
    debugPrint('🔴 Realtime: semua badge subscription dihentikan');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VERIFIKASI DRIVER - IMPROVED
  // ══════════════════════════════════════════════════════════════════════════

  /// Load pending drivers
  Future<void> loadPendingDrivers() async {
    try {
      _isLoadingDrivers = true;
      notifyListeners();
      
      print('🔄 Provider: Loading pending drivers...');
      _pendingDrivers = await _adminService.getPendingDrivers();
      print('✅ Provider: Loaded ${_pendingDrivers.length} pending drivers');
      
      _isLoadingDrivers = false;
      notifyListeners();
    } catch (e) {
      print('❌ Provider: Error loading pending drivers: $e');
      _isLoadingDrivers = false;
      _pendingDrivers = []; // Reset to empty
      notifyListeners();
      rethrow; // Pass error to UI
    }
  }

  /// Get driver detail
  Future<DriverVerification?> getDriverDetail(String idDriver) async {
    try {
      print('🔄 Provider: Getting driver detail for $idDriver');
      final driver = await _adminService.getDriverDetail(idDriver);
      print('✅ Provider: Got driver detail');
      return driver;
    } catch (e) {
      print('❌ Provider: Error loading driver detail: $e');
      _setError('Error loading driver detail: ${e.toString()}');
      return null;
    }
  }

  Future<bool> approveDriver(String idUser, String idDriver, String idVehicle) async { 
    try {
      _setLoading(true);
      _clearError();
      
      print('📋 Provider: Approving driver vehicle $idVehicle');
      print('   ID User: $idUser');
      print('   ID Driver: $idDriver');
      print('   ID Vehicle: $idVehicle');
      
      final success = await _adminService.approveDriver(idUser, idDriver, idVehicle);  
      
      if (success) {
        print('✅ Provider: Driver vehicle approved, reloading data...');
        
        // Remove from pending list
        _pendingDrivers.removeWhere((d) => d.idVehicle == idVehicle);  
        
        // Reload dashboard
        await loadDashboardSummary();
        
        _setLoading(false);
        notifyListeners();
        return true;
      }
      
      _setLoading(false);
      _setError('Gagal menyetujui kendaraan');
      return false;
      
    } catch (e) {
      print('❌ Provider: Error approving driver: $e');
      _setError('Error: ${e.toString().replaceAll('Exception: ', '')}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> rejectDriver(String idUser, String idDriver, String idVehicle, String alasan) async {  
    try {
      _setLoading(true);
      _clearError();
      
      print('📋 Provider: Rejecting driver vehicle $idVehicle');
      print('   ID User: $idUser');
      print('   ID Driver: $idDriver');
      print('   ID Vehicle: $idVehicle');
      print('   Reason: $alasan');
      
      final success = await _adminService.rejectDriver(idUser, idDriver, idVehicle, alasan); 
      
      if (success) {
        print('✅ Provider: Driver vehicle rejected, reloading data...');
        
        // Remove from pending list
        _pendingDrivers.removeWhere((d) => d.idVehicle == idVehicle);
        
        // Reload dashboard
        await loadDashboardSummary();
        
        _setLoading(false);
        notifyListeners();
        return true;
      }
      
      _setLoading(false);
      _setError('Gagal menolak kendaraan');
      return false;
      
    } catch (e) {
      print('❌ Provider: Error rejecting driver: $e');
      _setError('Error: ${e.toString().replaceAll('Exception: ', '')}');
      _setLoading(false);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VERIFIKASI UMKM - IMPROVED
  // ══════════════════════════════════════════════════════════════════════════

  /// Load pending UMKM
  Future<void> loadPendingUmkm() async {
    try {
      _isLoadingUmkm = true;
      notifyListeners();
      
      print('🔄 Provider: Loading pending UMKM...');
      _pendingUmkm = await _adminService.getPendingUmkm();
      print('✅ Provider: Loaded ${_pendingUmkm.length} pending UMKM');
      
      _isLoadingUmkm = false;
      notifyListeners();
    } catch (e) {
      print('❌ Provider: Error loading pending UMKM: $e');
      _isLoadingUmkm = false;
      _pendingUmkm = []; // Reset to empty
      notifyListeners();
      rethrow; // Pass error to UI
    }
  }

  /// Get UMKM detail
  Future<UmkmVerification?> getUmkmDetail(String idUmkm) async {
    try {
      print('🔄 Provider: Getting UMKM detail for $idUmkm');
      final umkm = await _adminService.getUmkmDetail(idUmkm);
      print('✅ Provider: Got UMKM detail');
      return umkm;
    } catch (e) {
      print('❌ Provider: Error loading UMKM detail: $e');
      _setError('Error loading UMKM detail: ${e.toString()}');
      return null;
    }
  }

  Future<bool> approveUmkm(String idUser, String idUmkm) async {
    debugPrint('🔍 [AdminProvider] Approving UMKM...');
    debugPrint('   ID User: $idUser');
    debugPrint('   ID UMKM: $idUmkm');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _adminService.approveUmkm(idUser, idUmkm);
      
      _isLoading = false;
      notifyListeners();
      
      debugPrint('✅ [AdminProvider] UMKM approved successfully');
      return success;
    } catch (e) {
      debugPrint('❌ [AdminProvider] Error approving UMKM: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectUmkm(String idUser, String idUmkm, String alasan) async {
    debugPrint('🔍 [AdminProvider] Rejecting UMKM...');
    debugPrint('   ID User: $idUser');
    debugPrint('   ID UMKM: $idUmkm');
    debugPrint('   Reason: $alasan');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _adminService.rejectUmkm(idUser, idUmkm, alasan);
      
      _isLoading = false;
      notifyListeners();
      
      debugPrint('✅ [AdminProvider] UMKM rejected successfully');
      return success;
    } catch (e) {
      debugPrint('❌ [AdminProvider] Error rejecting UMKM: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PENARIKAN SALDO - FIXED VERSION
  // ══════════════════════════════════════════════════════════════════════════

  /// Load pending penarikan
  Future<void> loadPendingPenarikan() async {
    try {
      _isLoadingPenarikan = true;
      notifyListeners();
      
      print('🔄 Provider: Loading pending penarikan...');
      _pendingPenarikan = await _adminService.getPendingPenarikan();
      print('✅ Provider: Loaded ${_pendingPenarikan.length} pending penarikan');
      
      _isLoadingPenarikan = false;
      notifyListeners();
    } catch (e) {
      print('❌ Provider: Error loading pending penarikan: $e');
      _isLoadingPenarikan = false;
      _pendingPenarikan = []; // Reset to empty
      notifyListeners();
    }
  }

  /// ✅ FIXED: Approve dengan bukti transfer
  Future<bool> approveWithdrawalWithProof({
    required String withdrawalId,
    required String proofUrl,
  }) async {
    try {
      _setLoading(true);
      
      // ✅ PAKAI idUser BUKAN idAdmin!
      final adminUserId = _currentAdmin?.idUser;
      if (adminUserId == null) {
        throw Exception('Admin User ID not found');
      }

      final success = await _adminService.approveWithdrawalWithProof(
        withdrawalId: withdrawalId,
        adminId: adminUserId, // ✅ INI YANG BENAR!
        proofUrl: proofUrl,
      );
      
      if (success) {
        _pendingPenarikan.removeWhere((p) => p.idPenarikan == withdrawalId);
        await loadDashboardSummary();
        _setLoading(false);
        notifyListeners();
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Error approving withdrawal: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> rejectWithdrawalWithRefund({
    required String withdrawalId,
    required String reason,
  }) async {
    try {
      _setLoading(true);
      
      // ✅ PAKAI idUser BUKAN idAdmin!
      final adminUserId = _currentAdmin?.idUser;
      if (adminUserId == null) {
        throw Exception('Admin User ID not found');
      }

      final success = await _adminService.rejectWithdrawalWithRefund(
        withdrawalId: withdrawalId,
        adminId: adminUserId, // ✅ INI YANG BENAR!
        reason: reason,
      );
      
      if (success) {
        _pendingPenarikan.removeWhere((p) => p.idPenarikan == withdrawalId);
        await loadDashboardSummary();
        _setLoading(false);
        notifyListeners();
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Error rejecting withdrawal: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }


  // ══════════════════════════════════════════════════════════════════════════
  // CRUD ADMIN - NEW SECTION
  // ══════════════════════════════════════════════════════════════════════════

  // Data state
  List<AdminModel> _adminList = [];
  bool _isLoadingAdmins = false;

  // Getters
  List<AdminModel> get adminList => _adminList;
  bool get isLoadingAdmins => _isLoadingAdmins;

  /// Load all admins
  Future<void> loadAdmins({
    String? searchQuery,
    String? filterLevel,
    String? filterStatus,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      _isLoadingAdmins = true;
      notifyListeners();
      
      debugPrint('📄 Provider: Loading admins...');
      _adminList = await _adminService.getAllAdmins(
        searchQuery: searchQuery,
        filterLevel: filterLevel,
        filterStatus: filterStatus,
        limit: limit,
        offset: offset,
      );
      debugPrint('✅ Provider: Loaded ${_adminList.length} admins');
      
      _isLoadingAdmins = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Provider: Error loading admins: $e');
      _isLoadingAdmins = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get total admins
  Future<int> getTotalAdmins({
    String? filterLevel,
    String? filterStatus,
  }) async {
    try {
      return await _adminService.getTotalAdmins(
        filterLevel: filterLevel,
        filterStatus: filterStatus,
      );
    } catch (e) {
      debugPrint('❌ Provider: Error getting total admins: $e');
      return 0;
    }
  }

  /// Create admin
  Future<bool> createAdmin({
    required String email,
    required String password,
    required String username,
    required String nama,
    required String level,
  }) async {
    try {
      _setLoading(true);
      
      debugPrint('📝 Provider: Creating admin...');
      await _adminService.createAdmin(
        email: email,
        password: password,
        username: username,
        nama: nama,
        level: level,
      );
      
      debugPrint('✅ Provider: Admin created successfully');
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Provider: Error creating admin: $e');
      _setError('Error creating admin: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update admin
  Future<bool> updateAdmin({
    required String idAdmin,
    required String nama,
    required String level,
    required bool isActive,
    String? newPassword,
  }) async {
    try {
      _setLoading(true);
      
      debugPrint('✏️ Provider: Updating admin...');
      await _adminService.updateAdmin(
        idAdmin: idAdmin,
        nama: nama,
        level: level,
        isActive: isActive,
        newPassword: newPassword,
      );
      
      debugPrint('✅ Provider: Admin updated successfully');
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Provider: Error updating admin: $e');
      _setError('Error updating admin: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete admin
  Future<bool> deleteAdmin(String idAdmin) async {
    try {
      _setLoading(true);
      
      debugPrint('🗑️ Provider: Deleting admin...');
      await _adminService.deleteAdmin(idAdmin);
      
      debugPrint('✅ Provider: Admin deleted successfully');
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Provider: Error deleting admin: $e');
      _setError('Error deleting admin: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get level list
  List<String> getLevelList() {
    return _adminService.getLevelList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear all data (for logout)
  void clearData() {
    stopRealtimeBadges(); // ✅ stop semua listener saat logout
    stopCsChatRealtime(); // ✅ stop CS chat realtime saat logout
    _currentAdmin = null;
    _dashboardSummary = null;
    _pendingDrivers = [];
    _pendingUmkm = [];
    _pendingPenarikan = [];
    _pendingRefundCount = 0;
    _isLoadingDrivers = false;
    _isLoadingUmkm = false;
    _isLoadingPenarikan = false;
    _clearError();
    notifyListeners();
  }


  // ============================================================================
  // CASH SETTLEMENT METHODS
  // ============================================================================

  Future<void> loadPendingSettlements() async {
    _isLoadingSettlements = true;
    notifyListeners();

    try {
      _pendingSettlements = await _adminService.getPendingSettlements();
      print('✅ Loaded ${_pendingSettlements.length} settlements');
    } catch (e) {
      print('❌ Error load settlements: $e');
      _pendingSettlements = [];
    } finally {
      _isLoadingSettlements = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminWalletStats() async {
    if (_currentAdmin == null) return;
    
    try {
      _walletStats = await _adminService.getAdminWalletStats(_currentAdmin!.idUser);
      notifyListeners();
    } catch (e) {
      print('❌ Error load wallet stats: $e');
    }
  }

  Future<bool> approveSettlement(String settlementId, {String? catatan}) async {
    if (_currentAdmin == null) return false;

    try {
      final success = await _adminService.approveSettlement(
        settlementId,
        _currentAdmin!.idUser,
        catatan: catatan,
      );

      if (success) {
        await loadPendingSettlements();
        await loadAdminWalletStats();
      }

      return success;
    } catch (e) {
      print('❌ Error approve settlement: $e');
      rethrow;
    }
  }

  Future<bool> rejectSettlement(String settlementId, String alasan) async {
    if (_currentAdmin == null) return false;

    try {
      final success = await _adminService.rejectSettlement(
        settlementId,
        _currentAdmin!.idUser,
        alasan,
      );

      if (success) {
        await loadPendingSettlements();
        await loadAdminWalletStats();
      }

      return success;
    } catch (e) {
      print('❌ Error reject settlement: $e');
      rethrow;
    }
  }

  // ============================================================================
  // KTM VERIFICATION STATE & METHODS
  // ============================================================================
  
  List<KtmVerificationModel> _pendingKtmVerifications = [];
  bool _isLoadingKtmVerifications = false;

  List<KtmVerificationModel> get pendingKtmVerifications => _pendingKtmVerifications;
  bool get isLoadingKtmVerifications => _isLoadingKtmVerifications;

  // ============================================================================
  // REFUND COUNT STATE
  // ============================================================================
  int _pendingRefundCount = 0;
  int get pendingRefundCount => _pendingRefundCount;

  // CS Chat unread badge — diupdate oleh _recalcCsChatBadge() secara internal
  int _csChatUnreadCount = 0;
  int get csChatUnreadCount => _csChatUnreadCount;

  /// Load hanya count refund pending (efisien, tidak load full list)
  Future<void> loadPendingRefundCount() async {
    try {
      debugPrint('🔄 Provider: Loading pending refund count...');
      final response = await _adminService.getPendingRefundCount();
      _pendingRefundCount = response;
      debugPrint('✅ Provider: Pending refund count = $_pendingRefundCount');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Provider: Error loading refund count: $e');
      _pendingRefundCount = 0;
      notifyListeners();
    }
  }

  /// Load pending KTM verifications
  Future<void> loadPendingKtmVerifications() async {
    try {
      _isLoadingKtmVerifications = true;
      notifyListeners();
      
      debugPrint('🔄 Provider: Loading pending KTM verifications...');
      _pendingKtmVerifications = await _adminService.getPendingKtmVerifications();
      debugPrint('✅ Provider: Loaded ${_pendingKtmVerifications.length} pending KTM verifications');
      
      _isLoadingKtmVerifications = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Provider: Error loading KTM verifications: $e');
      _isLoadingKtmVerifications = false;
      _pendingKtmVerifications = [];
      notifyListeners();
      rethrow;
    }
  }

  /// Approve KTM verification
  Future<bool> approveKtmVerification(String requestId) async {
    if (_currentAdmin == null) return false;
    
    try {
      _setLoading(true);
      _clearError();
      
      debugPrint('✅ Provider: Approving KTM verification: $requestId');
      
      final success = await _adminService.approveKtmVerification(
        requestId,
        _currentAdmin!.idUser,
      );
      
      if (success) {
        debugPrint('✅ Provider: KTM verification approved');
        _pendingKtmVerifications.removeWhere((r) => r.id == requestId);
        await loadDashboardSummary();
      }
      
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('❌ Provider: Error approving KTM verification: $e');
      _setError('Error: ${e.toString().replaceAll('Exception: ', '')}');
      _setLoading(false);
      return false;
    }
  }

  /// Reject KTM verification
  Future<bool> rejectKtmVerification(String requestId, String reason) async {
    if (_currentAdmin == null) return false;
    
    try {
      _setLoading(true);
      _clearError();
      
      debugPrint('❌ Provider: Rejecting KTM verification: $requestId');
      debugPrint('   Reason: $reason');
      
      final success = await _adminService.rejectKtmVerification(
        requestId,
        _currentAdmin!.idUser,
        reason,
      );
      
      if (success) {
        debugPrint('✅ Provider: KTM verification rejected');
        _pendingKtmVerifications.removeWhere((r) => r.id == requestId);
        await loadDashboardSummary();
      }
      
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('❌ Provider: Error rejecting KTM verification: $e');
      _setError('Error: ${e.toString().replaceAll('Exception: ', '')}');
      _setLoading(false);
      return false;
    }
  }

  // ============================================================================
  // FINANCIAL TRACKING STATE & METHODS
  // ============================================================================

  List<FinancialTrackingModel> _financialTrackingList = [];
  FinancialSummary? _financialSummary;
  bool _isLoadingFinancialTracking = false;

  List<FinancialTrackingModel> get financialTrackingList => _financialTrackingList;
  FinancialSummary? get financialSummary => _financialSummary;
  bool get isLoadingFinancialTracking => _isLoadingFinancialTracking;

  // ============================================================================
  // ADMIN PAYOUT STATE (WITHDRAWAL/DISBURSEMENT)
  // ============================================================================
  
  bool _isCreatingPayout = false;
  String? _payoutError;
  
  bool get isCreatingPayout => _isCreatingPayout;
  String? get payoutError => _payoutError;

  /// Create admin payout request (Tarik Saldo)
  Future<bool> createAdminPayout({
    required double amount,
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    String? notes,
    bool saveAccount = false,
    bool setAsDefault = false,
  }) async {
    if (_currentAdmin == null) {
      _payoutError = 'Admin not logged in';
      return false;
    }

    _isCreatingPayout = true;
    _payoutError = null;
    notifyListeners();

    try {
      debugPrint('💰 Provider: Creating admin payout...');
      debugPrint('   Amount: $amount');
      debugPrint('   Bank: $bankCode - $accountNumber');
      debugPrint('   Save Account: $saveAccount');

      // 1. Save bank account jika diminta
      if (saveAccount) {
        await saveBankAccount(
          bankCode: bankCode,
          bankName: bankName,
          accountNumber: accountNumber,
          accountHolderName: accountHolderName,
          setAsDefault: setAsDefault,
        );
      }

      // 2. Create payout
      final success = await _adminService.createAdminPayout(
        adminId: _currentAdmin!.idAdmin,
        adminNama: _currentAdmin!.nama,
        amount: amount,
        bankCode: bankCode,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
        notes: notes,
      );

      if (success) {
        debugPrint('✅ Provider: Payout created successfully');
        
        // Update last used timestamp untuk saved account
        if (!saveAccount) {
          final savedAcc = _savedBankAccounts.firstWhere(
            (acc) => acc.accountNumber == accountNumber,
            orElse: () => SavedBankAccount(
              id: '',
              idAdmin: '',
              bankCode: '',
              bankName: '',
              accountNumber: '',
              accountHolderName: '',
              isDefault: false,
              createdAt: DateTime.now(),
            ),
          );
          if (savedAcc.id.isNotEmpty) {
            await _adminService.updateLastUsedAccount(savedAcc.id);
          }
        }
        
        // Reload wallet stats untuk update saldo
        await loadAdminWalletStats();
      }

      _isCreatingPayout = false;
      notifyListeners();
      return success;
      
    } catch (e) {
      debugPrint('❌ Provider: Error creating payout: $e');
      _payoutError = e.toString().replaceAll('Exception: ', '');
      _isCreatingPayout = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear payout error
  void clearPayoutError() {
    _payoutError = null;
    notifyListeners();
  }

  // ============================================================================
  // SAVED BANK ACCOUNTS STATE
  // ============================================================================
  
  List<SavedBankAccount> _savedBankAccounts = [];
  bool _isLoadingSavedAccounts = false;
  
  List<SavedBankAccount> get savedBankAccounts => _savedBankAccounts;
  bool get isLoadingSavedAccounts => _isLoadingSavedAccounts;

  /// Load saved bank accounts
  Future<void> loadSavedBankAccounts() async {
    if (_currentAdmin == null) return;

    _isLoadingSavedAccounts = true;
    notifyListeners();

    try {
      debugPrint('💳 Provider: Loading saved bank accounts...');
      
      _savedBankAccounts = await _adminService.getSavedBankAccounts(
        _currentAdmin!.idAdmin,
      );
      
      debugPrint('✅ Provider: Loaded ${_savedBankAccounts.length} saved accounts');
    } catch (e) {
      debugPrint('❌ Provider: Error loading saved accounts: $e');
      _savedBankAccounts = [];
    } finally {
      _isLoadingSavedAccounts = false;
      notifyListeners();
    }
  }

  /// Save new bank account
  Future<bool> saveBankAccount({
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    required bool setAsDefault,
  }) async {
    if (_currentAdmin == null) return false;

    try {
      debugPrint('💾 Provider: Saving bank account...');
      
      await _adminService.saveBankAccount(
        adminId: _currentAdmin!.idAdmin,
        bankCode: bankCode,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
        setAsDefault: setAsDefault,
      );
      
      // Reload saved accounts
      await loadSavedBankAccounts();
      
      debugPrint('✅ Provider: Bank account saved');
      return true;
    } catch (e) {
      debugPrint('❌ Provider: Error saving bank account: $e');
      return false;
    }
  }

  /// Delete saved bank account
  Future<bool> deleteSavedBankAccount(String accountId) async {
    try {
      debugPrint('🗑️ Provider: Deleting bank account...');
      
      await _adminService.deleteSavedBankAccount(accountId);
      
      // Remove from local list
      _savedBankAccounts.removeWhere((acc) => acc.id == accountId);
      notifyListeners();
      
      debugPrint('✅ Provider: Bank account deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Provider: Error deleting bank account: $e');
      return false;
    }
  }

  /// Set default bank account
  Future<bool> setDefaultBankAccount(String accountId) async {
    try {
      debugPrint('⭐ Provider: Setting default bank account...');
      
      await _adminService.setDefaultBankAccount(accountId);
      
      // Update local list
      for (var acc in _savedBankAccounts) {
        acc = acc.copyWith(isDefault: acc.id == accountId);
      }
      notifyListeners();
      
      debugPrint('✅ Provider: Default bank account set');
      return true;
    } catch (e) {
      debugPrint('❌ Provider: Error setting default: $e');
      return false;
    }
  }

  /// Load financial tracking data
  Future<void> loadFinancialTracking({
    String? jenisFilter,
    String? metodePembayaran,
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    _isLoadingFinancialTracking = true;
    notifyListeners();

    try {
      _financialTrackingList = await _adminService.getFinancialTracking(
        jenisFilter: jenisFilter,
        metodePembayaran: metodePembayaran,
        statusFilter: statusFilter,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
      print('✅ Loaded ${_financialTrackingList.length} financial tracking records');
    } catch (e) {
      print('❌ Error load financial tracking: $e');
      _financialTrackingList = [];
    } finally {
      _isLoadingFinancialTracking = false;
      notifyListeners();
    }
  }

  /// Load financial summary
  Future<void> loadFinancialSummary() async {
    try {
      _financialSummary = await _adminService.getFinancialSummary();
      notifyListeners();
    } catch (e) {
      print('❌ Error load financial summary: $e');
      _financialSummary = FinancialSummary.empty();
      notifyListeners();
    }
  }

  /// Search financial tracking
  Future<void> searchFinancialTracking(String query) async {
    if (query.trim().isEmpty) {
      await loadFinancialTracking();
      return;
    }

    _isLoadingFinancialTracking = true;
    notifyListeners();

    try {
      _financialTrackingList = await _adminService.searchFinancialTracking(query);
      print('✅ Found ${_financialTrackingList.length} results');
    } catch (e) {
      print('❌ Error search financial tracking: $e');
      _financialTrackingList = [];
    } finally {
      _isLoadingFinancialTracking = false;
      notifyListeners();
    }
  }

  /// Get total count untuk pagination
  Future<int> getFinancialTrackingCount({
    String? jenisFilter,
    String? metodePembayaran,
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _adminService.getFinancialTrackingCount(
        jenisFilter: jenisFilter,
        metodePembayaran: metodePembayaran,
        statusFilter: statusFilter,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('❌ Error get financial tracking count: $e');
      return 0;
    }
  }


  List<Map<String, dynamic>> _tarifConfigs = [];
  bool _isLoadingTarif = false;
  bool _isSavingTarif = false;
  String? _tarifErrorMessage;

  // --- Getters ---
  List<Map<String, dynamic>> get tarifConfigs => _tarifConfigs;
  bool get isLoadingTarif => _isLoadingTarif;
  bool get isSavingTarif => _isSavingTarif;
  String? get tarifErrorMessage => _tarifErrorMessage;

  // Helper: ambil nilai config berdasarkan key
  double getTarifValue(String key, {double fallback = 0}) {
    final item = _tarifConfigs.firstWhere(
      (e) => e['config_key'] == key,
      orElse: () => {'config_value': '$fallback'},
    );
    return double.tryParse(item['config_value']?.toString() ?? '') ?? fallback;
  }

  // Helper: kelompokkan per category
  List<Map<String, dynamic>> getTarifByCategory(String category) =>
      _tarifConfigs.where((e) => e['category'] == category).toList();

  /// Load semua konfigurasi tarif
  Future<void> loadTarifConfigs() async {
    if (_isLoadingTarif) return;

    _isLoadingTarif = true;
    _tarifErrorMessage = null;
    notifyListeners();

    try {
      _tarifConfigs = await _adminService.fetchTarifConfigs();
      debugPrint('✅ Provider: Loaded ${_tarifConfigs.length} tarif configs');
    } catch (e) {
      _tarifErrorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('❌ Provider: Error loading tarif configs: $e');
    } finally {
      _isLoadingTarif = false;
      notifyListeners();
    }
  }

  /// Simpan perubahan tarif secara batch
  Future<bool> saveTarifConfigs(Map<String, String> updates) async {
    if (_isSavingTarif) return false;

    _isSavingTarif = true;
    _tarifErrorMessage = null;
    notifyListeners();

    try {
      await _adminService.batchUpdateTarifConfigs(updates);

      // Update local state tanpa perlu refetch dari DB
      for (final entry in updates.entries) {
        final idx = _tarifConfigs.indexWhere((e) => e['config_key'] == entry.key);
        if (idx != -1) {
          _tarifConfigs[idx] = Map<String, dynamic>.from(_tarifConfigs[idx])
            ..['config_value'] = entry.value
            ..['updated_at'] = DateTime.now().toIso8601String()
            ..['updated_by_name'] = _currentAdmin?.nama ?? 'Admin';
        }
      }

      debugPrint('✅ Provider: Tarif configs saved');
      _isSavingTarif = false;
      notifyListeners();
      return true;
    } catch (e) {
      _tarifErrorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('❌ Provider: Error saving tarif configs: $e');
      _isSavingTarif = false;
      notifyListeners();
      return false;
    }
  }
}