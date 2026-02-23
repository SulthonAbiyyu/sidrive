import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/providers/theme_provider.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1F3A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        elevation: 0,
        title: Text(
          'Chat',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: ResponsiveMobile.scaledW(80),
              color: isDark ? Colors.white24 : Colors.grey[300],
            ),
            SizedBox(height: ResponsiveMobile.scaledH(16)),
            Text(
              'Belum ada percakapan',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(16),
                color: isDark ? Colors.white54 : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}