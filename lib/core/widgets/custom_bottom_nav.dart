import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ TAMBAH untuk haptic feedback
import 'dart:ui';
import 'dart:math' as math;

class CustomBottomNav extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final String role;
  final Map<int, int>? badgeCounts;

  const CustomBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
    required this.role,
    this.badgeCounts,
  }) : super(key: key);

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  String? _hoveredOption;

  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // ✅ CONSTANTS untuk mudah maintenance
  static const double _floatingButtonSize = 64.0;
  static const double _optionButtonSize = 40.0;
  static const double _deadZone = 15.0; // ✅ Diperbesar sedikit
  static const double _optionDistance = 65.0;
  static const double _navbarHeight = 65.0;
  static const double _navbarRadius = 25.0;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _showOptions() {
    // ✅ TAMBAH: Haptic feedback saat options muncul
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isExpanded = true;
      _hoveredOption = null;
    });
    _scaleController.forward();
    _fadeController.forward();
  }

  void _hideOptions() {
    _scaleController.reverse();
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _hoveredOption = null;
        });
      }
    });
  }

  void _handleDragUpdate(Offset globalPosition) {
    if (!_isExpanded) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final buttonPosition = box.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    final buttonCenterY = buttonPosition.dy + (_floatingButtonSize / 2);

    final dx = globalPosition.dx - centerX;
    final dy = globalPosition.dy - buttonCenterY;

    String? newHovered;

    // ✅ PERBAIKAN: Dead zone konsisten untuk X dan Y
    // Logika: cek jarak dari center, bila < deadzone = cancel
    final distance = math.sqrt(dx * dx + dy * dy);
    
    if (distance < _deadZone) {
      // Terlalu dekat dengan center = cancel zone
      newHovered = 'cancel';
    } else if (dy < -_deadZone) {
      // Area atas (motor/mobil)
      if (dx < 0) {
        newHovered = 'motor';
      } else {
        newHovered = 'mobil';
      }
    } else {
      // Area bawah atau dalam deadzone = cancel
      newHovered = 'cancel';
    }

    // ✅ PERBAIKAN: Check mounted SEBELUM condition
    if (mounted && _hoveredOption != newHovered) {
      // ✅ TAMBAH: Haptic feedback saat pindah opsi
      HapticFeedback.selectionClick();
      
      setState(() {
        _hoveredOption = newHovered;
      });
    }
  }

  void _handleDragEnd() {
    // ✅ TAMBAH: Haptic feedback berbeda untuk action vs cancel
    if (_hoveredOption == 'motor') {
      HapticFeedback.lightImpact();
      Navigator.pushNamed(context, '/order/ojek', arguments: 'motor');
    } else if (_hoveredOption == 'mobil') {
      HapticFeedback.lightImpact();
      Navigator.pushNamed(context, '/order/ojek', arguments: 'mobil');
    } else {
      // Cancel - feedback lebih soft
      HapticFeedback.selectionClick();
    }
    _hideOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 🔥 LIQUID GLASS NAVBAR dengan NOTCH + GRADIENT BORDER
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: ClipPath(
            clipper: _BottomNavNotchClipper(
              notchRadius: _floatingButtonSize / 2 + 6,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_navbarRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: _navbarHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFFFF).withOpacity(0.25),
                        Color(0xFFFFFFFF).withOpacity(0.15),
                        Color(0xFFFFFFFF).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_navbarRadius),
                  ),
                    child: CustomPaint(
                      painter: _GradientBorderPainter(),
                      child: SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            children: _buildNavItems(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ),
          ),
        ),


        if (widget.role == 'customer')
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: GestureDetector(
              onLongPressStart: (_) {
                _showOptions();
              },
              onLongPressMoveUpdate: (details) {
                _handleDragUpdate(details.globalPosition);
              },
              onLongPressEnd: (_) {
                _handleDragEnd();
              },
              child: Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_scaleAnimation.value * 0.15),
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: _floatingButtonSize,
                    height: _floatingButtonSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // ✅ OPTIONS: Motor, Mobil, Cancel
                        if (_isExpanded) ...[
                          // MOTOR OPTION (kiri atas)
                          AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              final distance = _optionDistance * _fadeAnimation.value;
                              final angleRad = (230 * math.pi / 180);
                              final dx = distance * math.cos(angleRad);
                              final dy = distance * math.sin(angleRad);

                              return Positioned(
                                left: (_floatingButtonSize / 2) + dx - (_optionButtonSize / 2),
                                top: (_floatingButtonSize / 2) + dy - (_optionButtonSize / 2),
                                child: Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Transform.scale(
                                    scale: _fadeAnimation.value,
                                    child: _buildCleanIconOption(
                                      icon: Icons.two_wheeler_rounded,
                                      isHovered: _hoveredOption == 'motor',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // MOBIL OPTION (kanan atas)
                          AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              final distance = _optionDistance * _fadeAnimation.value;
                              final angleRad = (310 * math.pi / 180);
                              final dx = distance * math.cos(angleRad);
                              final dy = distance * math.sin(angleRad);

                              return Positioned(
                                left: (_floatingButtonSize / 2) + dx - (_optionButtonSize / 2),
                                top: (_floatingButtonSize / 2) + dy - (_optionButtonSize / 2),
                                child: Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Transform.scale(
                                    scale: _fadeAnimation.value,
                                    child: _buildCleanIconOption(
                                      icon: Icons.directions_car_rounded,
                                      isHovered: _hoveredOption == 'mobil',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // CANCEL OPTION (kanan bawah)
                          AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              final distance = 60.0 * _fadeAnimation.value;
                              final angleRad = (20 * math.pi / 180);
                              final dx = distance * math.cos(angleRad);
                              final dy = distance * math.sin(angleRad);

                              return Positioned(
                                left: (_floatingButtonSize / 2) + dx - (_optionButtonSize / 2),
                                top: (_floatingButtonSize / 2) + dy - (_optionButtonSize / 2),
                                child: Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Transform.scale(
                                    scale: _fadeAnimation.value,
                                    child: _buildCleanIconOption(
                                      icon: Icons.close_rounded,
                                      isHovered: _hoveredOption == 'cancel',
                                      isCancel: true,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],

                        // 🔥 Main Button dengan Shimmer
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Container(
                              width: _floatingButtonSize,
                              height: _floatingButtonSize,
                              child: CustomPaint(
                                painter: _CircleGradientBorderPainter(),
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: _isExpanded
                                              ? [
                                                  Color(0xFFFF85A1).withOpacity(0.8),
                                                  Color(0xFFFFB6C1).withOpacity(0.6),
                                                ]
                                              : [
                                                  Color(0xFFFFB6C1).withOpacity(0.7),
                                                  Color(0xFFFF85A1).withOpacity(0.5),
                                                ],
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          if (!_isExpanded)
                                            Positioned.fill(
                                              child: Transform.translate(
                                                offset: Offset(
                                                  (_shimmerController.value * 2 - 1) * 80,
                                                  0,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.white.withOpacity(0.3),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Center(
                                            child: Icon(
                                              Icons.two_wheeler_rounded,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // 🔥 Ripple Effect - saat expanded
                        if (_isExpanded)
                          AnimatedBuilder(
                            animation: _scaleController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_scaleController.value * 0.8),
                                child: Opacity(
                                  opacity: 1.0 - _scaleController.value,
                                  child: Container(
                                    width: _floatingButtonSize,
                                    height: _floatingButtonSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      // ✅ LIGHT MODE: pink ripple
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFFF85A1).withOpacity(0.3),
                                          Color(0xFFFFB6C1).withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: _CircleGradientBorderPainter(opacity: 0.5),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        // 🔥 Teks "Hold" - DI ATAS BUTTON
                        if (!_isExpanded)
                          Positioned(
                            top: _floatingButtonSize + 4, // ✅ Dynamic positioning
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Text(
                                'Hold',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  // ✅ LIGHT MODE: warna ungu terang
                                  color: Color(0xFF6200EA),
                                  letterSpacing: 0.8,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )

          // Creator by Matchaby
          // Instagram: @_matchaby

          else if (widget.role == 'driver')
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      width: _floatingButtonSize,
                      height: _floatingButtonSize,
                      child: CustomPaint(
                        painter: _CircleGradientBorderPainter(),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: widget.selectedIndex == 2
                                      ? [
                                          Color(0xFFFF85A1).withOpacity(0.8),
                                          Color(0xFFFFB6C1).withOpacity(0.6),
                                        ]
                                      : [
                                          Color(0xFFFFB6C1).withOpacity(0.7),
                                          Color(0xFFFF85A1).withOpacity(0.5),
                                        ],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Transform.translate(
                                      offset: Offset(
                                        (_shimmerController.value * 2 - 1) * 80,
                                        0,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: IconButton(
                                      onPressed: () => widget.onTap(2),
                                      icon: Icon(
                                        Icons.home_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )

          else if (widget.role == 'umkm')
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      width: _floatingButtonSize,
                      height: _floatingButtonSize,
                      child: CustomPaint(
                        painter: _CircleGradientBorderPainter(),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: widget.selectedIndex == 2
                                      ? [
                                          Color(0xFFFF9966).withOpacity(0.8),
                                          Color(0xFFFFB84D).withOpacity(0.6),
                                        ]
                                      : [
                                          Color(0xFFFFB84D).withOpacity(0.7),
                                          Color(0xFFFF9966).withOpacity(0.5),
                                        ],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Transform.translate(
                                      offset: Offset(
                                        (_shimmerController.value * 2 - 1) * 80,
                                        0,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: IconButton(
                                      onPressed: () => widget.onTap(2),
                                      icon: Icon(
                                        Icons.home_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }

  // 🔥 Build Clean Icon Option
  Widget _buildCleanIconOption({
    required IconData icon,
    required bool isHovered,
    bool isCancel = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 1.0, end: isHovered ? 1.15 : 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: _optionButtonSize,
            height: _optionButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  // ✅ LIGHT MODE: shadow berbeda untuk hover/normal
                  color: (isHovered 
                      ? (isCancel ? Colors.red.shade400 : Color(0xFFFF85A1))
                      : Colors.grey.shade300) // ✅ Light shadow untuk normal
                      .withOpacity(isHovered ? 0.4 : 0.2),
                  blurRadius: isHovered ? 18 : 8,
                  offset: Offset(0, isHovered ? 5 : 2),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _ThinCircleBorderPainter(
                isHovered: isHovered,
                isCancel: isCancel,
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // ✅ LIGHT MODE: gradient putih/pink/red saja
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isHovered
                            ? isCancel
                                ? [
                                    Colors.red.shade400.withOpacity(0.9),
                                    Colors.red.shade300.withOpacity(0.75),
                                  ]
                                : [
                                    Color(0xFFFF85A1).withOpacity(0.9),
                                    Color(0xFFFFB6C1).withOpacity(0.75),
                                  ]
                            : [
                                Colors.white.withOpacity(0.5),
                                Colors.white.withOpacity(0.3),
                              ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 20,
                        // ✅ LIGHT MODE: icon color
                        color: isHovered 
                            ? Colors.white 
                            : (isCancel ? Colors.red.shade400 : Color(0xFFFF85A1)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildNavItems() {
    if (widget.role == 'customer') {
      return [
        Expanded(
          child: Center(child: _buildNavItem(0, Icons.home_rounded)),
        ),
        Expanded(
          child: Center(child: _buildNavItem(1, Icons.store_rounded)),
        ),
        SizedBox(width: _floatingButtonSize), // ✅ Dynamic spacing
        Expanded(
          child: Center(
            child: _buildNavItem(
              3, 
              Icons.chat_bubble_rounded,
              badge: widget.badgeCounts?[3],
            ),
          ),
        ),
        Expanded(
          child: Center(child: _buildNavItem(4, Icons.person_rounded)),
        ),
      ];
    } else if (widget.role == 'driver') {
      return [
        Expanded(
          child: Center(
            child: _buildNavItem(
              0, 
              Icons.receipt_long,
              badge: widget.badgeCounts?[0],
            ),
          ),
        ),
        Expanded(
          child: Center(child: _buildNavItem(1, Icons.payments)),
        ),
        SizedBox(width: _floatingButtonSize), 
        Expanded(
          child: Center(
            child: _buildNavItem(
              3, 
              Icons.chat_bubble_rounded,
              badge: widget.badgeCounts?[3],
            ),
          ),
        ),
        Expanded(
          child: Center(child: _buildNavItem(4, Icons.person)),
        ),
      ];
    } else if (widget.role == 'umkm') {
      return [
        Expanded(
          child: Center(child: _buildNavItem(0, Icons.inventory_2_rounded)),
        ),
        Expanded(
          child: Center(child: _buildNavItem(1, Icons.account_balance_wallet_rounded)),
        ),
        SizedBox(width: _floatingButtonSize), // Spacing untuk floating button
        Expanded(
          child: Center(
            child: _buildNavItem(
              3, 
              Icons.chat_bubble_rounded,
              badge: widget.badgeCounts?[3],
            ),
          ),
        ),
        Expanded(
          child: Center(child: _buildNavItem(4, Icons.person_rounded)),
        ),
      ];
    }
    
    return [];
  }

  Widget _buildNavItem(
    int index,
    IconData icon, {
    int? badge,
  }) {
    final isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () {
        // ✅ TAMBAH: Haptic feedback saat tap nav item
        HapticFeedback.selectionClick();
        widget.onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // ✅ LIGHT MODE: gradient pink muda untuk selected
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE5EC).withOpacity(0.6),
                    Color(0xFFFFE5EC).withOpacity(0.3),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFFFF85A1).withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              // ✅ LIGHT MODE: pink untuk selected, grey untuk normal
              color: isSelected ? Color(0xFFFF85A1) : Colors.grey.shade600,
              size: 24,
            ),
            // ✅ PERBAIKAN: Badge overflow protection
            if (badge != null && badge > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10), // ✅ Lebih circular
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                    maxWidth: 28, // ✅ PERBAIKAN: batasi lebar max
                  ),
                  child: Center( // ✅ PERBAIKAN: Center untuk alignment
                    child: Text(
                      badge > 99 ? '99+' : '$badge', // ✅ PERBAIKAN: max 99+
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1, // ✅ PERBAIKAN: prevent overflow
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ✅ Custom Clipper untuk NOTCH - DYNAMIC
class _BottomNavNotchClipper extends CustomClipper<Path> {
  final double notchRadius;

  _BottomNavNotchClipper({this.notchRadius = 38.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final notchMargin = 12.0;

    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius - notchMargin, 0);

    // Curve masuk ke notch (kiri)
    path.quadraticBezierTo(
      centerX - notchRadius - (notchMargin / 2),
      0,
      centerX - notchRadius - 2,
      6,
    );

    // Arc untuk notch (semicircle)
    path.arcToPoint(
      Offset(centerX + notchRadius + 2, 6),
      radius: Radius.circular(notchRadius + 2),
      clockwise: false,
    );

    // Curve keluar dari notch (kanan)
    path.quadraticBezierTo(
      centerX + notchRadius + (notchMargin / 2),
      0,
      centerX + notchRadius + notchMargin,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_BottomNavNotchClipper oldClipper) {
    // ✅ PERBAIKAN: Reclip jika radius berubah
    return oldClipper.notchRadius != notchRadius;
  }
}

// 🔥 GRADIENT BORDER PAINTER untuk Navbar - LIGHT MODE
class _GradientBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(25));

    // ✅ LIGHT MODE: gradient putih saja
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF).withOpacity(0.5),  // ✅ Hardcode #FFFFFF
        Color(0xFFFFFFFF).withOpacity(0.2),
        Color(0xFFFFFFFF).withOpacity(0.1),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🔥 GRADIENT BORDER PAINTER untuk Circle Button - LIGHT MODE
class _CircleGradientBorderPainter extends CustomPainter {
  final double opacity;

  _CircleGradientBorderPainter({this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // ✅ LIGHT MODE: sweep gradient putih
    final gradient = SweepGradient(
      colors: [
        Colors.white.withOpacity(0.6 * opacity),
        Colors.white.withOpacity(0.3 * opacity),
        Colors.white.withOpacity(0.1 * opacity),
        Colors.white.withOpacity(0.6 * opacity),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round; // ✅ PERBAIKAN: Round cap untuk smooth

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_CircleGradientBorderPainter oldDelegate) {
    // ✅ PERBAIKAN: Repaint jika opacity berubah
    return oldDelegate.opacity != opacity;
  }
}

// 🔥 THIN BORDER PAINTER untuk Clean Icons - LIGHT MODE
class _ThinCircleBorderPainter extends CustomPainter {
  final bool isHovered;
  final bool isCancel;

  _ThinCircleBorderPainter({
    required this.isHovered,
    this.isCancel = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // ✅ LIGHT MODE: gradient berbeda untuk hover/cancel/normal
    final gradient = SweepGradient(
      colors: isHovered
          ? isCancel
              ? [
                  Colors.red.shade300.withOpacity(0.7),
                  Colors.red.shade400.withOpacity(0.5),
                  Colors.red.shade300.withOpacity(0.3),
                  Colors.red.shade300.withOpacity(0.7),
                ]
              : [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.7),
                ]
          : [
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.5),
            ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round; // ✅ PERBAIKAN: Round cap

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_ThinCircleBorderPainter oldDelegate) {
    // ✅ PERBAIKAN: Repaint jika state berubah
    return oldDelegate.isHovered != isHovered || 
           oldDelegate.isCancel != isCancel;
  }
}