// lib/screens/driver/widgets/request_driver/driver_appbar_widget.dart
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class DriverAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const DriverAppBarWidget({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 4,
      shadowColor: Colors.blue.shade200,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: onBack,
      ),
      title: Row(
        children: [
          Container(
            padding: ResponsiveMobile.allScaledPadding(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: ResponsiveMobile.scaledFont(20),
            ),
          ),
          ResponsiveMobile.hSpace(12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveMobile.subtitleSize(context),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}