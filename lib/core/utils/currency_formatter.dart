// lib/core/utils/currency_formatter.dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Format asli Anda (tanpa Rp)
  static String formatRupiah(double value) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(value.toInt()).replaceAll(',', '.');
  }
  
  // ✅ Format dengan prefix "Rp "
  static String formatRupiahWithPrefix(double value) {
    return 'Rp ${formatRupiah(value)}';
  }
  
  // ✅ Format compact (1.5jt, 750rb)
  static String formatCompact(double value) {
    if (value >= 1000000) {
      final juta = value / 1000000;
      final formatted = juta % 1 == 0 
          ? juta.toInt().toString() 
          : juta.toStringAsFixed(1);
      return 'Rp ${formatted}jt';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }
    return formatRupiahWithPrefix(value);
  }
  
  // ✅ Handle dynamic type (int, double, string)
  static String format(dynamic value, {bool withPrefix = true}) {
    if (value == null) return withPrefix ? 'Rp 0' : '0';
    
    double amount = 0;
    if (value is int) {
      amount = value.toDouble();
    } else if (value is double) {
      amount = value;
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0;
    }
    
    return withPrefix ? formatRupiahWithPrefix(amount) : formatRupiah(amount);
  }
}