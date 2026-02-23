import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/core/widgets/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';
import 'package:sidrive/screens/auth/widgets/request_umkm/umkm_header_info_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_umkm/umkm_info_toko_section.dart';
import 'package:sidrive/screens/auth/widgets/request_umkm/umkm_jam_operasional_section.dart';
import 'package:sidrive/screens/auth/widgets/request_umkm/umkm_upload_section.dart';
import 'package:sidrive/screens/auth/widgets/request_umkm/umkm_existing_status_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_umkm/umkm_appbar_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_umkm/umkm_lokasi_toko_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_umkm/umkm_bank_form_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_umkm/umkm_terms_condition_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:sidrive/screens/umkm/pages/umkm_map_picker.dart';


class RequestUmkmRoleScreen extends StatefulWidget {
  const RequestUmkmRoleScreen({super.key});

  @override
  State<RequestUmkmRoleScreen> createState() => _RequestUmkmRoleScreenState();
}

class _RequestUmkmRoleScreenState extends State<RequestUmkmRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  
  // Controllers
  final _namaTokoController = TextEditingController();
  final _alamatTokoController = TextEditingController();
  final _deskripsiTokoController = TextEditingController();
  final _nomorRekeningController = TextEditingController();
  final _namaRekeningController = TextEditingController();
  
  // State
  String _kategoriToko = 'makanan';
  String? _namaBank; // ✅ CHANGED: Dari controller ke nullable String
  TimeOfDay _jamBuka = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamTutup = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = false;
  bool _isCheckingExisting = true;
  bool _hasBankData = false; // ✅ NEW: Track apakah sudah ada data bank
  bool _hasAgreedToTerms = false; // ✅ NEW: S&K wajib setuju sebelum submit
  LatLng? _lokasiToko;
  String _lokasiTokoAddress = '';
  
  // Files
  File? _fotoToko;
  List<File> _fotoProduk = [];
  
  XFile? _xFileFotoToko;
  List<XFile> _xFileFotoProduk = [];
  
  final _picker = ImagePicker();
  
  // Existing UMKM check
  bool _hasExistingUmkm = false;
  String? _existingStatus;
  
  final List<String> _kategoriList = [
    'makanan',
    'minuman',
    'fashion',
    'elektronik',
    'kesehatan',
    'kecantikan',
    'olahraga',
    'buku',
    'lainnya',
  ];

  final List<String> _bankList = [
    'BCA',
    'BRI',
    'Bank Jago',
    'Bank Jatim',
    'Bank Mega',
    'BJB (Bank Jabar Banten)',
    'Blu by BCA Digital',
    'BNI',
    'BSI (Bank Syariah Indonesia)',
    'BTN',
    'Bukopin',
    'CIMB Niaga',
    'Danamon',
    'Jenius (BTPN)',
    'Mandiri',
    'Maybank',
    'Muamalat',
    'Neo Commerce (Bank Neo)',
    'OCBC NISP',
    'Panin Bank',
    'Permata Bank',
    'SeaBank',
    'Allo Bank',
    'Bank Raya',
    'Digibank (DBS)',
    'Flip',
    'Ovo (Bank Ovo)',
    'Sakuku (BCA)',
    'Bank Aceh Syariah',
    'Bank Muamalat',
    'Bank Syariah Bukopin',
    'BRIS (BRI Syariah)',
    'BNIS (BNI Syariah)',
    'Bank DKI',
    'Bank Kalbar',
    'Bank Kalteng',
    'Bank Kaltim',
    'Bank NTB Syariah',
    'Bank NTT',
    'Bank Papua',
    'Bank Riau Kepri',
    'Bank Sulselbar',
    'Bank Sumsel Babel',
    'Bank Sumut',
    'BPD Bali',
    'BPD DIY',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 [RequestUmkm] Screen initialized');
    _checkExistingUmkm();
    _loadBankInfo();
  }

  @override
  void dispose() {
    debugPrint('📚 [RequestUmkm] Disposing controllers');
    _namaTokoController.dispose();
    _alamatTokoController.dispose();
    _deskripsiTokoController.dispose();
    _nomorRekeningController.dispose();
    _namaRekeningController.dispose();
    super.dispose();
  }

  // ========================================================================
  // CHECK EXISTING UMKM - FIXED VERSION 🔥
  // ========================================================================
  
  Future<void> _checkExistingUmkm() async {
    debugPrint('🔍 [RequestUmkm] Checking existing UMKM...');
    
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) {
      debugPrint('❌ [RequestUmkm] User not found');
      setState(() => _isCheckingExisting = false);
      return;
    }
    
    try {
      debugPrint('📊 [RequestUmkm] Fetching UMKM data for user: ${user.idUser}');
      
      final umkmData = await _supabase
          .from('umkm')
          .select('id_umkm, nama_toko')
          .eq('id_user', user.idUser)
          .maybeSingle();
      
      if (umkmData != null) {
        debugPrint('✅ [RequestUmkm] Existing UMKM found: ${umkmData['nama_toko']}');
        
        // Cek status dari user_roles
        final roleData = await _supabase
            .from('user_roles')
            .select('status')
            .eq('id_user', user.idUser)
            .eq('role', 'umkm')
            .eq('is_active', true)
            .maybeSingle();
        
        if (roleData != null) {
          final status = roleData['status'] as String;
          
          if (status == 'rejected') {
            debugPrint('🗑️ [RequestUmkm] Status rejected - deleting old data...');
            
            await _supabase.from('umkm').delete().eq('id_user', user.idUser);
            await _supabase.from('user_roles').delete().eq('id_user', user.idUser).eq('role', 'umkm');
            
            setState(() {
              _hasExistingUmkm = false;
              _existingStatus = null;
            });
          } else {
            setState(() {
              _hasExistingUmkm = true;
              _existingStatus = status;
            });
          }
        }
      } else {
        debugPrint('ℹ️ [RequestUmkm] No existing UMKM record');
        setState(() {
          _hasExistingUmkm = false;
          _existingStatus = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [RequestUmkm] Error checking UMKM: $e');
      debugPrint('📚 [RequestUmkm] Stack trace: $stackTrace');
      
      // JANGAN TAMPILKAN WARNING! Langsung set false biar form bisa diisi
      setState(() {
        _hasExistingUmkm = false;
        _existingStatus = null;
      });
    } finally {
      setState(() => _isCheckingExisting = false);
      debugPrint('✅ [RequestUmkm] Check existing UMKM completed');
    }
  }

  Future<void> _loadBankInfo() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) return;
    
    try {
      final userData = await _supabase
          .from('users')
          .select('nama_bank, nomor_rekening, nama_rekening')
          .eq('id_user', user.idUser)
          .single();
      
      if (mounted && userData['nama_bank'] != null) {
        setState(() {
          _namaBank = userData['nama_bank'] ?? null;
          _nomorRekeningController.text = userData['nomor_rekening'] ?? '';
          _namaRekeningController.text = userData['nama_rekening'] ?? '';
          _hasBankData = true; // ✅ Mark that user has bank data
        });
        debugPrint('✅ Bank info auto-filled from users table');
      }
    } catch (e) {
      debugPrint('ℹ️ No existing bank info: $e');
    }
  }

  // ========================================================================
  // IMAGE PICKING
  // ========================================================================
  
  Future<void> _pickFotoToko() async {
    debugPrint('📸 [RequestUmkm] Picking foto toko');
    
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        debugPrint('✅ [RequestUmkm] Foto toko picked: ${pickedFile.name}');
        setState(() {
          _xFileFotoToko = pickedFile;
          _fotoToko = File(pickedFile.path);
        });
        
        if (mounted) {
          _showSuccessSnackBar('Foto toko berhasil dipilih');
        }
      } else {
        debugPrint('ℹ️ [RequestUmkm] Picker cancelled');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [RequestUmkm] Error picking foto toko: $e');
      debugPrint('📚 Stack: $stackTrace');
      
      if (mounted) {
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Gagal Memilih Foto',
          message: 'Pastikan Anda memberikan izin akses galeri.',
        );
      }
    }
  }

  Future<void> _pickFotoProduk() async {
    if (_fotoProduk.length >= 5) {
      _showErrorSnackBar('Maksimal 5 foto produk');
      return;
    }
    
    debugPrint('📸 [RequestUmkm] Picking foto produk');
    
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        debugPrint('✅ [RequestUmkm] Foto produk picked: ${pickedFile.name}');
        setState(() {
          _xFileFotoProduk.add(pickedFile);
          _fotoProduk.add(File(pickedFile.path));
        });
        
        if (mounted) {
          _showSuccessSnackBar('Foto produk ditambahkan (${_fotoProduk.length}/5)');
        }
      }
    } catch (e) {
      debugPrint('❌ [RequestUmkm] Error picking foto produk: $e');
      if (mounted) {
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Gagal Memilih Foto',
          message: 'Pastikan Anda memberikan izin akses galeri.',
        );
      }
    }
  }

  void _removeFotoProduk(int index) {
    debugPrint('🗑️ [RequestUmkm] Removing foto produk at index $index');
    setState(() {
      _fotoProduk.removeAt(index);
      _xFileFotoProduk.removeAt(index);
    });
  }

  // ========================================================================
  // FILE UPLOAD
  // ========================================================================
  
  Future<String?> _uploadFile(XFile? xFile, String bucket, String path) async {
    if (xFile == null) {
      debugPrint('⚠️ [RequestUmkm] Upload skipped - file is null');
      return null;
    }
    
    debugPrint('📤 [RequestUmkm] Uploading file to bucket: $bucket, path: $path');
    
    try {
      final bytes = await xFile.readAsBytes();
      final fileExt = xFile.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$path/$fileName';

      debugPrint('📊 [RequestUmkm] File size: ${bytes.length} bytes');

      await _supabase.storage.from(bucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);
      debugPrint('✅ [RequestUmkm] Upload successful');
      
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ [RequestUmkm] Upload failed: $e');
      debugPrint('📚 Stack: $stackTrace');
      return null;
    }
  }

  // ========================================================================
  // TIME PICKER
  // ========================================================================
  
  Future<void> _selectTime(BuildContext context, bool isBuka) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isBuka ? _jamBuka : _jamTutup,
    );
    
    if (picked != null) {
      setState(() {
        if (isBuka) {
          _jamBuka = picked;
        } else {
          _jamTutup = picked;
        }
      });
    }
  }

  Future<void> _pickLokasiToko() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => UmkmMapPicker(
          initialLocation: _lokasiToko,
          initialAddress: _lokasiTokoAddress,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lokasiToko = result['location'] as LatLng?;
        _lokasiTokoAddress = result['address'] as String? ?? '';
      });
      
      debugPrint('✅ Lokasi toko dipilih: $_lokasiTokoAddress');
    }
  }

  // ========================================================================
  // SUBMIT FORM - FIXED VERSION 🔥
  // ========================================================================
  
  Future<void> _submitForm() async {
    debugPrint('🚀 [RequestUmkm] Starting form submission...');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('⚠️ [RequestUmkm] Form validation failed');
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Data Tidak Lengkap',
        message: 'Mohon lengkapi semua data toko dengan benar.',
      );
      return;
    }

    // 🔥 FIX: Single declaration of authProvider and user
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) {
      ErrorDialogUtils.showErrorDialog(
        context: context,
        title: 'Sesi Berakhir',
        message: 'Sesi Anda telah berakhir. Silakan login kembali.',
        onAction: () => Navigator.pop(context),
      );
      return;
    }

    if (_fotoToko == null) {
      debugPrint('⚠️ [RequestUmkm] Foto toko not uploaded');
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Foto Toko Belum Dipilih',
        message: 'Harap upload foto tampak depan toko Anda.',
      );
      return;
    }
    
    if (_fotoProduk.isEmpty) {
      debugPrint('⚠️ [RequestUmkm] Foto produk not uploaded');
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Foto Produk Belum Dipilih',
        message: 'Harap upload minimal 1 foto produk sample.',
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('⏳ [RequestUmkm] Loading state activated');

    try {
      // CEK APAKAH ROLE UMKM SUDAH ADA
      debugPrint('🔍 [RequestUmkm] Checking existing UMKM role...');
      
      final hasUmkmRole = authProvider.hasRole('umkm');
      debugPrint('📊 [RequestUmkm] Has UMKM role: $hasUmkmRole');
      
      // STEP 1: UPLOAD DOCUMENTS
      debugPrint('📊 [RequestUmkm] Step 1: Uploading documents...');
      
      // Upload foto toko
      final fotoTokoUrl = await _uploadFile(
        _xFileFotoToko,
        'store-images',
        'toko/${user.idUser}'
      );
      
      if (fotoTokoUrl == null) {
        throw Exception('Gagal upload foto toko. Periksa koneksi internet Anda.');
      }

      debugPrint('✅ [RequestUmkm] Foto toko uploaded: $fotoTokoUrl');

      // Upload foto produk
      List<String> fotoProdukUrls = [];
      for (int i = 0; i < _xFileFotoProduk.length; i++) {
        debugPrint('📤 [RequestUmkm] Uploading foto produk ${i + 1}/${_xFileFotoProduk.length}');
        final url = await _uploadFile(
          _xFileFotoProduk[i],
          'product-images',
          'produk/${user.idUser}'
        );
        if (url != null) {
          fotoProdukUrls.add(url);
        }
      }

      if (fotoProdukUrls.isEmpty) {
        throw Exception('Gagal upload foto produk. Periksa koneksi internet Anda.');
      }

      debugPrint('✅ [RequestUmkm] All documents uploaded successfully');

      // STEP 2: ADD ROLE DULU SEBELUM INSERT DATA UMKM
      debugPrint('📊 [RequestUmkm] Step 2: Adding/Verifying UMKM role...');
      
      if (!hasUmkmRole) {
        debugPrint('➕ [RequestUmkm] Adding new UMKM role...');
        
        final roleAdded = await authProvider.addRole('umkm');
        
        if (!roleAdded) {
          throw Exception('Gagal menambahkan role UMKM. Silakan coba lagi.');
        }
        
        debugPrint('✅ [RequestUmkm] UMKM role added successfully');
      } else {
        debugPrint('ℹ️ [RequestUmkm] UMKM role already exists, skipping addRole()');
      }

      // STEP 3: INSERT DATA UMKM SETELAH ROLE BERHASIL
      debugPrint('📊 [RequestUmkm] Step 3: Inserting UMKM data...');

      String? lokasiTokoPoint;
      String? alamatTokoLengkap;

      if (_lokasiToko != null) {
        // Format sebagai POINT geometry untuk PostGIS
        lokasiTokoPoint = 'POINT(${_lokasiToko!.longitude} ${_lokasiToko!.latitude})';
        alamatTokoLengkap = _lokasiTokoAddress.isNotEmpty 
            ? _lokasiTokoAddress 
            : _alamatTokoController.text.trim();
        
        debugPrint('📍 Lokasi toko POINT: $lokasiTokoPoint');
        debugPrint('📍 Alamat lengkap: $alamatTokoLengkap');
      }
      
      final umkmData = {
        'id_user': user.idUser,
        'nama_toko': _namaTokoController.text.trim(),
        'alamat_toko': _alamatTokoController.text.trim(),
        'alamat_toko_lengkap': alamatTokoLengkap,
        'lokasi_toko': lokasiTokoPoint,
        'deskripsi_toko': _deskripsiTokoController.text.trim().isEmpty 
            ? null 
            : _deskripsiTokoController.text.trim(),
        'foto_toko': fotoTokoUrl,
        'kategori_toko': _kategoriToko,
        'jam_buka': '${_jamBuka.hour.toString().padLeft(2, '0')}:${_jamBuka.minute.toString().padLeft(2, '0')}:00',
        'jam_tutup': '${_jamTutup.hour.toString().padLeft(2, '0')}:${_jamTutup.minute.toString().padLeft(2, '0')}:00',
        'status_toko': 'tutup',
        'rating_toko': 0.0,
        'total_rating': 0,
        'total_penjualan': 0.0,
        'jumlah_produk_terjual': 0,
        'foto_produk_sample': fotoProdukUrls,
        // Bank info langsung di tabel umkm (sesuai schema DB)
        'nama_bank': _namaBank, // ✅ Use dropdown value
        'nomor_rekening': _nomorRekeningController.text.trim().isNotEmpty 
            ? _nomorRekeningController.text.trim() 
            : null,
        'nama_rekening': _namaRekeningController.text.trim().isNotEmpty 
            ? _namaRekeningController.text.trim() 
            : null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('📋 [RequestUmkm] Data to insert:');
      debugPrint('   - ID User: ${user.idUser}');
      debugPrint('   - Nama Toko: ${_namaTokoController.text.trim()}');
      
      final insertResult = await _supabase
          .from('umkm')
          .insert(umkmData)
          .select()
          .single();

      debugPrint('✅ [RequestUmkm] UMKM data inserted successfully!');
      debugPrint('   - ID UMKM: ${insertResult['id_umkm']}');

      setState(() => _isLoading = false);
      debugPrint('🎉 [RequestUmkm] REGISTRATION COMPLETED SUCCESSFULLY!');

      if (!mounted) return;

      await ErrorDialogUtils.showSuccessDialog(
        context: context,
        title: 'Berhasil! 🎉',
        message: 'Pengajuan toko UMKM berhasil dikirim!\n\n'
            'Tim kami akan memverifikasi toko Anda dalam waktu maksimal 1x24 jam. '
            'Anda akan mendapat notifikasi setelah verifikasi selesai.\n\n'
            'Sementara itu, Anda dapat melihat dashboard UMKM namun belum bisa mengelola toko.',
        actionText: 'OK, Mengerti',
        onAction: () => Navigator.pop(context),
      );

    } catch (e, stackTrace) {
      debugPrint('❌ [RequestUmkm] SUBMISSION FAILED: $e');
      debugPrint('📚 Stack: $stackTrace');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        if (errorMessage.contains('duplicate key') || 
            errorMessage.contains('already')) {
          errorMessage = 'Data UMKM Anda sudah terdaftar. Silakan hubungi admin jika ada masalah.';
        } else if (errorMessage.contains('foreign key')) {
          errorMessage = 'Terjadi kesalahan data. Silakan coba lagi atau hubungi admin.';
        } else if (errorMessage.contains('connection') || 
                  errorMessage.contains('network') ||
                  errorMessage.contains('internet')) {
          errorMessage = 'Koneksi internet terputus. Periksa koneksi Anda dan coba lagi.';
        } else if (errorMessage.contains('timeout')) {
          errorMessage = 'Waktu tunggu habis. Periksa koneksi internet Anda dan coba lagi.';
        } else if (errorMessage.contains('upload')) {
          errorMessage = 'Gagal upload foto. Periksa koneksi internet dan ukuran file.';
        }
        
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Gagal Mengirim Pengajuan',
          message: errorMessage,
        );
      }
    }
  }

  // ========================================================================
  // SNACKBAR HELPERS
  // ========================================================================
  
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ========================================================================
  // BUILD UI
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isCheckingExisting) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: UmkmAppBarWidget(
          title: 'Daftar Toko UMKM',
          onBack: () => Navigator.pop(context),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
              ),
              ResponsiveMobile.vSpace(16),
              Text(
                'Memuat data...',
                style: TextStyle(
                  fontSize: ResponsiveMobile.bodySize(context),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Already registered state
    if (_hasExistingUmkm) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: UmkmAppBarWidget(
          title: 'Daftar Toko UMKM',
          onBack: () => Navigator.pop(context),
        ),
        body: UmkmExistingStatusWidget(
          status: _existingStatus ?? 'pending_verification',
          onBack: () => Navigator.pop(context),
        ),
      );
    }

    // Main form
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: UmkmAppBarWidget(
        title: 'Daftar Toko UMKM',
        onBack: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: ResponsiveMobile.horizontalPadding(context, 4),
          children: [
            ResponsiveMobile.vSpace(20),
            
            const UmkmHeaderInfoWidget(),
            ResponsiveMobile.vSpace(24),
            
            _buildSectionTitle('Informasi Toko'),
            ResponsiveMobile.vSpace(16),
            UmkmInfoTokoSection(
              namaTokoController: _namaTokoController,
              alamatTokoController: _alamatTokoController,
              deskripsiTokoController: _deskripsiTokoController,
              kategoriToko: _kategoriToko,
              kategoriList: _kategoriList,
              onKategoriChanged: (value) => setState(() => _kategoriToko = value!),
            ),
            ResponsiveMobile.vSpace(24),

            _buildSectionTitle('Lokasi Toko'),
            ResponsiveMobile.vSpace(16),
            UmkmLokasiTokoWidget(
              lokasiToko: _lokasiToko,
              lokasiTokoAddress: _lokasiTokoAddress,
              onPickLokasi: _pickLokasiToko,
            ),
            ResponsiveMobile.vSpace(24),
            
            _buildSectionTitle('Jam Operasional'),
            ResponsiveMobile.vSpace(16),
            UmkmJamOperasionalSection(
              jamBuka: _jamBuka,
              jamTutup: _jamTutup,
              onSelectTime: _selectTime,
            ),
            ResponsiveMobile.vSpace(24),
            
            _buildSectionTitle('Upload Foto'),
            ResponsiveMobile.vSpace(16),
            UmkmUploadSection(
              fotoToko: _fotoToko,
              fotoProduk: _fotoProduk,
              onPickFotoToko: _pickFotoToko,
              onPickFotoProduk: _pickFotoProduk,
              onRemoveFotoProduk: _removeFotoProduk,
            ),
            ResponsiveMobile.vSpace(24),
            
            _buildSectionTitle('Informasi Bank (Opsional) 💳'),
            ResponsiveMobile.vSpace(8),
            Text(
              'Untuk pencairan saldo penghasilan Anda',
              style: TextStyle(
                fontSize: ResponsiveMobile.captionSize(context),
                color: Colors.grey.shade600,
              ),
            ),
            ResponsiveMobile.vSpace(16),
            UmkmBankFormWidget(
              hasBankData: _hasBankData,
              namaBank: _namaBank,
              nomorRekeningController: _nomorRekeningController,
              namaRekeningController: _namaRekeningController,
              bankList: _bankList,
              onBankChanged: (value) => setState(() => _namaBank = value),
            ),
            ResponsiveMobile.vSpace(24),

            // ── S&K Banner ──
            _buildTermsBanner(context),
            ResponsiveMobile.vSpace(16),

            SizedBox(
              height: ResponsiveMobile.minTouchTargetSize(context),
              child: Opacity(
                opacity: _hasAgreedToTerms ? 1.0 : 0.45,
                child: CustomButton(
                  text: 'Kirim Pengajuan',
                  onPressed: _hasAgreedToTerms ? _submitForm : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.warning_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Baca & setujui Syarat dan Ketentuan UMKM terlebih dahulu',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  isLoading: _isLoading,
                ),
              ),
            ),
            ResponsiveMobile.vSpace(32),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsBanner(BuildContext context) {
    return InkWell(
      onTap: () async {
        final agreed = await showUmkmTermsConditionDialog(context: context);
        if (agreed) {
          setState(() => _hasAgreedToTerms = true);
        }
      },
      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: ResponsiveMobile.allScaledPadding(12),
        decoration: BoxDecoration(
          color: _hasAgreedToTerms ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
          border: Border.all(
            color: _hasAgreedToTerms ? Colors.green.shade300 : Colors.orange.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hasAgreedToTerms
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _hasAgreedToTerms
                    ? Icons.check_circle_rounded
                    : Icons.gavel_rounded,
                color: _hasAgreedToTerms
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                size: 20,
              ),
            ),
            ResponsiveMobile.hSpace(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasAgreedToTerms
                        ? 'Syarat & Ketentuan Disetujui ✓'
                        : 'Baca & Setujui Syarat dan Ketentuan',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.captionSize(context) + 1,
                      fontWeight: FontWeight.w700,
                      color: _hasAgreedToTerms
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                  ResponsiveMobile.vSpace(2),
                  Text(
                    _hasAgreedToTerms
                        ? 'Kamu sudah menyetujui S&K UMKM SiDrive'
                        : 'Wajib dibaca & disetujui sebelum kirim pengajuan',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.captionSize(context) - 1,
                      color: _hasAgreedToTerms
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _hasAgreedToTerms
                  ? Icons.check_rounded
                  : Icons.chevron_right_rounded,
              color: _hasAgreedToTerms
                  ? Colors.green.shade600
                  : Colors.orange.shade500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ResponsiveMobile.bodySize(context) + 1,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }
}