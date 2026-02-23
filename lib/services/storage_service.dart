// ============================================================================
// STORAGE_SERVICE.DART
// Service untuk simpan data lokal (theme, onboarding status, dll)
// ============================================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidrive/config/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ONBOARDING
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> setFirstTime(bool value) async {
    return await _prefs!.setBool(StorageKeys.isFirstTime, value);
  }

  static bool isFirstTime() {
    return _prefs!.getBool(StorageKeys.isFirstTime) ?? true;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // THEME MODE
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> setThemeMode(String mode) async {
    return await _prefs!.setString(StorageKeys.themeMode, mode);
  }

  static String getThemeMode() {
    return _prefs!.getString(StorageKeys.themeMode) ?? 'system';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REMEMBER ME
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> setRememberMe(bool value) async {
    return await _prefs!.setBool(StorageKeys.rememberMe, value);
  }

  static bool getRememberMe() {
    return _prefs!.getBool(StorageKeys.rememberMe) ?? false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LAST NIM (untuk remember me)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> setLastNim(String nim) async {
    return await _prefs!.setString(StorageKeys.lastNim, nim);
  }

  static String? getLastNim() {
    return _prefs!.getString(StorageKeys.lastNim);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GENERIC STRING METHODS (untuk data lain seperti pending_ktm_nim)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> setString(String key, String value) async {
    return await _prefs!.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs!.getString(key);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GENERIC BOOL METHODS (untuk flag seperti ktm_rejection_acked)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs!.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs!.getBool(key);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GENERIC REMOVE METHOD
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> remove(String key) async {
    return await _prefs!.remove(key);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CLEAR ALL DATA (untuk logout)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> clearAll() async {
    return await _prefs!.clear();
  }
}