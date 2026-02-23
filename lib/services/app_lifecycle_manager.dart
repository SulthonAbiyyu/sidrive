import 'package:flutter/material.dart';

/// 📄 AppLifecycleManager - IMPROVED WITH SAFETY CHECKS
/// Mendeteksi lifecycle app (foreground/background/killed)
/// 
/// Fungsi utama:
/// - Deteksi saat user minimize app
/// - Deteksi saat user buka app lagi
/// - Trigger callback untuk re-sync timer
/// 
/// ✅ IMPROVEMENTS:
/// - Added safety checks untuk prevent crash
/// - Better error handling
/// - Debouncing untuk duplicate states
/// - Callback validation before execution
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  // Callback functions
  Function()? onAppPaused;
  Function()? onAppResumed;
  Function()? onAppInactive;
  Function()? onAppDetached;

  AppLifecycleState? _previousState;
  bool _isInitialized = false;

  // ✅ NEW: Track if callbacks are being executed
  bool _isExecutingCallback = false;

  // ✅ NEW: Track last state change time for debouncing
  DateTime? _lastStateChange;
  static const _debounceThreshold = Duration(milliseconds: 100);

  /// ✅ Initialize lifecycle observer
  void initialize() {
    if (_isInitialized) {
      print('⚠️ [AppLifecycleManager] Already initialized, skipping...');
      return;
    }

    try {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      print('📄 [AppLifecycleManager] Initialized successfully');
    } catch (e) {
      print('❌ [AppLifecycleManager] Initialization error: $e');
    }
  }

  /// ❌ Dispose lifecycle observer
  void dispose() {
    if (!_isInitialized) {
      print('⚠️ [AppLifecycleManager] Not initialized, skipping dispose...');
      return;
    }

    try {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
      
      // ✅ Clear callbacks saat dispose
      clearCallbacks();
      
      // ✅ Reset internal state
      _isExecutingCallback = false;
      _lastStateChange = null;
      
      print('📄 [AppLifecycleManager] Disposed successfully');
    } catch (e) {
      print('❌ [AppLifecycleManager] Error during dispose: $e');
    }
  }

  /// 🔡 Override didChangeAppLifecycleState dari WidgetsBindingObserver
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // ✅ Prevent duplicate calls untuk state yang sama
    if (_previousState == state) {
      return;
    }

    // ✅ Debouncing: Ignore if state changes too quickly
    final now = DateTime.now();
    if (_lastStateChange != null && 
        now.difference(_lastStateChange!) < _debounceThreshold) {
      print('⏭️ [AppLifecycleManager] State change debounced: $_previousState → $state');
      return;
    }
    _lastStateChange = now;

    // ✅ Don't execute new callbacks if one is already running
    if (_isExecutingCallback) {
      print('⏭️ [AppLifecycleManager] Callback already executing, skipping: $state');
      return;
    }

    print('📄 [AppLifecycleManager] State changed: $_previousState → $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App kembali ke foreground (user buka app lagi)
        print('   ✅ App RESUMED (kembali ke foreground)');
        _safeExecuteCallback(() => onAppResumed?.call(), 'onAppResumed');
        break;

      case AppLifecycleState.inactive:
        // App dalam transisi (biasanya sebelum paused atau resumed)
        print('   ⏸️ App INACTIVE (transisi)');
        _safeExecuteCallback(() => onAppInactive?.call(), 'onAppInactive');
        break;

      case AppLifecycleState.paused:
        // App masuk background (user minimize atau ganti app)
        print('   ⏯️ App PAUSED (masuk background)');
        _safeExecuteCallback(() => onAppPaused?.call(), 'onAppPaused');
        break;

      case AppLifecycleState.detached:
        // App akan di-terminate oleh sistem
        print('   🚫 App DETACHED (akan di-terminate)');
        _safeExecuteCallback(() => onAppDetached?.call(), 'onAppDetached');
        break;

      case AppLifecycleState.hidden:
        // App tersembunyi (khusus Android 13+)
        print('   🙈 App HIDDEN');
        break;
    }

    _previousState = state;
  }

  /// ✅ NEW: Safe callback execution with error handling
  void _safeExecuteCallback(Function()? callback, String callbackName) {
    if (callback == null) {
      return;
    }

    _isExecutingCallback = true;
    
    try {
      callback();
    } catch (e, stackTrace) {
      print('❌ [AppLifecycleManager] Error in $callbackName callback: $e');
      print('   Stack trace: $stackTrace');
    } finally {
      _isExecutingCallback = false;
    }
  }

  /// 🎯 Register callback untuk app paused (masuk background)
  void setOnAppPaused(Function() callback) {
    onAppPaused = callback;
    print('📄 [AppLifecycleManager] Callback registered: onAppPaused');
  }

  /// 🎯 Register callback untuk app resumed (buka app lagi)
  void setOnAppResumed(Function() callback) {
    onAppResumed = callback;
    print('📄 [AppLifecycleManager] Callback registered: onAppResumed');
  }

  /// 🎯 Register callback untuk app inactive (transisi)
  void setOnAppInactive(Function() callback) {
    onAppInactive = callback;
    print('📄 [AppLifecycleManager] Callback registered: onAppInactive');
  }

  /// 🎯 Register callback untuk app detached (akan di-terminate)
  void setOnAppDetached(Function() callback) {
    onAppDetached = callback;
    print('📄 [AppLifecycleManager] Callback registered: onAppDetached');
  }

  /// ❌ Clear all callbacks
  void clearCallbacks() {
    onAppPaused = null;
    onAppResumed = null;
    onAppInactive = null;
    onAppDetached = null;
    print('📄 [AppLifecycleManager] All callbacks cleared');
  }

  /// 📊 Get current lifecycle state
  AppLifecycleState? get currentState => _previousState;

  /// 🔍 Check if app is in foreground
  bool get isAppInForeground => 
      _previousState == AppLifecycleState.resumed;

  /// 🔍 Check if app is in background
  bool get isAppInBackground => 
      _previousState == AppLifecycleState.paused ||
      _previousState == AppLifecycleState.inactive;
  
  /// 🔍 Check if lifecycle manager is active
  bool get isInitialized => _isInitialized;

  /// 🔍 Check if callback is currently executing
  bool get isExecutingCallback => _isExecutingCallback;
}