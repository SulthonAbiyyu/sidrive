import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/services/mahasiswa_service.dart';
import 'package:sidrive/models/mahasiswa_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

/// ============================================================================
/// MAHASISWA FORM DIALOG - PRODUCTION READY + UMSIDA DATA
/// ============================================================================
/// - Overflow fixed dengan Column layout
/// - Dynamic year generation (auto-update setiap tahun)
/// - Professional validation
/// - Clean UI dengan proper spacing
/// - Program Studi & Fakultas menggunakan data resmi UMSIDA
/// - Dropdown Program Studi terfilter berdasarkan Fakultas
/// ============================================================================

// ============================================================================
// UMSIDA DATA CONSTANTS
// ============================================================================
class UmsidaData {
  static const List<String> fakultasList = [
    'Fakultas Agama Islam',
    'Fakultas Sains dan Teknologi',
    'Fakultas Bisnis, Hukum dan Ilmu Sosial',
    'Fakultas Psikologi dan Ilmu Pendidikan',
    'Fakultas Ilmu Kesehatan',
    'Fakultas Kedokteran',
    'Fakultas Kedokteran Gigi',
  ];

  static const Map<String, List<String>> prodiPerFakultas = {
    'Fakultas Agama Islam': [
      'Pendidikan Agama Islam',
      'Perbankan Syariah',
      'Hukum Keluarga Islam',
      'Komunikasi Penyiaran Islam',
    ],
    'Fakultas Sains dan Teknologi': [
      'Teknik Sipil',
      'Teknik Elektro',
      'Teknik Industri',
      'Teknik Mesin',
      'Informatika',
      'Arsitektur',
      'Perencanaan Wilayah dan Kota',
    ],
    'Fakultas Bisnis, Hukum dan Ilmu Sosial': [
      'Manajemen',
      'Akuntansi',
      'Ilmu Komunikasi',
      'Administrasi Publik',
      'Hukum',
      'Bisnis Digital',
    ],
    'Fakultas Psikologi dan Ilmu Pendidikan': [
      'Psikologi',
      'Pendidikan Guru PAUD',
      'Pendidikan Guru SD',
      'Pendidikan Bahasa Inggris',
      'Pendidikan IPA',
      'Pendidikan Teknologi Informasi',
    ],
    'Fakultas Ilmu Kesehatan': [
      'Kebidanan',
      'Fisioterapi',
      'Teknologi Laboratorium Medis',
      'Manajemen Informasi Kesehatan',
    ],
    'Fakultas Kedokteran': [
      'Kedokteran',
    ],
    'Fakultas Kedokteran Gigi': [
      'Kedokteran Gigi',
    ],
  };

  static List<String> getProdiByFakultas(String? fakultas) {
    if (fakultas == null) return [];
    return prodiPerFakultas[fakultas] ?? [];
  }
}

class MahasiswaFormDialog extends StatefulWidget {
  final MahasiswaModel? mahasiswa;
  final List<String> fakultasList;
  final List<String> angkatanList;
  final VoidCallback onSuccess;

  const MahasiswaFormDialog({
    super.key,
    this.mahasiswa,
    required this.fakultasList,
    required this.angkatanList,
    required this.onSuccess,
  });

  @override
  State<MahasiswaFormDialog> createState() => _MahasiswaFormDialogState();
}

class _MahasiswaFormDialogState extends State<MahasiswaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final MahasiswaService _mahasiswaService = MahasiswaService();
  
  // Controllers
  late TextEditingController _nimController;
  late TextEditingController _namaController;
  
  // Dropdown values
  String? _selectedFakultas;
  String? _selectedProdi;
  String? _selectedAngkatan;
  String _selectedStatus = 'aktif';
  
  // State
  bool _isLoading = false;
  bool get _isEditMode => widget.mahasiswa != null;
  
  // Dynamic Lists
  late List<String> _validAngkatanList;
  List<String> _availableProdiList = [];

  @override
  void initState() {
    super.initState();
    
    debugPrint('📝 [MahasiswaForm] Dialog opened in ${_isEditMode ? "EDIT" : "CREATE"} mode');
    
    // Generate valid angkatan list (auto-update setiap tahun)
    _validAngkatanList = _generateValidAngkatanList();
    
    // Initialize controllers
    _nimController = TextEditingController(
      text: widget.mahasiswa?.nim ?? '',
    );
    _namaController = TextEditingController(
      text: widget.mahasiswa?.namaLengkap ?? '',
    );
    
    // Initialize dropdowns dengan normalisasi nama fakultas
    String? rawFakultas = widget.mahasiswa?.fakultas;
    
    // Normalisasi: Ganti & dengan "dan" untuk backward compatibility
    if (rawFakultas != null) {
      rawFakultas = rawFakultas
          .replaceAll(' & ', ' dan ')
          .replaceAll('&', 'dan');
    }
    
    _selectedFakultas = rawFakultas;
    _selectedProdi = widget.mahasiswa?.programStudi;
    _selectedAngkatan = widget.mahasiswa?.angkatan;
    _selectedStatus = widget.mahasiswa?.statusMahasiswa ?? 'aktif';
    
    // Load prodi list based on fakultas
    if (_selectedFakultas != null) {
      _availableProdiList = UmsidaData.getProdiByFakultas(_selectedFakultas);
    }
    
    if (_isEditMode) {
      debugPrint('   Editing: ${widget.mahasiswa!.nim} - ${widget.mahasiswa!.namaLengkap}');
      debugPrint('   Fakultas (normalized): $_selectedFakultas');
    }
    
    debugPrint('✅ [MahasiswaForm] Valid angkatan range: ${_validAngkatanList.first} - ${_validAngkatanList.last}');
  }

  @override
  void dispose() {
    _nimController.dispose();
    _namaController.dispose();
    debugPrint('📝 [MahasiswaForm] Dialog disposed');
    super.dispose();
  }

  /// ============================================================================
  /// GENERATE VALID ANGKATAN LIST - AUTO UPDATE SETIAP TAHUN
  /// ============================================================================
  /// Formula: Mahasiswa maksimal 14 semester (7 tahun)
  /// Range: (currentYear - 7) sampai currentYear
  /// Contoh 2026: 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026
  /// ============================================================================
  List<String> _generateValidAngkatanList() {
    final currentYear = DateTime.now().year;
    final minYear = currentYear - 7; // 7 tahun yang lalu (14 semester)
    final maxYear = currentYear;
    
    final List<String> years = [];
    for (int year = maxYear; year >= minYear; year--) {
      years.add(year.toString());
    }
    
    debugPrint('📅 [MahasiswaForm] Generated angkatan: $minYear - $maxYear (${years.length} tahun)');
    return years;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusLG()),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520), // Sedikit lebih lebar
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusLG()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(ResponsiveAdmin.spaceLG()),
                  child: _buildForm(),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER - PROFESSIONAL GRADIENT
  // ============================================================================

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ResponsiveAdmin.radiusLG()),
          topRight: Radius.circular(ResponsiveAdmin.radiusLG()),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          SizedBox(width: ResponsiveAdmin.spaceSM()),
          Expanded(
            child: Text(
              _isEditMode ? 'Edit Mahasiswa' : 'Tambah Mahasiswa',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontH4(),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              debugPrint('❌ [MahasiswaForm] Dialog closed by user');
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            padding: EdgeInsets.all(ResponsiveAdmin.spaceXS()),
            constraints: const BoxConstraints(),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // FORM - FIXED OVERFLOW DENGAN COLUMN LAYOUT
  // ============================================================================

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NIM Field
          _buildLabel('NIM', showDisabled: _isEditMode),
          SizedBox(height: ResponsiveAdmin.spaceXS()),
          _buildTextInput(
            controller: _nimController,
            hint: 'Masukkan 12 digit NIM',
            icon: Icons.badge_rounded,
            enabled: !_isEditMode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return 'NIM wajib diisi';
              if (value.length != 12) return 'NIM harus 12 digit';
              return null;
            },
          ),
          
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          
          // Nama Lengkap Field
          _buildLabel('Nama Lengkap'),
          SizedBox(height: ResponsiveAdmin.spaceXS()),
          _buildTextInput(
            controller: _namaController,
            hint: 'Masukkan nama lengkap',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nama wajib diisi';
              if (value.length < 3) return 'Nama minimal 3 karakter';
              return null;
            },
          ),
          
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          
          // Fakultas Dropdown
          _buildLabel('Fakultas'),
          SizedBox(height: ResponsiveAdmin.spaceXS()),
          _buildDropdown(
            value: _selectedFakultas,
            items: UmsidaData.fakultasList,
            hint: 'Pilih Fakultas',
            icon: Icons.domain_rounded,
            onChanged: (value) {
              debugPrint('🔄 [MahasiswaForm] Fakultas selected: $value');
              setState(() {
                _selectedFakultas = value;
                _selectedProdi = null; // Reset prodi when fakultas changes
                _availableProdiList = UmsidaData.getProdiByFakultas(value);
                debugPrint('   Available prodi: $_availableProdiList');
              });
            },
          ),
          
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          
          // Program Studi Dropdown
          _buildLabel('Program Studi'),
          SizedBox(height: ResponsiveAdmin.spaceXS()),
          _buildDropdown(
            value: _selectedProdi,
            items: _availableProdiList,
            hint: _selectedFakultas == null 
                ? 'Pilih Fakultas terlebih dahulu' 
                : 'Pilih Program Studi',
            icon: Icons.school_outlined,
            enabled: _selectedFakultas != null,
            onChanged: (value) {
              debugPrint('🔄 [MahasiswaForm] Prodi selected: $value');
              setState(() => _selectedProdi = value);
            },
          ),
          
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          
          // Angkatan Dropdown
          _buildLabel('Angkatan'),
          SizedBox(height: ResponsiveAdmin.spaceXS()),
          _buildDropdown(
            value: _selectedAngkatan,
            items: _validAngkatanList,
            hint: 'Pilih Angkatan',
            icon: Icons.calendar_today_rounded,
            onChanged: (value) {
              debugPrint('🔄 [MahasiswaForm] Angkatan selected: $value');
              setState(() => _selectedAngkatan = value);
            },
          ),
          
          SizedBox(height: ResponsiveAdmin.spaceMD()),
          
          // Status Dropdown
          _buildLabel('Status Mahasiswa'),
          SizedBox(height: ResponsiveAdmin.spaceXS()),
          _buildDropdown(
            value: _selectedStatus,
            items: const ['aktif', 'cuti', 'lulus', 'keluar'],
            hint: 'Pilih Status',
            icon: Icons.info_outline_rounded,
            onChanged: (value) {
              debugPrint('🔄 [MahasiswaForm] Status selected: $value');
              setState(() => _selectedStatus = value ?? 'aktif');
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // REUSABLE WIDGETS - CLEAN & PROFESSIONAL
  // ============================================================================

  Widget _buildLabel(String text, {bool showDisabled = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveAdmin.fontBody(),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        if (showDisabled) ...[
          SizedBox(width: ResponsiveAdmin.spaceXS()),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveAdmin.spaceXS() + 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              'Tidak dapat diubah',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontCaption(),
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        fontSize: ResponsiveAdmin.fontBody(),
        color: enabled ? const Color(0xFF111827) : const Color(0xFF6B7280),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xFF6B7280), // DARKER HINT - ini yang penting!
          fontSize: ResponsiveAdmin.fontBody(),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          size: 18,
        ),
        filled: true,
        fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveAdmin.spaceSM() + 4,
          vertical: ResponsiveAdmin.spaceSM() + 2,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    // CRITICAL: Validate value exists in items to prevent assertion error
    final validValue = (value != null && items.contains(value)) ? value : null;
    
    if (value != null && !items.contains(value)) {
      debugPrint('⚠️ [Dropdown] Value "$value" not found in items. Setting to null.');
      debugPrint('   Available items: $items');
    }
    
    return DropdownButtonFormField<String>(
      value: validValue,
      dropdownColor: Colors.white,
      style: TextStyle(
        fontSize: ResponsiveAdmin.fontBody(),
        color: const Color(0xFF111827),
        fontWeight: FontWeight.w500,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontBody(),
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: (value) {
        // Validation khusus untuk fakultas dan prodi (wajib)
        if (icon == Icons.domain_rounded && (value == null || value.isEmpty)) {
          return 'Fakultas wajib dipilih';
        }
        if (icon == Icons.school_outlined && (value == null || value.isEmpty)) {
          return 'Program Studi wajib dipilih';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xFF6B7280), // DARKER HINT!
          fontSize: ResponsiveAdmin.fontBody(),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          size: 18,
        ),
        filled: true,
        fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveAdmin.spaceSM() + 4,
          vertical: ResponsiveAdmin.spaceSM() + 2,
        ),
        isDense: true,
      ),
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        color: enabled ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        size: 20,
      ),
      isExpanded: true,
    );
  }

  // ============================================================================
  // FOOTER - ACTION BUTTONS
  // ============================================================================

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel Button
          TextButton(
            onPressed: _isLoading ? null : () {
              debugPrint('❌ [MahasiswaForm] Cancelled by user');
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveAdmin.spaceMD(),
                vertical: ResponsiveAdmin.spaceSM(),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          SizedBox(width: ResponsiveAdmin.spaceSM()),
          
          // Submit Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitForm,
            icon: _isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.7),
                      ),
                    ),
                  )
                : Icon(
                    _isEditMode ? Icons.check_rounded : Icons.add_rounded,
                    size: 14,
                  ),
            label: Text(
              _isLoading 
                  ? 'Memproses...' 
                  : _isEditMode ? 'Update' : 'Simpan',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody(),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF6366F1).withOpacity(0.5),
              disabledForegroundColor: Colors.white.withOpacity(0.7),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveAdmin.spaceMD() + 4,
                vertical: ResponsiveAdmin.spaceSM() + 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SUBMIT FORM - WITH PROFESSIONAL VALIDATION
  // ============================================================================

  Future<void> _submitForm() async {
    debugPrint('📤 [MahasiswaForm] Submit button pressed');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ [MahasiswaForm] Validation failed');
      _showValidationErrorToast();
      return;
    }
    
    setState(() => _isLoading = true);
    
    debugPrint('📤 [MahasiswaForm] Starting ${_isEditMode ? "UPDATE" : "CREATE"} process...');
    debugPrint('   NIM: ${_nimController.text.trim()}');
    debugPrint('   Nama: ${_namaController.text.trim()}');
    debugPrint('   Prodi: $_selectedProdi');
    debugPrint('   Fakultas: $_selectedFakultas');
    debugPrint('   Angkatan: $_selectedAngkatan');
    debugPrint('   Status: $_selectedStatus');
    
    try {
      if (_isEditMode) {
        // UPDATE
        debugPrint('🔄 [MahasiswaForm] Updating mahasiswa ID: ${widget.mahasiswa!.idMahasiswa}');
        
        await _mahasiswaService.updateMahasiswa(
          idMahasiswa: widget.mahasiswa!.idMahasiswa,
          nim: _nimController.text.trim(),
          namaLengkap: _namaController.text.trim(),
          programStudi: _selectedProdi,
          fakultas: _selectedFakultas,
          angkatan: _selectedAngkatan,
          statusMahasiswa: _selectedStatus,
        );
        
        debugPrint('✅ [MahasiswaForm] Update successful');
      } else {
        // CREATE
        debugPrint('➕ [MahasiswaForm] Creating new mahasiswa...');
        
        await _mahasiswaService.createMahasiswa(
          nim: _nimController.text.trim(),
          namaLengkap: _namaController.text.trim(),
          programStudi: _selectedProdi,
          fakultas: _selectedFakultas,
          angkatan: _selectedAngkatan,
          statusMahasiswa: _selectedStatus,
        );
        
        debugPrint('✅ [MahasiswaForm] Create successful');
      }
      
      if (mounted) {
        Navigator.pop(context);
        _showSuccessToastInParent();
        widget.onSuccess();
      }
    } catch (e) {
      debugPrint('❌ [MahasiswaForm] ${_isEditMode ? "Update" : "Create"} failed');
      debugPrint('   Error: $e');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        _showErrorToastInDialog(e.toString());
      }
    }
  }

  // ============================================================================
  // TOAST NOTIFICATIONS - CLEAN UI
  // ============================================================================

  void _showValidationErrorToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
            SizedBox(width: ResponsiveAdmin.spaceSM()),
            Expanded(
              child: Text(
                'Mohon periksa kembali form yang Anda isi',
                style: TextStyle(
                  fontSize: ResponsiveAdmin.fontBody(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
        ),
        margin: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorToastInDialog(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 18),
            SizedBox(width: ResponsiveAdmin.spaceSM()),
            Expanded(
              child: Text(
                'Gagal menyimpan: ${error.replaceAll("Exception: ", "")}',
                style: TextStyle(
                  fontSize: ResponsiveAdmin.fontBody(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
        ),
        margin: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessToastInParent() {
    final message = _isEditMode 
        ? 'Data mahasiswa "${_namaController.text.trim()}" berhasil diupdate'
        : 'Mahasiswa "${_namaController.text.trim()}" berhasil ditambahkan';
    
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
                  fontSize: ResponsiveAdmin.fontBody(),
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
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
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
}