import 'package:flutter/material.dart';
import 'package:sidrive/services/mahasiswa_service.dart';
import 'package:sidrive/models/mahasiswa_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

// ✅ IMPORT SEMUA WIDGETS
import 'package:sidrive/screens/admin/contents/widgets/kelola_mahasiswa/mahasiswa_filter_bar.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_mahasiswa/mahasiswa_list.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_mahasiswa/mahasiswa_pagination.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_mahasiswa/mahasiswa_form_dialog.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_mahasiswa/mahasiswa_delete_dialog.dart';

// ✅ IMPORT CSV FEATURES
import 'package:sidrive/services/mahasiswa_import_service.dart';
import 'package:sidrive/screens/admin/contents/widgets/kelola_mahasiswa/mahasiswa_import_dialog.dart';

/// ============================================================================
/// KELOLA MAHASISWA CONTENT - CLEAN ARCHITECTURE + CSV IMPORT
/// ============================================================================
/// Main Controller - Hanya handle state management dan business logic
/// UI Components di-handle oleh widgets terpisah
/// ============================================================================

class KelolaMahasiswaContent extends StatefulWidget {
  const KelolaMahasiswaContent({super.key});

  @override
  State<KelolaMahasiswaContent> createState() => _KelolaMahasiswaContentState();
}

class _KelolaMahasiswaContentState extends State<KelolaMahasiswaContent> {
  final MahasiswaService _mahasiswaService = MahasiswaService();
  late final MahasiswaImportService _importService;
  
  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================
  
  // Data State
  List<MahasiswaModel> _mahasiswaList = [];
  bool _isLoading = false;
  bool _isImporting = false; // NEW: Import loading state
  
  // Filter State
  String _searchQuery = '';
  String _filterFakultas = 'Semua';
  String _filterAngkatan = 'Semua';
  String _filterStatus = 'Semua';
  
  // Dropdown Options
  List<String> _fakultasList = ['Semua'];
  List<String> _angkatanList = ['Semua'];
  
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
    _importService = MahasiswaImportService(_mahasiswaService);
    debugPrint('🔵 [KelolaMahasiswa] Screen initialized');
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    debugPrint('🔴 [KelolaMahasiswa] Screen disposed');
    super.dispose();
  }

  // ============================================================================
  // DATA LOADING METHODS
  // ============================================================================

  Future<void> _loadInitialData() async {
    debugPrint('🔥 [KelolaMahasiswa] Loading initial data...');
    await Future.wait([
      _loadMahasiswa(),
      _loadFilterOptions(),
    ]);
    debugPrint('✅ [KelolaMahasiswa] Initial data loaded');
  }

  Future<void> _loadMahasiswa() async {
    debugPrint('🔥 [KelolaMahasiswa] Loading mahasiswa list...');
    debugPrint('   Filters: Fakultas=$_filterFakultas, Angkatan=$_filterAngkatan, Status=$_filterStatus');
    debugPrint('   Search: "$_searchQuery"');
    debugPrint('   Pagination: Page $_currentPage, Limit $_itemsPerPage');
    
    setState(() => _isLoading = true);
    
    try {
      final mahasiswa = await _mahasiswaService.getAllMahasiswa(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        filterFakultas: _filterFakultas,
        filterAngkatan: _filterAngkatan,
        filterStatus: _filterStatus,
        limit: _itemsPerPage,
        offset: _currentPage * _itemsPerPage,
      );
      
      final total = await _mahasiswaService.getTotalMahasiswa(
        filterFakultas: _filterFakultas,
        filterAngkatan: _filterAngkatan,
        filterStatus: _filterStatus,
      );
      
      debugPrint('✅ [KelolaMahasiswa] Loaded ${mahasiswa.length} mahasiswa (Total: $total)');
      
      setState(() {
        _mahasiswaList = mahasiswa;
        _totalItems = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [KelolaMahasiswa] Error loading mahasiswa: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        _showErrorToast('Gagal memuat data mahasiswa: ${e.toString()}');
      }
    }
  }

  Future<void> _loadFilterOptions() async {
    debugPrint('🔥 [KelolaMahasiswa] Loading filter options...');
    
    try {
      final fakultas = await _mahasiswaService.getFakultasList();
      final angkatan = await _mahasiswaService.getAngkatanList();
      
      debugPrint('✅ [KelolaMahasiswa] Fakultas loaded: ${fakultas.length} items');
      debugPrint('✅ [KelolaMahasiswa] Angkatan loaded: ${angkatan.length} items');
      
      setState(() {
        _fakultasList = ['Semua', ...fakultas];
        _angkatanList = ['Semua', ...angkatan];
      });
    } catch (e) {
      debugPrint('❌ [KelolaMahasiswa] Error loading filter options: $e');
    }
  }

  // ============================================================================
  // CSV IMPORT METHODS
  // ============================================================================

  Future<void> _onImportCSV() async {
    debugPrint('📥 [KelolaMahasiswa] Import CSV button pressed');
    
    try {
      // Step 1: Pick file
      final fileResult = await _importService.pickCSVFile();
      
      if (fileResult == null || fileResult.files.isEmpty) {
        debugPrint('⚠️ [KelolaMahasiswa] No file selected');
        return;
      }
      
      final file = fileResult.files.first;
      debugPrint('✅ [KelolaMahasiswa] File selected: ${file.name}');
      
      // Show loading
      if (mounted) {
        _showImportLoadingDialog();
      }
      
      // Step 2: Parse and validate CSV
      final validationResult = await _importService.parseAndValidateCSV(file.bytes!);
      
      debugPrint('📊 [KelolaMahasiswa] Validation complete:');
      debugPrint('   Valid: ${validationResult.validItems.length}');
      debugPrint('   Duplicates: ${validationResult.duplicateItems.length}');
      debugPrint('   Errors: ${validationResult.errors.length}');
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Step 3: Show preview dialog
      if (mounted) {
        _showImportPreviewDialog(validationResult);
      }
      
    } catch (e) {
      debugPrint('❌ [KelolaMahasiswa] Import error: $e');
      
      // Close loading if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        _showErrorToast('Gagal memproses file CSV: ${e.toString()}');
      }
    }
  }

  void _showImportLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
                SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
                Text(
                  'Memproses file CSV...',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontBody(),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: ResponsiveAdmin.spaceXS()),
                Text(
                  'Mohon tunggu sebentar',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontSmall(),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImportPreviewDialog(ImportValidationResult validationResult) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MahasiswaImportDialog(
        validationResult: validationResult,
        onConfirmImport: _executeImport,
      ),
    );
  }

  Future<void> _executeImport(
    List<MahasiswaImportItem> items,
    bool replaceAll,
  ) async {
    debugPrint('🚀 [KelolaMahasiswa] Executing import...');
    debugPrint('   Items to import: ${items.length}');
    debugPrint('   Replace mode: $replaceAll');
    
    setState(() => _isImporting = true);
    
    // Show progress dialog
    _showImportProgressDialog();
    
    try {
      final result = await _importService.importMahasiswa(
        items: items,
        replaceExisting: replaceAll,
      );
      
      debugPrint('✅ [KelolaMahasiswa] Import complete');
      debugPrint('   Success: ${result.successCount}');
      debugPrint('   Failed: ${result.failedCount}');
      
      // Close progress dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      setState(() => _isImporting = false);
      
      // Reload data
      await _loadMahasiswa();
      await _loadFilterOptions();
      
      // Show result
      if (mounted) {
        if (result.allSuccess) {
          _showSuccessToast(
            'Import berhasil! ${result.successCount} mahasiswa ditambahkan/diupdate'
          );
        } else if (result.hasFailures) {
          _showImportResultDialog(result);
        }
      }
      
    } catch (e) {
      debugPrint('❌ [KelolaMahasiswa] Import execution error: $e');
      
      // Close progress dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      setState(() => _isImporting = false);
      
      if (mounted) {
        _showErrorToast('Gagal mengimport data: ${e.toString()}');
      }
    }
  }

  void _showImportProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
                SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
                Text(
                  'Mengimport data...',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontBody(),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: ResponsiveAdmin.spaceXS()),
                Text(
                  'Proses ini mungkin memakan waktu',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontSmall(),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImportResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Icon(
              result.failedCount > result.successCount
                  ? Icons.warning_rounded
                  : Icons.check_circle_rounded,
              color: result.failedCount > result.successCount
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
            ),
            SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
            const Text('Hasil Import'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Berhasil: ${result.successCount} data'),
            Text('❌ Gagal: ${result.failedCount} data'),
            if (result.failedItems.isNotEmpty) ...[
              SizedBox(height: ResponsiveAdmin.spaceSM()),
              const Text(
                'Detail error:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: ResponsiveAdmin.spaceXS()),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: result.failedItems
                        .map((item) => Padding(
                              padding: EdgeInsets.only(
                                bottom: ResponsiveAdmin.spaceXS(),
                              ),
                              child: Text(
                                '• $item',
                                style: TextStyle(
                                  fontSize: ResponsiveAdmin.fontSmall(),
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  void _onSearchChanged(String value) {
    debugPrint('🔍 [KelolaMahasiswa] Search query changed: "$value"');
    
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value && mounted) {
        debugPrint('🔍 [KelolaMahasiswa] Executing search: "$value"');
        setState(() {
          _searchQuery = value;
          _currentPage = 0;
        });
        _loadMahasiswa();
      }
    });
  }

  void _onFilterChanged() {
    debugPrint('🔄 [KelolaMahasiswa] Filter changed, resetting to page 0');
    setState(() => _currentPage = 0);
    _loadMahasiswa();
  }

  void _onPageChanged(int newPage) {
    debugPrint('📄 [KelolaMahasiswa] Page changed: $newPage');
    setState(() => _currentPage = newPage);
    _loadMahasiswa();
  }

  void _onRefresh() {
    debugPrint('🔄 [KelolaMahasiswa] Manual refresh triggered');
    _loadMahasiswa();
  }

  void _onAddMahasiswa() {
    debugPrint('➕ [KelolaMahasiswa] Add mahasiswa button pressed');
    _showMahasiswaDialog(null);
  }

  void _onEditMahasiswa(MahasiswaModel mahasiswa) {
    debugPrint('✏️ [KelolaMahasiswa] Edit mahasiswa: ${mahasiswa.nim}');
    _showMahasiswaDialog(mahasiswa);
  }

  void _onDeleteMahasiswa(MahasiswaModel mahasiswa) {
    debugPrint('🗑️ [KelolaMahasiswa] Delete mahasiswa: ${mahasiswa.nim}');
    _showDeleteConfirmation(mahasiswa);
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
      child: Column(
        children: [
          // Header dengan Import button
          _buildEnhancedHeader(),
          
          SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
          
          // Filter Bar
          MahasiswaFilterBar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            filterFakultas: _filterFakultas,
            filterAngkatan: _filterAngkatan,
            filterStatus: _filterStatus,
            fakultasList: _fakultasList,
            angkatanList: _angkatanList,
            onFakultasChanged: (value) {
              debugPrint('🔄 [KelolaMahasiswa] Fakultas filter: $value');
              setState(() => _filterFakultas = value!);
              _onFilterChanged();
            },
            onAngkatanChanged: (value) {
              debugPrint('🔄 [KelolaMahasiswa] Angkatan filter: $value');
              setState(() => _filterAngkatan = value!);
              _onFilterChanged();
            },
            onStatusChanged: (value) {
              debugPrint('🔄 [KelolaMahasiswa] Status filter: $value');
              setState(() => _filterStatus = value!);
              _onFilterChanged();
            },
          ),
          
          SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
          
          // List
          Expanded(
            child: MahasiswaList(
              mahasiswaList: _mahasiswaList,
              isLoading: _isLoading,
              searchQuery: _searchQuery,
              hasActiveFilters: _filterFakultas != 'Semua' || 
                               _filterAngkatan != 'Semua' || 
                               _filterStatus != 'Semua',
              onRefresh: _loadMahasiswa,
              onEdit: _onEditMahasiswa,
              onDelete: _onDeleteMahasiswa,
            ),
          ),
          
          // Pagination
          if (_totalItems > _itemsPerPage) ...[
            SizedBox(height: ResponsiveAdmin.spaceSM() + 4),
            MahasiswaPagination(
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

  Widget _buildEnhancedHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
          ),
          
          SizedBox(width: ResponsiveAdmin.spaceSM() + 4),
          
          // Title & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Mahasiswa',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontH4(),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: ResponsiveAdmin.spaceXS() - 2),
                Text(
                  '$_totalItems mahasiswa terdaftar',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontSmall(),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              // Import CSV Button
              ElevatedButton.icon(
                onPressed: _isImporting ? null : _onImportCSV,
                icon: const Icon(Icons.upload_file_rounded, size: 15),
                label: Text(
                  'Import CSV',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontCaption() + 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveAdmin.spaceSM() + 4,
                    vertical: ResponsiveAdmin.spaceXS() + 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                  ),
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                ),
              ),
              
              SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
              
              // Refresh Button
              IconButton(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF6B7280),
                  padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 2),
                  minimumSize: const Size(32, 32),
                ),
                tooltip: 'Refresh Data',
              ),
              
              SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
              
              // Tambah Button
              ElevatedButton.icon(
                onPressed: _onAddMahasiswa,
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(
                  'Tambah Mahasiswa',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontCaption() + 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveAdmin.spaceSM() + 6,
                    vertical: ResponsiveAdmin.spaceXS() + 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                  ),
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DIALOG METHODS
  // ============================================================================

  void _showMahasiswaDialog(MahasiswaModel? mahasiswa) {
    debugPrint('📝 [KelolaMahasiswa] Opening form dialog for: ${mahasiswa?.nim ?? "NEW"}');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MahasiswaFormDialog(
        mahasiswa: mahasiswa,
        fakultasList: _fakultasList.where((f) => f != 'Semua').toList(),
        angkatanList: _angkatanList.where((a) => a != 'Semua').toList(),
        onSuccess: () {
          debugPrint('✅ [KelolaMahasiswa] Form dialog success callback');
          _loadMahasiswa();
          _loadFilterOptions();
        },
      ),
    );
  }

  void _showDeleteConfirmation(MahasiswaModel mahasiswa) {
    debugPrint('🗑️ [KelolaMahasiswa] Showing delete confirmation for: ${mahasiswa.nim}');
    
    showDialog(
      context: context,
      builder: (context) => MahasiswaDeleteDialog(
        mahasiswa: mahasiswa,
        onConfirm: () => _deleteMahasiswa(mahasiswa.idMahasiswa, mahasiswa.nim),
      ),
    );
  }

  // ============================================================================
  // DELETE METHOD
  // ============================================================================

  Future<void> _deleteMahasiswa(String idMahasiswa, String nim) async {
    debugPrint('🗑️ [KelolaMahasiswa] Starting delete process...');
    debugPrint('   ID: $idMahasiswa');
    debugPrint('   NIM: $nim');
    
    try {
      await _mahasiswaService.deleteMahasiswa(idMahasiswa, hardDelete: true);
      
      debugPrint('✅ [KelolaMahasiswa] Delete successful for NIM: $nim');
      
      if (mounted) {
        _showSuccessToast('Mahasiswa "$nim" berhasil dihapus');
        await _loadMahasiswa();
      }
    } catch (e) {
      debugPrint('❌ [KelolaMahasiswa] Delete failed for NIM: $nim');
      debugPrint('   Error: $e');
      
      if (mounted) {
        _showErrorToast('Gagal menghapus mahasiswa: ${e.toString()}');
      }
    }
  }

  // ============================================================================
  // TOAST NOTIFICATION METHODS
  // ============================================================================

  void _showSuccessToast(String message) {
    if (!mounted) return;
    
    debugPrint('✅ [KelolaMahasiswa] Success toast: $message');
    
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
    
    debugPrint('❌ [KelolaMahasiswa] Error toast: $message');
    
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