// lib/screens/auth/widgets/request_umkm/umkm_bank_form_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class UmkmBankFormWidget extends StatelessWidget {
  final bool hasBankData;
  final String? namaBank;
  final TextEditingController nomorRekeningController;
  final TextEditingController namaRekeningController;
  final List<String> bankList;
  final ValueChanged<String?> onBankChanged;

  const UmkmBankFormWidget({
    super.key,
    required this.hasBankData,
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
        color: hasBankData ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        border: Border.all(
          color: hasBankData ? Colors.grey.shade400 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBankData) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data bank sudah terisi dari profil Anda',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          IgnorePointer(
            ignoring: hasBankData,
            child: Opacity(
              opacity: hasBankData ? 0.6 : 1.0,
              child: DropdownButtonFormField<String>(
                value: namaBank,
                decoration: InputDecoration(
                  labelText: 'Nama Bank',
                  hintText: 'Pilih bank',
                  prefixIcon: Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.account_balance,
                      color: hasBankData ? Colors.grey : Colors.orange,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: hasBankData ? Colors.grey.shade300 : Colors.grey.shade400,
                    ),
                  ),
                  filled: true,
                  fillColor: hasBankData ? Colors.grey.shade200 : Colors.white,
                ),
                isExpanded: true,
                items: bankList.map((bank) {
                  return DropdownMenuItem(
                    value: bank,
                    child: Text(
                      bank,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: hasBankData ? null : onBankChanged,
              ),
            ),
          ),
          
          ResponsiveMobile.vSpace(12),
          
          IgnorePointer(
            ignoring: hasBankData,
            child: Opacity(
              opacity: hasBankData ? 0.6 : 1.0,
              child: TextFormField(
                controller: nomorRekeningController,
                decoration: InputDecoration(
                  labelText: 'Nomor Rekening',
                  hintText: '1234567890',
                  prefixIcon: Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.credit_card,
                      color: hasBankData ? Colors.grey : Colors.orange,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: hasBankData ? Colors.grey.shade300 : Colors.grey.shade400,
                    ),
                  ),
                  filled: true,
                  fillColor: hasBankData ? Colors.grey.shade200 : Colors.white,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !hasBankData,
              ),
            ),
          ),
          
          ResponsiveMobile.vSpace(12),
          
          IgnorePointer(
            ignoring: hasBankData,
            child: Opacity(
              opacity: hasBankData ? 0.6 : 1.0,
              child: TextFormField(
                controller: namaRekeningController,
                decoration: InputDecoration(
                  labelText: 'Nama Pemilik Rekening',
                  hintText: 'Sesuai buku tabungan',
                  prefixIcon: Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person,
                      color: hasBankData ? Colors.grey : Colors.orange,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: hasBankData ? Colors.grey.shade300 : Colors.grey.shade400,
                    ),
                  ),
                  filled: true,
                  fillColor: hasBankData ? Colors.grey.shade200 : Colors.white,
                ),
                enabled: !hasBankData,
              ),
            ),
          ),
        ],
      ),
    );
  }
}