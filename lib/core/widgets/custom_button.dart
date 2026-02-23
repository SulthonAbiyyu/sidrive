import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final IconData? icon;
  final bool outlined;
  final bool enable3DEffect;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.width,
    this.icon,
    this.outlined = false,
    this.enable3DEffect = true,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.enable3DEffect) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );
      _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
      _rotateAnimation = Tween<double>(begin: 0.0, end: -0.02).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
      _elevationAnimation = Tween<double>(begin: 6.0, end: 2.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.enable3DEffect) _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (widget.onPressed == null || widget.isLoading) return;
    if (widget.enable3DEffect) {
      await _animationController.forward();
      await _animationController.reverse();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Setup Colors & Dimensions
    final bgColor = widget.backgroundColor ?? const Color(0xFF5DADE2);
    final txtColor = widget.textColor ?? Colors.white;
    final btnHeight = widget.height ?? ResponsiveMobile.scaledH(48);
    final btnWidth = widget.width;

    // 2. Setup Child Content (Text/Icon/Loading)
    Widget content = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.outlined ? bgColor : txtColor,
              ),
            ),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 18,
                    color: widget.outlined ? bgColor : txtColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: widget.outlined ? bgColor : txtColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );

    // 3. Create Button Widget (DIPISAH agar tidak error casting)
    Widget buttonWidget;

    if (widget.outlined) {
      buttonWidget = OutlinedButton(
        onPressed: widget.isLoading ? null : _handlePress,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: bgColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: Size(0, btnHeight),
          foregroundColor: bgColor, // Text/Ripple color
        ),
        child: content,
      );
    } else {
      buttonWidget = ElevatedButton(
        onPressed: widget.isLoading ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          elevation: 0, // Elevation di-handle container parent utk efek 3D
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: Size(0, btnHeight),
        ),
        child: content,
      );
    }

    // 4. Wrap with 3D Animation if needed
    if (widget.enable3DEffect && !widget.isLoading && !widget.outlined) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_rotateAnimation.value)
              ..scale(_scaleAnimation.value),
            alignment: Alignment.center,
            child: Container(
              width: btnWidth,
              height: btnHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.3),
                    blurRadius: _elevationAnimation.value * 2,
                    offset: Offset(0, _elevationAnimation.value),
                  ),
                ],
              ),
              child: buttonWidget,
            ),
          );
        },
      );
    }

    // 5. Default Return
    return SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: buttonWidget,
    );
  }
}