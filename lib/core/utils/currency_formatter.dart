import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _numberFormat = NumberFormat('#,###', 'ar');
  static final _latinFormat = NumberFormat('#,###', 'en_US');

  /// Formats IQD integer amount with thousand separators: e.g. 25,000 د.ع
  static String formatIqd(int amount, {bool includeSymbol = true, bool arabicDigits = false}) {
    final formatted = arabicDigits ? _numberFormat.format(amount) : _latinFormat.format(amount);
    if (!includeSymbol) return formatted;
    return '$formatted د.ع';
  }

  /// Parses text into an integer IQD amount, ignoring commas and spaces
  static int? parseIqd(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final cleaned = text.replaceAll(',', '').replaceAll('،', '').replaceAll(' ', '').trim();
    return int.tryParse(cleaned);
  }
}
