// ============================================================================
// HELP FAQ PAGE
// Halaman Bantuan & FAQ dengan dua pilihan:
//   1. FAQ   → Accordion list pertanyaan umum
//   2. Live Chat → Buka room CS realtime dengan admin
// ============================================================================
// Dipanggil dari: profile_tab.dart → _buildCommonMenus → 'Bantuan & FAQ'
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/services/customer_support_service.dart';
import 'package:sidrive/screens/chat/chat_room_page.dart';

class HelpFaqPage extends StatefulWidget {
  const HelpFaqPage({super.key});

  @override
  State<HelpFaqPage> createState() => _HelpFaqPageState();
}

class _HelpFaqPageState extends State<HelpFaqPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isStartingChat = false;

  // =========================================================================
  // DATA FAQ
  // Tambah/ubah item FAQ di sini sesuai kebutuhan
  // =========================================================================
  final List<FaqItem> _faqItems = [
    FaqItem(
      question: 'Bagaimana cara memesan ojek/mobil di SiDrive?',
      answer:
          'Buka halaman utama, pilih jenis kendaraan (motor atau mobil), '
          'masukkan tujuan Anda, lalu tekan tombol "Pesan Sekarang". '
          'Driver terdekat akan menerima pesanan Anda secara otomatis.',
    ),
    FaqItem(
      question: 'Bagaimana cara membayar pesanan?',
      answer:
          'SiDrive menggunakan sistem dompet digital (wallet). '
          'Pastikan saldo wallet Anda mencukupi sebelum memesan. '
          'Anda bisa mengisi saldo melalui menu Wallet di halaman utama.',
    ),
    FaqItem(
      question: 'Apa yang harus dilakukan jika driver tidak datang?',
      answer:
          'Jika driver tidak datang dalam waktu lebih dari 10 menit, '
          'Anda dapat membatalkan pesanan melalui menu "Pesanan Aktif" '
          'tanpa dikenakan biaya pembatalan. Hubungi CS jika membutuhkan bantuan.',
    ),
    FaqItem(
      question: 'Bagaimana cara mendaftar sebagai driver?',
      answer:
          'Buka halaman Profil → Role Anda → klik "Tambah Role" → pilih Driver. '
          'Lengkapi data kendaraan dan upload dokumen yang diminta. '
          'Admin akan memverifikasi data Anda dalam 1×24 jam.',
    ),
    FaqItem(
      question: 'Bagaimana cara berjualan di SiDrive (UMKM)?',
      answer:
          'Buka halaman Profil → Role Anda → klik "Tambah Role" → pilih UMKM. '
          'Isi data toko dan upload dokumen usaha Anda. '
          'Setelah diverifikasi admin, Anda bisa mulai menambahkan produk.',
    ),
    FaqItem(
      question: 'Bagaimana cara melacak pesanan secara real-time?',
      answer:
          'Setelah pesanan diterima driver, Anda bisa melihat posisi driver '
          'secara real-time di halaman "Pesanan Aktif". '
          'Notifikasi otomatis akan dikirim saat status pesanan berubah.',
    ),
    FaqItem(
      question: 'Apakah saldo wallet bisa dikembalikan (refund)?',
      answer:
          'Refund saldo dilakukan otomatis jika pesanan dibatalkan oleh driver. '
          'Proses refund berlangsung dalam beberapa menit. '
          'Jika saldo tidak kembali dalam 1 jam, hubungi CS kami.',
    ),
    FaqItem(
      question: 'Bagaimana cara menghubungi driver saat perjalanan?',
      answer:
          'Setelah driver menempuh minimal 2 km, fitur chat akan aktif otomatis. '
          'Anda dapat mengirim pesan langsung kepada driver '
          'melalui ikon chat di halaman pesanan aktif.',
    ),
    FaqItem(
      question: 'Apa yang terjadi jika aplikasi error saat memesan?',
      answer:
          'Jika terjadi error, coba tutup dan buka kembali aplikasi. '
          'Periksa koneksi internet Anda. '
          'Jika masalah berlanjut, hubungi tim CS kami melalui fitur Live Chat.',
    ),
    FaqItem(
      question: 'Bagaimana cara mengubah data profil saya?',
      answer:
          'Buka halaman Profil → Pengaturan → Edit Profil. '
          'Anda dapat mengubah nama, nomor telepon, dan foto profil. '
          'Perubahan akan tersimpan otomatis.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =========================================================================
  // BUKA LIVE CHAT
  // =========================================================================
  Future<void> _openLiveChat() async {
    if (_isStartingChat) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      _showError('Silakan login terlebih dahulu.');
      return;
    }

    setState(() => _isStartingChat = true);

    try {
      final service = CustomerSupportService();
      final result = await service.createOrGetSupportRoom(
        userId: user.idUser,
        userRole: authProvider.activeRole ?? user.role,
      );

      if (!mounted) return;

      if (!result.isSuccess || result.room == null) {
        _showError(result.errorMessage ?? 'Gagal memulai chat.');
        return;
      }

      // Navigasi ke ChatRoomPage dengan room yang sudah ada
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            roomId: result.room!.id,
            room: result.room,
            currentUserId: user.idUser,
            currentUserRole: authProvider.activeRole ?? user.role,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bantuan & FAQ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveMobile.scaledFont(18),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(14),
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(14),
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.quiz_outlined, size: 20),
              text: 'FAQ',
            ),
            Tab(
              icon: Icon(Icons.support_agent_outlined, size: 20),
              text: 'Live Chat',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(),
          _buildLiveChatTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB FAQ
  // =========================================================================
  Widget _buildFaqTab() {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveMobile.wp(context, 5),
        vertical: ResponsiveMobile.scaledH(16),
      ),
      children: [
        // Header info
        Container(
          padding: ResponsiveMobile.allScaledPadding(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade50, Colors.teal.shade100],
            ),
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.teal.shade700,
                size: ResponsiveMobile.scaledFont(24),
              ),
              SizedBox(width: ResponsiveMobile.scaledW(12)),
              Expanded(
                child: Text(
                  'Temukan jawaban untuk pertanyaan yang sering diajukan',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(13),
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: ResponsiveMobile.scaledH(16)),

        // FAQ List
        ..._faqItems.asMap().entries.map((entry) {
          return _buildFaqTile(entry.value, entry.key);
        }),

        SizedBox(height: ResponsiveMobile.scaledH(16)),

        // CTA ke Live Chat
        _buildCtaToLiveChat(),

        SizedBox(height: ResponsiveMobile.scaledH(24)),
      ],
    );
  }

  Widget _buildFaqTile(FaqItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: ResponsiveMobile.scaledW(16),
            vertical: ResponsiveMobile.scaledH(4),
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            ResponsiveMobile.scaledW(16),
            0,
            ResponsiveMobile.scaledW(16),
            ResponsiveMobile.scaledH(14),
          ),
          leading: Container(
            width: ResponsiveMobile.scaledW(32),
            height: ResponsiveMobile.scaledW(32),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(13),
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ),
          ),
          title: Text(
            item.question,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          iconColor: Colors.teal,
          collapsedIconColor: Colors.grey,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
              ),
              child: Text(
                item.answer,
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(13),
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaToLiveChat() {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: ResponsiveMobile.allScaledPadding(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.headset_mic_outlined,
              color: Colors.white,
              size: ResponsiveMobile.scaledFont(24),
            ),
          ),
          SizedBox(width: ResponsiveMobile.scaledW(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidak menemukan jawaban?',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(14),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveMobile.scaledH(4)),
                Text(
                  'Chat langsung dengan tim CS kami',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(12),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
            child: InkWell(
              onTap: () {
                _tabController.animateTo(1); // Pindah ke tab Live Chat
              },
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveMobile.scaledW(12),
                  vertical: ResponsiveMobile.scaledH(8),
                ),
                child: Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(13),
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB LIVE CHAT
  // =========================================================================
  Widget _buildLiveChatTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveMobile.wp(context, 5),
        vertical: ResponsiveMobile.scaledH(24),
      ),
      child: Column(
        children: [
          // Ilustrasi / Hero
          Container(
            width: double.infinity,
            padding: ResponsiveMobile.allScaledPadding(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.teal.shade400, Colors.teal.shade700],
              ),
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: ResponsiveMobile.scaledW(80),
                  height: ResponsiveMobile.scaledW(80),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent,
                    size: ResponsiveMobile.scaledFont(44),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveMobile.scaledH(16)),
                Text(
                  'Customer Service SiDrive',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveMobile.scaledH(8)),
                Text(
                  'Tim kami siap membantu Anda\nSetiap hari • 08.00 - 21.00 WIB',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(13),
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: ResponsiveMobile.scaledH(24)),

          // Info cards
          _buildInfoCard(
            icon: Icons.bolt_outlined,
            title: 'Respons Cepat',
            subtitle: 'Rata-rata waktu balasan kurang dari 5 menit',
            color: Colors.orange,
          ),
          SizedBox(height: ResponsiveMobile.scaledH(10)),
          _buildInfoCard(
            icon: Icons.history_outlined,
            title: 'Riwayat Tersimpan',
            subtitle: 'Semua percakapan tersimpan dan bisa dibuka kembali',
            color: Colors.blue,
          ),
          SizedBox(height: ResponsiveMobile.scaledH(10)),
          _buildInfoCard(
            icon: Icons.security_outlined,
            title: 'Aman & Terpercaya',
            subtitle: 'Percakapan Anda bersifat rahasia',
            color: Colors.green,
          ),

          SizedBox(height: ResponsiveMobile.scaledH(32)),

          // Tombol Mulai Chat
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isStartingChat ? null : _openLiveChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.teal.shade200,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveMobile.scaledH(16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
                ),
                elevation: 0,
              ),
              child: _isStartingChat
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: ResponsiveMobile.scaledW(20),
                          height: ResponsiveMobile.scaledW(20),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: ResponsiveMobile.scaledW(10)),
                        Text(
                          'Menghubungkan...',
                          style: TextStyle(
                            fontSize: ResponsiveMobile.scaledFont(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: ResponsiveMobile.scaledFont(22),
                        ),
                        SizedBox(width: ResponsiveMobile.scaledW(10)),
                        Text(
                          'Mulai Live Chat',
                          style: TextStyle(
                            fontSize: ResponsiveMobile.scaledFont(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: ResponsiveMobile.scaledH(16)),

          // Catatan kecil
          Text(
            'Chat Anda akan dijawab oleh tim customer service kami.\nPercakapan sebelumnya tetap tersimpan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(12),
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),

          SizedBox(height: ResponsiveMobile.scaledH(24)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveMobile.scaledW(16),
        vertical: ResponsiveMobile.scaledH(14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveMobile.scaledW(44),
            height: ResponsiveMobile.scaledW(44),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveMobile.scaledFont(22),
            ),
          ),
          SizedBox(width: ResponsiveMobile.scaledW(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: ResponsiveMobile.scaledH(3)),
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
        ],
      ),
    );
  }
}

// ============================================================================
// DATA CLASS FAQ
// ============================================================================
class FaqItem {
  final String question;
  final String answer;

  const FaqItem({
    required this.question,
    required this.answer,
  });
}