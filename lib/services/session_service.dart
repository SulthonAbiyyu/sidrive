// ============================================================================
// SESSION_SERVICE.DART
// Service untuk persist & restore Supabase session
// ✅ FIX: Tambah fallback refreshSession() jika setSession() gagal
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // ============================================================================
  // SAVE SESSION - Dipanggil saat login berhasil
  // ============================================================================
  static Future<void> saveSession() async {
    try {
      debugPrint('💾 [SESSION] Saving session...');
      
      final session = _supabase.auth.currentSession;
      
      if (session == null) {
        debugPrint('⚠️ [SESSION] No active session to save');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // Simpan access token & refresh token
      await prefs.setString('access_token', session.accessToken);
      await prefs.setString('refresh_token', session.refreshToken ?? '');
      await prefs.setString('session_saved_at', DateTime.now().toIso8601String());
      
      debugPrint('✅ [SESSION] Session saved successfully');
      debugPrint('   Access Token: ${session.accessToken.substring(0, 20)}...');
      
    } catch (e) {
      debugPrint('❌ [SESSION] Error saving session: $e');
    }
  }
  
  // ============================================================================
  // RESTORE SESSION - Dipanggil saat app start atau resume
  // ✅ FIX: Tambah fallback ke refreshSession() jika setSession() gagal
  // ============================================================================
  static Future<bool> restoreSession() async {
    try {
      debugPrint('🔄 [SESSION] Restoring session...');
      
      // ✅ Langkah 1: Cek apakah Supabase sudah punya session aktif
      // Supabase v2 otomatis menyimpan session di SharedPreferences.
      // Jadi mungkin session sudah ada tanpa perlu kita restore manual.
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        // ✅ FIX: Cek apakah token sudah expired atau belum
        final expiresAt = currentSession.expiresAt;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        if (expiresAt != null && expiresAt > now) {
          // Token masih valid
          debugPrint('✅ [SESSION] Active & valid session already exists, skip restore');
          return true;
        } else {
          // Token expired, perlu refresh
          debugPrint('⚠️ [SESSION] Session exists but expired, attempting refresh...');
          return await _tryRefreshSession();
        }
      }
      
      // ✅ Langkah 2: Session tidak ada di memory Supabase, coba dari SharedPreferences kita
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('⚠️ [SESSION] No saved session found');
        return false;
      }
      
      debugPrint('🔄 [SESSION] Found saved refresh token, trying to restore...');
      
      // ✅ Langkah 3: Coba restore dengan setSession
      try {
        final response = await _supabase.auth.setSession(refreshToken);
        
        if (response.session != null) {
          debugPrint('✅ [SESSION] Session restored with setSession()');
          debugPrint('   User ID: ${response.user?.id}');
          
          // Update saved session dengan token baru
          await saveSession();
          return true;
        }
      } catch (setSessionError) {
        // setSession gagal (token mungkin expired), coba cara lain
        debugPrint('⚠️ [SESSION] setSession() failed: $setSessionError');
        debugPrint('🔄 [SESSION] Trying refreshSession() as fallback...');
        
        // ✅ FIX: Fallback ke refreshSession()
        return await _tryRefreshSession();
      }
      
      // Kalau sampai sini, semua cara gagal
      debugPrint('❌ [SESSION] All restore methods failed');
      await clearSession();
      return false;
      
    } catch (e) {
      debugPrint('❌ [SESSION] Error restoring session: $e');
      await clearSession();
      return false;
    }
  }
  
  // ============================================================================
  // HELPER: Coba refresh session yang ada
  // ✅ FIX: Metode baru sebagai fallback jika setSession() gagal
  // ============================================================================
  static Future<bool> _tryRefreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      
      if (response.session != null) {
        debugPrint('✅ [SESSION] Session refreshed successfully via refreshSession()');
        await saveSession(); // Simpan token baru
        return true;
      } else {
        debugPrint('❌ [SESSION] refreshSession() returned null session');
        await clearSession();
        return false;
      }
    } catch (e) {
      debugPrint('❌ [SESSION] refreshSession() also failed: $e');
      await clearSession();
      return false;
    }
  }
  
  // ============================================================================
  // CLEAR SESSION - Dipanggil saat logout
  // ============================================================================
  static Future<void> clearSession() async {
    try {
      debugPrint('🗑️ [SESSION] Clearing saved session...');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('session_saved_at');
      
      debugPrint('✅ [SESSION] Session cleared');
      
    } catch (e) {
      debugPrint('❌ [SESSION] Error clearing session: $e');
    }
  }
  
  // ============================================================================
  // CHECK SESSION - Cek apakah ada session yang valid
  // ============================================================================
  static Future<bool> checkSession() async {
    try {
      final session = _supabase.auth.currentSession;
      
      if (session != null) {
        // ✅ FIX: Cek juga apakah token belum expired
        final expiresAt = session.expiresAt;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        if (expiresAt != null && expiresAt > now) {
          debugPrint('✅ [SESSION] Valid session exists');
          return true;
        } else {
          debugPrint('⚠️ [SESSION] Session expired, attempting refresh...');
          return await _tryRefreshSession();
        }
      }
      
      debugPrint('⚠️ [SESSION] No active session');
      return false;
      
    } catch (e) {
      debugPrint('❌ [SESSION] Error checking session: $e');
      return false;
    }
  }
  
  // ============================================================================
  // REFRESH SESSION - Dipanggil saat app resume
  // ============================================================================
  static Future<void> refreshSessionIfNeeded() async {
    try {
      final currentSession = _supabase.auth.currentSession;
      
      if (currentSession == null) {
        debugPrint('⚠️ [SESSION] No session, attempting restore...');
        await restoreSession();
      } else {
        // ✅ FIX: Cek apakah perlu refresh (token hampir expired)
        final expiresAt = currentSession.expiresAt;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        // Refresh kalau token akan expired dalam 5 menit (300 detik)
        if (expiresAt != null && (expiresAt - now) < 300) {
          debugPrint('🔄 [SESSION] Token will expire soon, refreshing...');
          await _tryRefreshSession();
        } else {
          debugPrint('✅ [SESSION] Session active, no refresh needed');
        }
      }
      
    } catch (e) {
      debugPrint('❌ [SESSION] Error refreshing session: $e');
    }
  }
}