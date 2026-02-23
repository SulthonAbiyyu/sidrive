import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_admin/admin_header.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_admin/admin_filter_bar.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_admin/admin_list.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_admin/admin_pagination.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_admin/admin_form_dialog.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_admin/admin_delete_dialog.dart';



class KelolaAdminContent extends StatefulWidget {
  const KelolaAdminContent({super.key});

  @override
  State<KelolaAdminContent> createState() => _KelolaAdminContentState();
}

class _KelolaAdminContentState extends State<KelolaAdminContent> {
  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================
  
  // Data State
  List<AdminModel> _adminList = [];
  bool _isLoading = false;
  
  // Filter State
  String _searchQuery = '';
  String _filterLevel = 'Semua';
  String _filterStatus = 'Semua';
  
  // Dropdown Options
  final List<String> _levelList = ['Semua', 'admin', 'super_admin'];
  final List<String> _statusList = ['Semua', 'aktif', 'nonaktif'];
  
  // Pagination State
  final int _itemsPerPage = 20;
  int _currentPage = 0;
  int _totalItems = 0;
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 [KelolaAdmin] Screen initialized');
    
    // Check authorization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = context.read<AdminProvider>();
      final isSuperAdmin = adminProvider.currentAdmin?.level == 'super_admin';
      
      if (!isSuperAdmin) {
        debugPrint('⚠️ [KelolaAdmin] Access denied - not super_admin!');
        _showUnauthorizedMessage();
        return;
      }
      
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    debugPrint('🔴 [KelolaAdmin] Screen disposed');
    super.dispose();
  }

  // ============================================================================
  // DATA LOADING METHODS
  // ============================================================================

  Future<void> _loadInitialData() async {
    debugPrint('🔥 [KelolaAdmin] Loading initial data...');
    await _loadAdmins();
    debugPrint('✅ [KelolaAdmin] Initial data loaded');
  }

  Future<void> _loadAdmins() async {
    debugPrint('🔥 [KelolaAdmin] Loading admin list...');
    debugPrint('   Filters: Level=$_filterLevel, Status=$_filterStatus');
    debugPrint('   Search: "$_searchQuery"');
    debugPrint('   Pagination: Page $_currentPage, Limit $_itemsPerPage');
    
    setState(() => _isLoading = true);
    
    try {
      final adminProvider = context.read<AdminProvider>();
      
      await adminProvider.loadAdmins(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        filterLevel: _filterLevel,
        filterStatus: _filterStatus,
        limit: _itemsPerPage,
        offset: _currentPage * _itemsPerPage,
      );
      
      final total = await adminProvider.getTotalAdmins(
        filterLevel: _filterLevel,
        filterStatus: _filterStatus,
      );
      
      debugPrint('✅ [KelolaAdmin] Loaded ${adminProvider.adminList.length} admins (Total: $total)');
      
      setState(() {
        _adminList = adminProvider.adminList;
        _totalItems = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [KelolaAdmin] Error loading admins: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        _showErrorToast('Gagal memuat data admin: ${e.toString()}');
      }
    }
  }

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  void _onSearchChanged(String value) {
    debugPrint('🔍 [KelolaAdmin] Search query changed: "$value"');
    
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value && mounted) {
        debugPrint('🔍 [KelolaAdmin] Executing search: "$value"');
        setState(() {
          _searchQuery = value;
          _currentPage = 0;
        });
        _loadAdmins();
      }
    });
  }

  void _onFilterChanged() {
    debugPrint('🔄 [KelolaAdmin] Filter changed, resetting to page 0');
    setState(() => _currentPage = 0);
    _loadAdmins();
  }

  void _onPageChanged(int newPage) {
    debugPrint('🔄 [KelolaAdmin] Page changed: $newPage');
    setState(() => _currentPage = newPage);
    _loadAdmins();
  }

  void _onRefresh() {
    debugPrint('🔄 [KelolaAdmin] Manual refresh triggered');
    _loadAdmins();
  }

  void _onAddAdmin() {
    debugPrint('➕ [KelolaAdmin] Add admin button pressed');
    _showAdminDialog(null);
  }

  void _onEditAdmin(AdminModel admin) {
    debugPrint('✏️ [KelolaAdmin] Edit admin: ${admin.username}');
    _showAdminDialog(admin);
  }

  void _onDeleteAdmin(AdminModel admin) {
    debugPrint('🗑️ [KelolaAdmin] Delete admin: ${admin.username}');
    _showDeleteConfirmation(admin);
  }

  // ============================================================================
  // AUTHORIZATION CHECK
  // ============================================================================

  void _showUnauthorizedMessage() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 2),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            SizedBox(width: ResponsiveAdmin.spaceSM()),
            Text(
              'Akses Ditolak',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontH4(),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: Text(
          'Hanya Super Admin yang dapat mengakses halaman ini.',
          style: TextStyle(
            fontSize: ResponsiveAdmin.fontBody(),
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody(),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final isSuperAdmin = adminProvider.currentAdmin?.level == 'super_admin';
    
    // Double check authorization
    if (!isSuperAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
            Text(
              'Akses Ditolak',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontH3(),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: ResponsiveAdmin.spaceXS()),
            Text(
              'Hanya Super Admin yang dapat mengakses halaman ini',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody(),
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
      child: Column(
        children: [
          // Header
          AdminHeader(
            totalItems: _totalItems,
            onRefresh: _onRefresh,
            onAdd: _onAddAdmin,
          ),
          
          SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
          
          // Filter Bar
          AdminFilterBar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            filterLevel: _filterLevel,
            filterStatus: _filterStatus,
            levelList: _levelList,
            statusList: _statusList,
            onLevelChanged: (value) {
              debugPrint('🔄 [KelolaAdmin] Level filter: $value');
              setState(() => _filterLevel = value!);
              _onFilterChanged();
            },
            onStatusChanged: (value) {
              debugPrint('🔄 [KelolaAdmin] Status filter: $value');
              setState(() => _filterStatus = value!);
              _onFilterChanged();
            },
          ),
          
          SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
          
          // List
          Expanded(
            child: AdminList(
              adminList: _adminList,
              isLoading: _isLoading,
              searchQuery: _searchQuery,
              hasActiveFilters: _filterLevel != 'Semua' || _filterStatus != 'Semua',
              onRefresh: _loadAdmins,
              onEdit: _onEditAdmin,
              onDelete: _onDeleteAdmin,
            ),
          ),
          
          // Pagination
          if (_totalItems > _itemsPerPage) ...[
            SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
            AdminPagination(
              currentPage: _currentPage,
              itemsPerPage: _itemsPerPage,
              totalItems: _totalItems,
              onPageChanged: _onPageChanged,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // DIALOG METHODS
  // ============================================================================

  void _showAdminDialog(AdminModel? admin) {
    debugPrint('📋 [KelolaAdmin] Opening form dialog for: ${admin?.username ?? "NEW"}');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminFormDialog(
        admin: admin,
        levelList: _levelList.where((l) => l != 'Semua').toList(),
        onSuccess: () {
          debugPrint('✅ [KelolaAdmin] Form dialog success callback');
          _loadAdmins();
        },
      ),
    );
  }

  void _showDeleteConfirmation(AdminModel admin) {
    debugPrint('🗑️ [KelolaAdmin] Showing delete confirmation for: ${admin.username}');
    
    showDialog(
      context: context,
      builder: (context) => AdminDeleteDialog(
        admin: admin,
        onConfirm: () => _deleteAdmin(admin.idAdmin, admin.username),
      ),
    );
  }

  // ============================================================================
  // DELETE METHOD
  // ============================================================================

  Future<void> _deleteAdmin(String idAdmin, String username) async {
    debugPrint('🗑️ [KelolaAdmin] Starting delete process...');
    debugPrint('   ID: $idAdmin');
    debugPrint('   Username: $username');
    
    try {
      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.deleteAdmin(idAdmin);
      
      if (success) {
        debugPrint('✅ [KelolaAdmin] Delete successful for username: $username');
        
        if (mounted) {
          _showSuccessToast('Admin "$username" berhasil dihapus (status diubah ke nonaktif)');
          await _loadAdmins();
        }
      }
    } catch (e) {
      debugPrint('❌ [KelolaAdmin] Delete failed for username: $username');
      debugPrint('   Error: $e');
      
      if (mounted) {
        _showErrorToast('Gagal menghapus admin: ${e.toString()}');
      }
    }
  }

  // ============================================================================
  // TOAST NOTIFICATION METHODS
  // ============================================================================

  void _showSuccessToast(String message) {
    if (!mounted) return;
    
    debugPrint('✅ [KelolaAdmin] Success toast: $message');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: ResponsiveAdmin.spaceSM()),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: ResponsiveAdmin.fontCaption() + 1,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        ),
        margin: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveAdmin.spaceSM() + 4,
          vertical: ResponsiveAdmin.spaceSM() + 4,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    
    debugPrint('❌ [KelolaAdmin] Error toast: $message');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: ResponsiveAdmin.spaceSM()),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: ResponsiveAdmin.fontCaption() + 1,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        ),
        margin: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveAdmin.spaceSM() + 4,
          vertical: ResponsiveAdmin.spaceSM() + 4,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}