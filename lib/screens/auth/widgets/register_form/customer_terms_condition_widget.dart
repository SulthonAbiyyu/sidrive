// lib/screens/auth/widgets/register_form/customer_terms_condition_widget.dart
// ============================================================================
// SYARAT & KETENTUAN CUSTOMER — SIDRIVE UMSIDA
// Mengikuti pola yang sama dengan umkm_terms_condition_widget.dart
// dan driver_terms_condition_widget.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

// ============================================================================
// FUNGSI UNTUK MENAMPILKAN DIALOG S&K CUSTOMER
// Panggil: showCustomerTermsConditionDialog(context: context, onAgreed: () { ... });
// ============================================================================
Future<bool> showCustomerTermsConditionDialog({
  required BuildContext context,
  VoidCallback? onAgreed,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CustomerTermsConditionDialog(),
  );
  if (result == true) {
    onAgreed?.call();
  }
  return result ?? false;
}

class CustomerTermsConditionDialog extends StatefulWidget {
  const CustomerTermsConditionDialog({super.key});

  @override
  State<CustomerTermsConditionDialog> createState() =>
      _CustomerTermsConditionDialogState();
}

class _CustomerTermsConditionDialogState
    extends State<CustomerTermsConditionDialog> {
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
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: ResponsiveMobile.allScaledPadding(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade800],
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
                    Icons.shield_rounded,
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
                        'Syarat & Ketentuan Customer',
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

          // ── Banner scroll reminder ───────────────────────────────────────
          if (!_hasScrolledToBottom)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.scaledW(14),
                vertical: ResponsiveMobile.scaledH(8),
              ),
              color: Colors.teal.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.teal.shade800),
                  ResponsiveMobile.hSpace(6),
                  Expanded(
                    child: Text(
                      'Scroll ke bawah untuk membaca seluruh S&K',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context),
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Scrollable content ───────────────────────────────────────────
          Flexible(
            child: ListView(
              controller: _scrollController,
              padding: ResponsiveMobile.allScaledPadding(16),
              shrinkWrap: true,
              children: [
                _buildIntro(context),
                ResponsiveMobile.vSpace(16),

                // 1. Persyaratan Keanggotaan
                _buildSection(
                  context,
                  number: '1',
                  icon: Icons.school_rounded,
                  color: Colors.teal.shade600,
                  title: 'Persyaratan Keanggotaan',
                  items: [
                    'Pengguna layanan SiDrive wajib merupakan mahasiswa aktif Universitas Muhammadiyah Sidoarjo (UMSIDA) yang terdaftar secara resmi pada semester berjalan.',
                    'Pendaftaran akun customer dilakukan menggunakan identitas Nomor Induk Mahasiswa (NIM) yang valid dan terverifikasi melalui Kartu Tanda Mahasiswa (KTM).',
                    'Satu akun hanya dapat digunakan oleh satu mahasiswa dan tidak diperkenankan untuk dipinjamkan, diperjualbelikan, atau dialihkan kepada pihak lain.',
                    'Akun yang terbukti digunakan oleh bukan pemiliknya dapat dinonaktifkan sewaktu-waktu tanpa pemberitahuan sebelumnya.',
                    'Mahasiswa yang telah lulus, cuti akademik, atau tidak lagi berstatus mahasiswa aktif UMSIDA tidak diperkenankan menggunakan layanan platform ini.',
                  ],
                ),

                // 2. Layanan Customer
                _buildSection(
                  context,
                  number: '2',
                  icon: Icons.apps_rounded,
                  color: Colors.blue.shade600,
                  title: 'Layanan yang Tersedia',
                  items: [
                    'Customer dapat menggunakan layanan ojek online untuk pemesanan transportasi berbasis motor yang dioperasikan oleh sesama mahasiswa UMSIDA yang terdaftar sebagai driver.',
                    'Customer dapat melakukan pembelian dan checkout produk dari toko UMKM milik sesama mahasiswa UMSIDA yang terdaftar di platform SiDrive.',
                    'Ketersediaan layanan dapat berubah sewaktu-waktu sesuai dengan jam operasional driver atau UMKM yang bersangkutan.',
                    'SiDrive tidak menjamin ketersediaan driver atau produk UMKM setiap saat; layanan bergantung pada ketersediaan pengguna lain di platform.',
                  ],
                ),

                // 3. Batasan Area Layanan Ojek
                _buildSection(
                  context,
                  number: '3',
                  icon: Icons.location_on_rounded,
                  color: Colors.green.shade600,
                  title: 'Batasan Area Layanan Ojek',
                  items: [
                    'Layanan ojek online hanya dapat digunakan dalam radius maksimal 30 (tiga puluh) kilometer dari kampus Universitas Muhammadiyah Sidoarjo.',
                    'Pemesanan yang titik penjemputan atau tujuan berada di luar radius 30 km dari kampus UMSIDA tidak akan dapat diproses oleh sistem.',
                    'Batas radius dihitung secara garis lurus (radius lingkaran) dari titik koordinat resmi kampus UMSIDA.',
                    'Ketentuan batasan area ini ditetapkan demi keamanan driver dan customer serta memastikan kualitas layanan yang optimal di lingkungan kampus dan sekitarnya.',
                    'SiDrive berhak mengubah batas radius layanan sewaktu-waktu dengan pemberitahuan sebelumnya kepada pengguna.',
                  ],
                ),

                // 4. Metode Pembayaran
                _buildSection(
                  context,
                  number: '4',
                  icon: Icons.wallet_rounded,
                  color: Colors.purple.shade600,
                  title: 'Metode Pembayaran',
                  items: [
                    'Platform SiDrive menyediakan tiga metode pembayaran yang dapat dipilih oleh customer, yaitu: Tunai (Cash), Transfer Bank, dan Dompet Digital Internal (SiWallet).',
                    'Pembayaran Tunai (Cash) dilakukan secara langsung kepada driver atau UMKM pada saat transaksi selesai.',
                    'Pembayaran via Transfer Bank dilakukan melalui rekening yang tercantum pada platform.',
                    'SiWallet adalah dompet digital internal SiDrive yang dapat diisi (top-up) dan digunakan untuk transaksi di dalam platform tanpa perlu transfer manual setiap kali bertransaksi.',
                    'Customer bertanggung jawab penuh atas kebenaran dan kelengkapan data pembayaran yang diinputkan.',
                    'Segala bentuk kecurangan dalam pembayaran, termasuk namun tidak terbatas pada pembayaran fiktif, dapat berakibat pada pemblokiran akun secara permanen.',
                  ],
                ),

                // 5. Kewajiban & Etika Customer
                _buildSection(
                  context,
                  number: '5',
                  icon: Icons.handshake_rounded,
                  color: Colors.orange.shade600,
                  title: 'Kewajiban & Etika Customer',
                  items: [
                    'Customer wajib memberikan informasi yang benar, akurat, dan tidak menyesatkan saat melakukan pemesanan, termasuk alamat penjemputan, tujuan, dan data kontak.',
                    'Customer wajib bersikap sopan, santun, dan menghargai driver maupun penjual UMKM dalam setiap interaksi yang terjadi melalui platform.',
                    'Customer dilarang melakukan pembatalan pesanan secara berulang atau sembarangan yang dapat merugikan driver atau penjual UMKM.',
                    'Customer wajib menyelesaikan pembayaran sesuai dengan metode yang dipilih pada saat pemesanan dan tidak diperkenankan mengingkari kewajiban pembayaran.',
                    'Customer bertanggung jawab untuk memastikan keakuratan lokasi penjemputan dan tujuan agar tidak merugikan driver.',
                    'Customer dilarang meminta driver untuk melakukan tindakan yang melanggar hukum atau ketentuan yang berlaku.',
                  ],
                ),

                // 6. Pemesanan & Pembatalan
                _buildSection(
                  context,
                  number: '6',
                  icon: Icons.cancel_rounded,
                  color: Colors.red.shade600,
                  title: 'Pemesanan & Pembatalan',
                  items: [
                    'Pesanan yang telah dikonfirmasi oleh driver atau UMKM dianggap sebagai komitmen yang mengikat antara customer dengan pihak penyedia layanan.',
                    'Pembatalan pesanan oleh customer setelah driver atau UMKM menerima pesanan dapat dikenai catatan pada riwayat akun customer.',
                    'Pembatalan yang dilakukan oleh pihak driver atau UMKM akan mengakibatkan pengembalian dana (refund) sebesar 100% kepada customer.',
                    'Proses pengembalian dana via SiWallet dilakukan secara instan, sedangkan via transfer bank diselesaikan maksimal 1×24 jam pada hari kerja.',
                    'Customer dapat mengajukan keluhan atas pembatalan atau ketidaksesuaian layanan melalui fitur laporan yang tersedia di aplikasi.',
                  ],
                ),

                // 7. Ulasan & Penilaian
                _buildSection(
                  context,
                  number: '7',
                  icon: Icons.star_rounded,
                  color: Colors.amber.shade700,
                  title: 'Ulasan & Penilaian',
                  items: [
                    'Customer berhak memberikan penilaian (rating) dan ulasan (review) terhadap layanan driver maupun produk UMKM setelah transaksi selesai.',
                    'Ulasan yang diberikan harus jujur, objektif, dan relevan dengan pengalaman transaksi yang sesungguhnya.',
                    'Dilarang memberikan ulasan palsu, ulasan yang mengandung unsur SARA, fitnah, atau konten tidak pantas yang dapat merugikan pihak lain.',
                    'SiDrive berhak menghapus ulasan yang melanggar ketentuan tanpa pemberitahuan sebelumnya.',
                    'Penyalahgunaan fitur ulasan dapat berakibat pada pemblokiran akun customer.',
                  ],
                ),

                // 8. Privasi & Keamanan Data
                _buildSection(
                  context,
                  number: '8',
                  icon: Icons.lock_rounded,
                  color: Colors.indigo.shade600,
                  title: 'Privasi & Keamanan Data',
                  items: [
                    'SiDrive mengumpulkan dan memproses data pribadi customer (nama, NIM, nomor telepon, lokasi) semata-mata untuk keperluan operasional layanan.',
                    'Data pribadi customer tidak akan dijual, disewakan, atau dibagikan kepada pihak ketiga di luar keperluan operasional platform tanpa persetujuan customer.',
                    'Customer bertanggung jawab penuh atas kerahasiaan kata sandi (password) akun masing-masing dan wajib segera mengganti password apabila dicurigai telah diketahui pihak lain.',
                    'Customer dilarang menggunakan teknik rekayasa (hacking), scraping, atau metode otomatis lainnya untuk mengakses atau mengumpulkan data dari platform.',
                    'Dalam hal terjadi pelanggaran keamanan data, SiDrive akan memberitahukan customer yang terdampak sesuai dengan ketentuan yang berlaku.',
                  ],
                ),

                // 9. Larangan & Sanksi
                _buildSection(
                  context,
                  number: '9',
                  icon: Icons.warning_rounded,
                  color: Colors.deepOrange.shade600,
                  title: 'Larangan & Sanksi',
                  items: [
                    'Customer dilarang menggunakan platform SiDrive untuk tujuan yang melanggar hukum, peraturan perundang-undangan yang berlaku di Indonesia, atau norma kesusilaan.',
                    'Dilarang melakukan pelecehan, intimidasi, ancaman, atau tindakan yang tidak menyenangkan terhadap driver, penjual UMKM, maupun pengguna lain.',
                    'Dilarang membuat lebih dari satu akun untuk satu mahasiswa (multi-account) demi memanipulasi sistem atau mendapatkan keuntungan yang tidak seharusnya.',
                    'Pelanggaran ringan akan mendapatkan peringatan pertama melalui notifikasi aplikasi. Pelanggaran berulang dapat berakibat pada suspend sementara akun (7–30 hari).',
                    'Pelanggaran berat, termasuk penipuan pembayaran, harassment berat, atau tindak pidana, dapat berakibat pada pencabutan akses akun secara permanen dan pelaporan kepada pihak berwenang.',
                  ],
                ),

                // 10. Dukungan & Bantuan
                _buildSection(
                  context,
                  number: '10',
                  icon: Icons.support_agent_rounded,
                  color: Colors.cyan.shade700,
                  title: 'Dukungan & Bantuan',
                  items: [
                    'Tim SiDrive menyediakan layanan dukungan teknis melalui fitur bantuan (help center) yang tersedia di dalam aplikasi pada hari dan jam kerja (Senin–Jumat, 08.00–17.00 WIB).',
                    'Customer dapat melaporkan driver atau penjual UMKM yang berperilaku tidak sesuai melalui fitur laporan di aplikasi.',
                    'Pengaduan terkait transaksi yang bermasalah akan ditindaklanjuti oleh tim SiDrive maksimal 3×24 jam pada hari kerja.',
                    'SiDrive berhak melakukan perubahan terhadap S&K ini sewaktu-waktu; customer akan diberitahu melalui notifikasi aplikasi apabila terdapat perubahan material.',
                  ],
                ),

                // 11. Batasan Tanggung Jawab
                _buildSection(
                  context,
                  number: '11',
                  icon: Icons.gavel_rounded,
                  color: Colors.blueGrey.shade600,
                  title: 'Batasan Tanggung Jawab',
                  items: [
                    'SiDrive berperan sebagai platform penghubung antara customer dengan driver dan UMKM mahasiswa UMSIDA, bukan sebagai penyedia layanan transportasi atau penjual produk secara langsung.',
                    'SiDrive tidak bertanggung jawab atas kerugian yang timbul akibat kejadian di luar kendali platform (force majeure), termasuk namun tidak terbatas pada bencana alam, gangguan jaringan, atau kebijakan pemerintah.',
                    'SiDrive tidak menjamin bahwa layanan platform akan selalu bebas dari gangguan teknis, namun berkomitmen untuk memulihkan layanan sesegera mungkin apabila terjadi gangguan.',
                    'Customer mengakui bahwa penggunaan layanan ojek online merupakan kegiatan yang memiliki risiko inheren dan bertanggung jawab atas keselamatan diri masing-masing sesuai ketentuan yang berlaku.',
                  ],
                ),

                ResponsiveMobile.vSpace(16),
                _buildLastUpdated(context),
              ],
            ),
          ),

          // ── Footer: Checkbox + Tombol ────────────────────────────────────
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
                              ? (val) =>
                                  setState(() => _isAgreed = val ?? false)
                              : null,
                          activeColor: Colors.teal.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Saya telah membaca dan menyetujui seluruh Syarat & Ketentuan Customer SiDrive UMSIDA',
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
                          backgroundColor: Colors.teal.shade600,
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
                            fontSize:
                                ResponsiveMobile.captionSize(context) + 1,
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

  // ── Widget: Intro box ──────────────────────────────────────────────────────
  Widget _buildIntro(BuildContext context) {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(14),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Text(
        'Selamat datang di SiDrive! Sebelum menggunakan layanan, harap baca dan pahami seluruh Syarat & Ketentuan berikut dengan saksama. Dengan menekan "Setuju & Lanjutkan", Anda menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan di bawah ini, serta bersedia terikat secara hukum dengan ketentuan tersebut.',
        style: TextStyle(
          fontSize: ResponsiveMobile.captionSize(context),
          color: Colors.teal.shade800,
          height: 1.55,
        ),
      ),
    );
  }

  // ── Widget: Section ────────────────────────────────────────────────────────
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

  // ── Widget: Last updated ───────────────────────────────────────────────────
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