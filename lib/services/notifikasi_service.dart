// ============================================================================
// NOTIFIKASI SERVICE
// Service untuk fetch data notifikasi dari Supabase
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/models/notifikasi_model.dart';

class NotifikasiService {
  final _supabase = Supabase.instance.client;

  /// Get all notifications untuk user
  Future<List<NotifikasiModel>> getNotifikasi(String userId) async {
    try {
      print('🔍 [NotifService] Fetching notifications for user: $userId');

      final response = await _supabase
          .from('notifikasi')
          .select()
          .eq('id_user', userId)
          .order('tanggal_notifikasi', ascending: false)
          .limit(50); // Limit 50 notifikasi terbaru

      final List<dynamic> data = response as List<dynamic>;

      print('✅ [NotifService] Got ${data.length} notifications');

      return data.map((json) => NotifikasiModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ [NotifService] Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifikasi')
          .select()
          .eq('id_user', userId)
          .eq('status', 'unread');

      final List<dynamic> data = response as List<dynamic>;

      print('📊 [NotifService] Unread count: ${data.length}');

      return data.length;
    } catch (e) {
      print('❌ [NotifService] Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notifId) async {
    try {
      print('✅ [NotifService] Marking notification as read: $notifId');

      await _supabase
          .from('notifikasi')
          .update({'status': 'read'})
          .eq('id_notifikasi', notifId);

      print('✅ [NotifService] Notification marked as read');
      return true;
    } catch (e) {
      print('❌ [NotifService] Error marking as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      print('✅ [NotifService] Marking all notifications as read for user: $userId');

      await _supabase
          .from('notifikasi')
          .update({'status': 'read'})
          .eq('id_user', userId)
          .eq('status', 'unread');

      print('✅ [NotifService] All notifications marked as read');
      return true;
    } catch (e) {
      print('❌ [NotifService] Error marking all as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotifikasi(String notifId) async {
    try {
      print('🗑️ [NotifService] Deleting notification: $notifId');

      await _supabase
          .from('notifikasi')
          .delete()
          .eq('id_notifikasi', notifId);

      print('✅ [NotifService] Notification deleted');
      return true;
    } catch (e) {
      print('❌ [NotifService] Error deleting notification: $e');
      return false;
    }
  }

  /// Listen to new notifications (real-time)
  Stream<List<NotifikasiModel>> listenNotifikasi(String userId) {
    print('👂 [NotifService] Listening for notifications...');

    return _supabase
        .from('notifikasi')
        .stream(primaryKey: ['id_notifikasi'])
        .eq('id_user', userId)
        .order('tanggal_notifikasi', ascending: false)
        .limit(50)
        .map((data) {
          print('📡 [NotifService] Stream update: ${data.length} notifications');
          return data.map((json) => NotifikasiModel.fromJson(json)).toList();
        });
  }
}