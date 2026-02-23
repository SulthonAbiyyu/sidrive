// lib/screens/auth/widgets/request_umkm/umkm_appbar_widget.dart
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class UmkmAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const UmkmAppBarWidget({
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
            colors: [Colors.orange.shade600, Colors.orange.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 4,
      shadowColor: Colors.orange.shade200,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveMobile.subtitleSize(context),
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}