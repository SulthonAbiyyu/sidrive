import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/widgets/custom_textfield.dart';

class UmkmBankSection extends StatelessWidget {
  final TextEditingController namaBankController;
  final TextEditingController nomorRekeningController;
  final TextEditingController namaRekeningController;

  const UmkmBankSection({
    super.key,
    required this.namaBankController,
    required this.nomorRekeningController,
    required this.namaRekeningController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CustomTextField(
            label: 'Nama Bank',
            hint: 'BCA / Mandiri / BRI',
            controller: namaBankController,
          ),
          ResponsiveMobile.vSpace(12),
          CustomTextField(
            label: 'Nomor Rekening',
            hint: '1234567890',
            controller: nomorRekeningController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          ResponsiveMobile.vSpace(12),
          CustomTextField(
            label: 'Nama Pemilik Rekening',
            hint: 'Sesuai buku tabungan',
            controller: namaRekeningController,
          ),
        ],
      ),
    );
  }
}