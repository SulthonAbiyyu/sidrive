// lib/screens/driver/request_driver_role_screen.dart
// ============================================================================
// REQUEST DRIVER ROLE SCREEN - FINAL PERFECT VERSION 🔥
// ============================================================================
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/core/widgets/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';
import 'package:sidrive/screens/auth/widgets/request_driver/driver_appbar_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_driver/driver_header_info_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_driver/driver_vehicle_selection_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_driver/driver_vehicle_forms_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_driver/driver_bank_form_widget.dart';
import 'package:sidrive/screens/auth/widgets/request_driver/driver_terms_condition_widget.dart';

class RequestDriverRoleScreen extends StatefulWidget {
  final String? lockedVehicleType;
  
  const RequestDriverRoleScreen({
    super.key,
    this.lockedVehicleType,
  });

  @override
  State<RequestDriverRoleScreen> createState() => _RequestDriverRoleScreenState();
}

class _RequestDriverRoleScreenState extends State<RequestDriverRoleScreen> {
  final _formKeyMotor = GlobalKey<FormState>();
  final _formKeyMobil = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  
  // Controllers - Motor
  final _platNomorMotorController = TextEditingController();
  final _merkKendaraanMotorController = TextEditingController();
  final _warnaKendaraanMotorController = TextEditingController();
  
  // Controllers - Mobil
  final _platNomorMobilController = TextEditingController();
  final _merkKendaraanMobilController = TextEditingController();
  final _warnaKendaraanMobilController = TextEditingController();
  
  // Controllers - Bank
  String? _namaBank;
  final _nomorRekeningController = TextEditingController();
  final _namaRekeningController = TextEditingController();
  
  // State - Selection
  bool _isMotorSelected = false;
  bool _isMobilSelected = false;
  bool _isMotorLocked = false;
  bool _isMobilLocked = false;
  
  String? _motorLockedReason;
  String? _mobilLockedReason;
  
  bool _isLoading = false;
  bool _isCheckingExisting = true;
  bool _hasBankInfo = false; // ✅ NEW: Track apakah sudah ada bank info
  bool _hasAgreedToTerms = false; // ✅ S&K: wajib setuju sebelum submit
  
  // Files - Motor
  File? _fotoSTNKMotor;
  File? _fotoSIMMotor;
  File? _fotoKendaraanMotor;
  
  XFile? _xFileSTNKMotor;
  XFile? _xFileSIMMotor;
  XFile? _xFileKendaraanMotor;
  
  // Files - Mobil
  File? _fotoSTNKMobil;
  File? _fotoSIMMobil;
  File? _fotoKendaraanMobil;
  
  XFile? _xFileSTNKMobil;
  XFile? _xFileSIMMobil;
  XFile? _xFileKendaraanMobil;
  
  final _picker = ImagePicker();
  
  Timer? _selectionDebounce;

  Map<String, String> _existingVehicles = {};

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
    debugPrint('🚀 [RequestDriverRole] Screen initialized');
    _checkExistingVehicles();
    _loadBankInfo();
  }
  
  @override
  void dispose() {
    debugPrint('🔚 [RequestDriverRole] Disposing controllers');
    _selectionDebounce?.cancel();
    _platNomorMotorController.dispose();
    _merkKendaraanMotorController.dispose();
    _warnaKendaraanMotorController.dispose();
    _platNomorMobilController.dispose();
    _merkKendaraanMobilController.dispose();
    _warnaKendaraanMobilController.dispose();
    _nomorRekeningController.dispose();
    _namaRekeningController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingVehicles() async {
    debugPrint('🔍 [RequestDriverRole] Checking existing vehicles...');
    
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) {
      debugPrint('❌ [RequestDriverRole] User not found - session expired');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ErrorDialogUtils.showErrorDialog(
            context: context,
            title: 'Sesi Berakhir',
            message: 'Silakan login kembali untuk melanjutkan.',
            onAction: () => Navigator.pop(context),
          );
        }
      });
      return;
    }
    
    try {
      debugPrint('📊 [RequestDriverRole] Fetching driver data for user: ${user.idUser}');
      
      final driverData = await _supabase
          .from('drivers')
          .select('id_driver')
          .eq('id_user', user.idUser)
          .maybeSingle();
      
      if (driverData != null) {
        final idDriver = driverData['id_driver'];
        debugPrint('✅ [RequestDriverRole] Driver found: $idDriver');
        
        final vehicles = await _supabase
            .from('driver_vehicles')
            .select('jenis_kendaraan, status_verifikasi')
            .eq('id_driver', idDriver);
        
        debugPrint('🚗 [RequestDriverRole] Found ${vehicles.length} vehicles');
        
        final Map<String, String> vehicleMap = {};
        
        for (var v in vehicles) {
          final jenis = v['jenis_kendaraan'] as String;
          final status = v['status_verifikasi'] as String;
          vehicleMap[jenis] = status;
          debugPrint('   - $jenis: $status');
        }
        
        setState(() {
          _existingVehicles.clear();
          _existingVehicles.addAll(vehicleMap);
          
          if (vehicleMap.containsKey('motor')) {
            _isMotorLocked = true;
            _motorLockedReason = vehicleMap['motor'];
            debugPrint('🔒 [RequestDriverRole] Motor locked: ${_motorLockedReason}');
          }
          
          if (vehicleMap.containsKey('mobil')) {
            _isMobilLocked = true;
            _mobilLockedReason = vehicleMap['mobil'];
            debugPrint('🔒 [RequestDriverRole] Mobil locked: ${_mobilLockedReason}');
          }
          
          if (widget.lockedVehicleType != null) {
            if (widget.lockedVehicleType == 'motor' && !_isMobilLocked) {
              _isMobilSelected = true;
              debugPrint('✅ [RequestDriverRole] Auto-selected Mobil');
            } else if (widget.lockedVehicleType == 'mobil' && !_isMotorLocked) {
              _isMotorSelected = true;
              debugPrint('✅ [RequestDriverRole] Auto-selected Motor');
            }
          }
        });
      } else {
        debugPrint('ℹ️ [RequestDriverRole] No existing driver record');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [RequestDriverRole] Error checking vehicles: $e');
      debugPrint('📚 [RequestDriverRole] Stack trace: $stackTrace');
      
      if (mounted) {
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Peringatan',
          message: 'Tidak dapat memuat data kendaraan yang sudah terdaftar. Silakan coba lagi atau hubungi customer service jika masalah berlanjut.',
        );
      }
    } finally {
      setState(() => _isCheckingExisting = false);
      debugPrint('✅ [RequestDriverRole] Check existing vehicles completed');
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
          _namaBank = userData['nama_bank'];
          _nomorRekeningController.text = userData['nomor_rekening'] ?? '';
          _namaRekeningController.text = userData['nama_rekening'] ?? '';
          _hasBankInfo = true;
        });
        debugPrint('✅ Bank info auto-filled from users table (DISABLED)');
      }
    } catch (e) {
      debugPrint('ℹ️ No existing bank info: $e');
      setState(() {
        _hasBankInfo = false;
      });
    }
  }

  Future<void> _pickImage(String vehicleType, String docType) async {
    debugPrint('📸 [RequestDriverRole] Picking image - Type: $vehicleType, Doc: $docType');
    
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        debugPrint('✅ [RequestDriverRole] Image picked: ${pickedFile.name}');
        
        setState(() {
          if (vehicleType == 'motor') {
            switch (docType) {
              case 'stnk':
                _xFileSTNKMotor = pickedFile;
                _fotoSTNKMotor = File(pickedFile.path);
                break;
              case 'sim':
                _xFileSIMMotor = pickedFile;
                _fotoSIMMotor = File(pickedFile.path);
                break;
              case 'kendaraan':
                _xFileKendaraanMotor = pickedFile;
                _fotoKendaraanMotor = File(pickedFile.path);
                break;
            }
          } else {
            switch (docType) {
              case 'stnk':
                _xFileSTNKMobil = pickedFile;
                _fotoSTNKMobil = File(pickedFile.path);
                break;
              case 'sim':
                _xFileSIMMobil = pickedFile;
                _fotoSIMMobil = File(pickedFile.path);
                break;
              case 'kendaraan':
                _xFileKendaraanMobil = pickedFile;
                _fotoKendaraanMobil = File(pickedFile.path);
                break;
            }
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Foto ${docType.toUpperCase()} ${vehicleType == 'motor' ? 'Motor' : 'Mobil'} berhasil dipilih',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('ℹ️ [RequestDriverRole] Image picker cancelled by user');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [RequestDriverRole] Error picking image: $e');
      debugPrint('📚 [RequestDriverRole] Stack trace: $stackTrace');
      
      if (mounted) {
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Gagal Memilih Foto',
          message: 'Terjadi kesalahan saat memilih foto. Pastikan Anda memberikan izin akses galeri dan coba lagi.',
        );
      }
    }
  }

  Future<String?> _uploadFile(XFile? xFile, String bucket, String path) async {
    if (xFile == null) {
      debugPrint('⚠️ [RequestDriverRole] Upload skipped - file is null');
      return null;
    }
    
    debugPrint('📤 [RequestDriverRole] Uploading file to bucket: $bucket, path: $path');
    
    try {
      final bytes = await xFile.readAsBytes();
      final fileExt = xFile.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$path/$fileName';

      debugPrint('📊 [RequestDriverRole] File size: ${bytes.length} bytes');
      debugPrint('📊 [RequestDriverRole] File extension: $fileExt');

      await _supabase.storage.from(bucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);
      debugPrint('✅ [RequestDriverRole] Upload successful: $publicUrl');
      
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ [RequestDriverRole] Upload failed: $e');
      debugPrint('📚 [RequestDriverRole] Stack trace: $stackTrace');
      return null;
    }
  }

  // ============================================================================
  // 🔥 NUCLEAR FIX - GANTI SELURUH _submitForm()
  // PAKSA FLUTTER BUILD FORM DULU SEBELUM VALIDASI!
  // ============================================================================

  Future<void> _submitForm() async {
    debugPrint('🚀 [RequestDriverRole] Starting form submission...');
    debugPrint('   _isMotorSelected: $_isMotorSelected');
    debugPrint('   _isMobilSelected: $_isMobilSelected');
    
    if (!_isMotorSelected && !_isMobilSelected) {
      debugPrint('⚠️ [RequestDriverRole] No vehicle selected');
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Pilih Kendaraan',
        message: 'Silakan pilih minimal satu jenis kendaraan (Motor atau Mobil) untuk didaftarkan sebagai driver.',
      );
      return;
    }
    
    // ============================================================================
    // 🔥 PAKSA REBUILD & TUNGGU SAMPAI FRAME SELESAI!
    // ============================================================================
    
    setState(() {
      // Force rebuild semua widget
      _isMotorSelected = _isMotorSelected;
      _isMobilSelected = _isMobilSelected;
    });
    
    // Tunggu sampai frame BENAR-BENAR selesai render
    await WidgetsBinding.instance.endOfFrame;
    
    // Tunggu 1 frame lagi untuk safety (total 2 frames)
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) return;
    
    // ============================================================================
    // ✅ VALIDASI MOTOR
    // ============================================================================
    if (_isMotorSelected) {
      debugPrint('🔍 [RequestDriverRole] Validating motor form...');
      debugPrint('   Form key exists: ${_formKeyMotor.currentState != null}');
      
      if (_formKeyMotor.currentState == null) {
        debugPrint('❌ Motor form key is NULL after 2 frames!');
        
        // ULTIMATE FALLBACK: Scroll ke form motor & retry
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Form Belum Siap',
          message: 'Mohon scroll ke bagian form Motor, tunggu 2 detik, lalu coba submit lagi.',
        );
        return;
      }
      
      if (!_formKeyMotor.currentState!.validate()) {
        debugPrint('⚠️ Motor form validation FAILED');
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Data Motor Tidak Lengkap',
          message: 'Mohon lengkapi semua data kendaraan motor dengan benar.',
        );
        return;
      }
      debugPrint('✅ Motor form validation PASSED');
    }
    
    // ============================================================================
    // ✅ VALIDASI MOBIL
    // ============================================================================
    if (_isMobilSelected) {
      debugPrint('🔍 [RequestDriverRole] Validating mobil form...');
      debugPrint('   Form key exists: ${_formKeyMobil.currentState != null}');
      
      if (_formKeyMobil.currentState == null) {
        debugPrint('❌ Mobil form key is NULL after 2 frames!');
        
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Form Belum Siap',
          message: 'Mohon scroll ke bagian form Mobil, tunggu 2 detik, lalu coba submit lagi.',
        );
        return;
      }
      
      if (!_formKeyMobil.currentState!.validate()) {
        debugPrint('⚠️ Mobil form validation FAILED');
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Data Mobil Tidak Lengkap',
          message: 'Mohon lengkapi semua data kendaraan mobil dengan benar.',
        );
        return;
      }
      debugPrint('✅ Mobil form validation PASSED');
    }
    
    // ============================================================================
    // ✅ VALIDASI DOKUMEN MOTOR
    // ============================================================================
    if (_isMotorSelected) {
      debugPrint('🔍 [RequestDriverRole] Checking motor documents...');
      
      if (_fotoSTNKMotor == null || _fotoSIMMotor == null || _fotoKendaraanMotor == null) {
        debugPrint('⚠️ Motor documents INCOMPLETE');
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Dokumen Motor Belum Lengkap',
          message: 'Harap upload semua dokumen motor:\n• Foto STNK Motor\n• Foto SIM\n• Foto Kendaraan Motor',
        );
        return;
      }
      debugPrint('✅ Motor documents COMPLETE');
    }
    
    // ============================================================================
    // ✅ VALIDASI DOKUMEN MOBIL
    // ============================================================================
    if (_isMobilSelected) {
      debugPrint('🔍 [RequestDriverRole] Checking mobil documents...');
      
      if (_fotoSTNKMobil == null || _fotoSIMMobil == null || _fotoKendaraanMobil == null) {
        debugPrint('⚠️ Mobil documents INCOMPLETE');
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Dokumen Mobil Belum Lengkap',
          message: 'Harap upload semua dokumen mobil:\n• Foto STNK Mobil\n• Foto SIM\n• Foto Kendaraan Mobil',
        );
        return;
      }
      debugPrint('✅ Mobil documents COMPLETE');
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) {
      debugPrint('❌ User session expired');
      ErrorDialogUtils.showErrorDialog(
        context: context,
        title: 'Sesi Berakhir',
        message: 'Sesi Anda telah berakhir. Silakan login kembali.',
        onAction: () => Navigator.pop(context),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('⏳ Loading state activated');

    try {
      // PROSES UPLOAD & SUBMIT (sisanya sama seperti kode asli lo)
      debugPrint('📊 Step 1: Checking driver profile...');
      var driverData = await _supabase
          .from('drivers')
          .select('id_driver')
          .eq('id_user', user.idUser)
          .maybeSingle();

      String idDriver;

      if (driverData == null) {
        debugPrint('➕ Creating new driver profile...');
        
        final existingDriverRole = await _supabase
            .from('user_roles')
            .select('role, status')
            .eq('id_user', user.idUser)
            .eq('role', 'driver')
            .maybeSingle();
        
        if (existingDriverRole == null) {
          debugPrint('🆕 Adding driver role (new)');
          await authProvider.addRole('driver');
          debugPrint('✅ Driver role added to user');
        } else {
          debugPrint('⚠️ Driver role already exists: ${existingDriverRole['status']}');
          
          await _supabase
              .from('user_roles')
              .update({'status': 'pending_verification'})
              .eq('id_user', user.idUser)
              .eq('role', 'driver');
          
          debugPrint('✅ Driver role status updated to pending_verification');
        }
        
        final driverInsert = await _supabase
            .from('drivers')
            .insert({
              'id_user': user.idUser,
              'status_driver': 'offline',
              'rating_driver': 0.0,
              'total_pendapatan': 0.0,
              'jumlah_pesanan_selesai': 0,
              'total_rating': 0,
              'is_online': false,
              'nama_bank': _namaBank,
              'nomor_rekening': _nomorRekeningController.text.trim().isNotEmpty 
                  ? _nomorRekeningController.text.trim() 
                  : null,
              'nama_rekening': _namaRekeningController.text.trim().isNotEmpty 
                  ? _namaRekeningController.text.trim() 
                  : null,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select('id_driver')
            .single();

        idDriver = driverInsert['id_driver'];
        debugPrint('✅ Driver profile created: $idDriver');
      } else {
        idDriver = driverData['id_driver'];
        debugPrint('✅ Existing driver profile: $idDriver');
      }

      if (_isMotorSelected) {
        debugPrint('🏍️ Step 2a: Processing Motor registration...');
        
        debugPrint('📤 Uploading motor documents...');
        final fotoSTNKMotorUrl = await _uploadFile(
          _xFileSTNKMotor, 
          'proof-documents', 
          'driver/stnk/${user.idUser}/motor'
        );
        final fotoSIMMotorUrl = await _uploadFile(
          _xFileSIMMotor, 
          'proof-documents', 
          'driver/sim/${user.idUser}/motor'
        );
        final fotoKendaraanMotorUrl = await _uploadFile(
          _xFileKendaraanMotor, 
          'proof-documents', 
          'driver/kendaraan/${user.idUser}/motor'
        );

        if (fotoSTNKMotorUrl == null || fotoSIMMotorUrl == null || fotoKendaraanMotorUrl == null) {
          throw Exception('Gagal upload dokumen motor. Periksa koneksi internet Anda dan coba lagi.');
        }

        debugPrint('✅ Motor documents uploaded successfully');
        
        final existingMotor = await _supabase
            .from('driver_vehicles')
            .select('id_vehicle')
            .eq('id_driver', idDriver)
            .eq('jenis_kendaraan', 'motor')
            .maybeSingle();

        if (existingMotor != null) {
          throw Exception('Anda sudah memiliki kendaraan motor yang terdaftar.');
        }

        debugPrint('📝 Inserting motor vehicle record...');
        await _supabase.from('driver_vehicles').insert({
          'id_driver': idDriver,
          'jenis_kendaraan': 'motor',
          'plat_nomor': _platNomorMotorController.text.trim().toUpperCase(),
          'merk_kendaraan': _merkKendaraanMotorController.text.trim(),
          'warna_kendaraan': _warnaKendaraanMotorController.text.trim(),
          'foto_stnk': fotoSTNKMotorUrl,
          'foto_sim': fotoSIMMotorUrl,
          'foto_kendaraan': fotoKendaraanMotorUrl,
          'status_verifikasi': 'pending',
          'is_active': true,
        });
        
        debugPrint('✅ Motor registration completed');
      }

      if (_isMobilSelected) {
        debugPrint('🚗 Step 2b: Processing Mobil registration...');
        
        debugPrint('📤 Uploading mobil documents...');
        final fotoSTNKMobilUrl = await _uploadFile(
          _xFileSTNKMobil, 
          'proof-documents', 
          'driver/stnk/${user.idUser}/mobil'
        );
        final fotoSIMMobilUrl = await _uploadFile(
          _xFileSIMMobil, 
          'proof-documents', 
          'driver/sim/${user.idUser}/mobil'
        );
        final fotoKendaraanMobilUrl = await _uploadFile(
          _xFileKendaraanMobil, 
          'proof-documents', 
          'driver/kendaraan/${user.idUser}/mobil'
        );

        if (fotoSTNKMobilUrl == null || fotoSIMMobilUrl == null || fotoKendaraanMobilUrl == null) {
          throw Exception('Gagal upload dokumen mobil. Periksa koneksi internet Anda dan coba lagi.');
        }

        debugPrint('✅ Mobil documents uploaded successfully');
        
        final existingMobil = await _supabase
            .from('driver_vehicles')
            .select('id_vehicle')
            .eq('id_driver', idDriver)
            .eq('jenis_kendaraan', 'mobil')
            .maybeSingle();

        if (existingMobil != null) {
          throw Exception('Anda sudah memiliki kendaraan mobil yang terdaftar.');
        }

        debugPrint('📝 Inserting mobil vehicle record...');
        await _supabase.from('driver_vehicles').insert({
          'id_driver': idDriver,
          'jenis_kendaraan': 'mobil',
          'plat_nomor': _platNomorMobilController.text.trim().toUpperCase(),
          'merk_kendaraan': _merkKendaraanMobilController.text.trim(),
          'warna_kendaraan': _warnaKendaraanMobilController.text.trim(),
          'foto_stnk': fotoSTNKMobilUrl,
          'foto_sim': fotoSIMMobilUrl,
          'foto_kendaraan': fotoKendaraanMobilUrl,
          'status_verifikasi': 'pending',
          'is_active': _isMotorSelected ? false : true,
        });
        
        debugPrint('✅ Mobil registration completed');
      }

      if (!_hasBankInfo && 
          _namaBank != null && 
          _namaBank!.isNotEmpty && 
          _nomorRekeningController.text.trim().isNotEmpty) {
        debugPrint('💳 Saving bank info to users table...');
        await _supabase.from('users').update({
          'nama_bank': _namaBank,
          'nomor_rekening': _nomorRekeningController.text.trim(),
          'nama_rekening': _namaRekeningController.text.trim().isEmpty 
              ? user.nama 
              : _namaRekeningController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_user', user.idUser);
        
        debugPrint('✅ Bank info saved');
      }

      setState(() => _isLoading = false);
      debugPrint('🎉 ALL REGISTRATION COMPLETED SUCCESSFULLY!');

      if (!mounted) return;

      await ErrorDialogUtils.showSuccessDialog(
        context: context,
        title: 'Berhasil! 🎉',
        message: _isMotorSelected && _isMobilSelected
            ? 'Pengajuan Motor dan Mobil berhasil dikirim!\n\nTim kami akan memverifikasi dokumen Anda dalam waktu maksimal 1x24 jam.'
            : 'Pengajuan ${_isMotorSelected ? "Motor" : "Mobil"} berhasil dikirim!\n\nTim kami akan memverifikasi dokumen Anda dalam waktu maksimal 1x24 jam.',
        actionText: 'OK, Mengerti',
        onAction: () => Navigator.pop(context),
      );

    } catch (e, stackTrace) {
      debugPrint('❌ SUBMISSION FAILED: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        if (errorMessage.contains('connection') || errorMessage.contains('network')) {
          errorMessage = 'Koneksi internet terputus. Periksa koneksi Anda dan coba lagi.';
        } else if (errorMessage.contains('timeout')) {
          errorMessage = 'Waktu tunggu habis. Periksa koneksi internet Anda dan coba lagi.';
        }
        
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Gagal Mengirim Pengajuan',
          message: errorMessage,
        );
      }
    }
  }

  // ✅ TAMBAHKAN FUNCTION INI
  void _handleVehicleSelection(String type) {
    debugPrint('🎯 [Selection] User clicked: $type');
    
    // BATALKAN timer sebelumnya kalau ada
    if (_selectionDebounce != null && _selectionDebounce!.isActive) {
      debugPrint('   ⏸️ Canceling previous selection timer');
      _selectionDebounce!.cancel();
    }
    
    // BIKIN timer baru - tunggu 300 milliseconds
    _selectionDebounce = Timer(const Duration(milliseconds: 300), () {
      debugPrint('   ✅ Timer completed, processing selection...');
      
      // Cek apakah widget masih hidup (belum di-dispose)
      if (mounted) {
        setState(() {
          if (type == 'motor') {
            _isMotorSelected = !_isMotorSelected;
            debugPrint('   🏍️ Motor selected: $_isMotorSelected');
          } else {
            _isMobilSelected = !_isMobilSelected;
            debugPrint('   🚗 Mobil selected: $_isMobilSelected');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingExisting) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: DriverAppBarWidget(
          title: 'Daftar Jadi Driver',
          onBack: () => Navigator.pop(context),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
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
    
    if (_isMotorLocked && _isMobilLocked) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: DriverAppBarWidget(
          title: 'Daftar Jadi Driver',
          onBack: () => Navigator.pop(context),
        ),
        body: Center(
          child: Padding(
            padding: ResponsiveMobile.horizontalPadding(context, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: ResponsiveMobile.allScaledPadding(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: ResponsiveMobile.scaledW(64),
                  ),
                ),
                ResponsiveMobile.vSpace(24),
                Text(
                  'Semua Kendaraan\nTerdaftar',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.titleSize(context),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                ResponsiveMobile.vSpace(12),
                Text(
                  'Anda sudah mendaftar semua jenis kendaraan (Motor dan Mobil). Silakan kembali ke halaman sebelumnya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.bodySize(context),
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                ResponsiveMobile.vSpace(32),
                SizedBox(
                  width: ResponsiveMobile.wp(context, 70),
                  height: ResponsiveMobile.minTouchTargetSize(context),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                      ),
                    ),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: DriverAppBarWidget(
        title: widget.lockedVehicleType != null ? 'Tambah Kendaraan Baru' : 'Daftar Jadi Driver',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: ResponsiveMobile.horizontalPadding(context, 4),
        children: [
          ResponsiveMobile.vSpace(20),
          const DriverHeaderInfoWidget(),
          ResponsiveMobile.vSpace(24),
          DriverVehicleSelectionWidget(
            isMotorLocked: _isMotorLocked,
            isMobilLocked: _isMobilLocked,
            isMotorSelected: _isMotorSelected,
            isMobilSelected: _isMobilSelected,
            motorLockedReason: _motorLockedReason,
            mobilLockedReason: _mobilLockedReason,
            onVehicleToggle: _handleVehicleSelection,
          ),
          DriverVehicleFormsWidget(
            isMotorSelected: _isMotorSelected,
            isMobilSelected: _isMobilSelected,
            formKeyMotor: _formKeyMotor,
            formKeyMobil: _formKeyMobil,
            platNomorMotorController: _platNomorMotorController,
            merkKendaraanMotorController: _merkKendaraanMotorController,
            warnaKendaraanMotorController: _warnaKendaraanMotorController,
            platNomorMobilController: _platNomorMobilController,
            merkKendaraanMobilController: _merkKendaraanMobilController,
            warnaKendaraanMobilController: _warnaKendaraanMobilController,
            fotoSTNKMotor: _fotoSTNKMotor,
            fotoSIMMotor: _fotoSIMMotor,
            fotoKendaraanMotor: _fotoKendaraanMotor,
            fotoSTNKMobil: _fotoSTNKMobil,
            fotoSIMMobil: _fotoSIMMobil,
            fotoKendaraanMobil: _fotoKendaraanMobil,
            onPickImage: _pickImage,
          ),

          ResponsiveMobile.vSpace(28),
          
          if (_isMotorSelected || _isMobilSelected) ...[
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
            DriverBankFormWidget(
              hasBankInfo: _hasBankInfo,
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
                                'Baca & setujui Syarat dan Ketentuan Driver terlebih dahulu',
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
          ],
          ResponsiveMobile.vSpace(32),
        ],
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

  // ── Banner S&K — wajib setuju sebelum submit ──
  Widget _buildTermsBanner(BuildContext context) {
    return InkWell(
      onTap: () async {
        final agreed = await showDriverTermsConditionDialog(context: context);
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
                        ? 'Kamu sudah menyetujui S&K Driver SiDrive'
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
}