// ============================================================================
// ADD_EDIT_PRODUK_SCREEN.DART (REVISI FINAL)
// ✅ Bug fix: Multi-photo upload
// ✅ Responsive dengan ResponsiveMobile
// ✅ Format harga real-time
// ✅ Error handling dengan ErrorDialogUtils
// ✅ Redesign modern & compact
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/umkm_service.dart';
import 'package:sidrive/services/product_storage_service.dart';
import 'package:sidrive/models/produk_model.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';

class AddEditProdukScreen extends StatefulWidget {
  final ProdukModel? produk;
  
  const AddEditProdukScreen({Key? key, this.produk}) : super(key: key);

  @override
  State<AddEditProdukScreen> createState() => _AddEditProdukScreenState();
}

class _AddEditProdukScreenState extends State<AddEditProdukScreen> {
  final _formKey = GlobalKey<FormState>();
  final _umkmService = UmkmService();
  final _storageService = ProductStorageService();
  
  // Controllers
  final _namaProdukController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _beratController = TextEditingController();
  final _waktuPersiapanController = TextEditingController();
  
  // Data
  String? _selectedKategori;
  String _selectedDriverType = 'MOTOR_AND_CAR';
  List<File> _fotoProduk = [];
  bool _isAvailable = true;
  bool _isLoading = false;
  List<String> _kategoriList = [];
  bool _isPickingImages = false;

  bool get isEditMode => widget.produk != null;

  @override
  void initState() {
    super.initState();
    _loadKategori();
    _initializeData();
    _setupHargaFormatter();
  }

  Future<void> _loadKategori() async {
    try {
      final kategori = await _umkmService.getKategoriProduk();
      if (mounted) {
        setState(() {
          _kategoriList = kategori;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error load kategori: $e');
    }
  }

  void _initializeData() {
    if (isEditMode) {
      final p = widget.produk!;
      _namaProdukController.text = p.namaProduk;
      _deskripsiController.text = p.deskripsiProduk ?? '';
      _hargaController.text = p.hargaProduk.toStringAsFixed(0);
      _stokController.text = p.stok.toString();
      _beratController.text = p.beratGram?.toString() ?? '';
      _waktuPersiapanController.text = p.waktuPersiapanMenit.toString();
      _selectedKategori = p.kategoriProduk;
      _selectedDriverType = p.allowedDriverType ?? 'MOTOR_AND_CAR';
      _isAvailable = p.isAvailable;
    } else {
      _waktuPersiapanController.text = '15';
    }
  }

  void _setupHargaFormatter() {
    _hargaController.addListener(() {
      final text = _hargaController.text.replaceAll('.', '');
      if (text.isNotEmpty && int.tryParse(text) != null) {
        final formatted = CurrencyFormatter.formatRupiah(double.parse(text));
        if (_hargaController.text != formatted) {
          _hargaController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _namaProdukController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _beratController.dispose();
    _waktuPersiapanController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    // ✅ Prevent multiple simultaneous calls
    if (_isPickingImages) {
      debugPrint('⚠️ Image picker already active, ignoring...');
      return;
    }

    try {
      if (_fotoProduk.length >= 5) {
        _showError('Maksimal 5 foto produk');
        return;
      }

      setState(() => _isPickingImages = true);

      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFiles.isNotEmpty) {
        List<File> validFiles = [];
        
        for (var pickedFile in pickedFiles) {
          final file = File(pickedFile.path);
          
          if (!_storageService.validateFileSize(file)) {
            _showError('File ${pickedFile.name} terlalu besar (max 5MB)');
            continue;
          }
          
          if (!_storageService.validateFileType(file)) {
            _showError('File ${pickedFile.name} harus gambar (jpg/png)');
            continue;
          }
          
          validFiles.add(file);
        }
        
        if (mounted) {
          setState(() {
            _fotoProduk.addAll(validFiles);
            
            if (_fotoProduk.length > 5) {
              _fotoProduk = _fotoProduk.sublist(0, 5);
              _showError('Maksimal 5 foto, sisanya diabaikan');
            }
          });
        }
        
        debugPrint('✅ Total foto: ${_fotoProduk.length}');
      }
    } catch (e) {
      debugPrint('❌ Error pick images: $e');
      if (mounted) {
        _showError('Gagal memilih foto. Silakan coba lagi.');
      }
    } finally {
      // ✅ Always release lock
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _fotoProduk.removeAt(index);
    });
    debugPrint('🗑️ Foto dihapus, sisa: ${_fotoProduk.length}');
  }

  Future<void> _submitProduk() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Mohon lengkapi semua field yang wajib');
      return;
    }
    
    if (_selectedKategori == null) {
      _showError('Pilih kategori produk terlebih dahulu');
      return;
    }

    if (_fotoProduk.isEmpty && !isEditMode) {
      _showError('Upload minimal 1 foto produk');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final umkm = await _umkmService.getUmkmByUserId(userId);
      if (umkm == null) {
        throw Exception('Toko belum terdaftar. Setup toko terlebih dahulu.');
      }

      // Parse harga (hapus separator)
      final hargaText = _hargaController.text.replaceAll('.', '');
      final hargaProduk = double.parse(hargaText);

      if (isEditMode) {
        await _handleUpdate(umkm.idUmkm, hargaProduk);
      } else {
        await _handleAdd(umkm.idUmkm, hargaProduk);
      }
    } catch (e) {
      debugPrint('❌ Error submit produk: $e');
      if (mounted) {
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Gagal Menyimpan Produk',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpdate(String idUmkm, double hargaProduk) async {
    List<String> fotoUrls = widget.produk!.fotoProduk ?? [];
    
    if (_fotoProduk.isNotEmpty) {
      debugPrint('📸 Uploading ${_fotoProduk.length} new photos...');
      
      final newUrls = await _storageService.uploadMultipleProductPhotos(
        files: _fotoProduk,
        idUmkm: idUmkm,
        idProduk: widget.produk!.idProduk,
      );
      
      if (newUrls.isEmpty) {
        throw Exception('Gagal upload foto. Periksa koneksi internet.');
      }
      
      if (fotoUrls.isNotEmpty) {
        await _storageService.deleteMultipleProductPhotos(fotoUrls);
      }
      
      fotoUrls = newUrls;
    }

    final success = await _umkmService.updateProduk(
      idProduk: widget.produk!.idProduk,
      namaProduk: _namaProdukController.text.trim(),
      deskripsiProduk: _deskripsiController.text.trim(),
      hargaProduk: hargaProduk,
      stokProduk: int.parse(_stokController.text),
      kategoriProduk: _selectedKategori!,
      fotoProduk: fotoUrls,
      isAvailable: _isAvailable,
      beratGram: _beratController.text.isNotEmpty 
          ? int.parse(_beratController.text) 
          : null,
      waktuPersiapanMenit: int.parse(_waktuPersiapanController.text),
      allowedDriverType: _selectedDriverType,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
      ErrorDialogUtils.showSuccessDialog(
        context: context,
        title: 'Berhasil!',
        message: 'Produk berhasil diperbarui',
      );
    } else {
      throw Exception('Gagal update produk ke database');
    }
  }

  Future<void> _handleAdd(String idUmkm, double hargaProduk) async {
    final tempId = _storageService.generateTempId();
    
    debugPrint('📸 Uploading ${_fotoProduk.length} photos...');
    
    final fotoUrls = await _storageService.uploadMultipleProductPhotos(
      files: _fotoProduk,
      idUmkm: idUmkm,
      idProduk: tempId,
    );
    
    if (fotoUrls.isEmpty) {
      throw Exception('Gagal upload foto. Periksa koneksi internet.');
    }

    final produk = await _umkmService.addProduk(
      idUmkm: idUmkm,
      namaProduk: _namaProdukController.text.trim(),
      deskripsiProduk: _deskripsiController.text.trim(),
      hargaProduk: hargaProduk,
      stokProduk: int.parse(_stokController.text),
      kategoriProduk: _selectedKategori!,
      fotoProduk: fotoUrls,
      beratGram: _beratController.text.isNotEmpty 
          ? int.parse(_beratController.text) 
          : null,
      waktuPersiapanMenit: int.parse(_waktuPersiapanController.text),
      allowedDriverType: _selectedDriverType,
    );

    if (produk != null && mounted) {
      Navigator.pop(context, true);
      ErrorDialogUtils.showSuccessDialog(
        context: context,
        title: 'Berhasil!',
        message: 'Produk berhasil ditambahkan ke toko Anda',
      );
    } else {
      await _storageService.deleteMultipleProductPhotos(fotoUrls);
      throw Exception('Gagal menambah produk ke database');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Perhatian',
        message: message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          isEditMode ? 'Edit Produk' : 'Tambah Produk',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Hapus Produk',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: ResponsiveMobile.allScaledPadding(12),
          children: [
            _buildFotoSection(),
            ResponsiveMobile.vSpace(16),
            _buildInfoSection(),
            ResponsiveMobile.vSpace(16),
            _buildHargaStokSection(),
            ResponsiveMobile.vSpace(16),
            _buildDriverTypeSelector(), 
            ResponsiveMobile.vSpace(16),
            _buildStatusSection(),
            ResponsiveMobile.vSpace(20),
            _buildSubmitButton(),
            ResponsiveMobile.vSpace(24),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoSection() {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                color: Colors.orange.shade600,
                size: ResponsiveMobile.scaledFont(20),
              ),
              ResponsiveMobile.hSpace(8),
              Text(
                'Foto Produk',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(15),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveMobile.scaledW(8),
                  vertical: ResponsiveMobile.scaledH(4),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                ),
                child: Text(
                  '${_fotoProduk.length}/5',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(12),
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          ResponsiveMobile.vSpace(12),
          if (_fotoProduk.isEmpty)
            _buildEmptyPhotoPlaceholder()
          else
            _buildPhotoGrid(),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotoPlaceholder() {
    return GestureDetector(
      onTap: _isPickingImages ? null : _pickImages,
      child: Container(
        height: ResponsiveMobile.scaledH(160),
        decoration: BoxDecoration(
          color: _isPickingImages ? Colors.grey.shade100 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
          border: Border.all(
            color: _isPickingImages ? Colors.grey.shade300 : Colors.orange.shade200,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isPickingImages)
              SizedBox(
                width: ResponsiveMobile.scaledFont(32),
                height: ResponsiveMobile.scaledFont(32),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.orange.shade400),
                ),
              )
            else
              Icon(
                Icons.add_photo_alternate_outlined,
                size: ResponsiveMobile.scaledFont(48),
                color: Colors.orange.shade400,
              ),
            ResponsiveMobile.vSpace(8),
            Text(
              _isPickingImages ? 'Memilih foto...' : 'Tap untuk upload foto',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(14),
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
            if (!_isPickingImages) ...[
              ResponsiveMobile.vSpace(4),
              Text(
                'Format: JPG/PNG • Max 5MB',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(11),
                color: Colors.grey.shade600,
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return SizedBox(
      height: ResponsiveMobile.scaledH(100),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _fotoProduk.length + (_fotoProduk.length < 5 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _fotoProduk.length) {
            return GestureDetector(
              onTap: _isPickingImages ? null : _pickImages,
              child: Container(
                width: ResponsiveMobile.scaledW(100),
                margin: EdgeInsets.only(right: ResponsiveMobile.scaledW(8)),
                decoration: BoxDecoration(
                  color: _isPickingImages ? Colors.grey.shade100 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  border: Border.all(
                    color: _isPickingImages ? Colors.grey.shade300 : Colors.orange.shade200,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPickingImages)
                      SizedBox(
                        width: ResponsiveMobile.scaledFont(24),
                        height: ResponsiveMobile.scaledFont(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.orange.shade400),
                        ),
                      )
                    else
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.orange.shade600,
                        size: ResponsiveMobile.scaledFont(28),
                      ),
                    ResponsiveMobile.vSpace(4),
                    Text(
                      _isPickingImages ? 'Loading...' : 'Tambah',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(11),
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              Container(
                width: ResponsiveMobile.scaledW(100),
                margin: EdgeInsets.only(right: ResponsiveMobile.scaledW(8)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  image: DecorationImage(
                    image: FileImage(_fotoProduk[index]),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveMobile.scaledW(4)),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: ResponsiveMobile.scaledFont(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade600,
                size: ResponsiveMobile.scaledFont(20),
              ),
              ResponsiveMobile.hSpace(8),
              Text(
                'Informasi Produk',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(15),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          ResponsiveMobile.vSpace(14),
          TextFormField(
            controller: _namaProdukController,
            decoration: InputDecoration(
              labelText: 'Nama Produk *',
              hintText: 'Contoh: Nasi Goreng Spesial',
              prefixIcon: Icon(Icons.shopping_bag_outlined, size: ResponsiveMobile.scaledFont(20)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(14),
                vertical: ResponsiveMobile.scaledH(12),
              ),
            ),
            style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14)),
            maxLength: 100,
            validator: (val) => val!.isEmpty ? 'Nama produk wajib diisi' : null,
          ),
          ResponsiveMobile.vSpace(12),
          DropdownButtonFormField<String>(
            value: _selectedKategori,
            decoration: InputDecoration(
              labelText: 'Kategori *',
              prefixIcon: Icon(Icons.category_outlined, size: ResponsiveMobile.scaledFont(20)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(14),
                vertical: ResponsiveMobile.scaledH(12),
              ),
            ),
            style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14), color: Colors.black87),
            items: _kategoriList.map((kategori) {
              return DropdownMenuItem(
                value: kategori,
                child: Text(kategori.toUpperCase()),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedKategori = val),
            validator: (val) => val == null ? 'Pilih kategori produk' : null,
          ),
          ResponsiveMobile.vSpace(12),
          TextFormField(
            controller: _deskripsiController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Deskripsi',
              hintText: 'Jelaskan detail produk...',
              prefixIcon: Icon(Icons.description_outlined, size: ResponsiveMobile.scaledFont(20)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(14),
                vertical: ResponsiveMobile.scaledH(12),
              ),
            ),
            style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14)),
          ),
        ],
      ),
    );
  }

  Widget _buildHargaStokSection() {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: Colors.orange.shade600,
                size: ResponsiveMobile.scaledFont(20),
              ),
              ResponsiveMobile.hSpace(8),
              Text(
                'Harga & Stok',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(15),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          ResponsiveMobile.vSpace(14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Harga *',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.payments_outlined, size: ResponsiveMobile.scaledFont(20)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.scaledW(14),
                      vertical: ResponsiveMobile.scaledH(12),
                    ),
                  ),
                  style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14)),
                  validator: (val) {
                    if (val!.isEmpty) return 'Harga wajib diisi';
                    final num = int.tryParse(val.replaceAll('.', ''));
                    if (num == null) return 'Format harga salah';
                    if (num < 100) return 'Harga minimal Rp 100';
                    return null;
                  },
                ),
              ),
              ResponsiveMobile.hSpace(10),
              Expanded(
                child: TextFormField(
                  controller: _stokController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Stok *',
                    prefixIcon: Icon(Icons.inventory_2_outlined, size: ResponsiveMobile.scaledFont(20)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.scaledW(14),
                      vertical: ResponsiveMobile.scaledH(12),
                    ),
                  ),
                  style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14)),
                  validator: (val) {
                    if (val!.isEmpty) return 'Stok wajib diisi';
                    if (int.tryParse(val) == null) return 'Harus angka';
                    return null;
                  },
                ),
              ),
            ],
          ),
          ResponsiveMobile.vSpace(12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _beratController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Berat (opsional)',
                    suffixText: 'gram',
                    prefixIcon: Icon(Icons.scale_outlined, size: ResponsiveMobile.scaledFont(20)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.scaledW(14),
                      vertical: ResponsiveMobile.scaledH(12),
                    ),
                  ),
                  style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14)),
                ),
              ),
              ResponsiveMobile.hSpace(10),
              Expanded(
                child: TextFormField(
                  controller: _waktuPersiapanController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Waktu Siap',
                    suffixText: 'menit',
                    prefixIcon: Icon(Icons.timer_outlined, size: ResponsiveMobile.scaledFont(20)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.scaledW(14),
                      vertical: ResponsiveMobile.scaledH(12),
                    ),
                  ),
                  style: TextStyle(fontSize: ResponsiveMobile.scaledFont(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(14),
      decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
      boxShadow: [
      BoxShadow(
      color: Colors.orange.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
      ),
      ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Row(
      children: [
      Icon(
      Icons.toggle_on_outlined,
      color: Colors.orange.shade600,
      size: ResponsiveMobile.scaledFont(20),
      ),
      ResponsiveMobile.hSpace(8),
      Text(
      'Status Produk',
      style: TextStyle(
      fontSize: ResponsiveMobile.scaledFont(15),
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      ),
      ),
      ],
      ),
      ResponsiveMobile.vSpace(8),
      SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
      'Tampilkan di Toko',
      style: TextStyle(
      fontSize: ResponsiveMobile.scaledFont(14),
      fontWeight: FontWeight.w600,
      ),
      ),
      subtitle: Text(
      _isAvailable
      ? 'Produk bisa dibeli customer'
      : 'Produk disembunyikan',
      style: TextStyle(
      fontSize: ResponsiveMobile.scaledFont(12),
      color: Colors.grey.shade600,
      ),
      ),
      value: _isAvailable,
      onChanged: (val) => setState(() => _isAvailable = val),
      activeColor: Colors.green,
      ),
      ],
      ),
    );
  }


  /// Widget untuk pilih allowed driver type
  Widget _buildDriverTypeSelector() {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: ResponsiveMobile.scaledFont(18),
                color: Colors.orange.shade700,
              ),
              ResponsiveMobile.hSpace(8),
              Text(
                'Kendaraan Pengiriman',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(15),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          ResponsiveMobile.vSpace(12),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildDriverTypeOption(
                  'MOTOR_AND_CAR',
                  'Motor & Mobil',
                  'Bisa diantar motor atau mobil',
                  Icons.two_wheeler,
                  Colors.blue,
                ),
                Divider(height: 1, color: Colors.grey.shade300),
                _buildDriverTypeOption(
                  'MOTOR_ONLY',
                  'Hanya Motor',
                  'Hanya bisa diantar motor',
                  Icons.motorcycle,
                  Colors.green,
                ),
                Divider(height: 1, color: Colors.grey.shade300),
                _buildDriverTypeOption(
                  'CAR_ONLY',
                  'Hanya Mobil',
                  'Hanya bisa diantar mobil',
                  Icons.directions_car,
                  Colors.orange,
                ),
              ],
            ),
          ),
          
          ResponsiveMobile.vSpace(8),
          Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: ResponsiveMobile.scaledFont(16),
                  color: Colors.blue.shade700,
                ),
                ResponsiveMobile.hSpace(8),
                Expanded(
                  child: Text(
                    'Jika berat produk >= 7kg, sistem otomatis hanya pilih mobil',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(11),
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverTypeOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedDriverType == value;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDriverType = value;
          });
        },
        child: Container(
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
          child: Row(
            children: [
              Container(
                width: ResponsiveMobile.scaledW(40),
                height: ResponsiveMobile.scaledW(40),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? color.withOpacity(0.1) 
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : Colors.grey.shade600,
                  size: ResponsiveMobile.scaledFont(20),
                ),
              ),
              ResponsiveMobile.hSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(14),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? color : Colors.grey.shade800,
                      ),
                    ),
                    ResponsiveMobile.vSpace(2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: ResponsiveMobile.scaledFont(24),
                ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildSubmitButton() {
return ElevatedButton(
onPressed: _isLoading ? null : _submitProduk,
style: ElevatedButton.styleFrom(
backgroundColor: Colors.orange.shade600,
disabledBackgroundColor: Colors.grey.shade300,
padding: EdgeInsets.symmetric(vertical: ResponsiveMobile.scaledH(14)),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
),
elevation: 2,
),
child: _isLoading
? SizedBox(
height: ResponsiveMobile.scaledH(20),
width: ResponsiveMobile.scaledW(20),
child: const CircularProgressIndicator(
strokeWidth: 2,
valueColor: AlwaysStoppedAnimation(Colors.white),
),
)
: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
isEditMode ? Icons.save_outlined : Icons.add_circle_outline,
size: ResponsiveMobile.scaledFont(20),
color: Colors.white,
),
ResponsiveMobile.hSpace(8),
Text(
isEditMode ? 'Simpan Perubahan' : 'Tambah Produk',
style: TextStyle(
fontSize: ResponsiveMobile.scaledFont(15),
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
],
),
);
}
Future<void> _confirmDelete() async {
final confirm = await showDialog<bool>(
context: context,
builder: (context) => AlertDialog(
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
),
title: Row(
children: [
Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
ResponsiveMobile.hSpace(8),
const Text('Hapus Produk?'),
],
),
content: const Text(
'Produk yang dihapus tidak bisa dikembalikan. Yakin ingin melanjutkan?',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('Batal'),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
),
child: const Text('Hapus'),
),
],
),
);
if (confirm == true && mounted) {
  setState(() => _isLoading = true);
  
  try {
    if (widget.produk!.fotoProduk != null) {
      await _storageService.deleteMultipleProductPhotos(widget.produk!.fotoProduk!);
    }
    
    final success = await _umkmService.deleteProduk(widget.produk!.idProduk);
    
    if (success && mounted) {
      Navigator.pop(context, true);
      ErrorDialogUtils.showSuccessDialog(
        context: context,
        title: 'Berhasil Dihapus',
        message: 'Produk telah dihapus dari toko Anda',
      );
    } else {
      throw Exception('Gagal menghapus produk dari database');
    }
  } catch (e) {
    debugPrint('❌ Error delete produk: $e');
    if (mounted) {
      ErrorDialogUtils.showErrorDialog(
        context: context,
        title: 'Gagal Menghapus',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
}
}
