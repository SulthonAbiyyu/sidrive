// lib/screens/driver/widgets/request_driver/driver_bank_form_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/widgets/custom_textfield.dart';

class DriverBankFormWidget extends StatelessWidget {
  final bool hasBankInfo;
  final String? namaBank;
  final TextEditingController nomorRekeningController;
  final TextEditingController namaRekeningController;
  final List<String> bankList;
  final void Function(String? value) onBankChanged;

  const DriverBankFormWidget({
    super.key,
    required this.hasBankInfo,
    required this.namaBank,
    required this.nomorRekeningController,
    required this.namaRekeningController,
    required this.bankList,
    required this.onBankChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(16),
      decoration: BoxDecoration(
        color: hasBankInfo ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        border: Border.all(
          color: hasBankInfo ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Judul
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rekening Bank ${hasBankInfo ? "(Sudah Terdaftar)" : "(Opsional)"}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (hasBankInfo)
                Icon(
                  Icons.lock,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
            ],
          ),
          ResponsiveMobile.vSpace(8),

          // 🔹 Deskripsi
          Text(
            hasBankInfo
                ? 'Informasi bank Anda sudah terdaftar dan tidak dapat diubah di halaman ini.'
                : 'Digunakan untuk pencairan saldo. Jika sudah pernah diisi, Anda tidak perlu mengisinya kembali.',
            style: TextStyle(
              fontSize: 12,
              color: hasBankInfo ? Colors.orange.shade700 : Colors.grey.shade600,
            ),
          ),
          ResponsiveMobile.vSpace(16),

          IgnorePointer(
            ignoring: hasBankInfo,
            child: Opacity(
              opacity: hasBankInfo ? 0.6 : 1.0,
              child: DropdownButtonFormField<String>(
                value: namaBank,
                decoration: InputDecoration(
                  labelText: 'Nama Bank',
                  hintText: 'Pilih bank',
                  prefixIcon: Icon(
                    Icons.account_balance,
                    color: hasBankInfo ? Colors.grey : Colors.blue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: hasBankInfo ? Colors.grey.shade300 : Colors.grey.shade400,
                    ),
                  ),
                  filled: true,
                  fillColor: hasBankInfo ? Colors.grey.shade200 : Colors.white,
                ),
                isExpanded: true, // ✅ TAMBAHKAN INI!
                items: bankList.map((bank) {
                  return DropdownMenuItem(
                    value: bank,
                    child: Text(
                      bank,
                      overflow: TextOverflow.ellipsis, // ✅ TAMBAHKAN INI!
                      maxLines: 1, // ✅ TAMBAHKAN INI!
                    ),
                  );
                }).toList(),
                onChanged: hasBankInfo ? null : onBankChanged,
              ),
            ),
          ),
          ResponsiveMobile.vSpace(12),

          CustomTextField(
            label: 'Nomor Rekening',
            hint: '1234567890',
            controller: nomorRekeningController,
            keyboardType: TextInputType.number,
            enabled: !hasBankInfo, // ✅ Disabled jika sudah ada
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          ResponsiveMobile.vSpace(12),

          CustomTextField(
            label: 'Nama Pemilik Rekening',
            hint: 'Sesuai buku tabungan',
            controller: namaRekeningController,
            enabled: !hasBankInfo, // ✅ Disabled jika sudah ada
          ),
        ],
      ),
    );
  }
}