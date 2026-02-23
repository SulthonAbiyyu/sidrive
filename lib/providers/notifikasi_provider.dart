// ============================================================================
// NOTIFIKASI PROVIDER
// State management untuk notifikasi
// ============================================================================

import 'package:flutter/material.dart';
import 'package:sidrive/models/notifikasi_model.dart';
import 'package:sidrive/services/notifikasi_service.dart';
import 'dart:async';

class NotifikasiProvider with ChangeNotifier {
  final NotifikasiService _service = NotifikasiService();

  // State
  List<NotifikasiModel> _notifikasi = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;
  StreamSubscription? _notifSubscription;

  // Getters
  List<NotifikasiModel> get notifikasi => _notifikasi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  // Filter
  List<NotifikasiModel> get unreadNotifikasi =>
      _notifikasi.where((n) => n.isUnread).toList();

  List<NotifikasiModel> getNotifikasiByJenis(String jenis) =>
      _notifikasi.where((n) => n.jenis == jenis).toList();

  /// Load notifikasi
  Future<void> loadNotifikasi(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📥 [NotifProvider] Loading notifications...');

      _notifikasi = await _service.getNotifikasi(userId);
      _unreadCount = await _service.getUnreadCount(userId);

      print('✅ [NotifProvider] Loaded ${_notifikasi.length} notifications');
      print('📊 [NotifProvider] Unread count: $_unreadCount');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ [NotifProvider] Error loading: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start listening for real-time updates
  void startListening(String userId) {
    print('👂 [NotifProvider] Starting real-time listener...');

    _notifSubscription?.cancel();

    _notifSubscription = _service.listenNotifikasi(userId).listen(
      (notifList) {
        print('📡 [NotifProvider] Real-time update received');

        _notifikasi = notifList;
        _updateUnreadCount();

        notifyListeners();
      },
      onError: (error) {
        print('❌ [NotifProvider] Stream error: $error');
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Stop listening
  void stopListening() {
    print('🛑 [NotifProvider] Stopping listener...');
    _notifSubscription?.cancel();
    _notifSubscription = null;
  }

  /// Mark as read
  Future<bool> markAsRead(String notifId) async {
    try {
      final success = await _service.markAsRead(notifId);

      if (success) {
        // Update local state
        final index = _notifikasi.indexWhere((n) => n.idNotifikasi == notifId);
        if (index != -1) {
          _notifikasi[index] = _notifikasi[index].copyWith(status: 'read');
          _updateUnreadCount();
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      print('❌ [NotifProvider] Error marking as read: $e');
      return false;
    }
  }

  /// Mark all as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      final success = await _service.markAllAsRead(userId);

      if (success) {
        // Update local state
        _notifikasi = _notifikasi.map((n) {
          return n.copyWith(status: 'read');
        }).toList();
        _unreadCount = 0;
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('❌ [NotifProvider] Error marking all as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotifikasi(String notifId) async {
    try {
      final success = await _service.deleteNotifikasi(notifId);

      if (success) {
        // Update local state
        _notifikasi.removeWhere((n) => n.idNotifikasi == notifId);
        _updateUnreadCount();
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('❌ [NotifProvider] Error deleting: $e');
      return false;
    }
  }

  /// Update unread count
  void _updateUnreadCount() {
    _unreadCount = _notifikasi.where((n) => n.isUnread).length;
  }

  /// Clear all
  void clear() {
    _notifikasi = [];
    _unreadCount = 0;
    _errorMessage = null;
    stopListening();
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}