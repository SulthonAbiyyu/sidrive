// ============================================================================
// USER_PROVIDER.DART - ULTIMATE FIX (NO AUTO-REFRESH CAUSING DATA RESET!)
// State management untuk kelola user dengan multi-role
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:sidrive/models/user_detail_model.dart';
import 'package:sidrive/models/user_transaction_model.dart';
import 'package:sidrive/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  // ═══════════════════════════════════════════════════════════════════════
  // STATE VARIABLES
  // ═══════════════════════════════════════════════════════════════════════
  List<UserDetailModel> _userList = [];
  List<UserDetailModel> _filteredList = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String _searchQuery = '';
  String? _roleFilter;
  String? _statusFilter;

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  int _totalItems = 0;

  // Selected user detail
  UserDetailModel? _selectedUser;
  List<UserTransactionModel> _selectedUserTransactions = [];
  List<UserTransactionModel> _selectedDriverDeliveries = [];
  List<UserTransactionModel> _selectedUmkmOrders = [];
  List<Map<String, dynamic>> _selectedDriverRatings = [];
  List<Map<String, dynamic>> _selectedUmkmReviews = [];

  // ═══════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════
  List<UserDetailModel> get userList => _filteredList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get roleFilter => _roleFilter;
  String? get statusFilter => _statusFilter;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  int get totalItems => _totalItems;
  UserDetailModel? get selectedUser => _selectedUser;
  List<UserTransactionModel> get selectedUserTransactions => _selectedUserTransactions;
  List<UserTransactionModel> get selectedDriverDeliveries => _selectedDriverDeliveries;
  List<UserTransactionModel> get selectedUmkmOrders => _selectedUmkmOrders;
  List<Map<String, dynamic>> get selectedDriverRatings => _selectedDriverRatings;
  List<Map<String, dynamic>> get selectedUmkmReviews => _selectedUmkmReviews;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _roleFilter != null ||
      _statusFilter != null;

  // ═══════════════════════════════════════════════════════════════════════
  // LOAD USERS
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) _currentPage = 0;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = _currentPage * _itemsPerPage;

      _userList = await _userService.getAllUsers(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        roleFilter: _roleFilter,
        statusFilter: _statusFilter,
        limit: _itemsPerPage,
        offset: offset,
      );

      _filteredList = _userList;

      // Get total count
      _totalItems = await _userService.getTotalUsersCount(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        roleFilter: _roleFilter,
        statusFilter: _statusFilter,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SEARCH USERS
  // ═══════════════════════════════════════════════════════════════════════
  void searchUsers(String query) {
    _searchQuery = query;
    _currentPage = 0;
    loadUsers();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTER BY ROLE
  // ═══════════════════════════════════════════════════════════════════════
  void filterByRole(String? role) {
    _roleFilter = role;
    _currentPage = 0;
    loadUsers();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTER BY STATUS
  // ═══════════════════════════════════════════════════════════════════════
  void filterByStatus(String? status) {
    _statusFilter = status;
    _currentPage = 0;
    loadUsers();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEAR FILTERS
  // ═══════════════════════════════════════════════════════════════════════
  void clearFilters() {
    _searchQuery = '';
    _roleFilter = null;
    _statusFilter = null;
    _currentPage = 0;
    loadUsers();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAGINATION
  // ═══════════════════════════════════════════════════════════════════════
  void changePage(int page) {
    _currentPage = page;
    loadUsers();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOAD USER DETAIL
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> loadUserDetail(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedUser = await _userService.getUserDetail(userId);

      // Load transactions based on roles
      if (_selectedUser!.hasRole('customer')) {
        _selectedUserTransactions = await _userService.getUserTransactions(userId);
      }

      if (_selectedUser!.hasRole('driver')) {
        _selectedDriverDeliveries = await _userService.getDriverDeliveries(userId);
        _selectedDriverRatings = await _userService.getDriverRatings(userId);
      }

      if (_selectedUser!.hasRole('umkm')) {
        _selectedUmkmOrders = await _userService.getUmkmOrders(userId);
        _selectedUmkmReviews = await _userService.getUmkmReviews(userId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UPDATE ROLE STATUS
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> updateRoleStatus({
    required String userId,
    required String role,
    required String status,
  }) async {
    try {
      await _userService.updateUserRoleStatus(
        userId: userId,
        role: role,
        status: status,
      );
      await loadUsers(refresh: true);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ADD ROLE TO USER
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> addRole({
    required String userId,
    required String role,
  }) async {
    try {
      await _userService.addUserRole(userId: userId, role: role);
      await loadUsers(refresh: true);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DELETE ROLE FROM USER - ✅ FIXED (NO AUTO REFRESH!)
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> deleteRole({
    required String userId,
    required String role,
  }) async {
    try {
      // 1. Delete dari database
      await _userService.deleteUserRole(userId: userId, role: role);
      
      // 2. ✅ Update LOCAL STATE - Create new list without deleted role
      final userIndex = _userList.indexWhere((u) => u.user.idUser == userId);
      if (userIndex != -1) {
        final currentUser = _userList[userIndex];
        // Filter out deleted role
        final updatedRoles = currentUser.roles.where((r) => r.role != role).toList();
        
        // Create new UserDetailModel dengan roles yang udah difilter
        _userList[userIndex] = UserDetailModel(
          user: currentUser.user,
          roles: updatedRoles,
          totalOrderOjek: currentUser.totalOrderOjek,
          totalOrderUmkm: currentUser.totalOrderUmkm,
          totalSpending: currentUser.totalSpending,
          totalOrderSelesai: currentUser.totalOrderSelesai,
          totalOrderDibatalkan: currentUser.totalOrderDibatalkan,
          idDriver: currentUser.idDriver,
          statusDriver: currentUser.statusDriver,
          ratingDriver: currentUser.ratingDriver,
          totalRatingDriver: currentUser.totalRatingDriver,
          jumlahPesananSelesaiDriver: currentUser.jumlahPesananSelesaiDriver,
          totalPendapatanDriver: currentUser.totalPendapatanDriver,
          activeVehicleType: currentUser.activeVehicleType,
          jumlahOrderBelumSetor: currentUser.jumlahOrderBelumSetor,
          totalCashPending: currentUser.totalCashPending,
          idUmkm: currentUser.idUmkm,
          namaToko: currentUser.namaToko,
          statusToko: currentUser.statusToko,
          ratingToko: currentUser.ratingToko,
          totalRatingUmkm: currentUser.totalRatingUmkm,
          totalPenjualan: currentUser.totalPenjualan,
          jumlahProdukTerjual: currentUser.jumlahProdukTerjual,
          kategoriToko: currentUser.kategoriToko,
          fotoToko: currentUser.fotoToko,
          saldoWallet: currentUser.saldoWallet,
          totalTopup: currentUser.totalTopup,
          namaBank: currentUser.namaBank,
          nomorRekening: currentUser.nomorRekening,
          namaRekening: currentUser.namaRekening,
        );
      }
      
      final filteredIndex = _filteredList.indexWhere((u) => u.user.idUser == userId);
      if (filteredIndex != -1) {
        final currentUser = _filteredList[filteredIndex];
        final updatedRoles = currentUser.roles.where((r) => r.role != role).toList();
        
        _filteredList[filteredIndex] = UserDetailModel(
          user: currentUser.user,
          roles: updatedRoles,
          totalOrderOjek: currentUser.totalOrderOjek,
          totalOrderUmkm: currentUser.totalOrderUmkm,
          totalSpending: currentUser.totalSpending,
          totalOrderSelesai: currentUser.totalOrderSelesai,
          totalOrderDibatalkan: currentUser.totalOrderDibatalkan,
          idDriver: currentUser.idDriver,
          statusDriver: currentUser.statusDriver,
          ratingDriver: currentUser.ratingDriver,
          totalRatingDriver: currentUser.totalRatingDriver,
          jumlahPesananSelesaiDriver: currentUser.jumlahPesananSelesaiDriver,
          totalPendapatanDriver: currentUser.totalPendapatanDriver,
          activeVehicleType: currentUser.activeVehicleType,
          jumlahOrderBelumSetor: currentUser.jumlahOrderBelumSetor,
          totalCashPending: currentUser.totalCashPending,
          idUmkm: currentUser.idUmkm,
          namaToko: currentUser.namaToko,
          statusToko: currentUser.statusToko,
          ratingToko: currentUser.ratingToko,
          totalRatingUmkm: currentUser.totalRatingUmkm,
          totalPenjualan: currentUser.totalPenjualan,
          jumlahProdukTerjual: currentUser.jumlahProdukTerjual,
          kategoriToko: currentUser.kategoriToko,
          fotoToko: currentUser.fotoToko,
          saldoWallet: currentUser.saldoWallet,
          totalTopup: currentUser.totalTopup,
          namaBank: currentUser.namaBank,
          nomorRekening: currentUser.nomorRekening,
          namaRekening: currentUser.namaRekening,
        );
      }
      
      // 3. ✅ Notify listeners tanpa loadUsers()
      notifyListeners();
      
      // ❌ JANGAN PANGGIL INI! Ini yang bikin data reset!
      // await loadUsers(refresh: true);
      
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DELETE USER (COMPLETE) - ✅ FIXED (NO AUTO REFRESH!)
  // Hapus user beserta semua data terkait - NO STUCK LOADING!
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> deleteUser({required String userId}) async {
    try {
      // 1. Delete via service
      await _userService.deleteUser(userId: userId);
      
      // 2. ✅ Remove from BOTH lists
      _userList.removeWhere((user) => user.user.idUser == userId);
      _filteredList.removeWhere((user) => user.user.idUser == userId);
      
      // 3. ✅ Update count
      _totalItems = _totalItems > 0 ? _totalItems - 1 : 0;
      
      // 4. ✅ Update UI immediately
      notifyListeners();
      
      // ❌ JANGAN refresh! Ini yang bikin stuck!
      // await loadUsers(refresh: true);
      
    } catch (e) {
      print('Error deleting user in provider: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEAR SELECTED USER
  // ═══════════════════════════════════════════════════════════════════════
  void clearSelectedUser() {
    _selectedUser = null;
    _selectedUserTransactions = [];
    _selectedDriverDeliveries = [];
    _selectedUmkmOrders = [];
    _selectedDriverRatings = [];
    _selectedUmkmReviews = [];
    notifyListeners();
  }
}