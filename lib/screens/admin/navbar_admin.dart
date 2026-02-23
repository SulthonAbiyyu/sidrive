import 'package:flutter/material.dart';
import 'package:sidrive/config/constants.dart';

class NavbarAdmin extends StatelessWidget {
  const NavbarAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // Sama dengan sidebar
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Bar (Centered content)
          Expanded(
            flex: 3,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24), // Lebih rounded
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // CENTER!
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.left, // Text dari kiri setelah icon
                      decoration: const InputDecoration(
                        hintText: 'Search anything...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.normal,
                      ),
                      cursorColor: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Notification Icon (Centered)
          _buildIconButton(
            context,
            icon: Icons.notifications_outlined,
            badge: 3,
            onTap: () {},
          ),

          const SizedBox(width: 12),

          // Logo pojok kanan — HD dengan filterQuality.high
          Image.asset(
            AssetPaths.logo,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    int? badge,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14), // Sama dengan menu sidebar
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Center( // CENTER icon
                child: Icon(
                  icon,
                  color: const Color(0xFF6B7280),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        if (badge != null && badge > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center( // CENTER badge number
                child: Text(
                  badge > 9 ? '9+' : badge.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}