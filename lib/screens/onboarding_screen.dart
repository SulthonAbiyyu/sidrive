// lib/screens/onboarding/onboarding_screen.dart
// ============================================================================
// ONBOARDING_SCREEN.DART - REVISI TOTAL V2
// FIX:
// - Teks benar sesuai kata2sidrive.txt
// - Slide 1: Text di ATAS/TENGAH (mobil di bawah)
// - Slide 2 & 3: Text di BAWAH (animasi di tengah/atas)
// - Align CENTER
// - Font kreatif dengan variasi
// - ANIMASI SWIPE INDICATOR (animated arrow)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:sidrive/config/constants.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  VideoPlayerController? _videoController1;
  VideoPlayerController? _videoController3;
  bool _isVideo1Initialized = false;
  bool _isVideo3Initialized = false;

  // Animation controller untuk swipe indicator
  late AnimationController _swipeAnimController;
  late Animation<double> _swipeAnimation;

  final List<Map<String, dynamic>> _slides = [
    {
      'type': 'video',
      'asset': AssetPaths.onboarding1Video,
      'title': '"Halo Mahasiswa Umsida,\nAyo Bergerak Lebih Mudah!"',
      'desc':
          'Butuh ojek untuk berangkat ke kampus, balik ke kos, atau pergi ke tempat lain?\n\nSIDRIVE siap bantu—dengan driver mahasiswa yang aman, dekat, dan selalu mengerti kebutuhan mobilitas kamu.',
      'textPosition': 'top', // Text di ATAS/TENGAH
    },
    {
      'type': 'image',
      'asset': AssetPaths.onboarding2Image,
      'title': '"Pesanan Kamu,\nDiantar Sampai Pintu Kelas."',
      'desc':
          'Mahasiswa driver SIDRIVE bisa mengantar makanan atau produk UMKM langsung ke ruang kelas, laboratorium, kantin, perpustakaan, atau titik mana pun di dalam area kampus.\n\nTidak perlu keluar gedung atau jalan jauh hanya untuk ambil pesanan.',
      'textPosition': 'bottom', // Text di BAWAH
    },
    {
      'type': 'video',
      'asset': AssetPaths.onboarding3Video,
      'title': '"Dukung Teman, Nikmati\nProduk Karya Mahasiswa."',
      'desc':
          'Semua UMKM di SIDRIVE dikelola oleh mahasiswa Umsida.\n\nKamu bisa menemukan makanan, minuman, ataupun produk kreatif sambil ikut membantu usaha teman sendiri.',
      'textPosition': 'bottom', // Text di BAWAH
    },
  ];

  @override
  void initState() {
    super.initState();
    _initVideoControllers();
    _initSwipeAnimation();
  }

  void _initSwipeAnimation() {
    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _swipeAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initVideoControllers() async {
    _videoController1 = VideoPlayerController.asset(AssetPaths.onboarding1Video);
    await _videoController1!.initialize();
    _videoController1!.setLooping(true);
    _videoController1!.setVolume(0);
    setState(() => _isVideo1Initialized = true);

    _videoController3 = VideoPlayerController.asset(AssetPaths.onboarding3Video);
    await _videoController3!.initialize();
    _videoController3!.setLooping(true);
    _videoController3!.setVolume(0);
    setState(() => _isVideo3Initialized = true);

    if (_currentPage == 0) _videoController1!.play();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);

    _videoController1?.pause();
    _videoController3?.pause();

    if (page == 0 && _isVideo1Initialized) {
      _videoController1!.play();
    } else if (page == 2 && _isVideo3Initialized) {
      _videoController3!.play();
    }

    if (page == _slides.length) {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await StorageService.setFirstTime(false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController1?.dispose();
    _videoController3?.dispose();
    _swipeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ============================================================
            // PAGEVIEW SLIDES
            // ============================================================
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length + 1,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                if (index == _slides.length) return const SizedBox();
                return _buildSlide(_slides[index], index);
              },
            ),

            // ============================================================
            // SKIP BUTTON (TOP RIGHT)
            // ============================================================
            Positioned(
              top: ResponsiveMobile.scaledH(16),
              right: ResponsiveMobile.scaledW(16),
              child: TextButton(
                onPressed: _finishOnboarding,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveMobile.scaledW(16),
                    vertical: ResponsiveMobile.scaledH(8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
                  ),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(14),
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // ============================================================
            // ANIMATED SWIPE INDICATOR (Kanan bawah)
            // ============================================================
            if (_currentPage < _slides.length - 1)
              Positioned(
                bottom: ResponsiveMobile.scaledH(80),
                right: ResponsiveMobile.scaledW(24),
                child: AnimatedBuilder(
                  animation: _swipeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_swipeAnimation.value, 0),
                      child: Container(
                        padding: EdgeInsets.all(ResponsiveMobile.scaledR(8)),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Geser',
                              style: TextStyle(
                                fontSize: ResponsiveMobile.scaledFont(12),
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: ResponsiveMobile.scaledW(4)),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: ResponsiveMobile.scaledSP(16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ============================================================
            // PAGE INDICATOR (BOTTOM CENTER)
            // ============================================================
            Positioned(
              bottom: ResponsiveMobile.scaledH(32),
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _buildIndicator(index == _currentPage),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slideData, int index) {
    final textPosition = slideData['textPosition'];

    return Stack(
      children: [
        // BACKGROUND
        Positioned.fill(
          child: slideData['type'] == 'video'
              ? _buildVideoBackground(index)
              : _buildImageBackground(slideData['asset']),
        ),


        // TEXT CONTENT
        if (textPosition == 'top')
          // TEXT DI ATAS/TENGAH (Slide 1)
          Positioned(
            top: ResponsiveMobile.scaledH(100),
            left: ResponsiveMobile.scaledW(24),
            right: ResponsiveMobile.scaledW(24),
            child: _buildTextContent(slideData),
          )
        else
          // TEXT DI BAWAH (Slide 2 & 3)
          Positioned(
            bottom: ResponsiveMobile.scaledH(100),
            left: ResponsiveMobile.scaledW(24),
            right: ResponsiveMobile.scaledW(24),
            child: _buildTextContent(slideData),
          ),
      ],
    );
  }

  Widget _buildTextContent(Map<String, dynamic> slideData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // TITLE - CENTER, BOLD, ITALIC
        Text(
          slideData['title'],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(20),
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.3,
            letterSpacing: 0.3,
            fontStyle: FontStyle.italic,
          ),
        ),

        SizedBox(height: ResponsiveMobile.scaledH(16)),

        // DESCRIPTION - CENTER
        Text(
          slideData['desc'],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(13),
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.95),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoBackground(int index) {
    VideoPlayerController? controller;
    bool isInitialized = false;

    if (index == 0) {
      controller = _videoController1;
      isInitialized = _isVideo1Initialized;
    } else if (index == 2) {
      controller = _videoController3;
      isInitialized = _isVideo3Initialized;
    }

    if (!isInitialized || controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildImageBackground(String assetPath) {
    return Image.asset(assetPath, fit: BoxFit.cover);
  }

  Widget _buildIndicator(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(4)),
      height: ResponsiveMobile.scaledH(8),
      width: active ? ResponsiveMobile.scaledW(24) : ResponsiveMobile.scaledW(8),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
      ),
    );
  }
}