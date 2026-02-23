// lib/screens/auth/widgets/request_umkm/umkm_terms_condition_widget.dart
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

Future<bool> showUmkmTermsConditionDialog({
  required BuildContext context,
  VoidCallback? onAgreed,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UmkmTermsConditionDialog(),
  );
  if (result == true) {
    onAgreed?.call();
  }
  return result ?? false;
}

class UmkmTermsConditionDialog extends StatefulWidget {
  const UmkmTermsConditionDialog({super.key});

  @override
  State<UmkmTermsConditionDialog> createState() => _UmkmTermsConditionDialogState();
}

class _UmkmTermsConditionDialogState extends State<UmkmTermsConditionDialog> {
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
          Container(
            width: double.infinity,
            padding: ResponsiveMobile.allScaledPadding(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade700],
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
                        'Syarat & Ketentuan UMKM',
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
                  color: Colors.orange.shade600,
                  title: 'Persyaratan Keanggotaan',
                  items: [
                    'Pendaftar wajib merupakan mahasiswa aktif Universitas Muhammadiyah Sidoarjo (UMSIDA) yang terdaftar secara resmi pada semester berjalan.',
                    'Pendaftaran UMKM menggunakan akun yang sama dengan akun customer dan driver. Satu akun dapat memiliki ketiga role tersebut.',
                    'Akun mahasiswa hanya dapat digunakan oleh satu orang dan tidak boleh dipinjamkan atau digunakan pihak lain.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '2',
                  icon: Icons.store_rounded,
                  color: Colors.green.shade600,
                  title: 'Persyaratan Toko/Usaha',
                  items: [
                    'Toko yang didaftarkan wajib merupakan usaha milik sendiri atau usaha keluarga yang dikelola oleh mahasiswa.',
                    'Produk yang dijual harus halal, legal, dan tidak melanggar hukum yang berlaku di Indonesia.',
                    'Dilarang menjual produk terlarang seperti: narkoba, minuman keras, rokok/vape (untuk non-perokok), senjata tajam, atau produk ilegal lainnya.',
                    'Toko wajib memiliki lokasi operasional yang jelas dan dapat diakses oleh mahasiswa UMSIDA.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '3',
                  icon: Icons.upload_file_rounded,
                  color: Colors.blue.shade600,
                  title: 'Dokumen & Verifikasi',
                  items: [
                    'Foto toko dan produk yang diupload harus asli, jelas, dan tidak mengalami rekayasa/editing berlebihan.',
                    'Proses verifikasi data oleh tim SiDrive dilakukan maksimal 1×24 jam pada hari kerja (Senin–Jumat).',
                    'Apabila data tidak memenuhi syarat, pengajuan akan ditolak dan pendaftar dapat mengajukan ulang dengan data yang benar.',
                    'Foto produk minimal 2 (dua) foto yang menampilkan produk utama yang dijual di toko.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '4',
                  icon: Icons.star_rounded,
                  color: Colors.purple.shade600,
                  title: 'Kewajiban & Etika Penjual UMKM',
                  items: [
                    'Memberikan pelayanan yang ramah, sopan, dan profesional kepada setiap customer mahasiswa UMSIDA.',
                    'Menjaga kualitas produk yang dijual dan memastikan produk dalam kondisi baik saat diterima customer.',
                    'Memberikan deskripsi produk yang jelas, jujur, dan tidak menyesatkan (harga, ukuran, varian, dll).',
                    'Merespons pesanan dengan cepat dan mengupdate status pesanan secara real-time di aplikasi.',
                    'Menjaga kebersihan toko dan area sekitar untuk kenyamanan customer yang datang.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '5',
                  icon: Icons.wallet_rounded,
                  color: Colors.teal.shade600,
                  title: 'Transaksi & Pembayaran',
                  items: [
                    'Pembayaran dari customer akan ditransfer ke rekening UMKM yang terdaftar maksimal 1×24 jam setelah pesanan selesai/diterima customer.',
                    'UMKM wajib memberikan struk/nota pembelian kepada customer jika diminta.',
                    'Harga yang ditampilkan di aplikasi harus sesuai dengan harga yang dibayarkan customer (tidak ada biaya tersembunyi).',
                    'UMKM dapat memberikan promo/diskon khusus mahasiswa UMSIDA, namun harus diinformasikan dengan jelas di deskripsi produk.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '6',
                  icon: Icons.cancel_rounded,
                  color: Colors.red.shade600,
                  title: 'Pembatalan & Pengembalian',
                  items: [
                    'Jika terjadi pembatalan pesanan dari pihak UMKM (produk habis, toko tutup mendadak, dll), wajib menginformasikan ke customer sesegera mungkin.',
                    'Dana customer akan dikembalikan 100% jika pembatalan dilakukan oleh UMKM.',
                    'UMKM wajib menerima komplain customer jika produk tidak sesuai deskripsi atau mengalami kerusakan saat diterima.',
                    'Pengembalian dana/refund dapat dilakukan melalui admin SiDrive jika terjadi sengketa yang tidak dapat diselesaikan.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '7',
                  icon: Icons.warning_rounded,
                  color: Colors.deepOrange.shade600,
                  title: 'Larangan & Sanksi',
                  items: [
                    'Dilarang melakukan kecurangan seperti: manipulasi harga, produk palsu, menjual produk ilegal, atau tindakan tidak jujur lainnya.',
                    'Dilarang melakukan harassment, diskriminasi, atau tindakan tidak menyenangkan terhadap customer atau sesama UMKM.',
                    'Dilarang menggunakan akun orang lain atau memberikan akses UMKM kepada pihak yang bukan mahasiswa UMSIDA.',
                    'Pelanggaran terhadap S&K dapat berakibat: peringatan, suspend sementara, atau pencabutan akses UMKM secara permanen.',
                  ],
                ),
                _buildSection(
                  context,
                  number: '8',
                  icon: Icons.support_agent_rounded,
                  color: Colors.indigo.shade600,
                  title: 'Dukungan & Bantuan',
                  items: [
                    'Tim SiDrive menyediakan dukungan melalui fitur chat/bantuan di aplikasi untuk kendala teknis atau pertanyaan seputar UMKM.',
                    'UMKM dapat melaporkan customer yang melakukan pelanggaran (pembayaran palsu, komplain tidak jelas, dll) melalui fitur laporan di aplikasi.',
                    'SiDrive berhak melakukan moderasi terhadap produk yang dijual untuk menjaga kualitas dan keamanan platform.',
                  ],
                ),
                ResponsiveMobile.vSpace(16),
                _buildLastUpdated(context),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveMobile.scaledW(16),
              vertical: ResponsiveMobile.scaledH(14),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
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
                          activeColor: Colors.orange.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Saya telah membaca dan menyetujui seluruh Syarat & Ketentuan UMKM SiDrive UMSIDA',
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
                          backgroundColor: Colors.orange.shade600,
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
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        'Selamat datang di program UMKM SiDrive! Sebelum mendaftar, harap baca dan pahami seluruh syarat & ketentuan berikut. Dengan menekan "Setuju & Lanjutkan", kamu menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan di bawah ini.',
        style: TextStyle(
          fontSize: ResponsiveMobile.captionSize(context),
          color: Colors.orange.shade800,
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