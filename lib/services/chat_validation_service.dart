// ============================================================================
// CHAT VALIDATION SERVICE
// POIN 2: Block nomor telepon dalam bentuk apapun
// ============================================================================

import 'package:flutter/material.dart';

class ChatValidationService {
  /// 🚫 VALIDATE MESSAGE - Block nomor telepon
  /// Returns: true jika VALID (tidak ada nomor), false jika INVALID (ada nomor)
  bool validateMessage(String message) {
    // Check berbagai format nomor telepon
    if (_containsPhoneNumber(message)) {
      return false;
    }
    return true;
  }

  /// 🔍 DETECT NOMOR TELEPON dalam berbagai format
  bool _containsPhoneNumber(String text) {
    final lowerText = text.toLowerCase().replaceAll(' ', '');

    // 1. Regex pattern untuk nomor telepon Indonesia & internasional
    final phonePatterns = [
      // Format standar: 08xx-xxxx-xxxx, 62xxx, +62xxx
      r'\b0?8\d{8,11}\b',
      r'\b62\d{9,12}\b',
      r'\+62\d{9,12}\b',
      
      // Format dengan separator: 08xx-xxxx-xxxx, 08xx.xxxx.xxxx
      r'\b0?8\d{2}[-.\s]?\d{4}[-.\s]?\d{4,5}\b',
      
      // Format tanpa leading 0: 8xxxxxxxxxx
      r'\b8\d{9,10}\b',
      
      // Format dengan parentheses: (08xx) xxxx-xxxx
      r'\(\d{4}\)\s?\d{4}[-.\s]?\d{4}',
      
      // WhatsApp format: wa.me/62xxx atau wa.link
      r'wa\.me/\d+',
      r'wa\.link/\w+',
      
      // Telegram format: t.me/+62xxx
      r't\.me/\+?\d+',
    ];

    for (final pattern in phonePatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        debugPrint('🚫 Detected phone number pattern: $pattern');
        return true;
      }
    }

    // 2. Check nomor dalam bentuk huruf (teks)
    // Contoh: "nol delapan lima" atau "kosong delapan lima"
    if (_containsTextualPhoneNumber(lowerText)) {
      debugPrint('🚫 Detected textual phone number');
      return true;
    }

    // 3. Check nomor yang dipisah dengan spasi/karakter
    // Contoh: "0 8 1 2 3 4 5 6 7 8 9"
    if (_containsSpacedDigits(text)) {
      debugPrint('🚫 Detected spaced phone number');
      return true;
    }

    // 4. Check kombinasi huruf-angka yang mencurigakan
    // Contoh: "o812" (huruf o sebagai angka 0)
    if (_containsDisguisedPhoneNumber(lowerText)) {
      debugPrint('🚫 Detected disguised phone number');
      return true;
    }

    return false;
  }

  /// 📝 DETECT NOMOR DALAM BENTUK TEKS
  /// Contoh: "nol delapan satu dua" atau "kosong lapan lima"
  bool _containsTextualPhoneNumber(String text) {
    // Map kata ke angka
    final numberWords = {
      'nol': '0', 'kosong': '0', 'zero': '0',
      'satu': '1', 'se': '1', 'one': '1',
      'dua': '2', 'two': '2',
      'tiga': '3', 'three': '3',
      'empat': '4', 'four': '4',
      'lima': '5', 'five': '5',
      'enam': '6', 'six': '6',
      'tujuh': '7', 'seven': '7',
      'delapan': '8', 'lapan': '8', 'eight': '8',
      'sembilan': '9', 'nine': '9',
    };

    // Split by non-alphanumeric
    final words = text.split(RegExp(r'[^\w]+')).where((w) => w.isNotEmpty).toList();

    // Convert words to numbers
    String converted = '';
    for (final word in words) {
      if (numberWords.containsKey(word)) {
        converted += numberWords[word]!;
      }
    }

    // Check if converted string is phone number
    if (converted.length >= 10) {
      // Check pattern: starts with 0 or 62 or 8
      if (RegExp(r'^(0|62)?8\d{8,}').hasMatch(converted)) {
        debugPrint('🚫 Textual number converted to: $converted');
        return true;
      }
    }

    return false;
  }

  /// 🔢 DETECT NOMOR DENGAN SPASI BERLEBIHAN
  /// Contoh: "0 8 1 2 3 4 5 6 7 8 9"
  bool _containsSpacedDigits(String text) {
    // Remove non-digit characters and count digits
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
    
    // If text has 10+ digits, check spacing pattern
    if (digitsOnly.length >= 10) {
      // Check if digits are heavily spaced (more spaces than normal)
      final spaces = text.split('').where((c) => c == ' ').length;
      final digits = text.split('').where((c) => RegExp(r'\d').hasMatch(c)).length;
      
      // Suspicious if ratio of spaces to digits > 0.7
      if (digits >= 10 && spaces / digits > 0.7) {
        // Additional check: starts with common phone prefixes
        if (RegExp(r'^[0+]?6?2?8').hasMatch(digitsOnly)) {
          debugPrint('🚫 Spaced digits detected: $digitsOnly');
          return true;
        }
      }
    }

    return false;
  }

  /// 🥸 DETECT NOMOR YANG DISAMARKAN
  /// Contoh: "o812" (huruf o), "I123" (huruf i)
  bool _containsDisguisedPhoneNumber(String text) {
    // Replace common letter-to-digit disguises
    final disguises = {
      'o': '0', 'O': '0',
      'i': '1', 'I': '1', 'l': '1', 'L': '1',
      'z': '2', 'Z': '2',
      's': '5', 'S': '5',
      'b': '6', 'B': '6',
      't': '7', 'T': '7',
      'g': '9', 'G': '9',
    };

    String normalized = text;
    disguises.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    // Check if normalized text contains phone number
    if (RegExp(r'\b0?8\d{8,11}\b').hasMatch(normalized)) {
      debugPrint('🚫 Disguised number detected: $normalized');
      return true;
    }

    return false;
  }

  /// 🎨 GET ERROR MESSAGE
  String getValidationErrorMessage() {
    return 'Tidak diperbolehkan mengirim nomor telepon. Mohon gunakan fitur chat untuk berkomunikasi.';
  }

  /// ✅ SUGGEST ALTERNATIVE
  String getSuggestionMessage() {
    return 'Untuk keamanan, kami tidak mengizinkan pertukaran kontak pribadi. Anda dapat berkomunikasi melalui chat ini.';
  }

  /// 🧪 TEST VALIDATION (untuk debugging)
  void testValidation() {
    final testCases = [
      // Format normal
      '081234567890',
      '08123-4567-890',
      '0812.3456.7890',
      '+62812345678',
      '62812345678',
      
      // Format dengan text
      'Hubungi saya di 081234567890',
      'WA: 0812-3456-7890',
      'Call me 62812345678',
      
      // Format disamarkan (textual)
      'nol delapan satu dua tiga empat lima',
      'kosong lapan lima tujuh sembilan',
      
      // Format dengan spasi
      '0 8 1 2 3 4 5 6 7 8 9 0',
      '0 8 1 2 - 3 4 5 6 - 7 8 9',
      
      // Format disamarkan (letter)
      'o812345678',
      'o8I2-345-678',
      
      // WhatsApp/Telegram
      'wa.me/62812345678',
      't.me/+62812345678',
      
      // Normal text (should pass)
      'Halo, produknya masih ready?',
      'Berapa harga untuk ukuran 8?',
      'Saya tertarik dengan produk 12345',
    ];

    print('🧪 Testing phone number validation...');
    for (final test in testCases) {
      final isValid = validateMessage(test);
      final status = isValid ? '✅ VALID' : '🚫 BLOCKED';
      print('$status: "$test"');
    }
  }
}