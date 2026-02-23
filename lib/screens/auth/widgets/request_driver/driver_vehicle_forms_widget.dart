// lib/screens/driver/widgets/request_driver/driver_vehicle_forms_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/widgets/custom_textfield.dart';

// ============================================================================
// DriverUploadCardWidget — diletakkan di sini agar tidak perlu import silang
// ============================================================================
class DriverUploadCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final File? file;
  final VoidCallback onTap;

  const DriverUploadCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFile = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
      child: Container(
        padding: ResponsiveMobile.allScaledPadding(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
          border: Border.all(
            color: hasFile ? Colors.green.shade300 : Colors.grey.shade200,
            width: hasFile ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasFile
                  ? Colors.green.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveMobile.scaledW(60),
              height: ResponsiveMobile.scaledW(60),
              decoration: BoxDecoration(
                color: hasFile ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                border: Border.all(
                  color: hasFile ? Colors.green.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Icon(
                hasFile ? Icons.check_circle_rounded : Icons.add_photo_alternate_rounded,
                color: hasFile ? Colors.green.shade600 : Colors.grey.shade500,
                size: ResponsiveMobile.scaledFont(30),
              ),
            ),
            ResponsiveMobile.hSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.captionSize(context) + 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  ResponsiveMobile.vSpace(4),
                  Text(
                    hasFile ? 'Foto sudah dipilih ✓' : subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.captionSize(context),
                      color: hasFile ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
              color: hasFile ? Colors.green.shade600 : Colors.grey.shade400,
              size: ResponsiveMobile.scaledFont(26),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverVehicleFormsWidget extends StatelessWidget {
  // Selection State
  final bool isMotorSelected;
  final bool isMobilSelected;

  // Form Keys
  final GlobalKey<FormState> formKeyMotor;
  final GlobalKey<FormState> formKeyMobil;

  // Controllers - Motor
  final TextEditingController platNomorMotorController;
  final TextEditingController merkKendaraanMotorController;
  final TextEditingController warnaKendaraanMotorController;

  // Controllers - Mobil
  final TextEditingController platNomorMobilController;
  final TextEditingController merkKendaraanMobilController;
  final TextEditingController warnaKendaraanMobilController;

  // Files - Motor
  final File? fotoSTNKMotor;
  final File? fotoSIMMotor;
  final File? fotoKendaraanMotor;

  // Files - Mobil
  final File? fotoSTNKMobil;
  final File? fotoSIMMobil;
  final File? fotoKendaraanMobil;

  // Callbacks
  final void Function(String vehicleType, String docType) onPickImage;

  const DriverVehicleFormsWidget({
    super.key,
    required this.isMotorSelected,
    required this.isMobilSelected,
    required this.formKeyMotor,
    required this.formKeyMobil,
    required this.platNomorMotorController,
    required this.merkKendaraanMotorController,
    required this.warnaKendaraanMotorController,
    required this.platNomorMobilController,
    required this.merkKendaraanMobilController,
    required this.warnaKendaraanMobilController,
    required this.fotoSTNKMotor,
    required this.fotoSIMMotor,
    required this.fotoKendaraanMotor,
    required this.fotoSTNKMobil,
    required this.fotoSIMMobil,
    required this.fotoKendaraanMobil,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== MOTOR SECTION ==========
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isMotorSelected ? null : 0,
          curve: Curves.easeInOut,
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveMobile.vSpace(28),
                _buildSectionTitle(context, 'Data Kendaraan Motor 🏍️'),
                ResponsiveMobile.vSpace(16),
                _buildMotorForm(context),
                ResponsiveMobile.vSpace(20),
                _buildUploadSection(context, 'motor'),
              ],
            ),
          ),
        ),

        // ========== MOBIL SECTION ==========
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isMobilSelected ? null : 0,
          curve: Curves.easeInOut,
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveMobile.vSpace(28),
                _buildSectionTitle(context, 'Data Kendaraan Mobil 🚗'),
                ResponsiveMobile.vSpace(16),
                _buildMobilForm(context),
                ResponsiveMobile.vSpace(20),
                _buildUploadSection(context, 'mobil'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ResponsiveMobile.bodySize(context) + 1,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMotorForm(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isMotorSelected ? null : 0, // ← KEY: height 0 = hidden, null = auto
      curve: Curves.easeInOut,
      child: ClipRect( // ← Prevent overflow saat animasi
        child: Form(
          key: formKeyMotor,
          child: Container(
            padding: ResponsiveMobile.allScaledPadding(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                CustomTextField(
                  label: 'Plat Nomor Motor',
                  hint: 'L 1234 AB',
                  controller: platNomorMotorController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Plat nomor motor wajib diisi';
                    if (value.length < 5) return 'Plat nomor tidak valid';
                    return null;
                  },
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => TextEditingValue(
                        text: newValue.text.toUpperCase(),
                        selection: newValue.selection,
                      ),
                    ),
                  ],
                ),
                ResponsiveMobile.vSpace(12),
                CustomTextField(
                  label: 'Merk Kendaraan Motor',
                  hint: 'Honda Vario 125',
                  controller: merkKendaraanMotorController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Merk kendaraan motor wajib diisi'
                      : null,
                ),
                ResponsiveMobile.vSpace(12),
                CustomTextField(
                  label: 'Warna Kendaraan Motor',
                  hint: 'Hitam',
                  controller: warnaKendaraanMotorController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Warna kendaraan motor wajib diisi'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobilForm(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isMobilSelected ? null : 0, // ← KEY: height 0 = hidden, null = auto
      curve: Curves.easeInOut,
      child: ClipRect( // ← Prevent overflow saat animasi
        child: Form(
          key: formKeyMobil,
          child: Container(
            padding: ResponsiveMobile.allScaledPadding(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                CustomTextField(
                  label: 'Plat Nomor Mobil',
                  hint: 'L 5678 CD',
                  controller: platNomorMobilController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Plat nomor mobil wajib diisi';
                    if (value.length < 5) return 'Plat nomor tidak valid';
                    return null;
                  },
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => TextEditingValue(
                        text: newValue.text.toUpperCase(),
                        selection: newValue.selection,
                      ),
                    ),
                  ],
                ),
                ResponsiveMobile.vSpace(12),
                CustomTextField(
                  label: 'Merk Kendaraan Mobil',
                  hint: 'Toyota Avanza',
                  controller: merkKendaraanMobilController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Merk kendaraan mobil wajib diisi'
                      : null,
                ),
                ResponsiveMobile.vSpace(12),
                CustomTextField(
                  label: 'Warna Kendaraan Mobil',
                  hint: 'Putih',
                  controller: warnaKendaraanMobilController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Warna kendaraan mobil wajib diisi'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection(BuildContext context, String vehicleType) {
    final isMotor = vehicleType == 'motor';
    final isSelected = isMotor ? isMotorSelected : isMobilSelected;
    final fotoSTNK = isMotor ? fotoSTNKMotor : fotoSTNKMobil;
    final fotoSIM = isMotor ? fotoSIMMotor : fotoSIMMobil;
    final fotoKendaraan = isMotor ? fotoKendaraanMotor : fotoKendaraanMobil;

    // ✅ SAMA SEPERTI FORM - PAKAI AnimatedContainer!
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSelected ? null : 0, // ← Hide kalau tidak selected
      curve: Curves.easeInOut,
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Dokumen ${isMotor ? "Motor" : "Mobil"}',
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context) + 1,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            ResponsiveMobile.vSpace(8),
            Text(
              'Pastikan foto jelas dan dokumen masih berlaku',
              style: TextStyle(
                fontSize: ResponsiveMobile.captionSize(context),
                color: Colors.grey.shade600,
              ),
            ),
            ResponsiveMobile.vSpace(16),
            DriverUploadCardWidget(
              title: 'Foto STNK ${isMotor ? "Motor" : "Mobil"}',
              subtitle: 'Upload foto STNK kendaraan',
              file: fotoSTNK,
              onTap: () => onPickImage(vehicleType, 'stnk'),
            ),
            ResponsiveMobile.vSpace(12),
            DriverUploadCardWidget(
              title: 'Foto SIM ${isMotor ? "Motor" : "Mobil"}',
              subtitle: 'Upload foto SIM yang masih berlaku',
              file: fotoSIM,
              onTap: () => onPickImage(vehicleType, 'sim'),
            ),
            ResponsiveMobile.vSpace(12),
            DriverUploadCardWidget(
              title: 'Foto Kendaraan ${isMotor ? "Motor" : "Mobil"}',
              subtitle: 'Upload foto kendaraan tampak depan',
              file: fotoKendaraan,
              onTap: () => onPickImage(vehicleType, 'kendaraan'),
            ),
          ],
        ),
      ),
    );
  }
}