// lib/screens/driver/widgets/request_driver/driver_terms_condition_widget.dart
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

// ============================================================================
// FUNGSI UNTUK MENAMPILKAN DIALOG S&K DRIVER
// Panggil: showDriverTermsConditionDialog(context: context, onAgreed: () { ... });
// ============================================================================
Future<bool> showDriverTermsConditionDialog({
  required BuildContext context,
  VoidCallback? onAgreed,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const DriverTermsConditionDialog(),
  );
  if (result == true) {
    onAgreed?.call();
  }
  return result ?? false;
}

class DriverTermsConditionDialog extends StatefulWidget {
  const DriverTermsConditionDialog({super.key});

  @override
  State<DriverTermsConditionDialog> createState() => _DriverTermsConditionDialogState();
}

class _DriverTermsConditionDialogState extends State<DriverTermsConditionDialog> {
  bool _isAgreed = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() => _hasScrolledToBottom = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveMobile.scaledW(16),
        vertical: ResponsiveMobile.scaledH(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: ResponsiveMobile.allScaledPadding(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ResponsiveMobile.scaledR(20)),
                topRight: Radius.circular(ResponsiveMobile.scaledR(20)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                ResponsiveMobile.hSpace(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Syarat & Ketentuan Driver',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.bodySize(context) + 1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'SiDrive — Platform Mahasiswa UMSIDA',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.captionSize(context),
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Peringatan scroll ──
          if (!_hasScrolledToBottom)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(14),
                vertical: ResponsiveMobile.scaledH(8),
              ),
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.amber.shade800),
                  ResponsiveMobile.hSpace(6),
                  Expanded(
                    child: Text(
                      'Scroll ke bawah untuk membaca seluruh S&K',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context),
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Isi S&K ──
          Flexible(
            child: ListView(
              controller: _scrollController,
              padding: ResponsiveMobile.allScaledPadding(16),
              shrinkWrap: true,
              children: [
                _buildIntro(context),
                ResponsiveMobile.vSpace(16),
                _buildSection(
                  context,
                  number: '1',
                  icon: Icons.school_rounded,
                  color: Colors.blue.shade600,
                  title: 'Persyaratan Keanggotaan',
                  items: [
                    'Pendaftar wajib merupakan mahasiswa aktif Universitas Muhammadiyah Sidoarjo (UMSIDA) yang terdaftar secara resmi pada semester berjalan.',
                    'Pendaftaran driver menggunakan akun yang sama dengan akun customer dan UMKM. Satu akun dapat memiliki ketiga role tersebut.',
                    'Akun mahasiswa hanya dapat digunakan oleh satu orang dan tidak boleh dipinjamkan atau digunakan pihak lain.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '2',
                  icon: Icons.two_wheeler_rounded,
                  color: Colors.green.shade600,
                  title: 'Persyaratan Kendaraan',
                  items: [
                    'Kendaraan yang didaftarkan (motor/mobil) wajib dimiliki sendiri atau atas nama keluarga inti (orang tua atau saudara kandung).',
                    'STNK dan SIM wajib masih aktif/berlaku pada saat pengajuan pendaftaran driver dilakukan.',
                    'Kendaraan harus dalam kondisi layak jalan, bersih, dan tidak mengalami kerusakan yang membahayakan penumpang.',
                    'Satu akun dapat mendaftarkan maksimal satu kendaraan motor dan satu kendaraan mobil.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '3',
                  icon: Icons.upload_file_rounded,
                  color: Colors.orange.shade600,
                  title: 'Dokumen & Verifikasi',
                  items: [
                    'Foto STNK, SIM, dan kendaraan yang diupload harus asli, jelas terbaca, dan tidak mengalami rekayasa/editing.',
                    'Proses verifikasi dokumen oleh tim SiDrive dilakukan maksimal 1×24 jam pada hari kerja (Senin–Jumat).',
                    'Apabila dokumen tidak memenuhi syarat, pengajuan akan ditolak dan pendaftar dapat mengajukan ulang dengan dokumen yang benar.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '4',
                  icon: Icons.star_rounded,
                  color: Colors.purple.shade600,
                  title: 'Kewajiban & Etika Driver',
                  items: [
                    'Driver wajib bersikap sopan, ramah, dan profesional kepada seluruh penumpang tanpa terkecuali.',
                    'Dilarang berkendara dalam keadaan mengantuk, mabuk, atau di bawah pengaruh zat terlarang apapun.',
                    'Driver wajib mematuhi peraturan lalu lintas yang berlaku dan mengutamakan keselamatan penumpang.',
                    'Dilarang merokok, menghidupkan musik terlalu keras, atau melakukan tindakan yang membuat penumpang tidak nyaman selama perjalanan.',
                    'Driver dilarang menolak pesanan yang masuk tanpa alasan yang jelas dan berulang-ulang.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '5',
                  icon: Icons.payments_rounded,
                  color: Colors.teal.shade600,
                  title: 'Pendapatan & Pembayaran',
                  items: [
                    'Pendapatan driver akan dihitung berdasarkan tarif yang telah ditetapkan oleh sistem SiDrive.',
                    'Pencairan saldo pendapatan dilakukan melalui rekening bank yang terdaftar di akun driver.',
                    'Rekening bank yang didaftarkan wajib atas nama driver sendiri. SiDrive tidak bertanggung jawab atas kesalahan pencairan akibat data rekening yang tidak valid.',
                    'Saldo pendapatan tidak dapat dipindahtangankan ke akun lain.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '6',
                  icon: Icons.warning_rounded,
                  color: Colors.red.shade600,
                  title: 'Penonaktifan & Sanksi',
                  items: [
                    'Akun driver dapat dinonaktifkan sementara atau permanen apabila terbukti melanggar Syarat & Ketentuan ini.',
                    'Laporan negatif yang berulang dari penumpang (rating buruk, komplain) dapat menyebabkan peninjauan akun oleh tim SiDrive.',
                    'Pemalsuan data atau dokumen yang diupload akan langsung berakibat pada pemblokiran akun secara permanen dan dapat dilaporkan ke pihak kampus.',
                    'Driver yang tidak aktif selama lebih dari 60 hari kalender tanpa pemberitahuan dapat dinonaktifkan sementara.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '7',
                  icon: Icons.privacy_tip_rounded,
                  color: Colors.indigo.shade600,
                  title: 'Privasi & Data',
                  items: [
                    'Data pribadi driver (nama, foto, nomor kendaraan, rekening) digunakan semata-mata untuk operasional layanan SiDrive.',
                    'Data driver tidak akan dibagikan kepada pihak ketiga tanpa persetujuan, kecuali diwajibkan oleh hukum yang berlaku.',
                    'Driver bertanggung jawab menjaga keamanan akun dan kerahasiaan password masing-masing.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '8',
                  icon: Icons.update_rounded,
                  color: Colors.blueGrey.shade600,
                  title: 'Perubahan Ketentuan',
                  items: [
                    'SiDrive berhak memperbarui Syarat & Ketentuan ini sewaktu-waktu.',
                    'Perubahan akan diberitahukan melalui notifikasi aplikasi. Penggunaan layanan driver setelah perubahan dianggap sebagai persetujuan atas ketentuan baru.',
                  ],
                ),
                ResponsiveMobile.vSpace(8),
                _buildLastUpdated(context),
                ResponsiveMobile.vSpace(4),
              ],
            ),
          ),

          // ── Checkbox & Tombol ──
          Container(
            padding: ResponsiveMobile.allScaledPadding(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(ResponsiveMobile.scaledR(20)),
                bottomRight: Radius.circular(ResponsiveMobile.scaledR(20)),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: _hasScrolledToBottom
                      ? () => setState(() => _isAgreed = !_isAgreed)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Opacity(
                    opacity: _hasScrolledToBottom ? 1.0 : 0.5,
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          onChanged: _hasScrolledToBottom
                              ? (val) => setState(() => _isAgreed = val ?? false)
                              : null,
                          activeColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Saya telah membaca dan menyetujui seluruh Syarat & Ketentuan Driver SiDrive UMSIDA',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.captionSize(context),
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ResponsiveMobile.vSpace(12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ResponsiveMobile.scaledR(12)),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: Text(
                          'Tolak',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    ResponsiveMobile.hSpace(12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isAgreed
                            ? () => Navigator.pop(context, true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ResponsiveMobile.scaledR(12)),
                          ),
                        ),
                        child: Text(
                          'Setuju & Lanjutkan',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveMobile.captionSize(context) + 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        'Selamat datang di program Driver SiDrive! Sebelum mendaftar, harap baca dan pahami seluruh syarat & ketentuan berikut. Dengan menekan "Setuju & Lanjutkan", kamu menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan di bawah ini.',
        style: TextStyle(
          fontSize: ResponsiveMobile.captionSize(context),
          color: Colors.blue.shade800,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String number,
    required IconData icon,
    required Color color,
    required String title,
    required List<String> items,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              ResponsiveMobile.hSpace(10),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.captionSize(context) + 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          ResponsiveMobile.vSpace(8),
          ...items.map((text) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveMobile.scaledH(6),
                left: ResponsiveMobile.scaledW(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  ResponsiveMobile.hSpace(8),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context),
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    return Text(
      'Terakhir diperbarui: 2025 · SiDrive UMSIDA',
      style: TextStyle(
        fontSize: ResponsiveMobile.captionSize(context) - 1,
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}