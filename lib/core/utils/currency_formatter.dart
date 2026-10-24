import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 2,
  );

  // Format angka atau string desimal menjadi tampilan Rupiah rapi
  // Contoh: 1500000 -> "Rp1.500.000"
  static String format(dynamic value) {
    if (value == null) return 'Rp0';

    double number = 0;
    if (value is num) {
      number = value.toDouble();
    } else if (value is String) {
      number = double.tryParse(value) ?? 0;
    }

    // Jika memiliki pecahan sen yang signifikan, tampilkan 2 desimal
    if (number % 1 != 0) {
      return _decimalFormatter.format(number).replaceAll(',00', '');
    }

    return _formatter.format(number);
  }

  // Bersihkan teks input pengguna hanya menyisakan angka
  // Contoh: "Rp 1.500.000" -> "1500000"
  static String cleanToNumeric(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // Parse teks input pengguna menjadi nilai double
  static double parseToDouble(String input) {
    final cleaned = cleanToNumeric(input);
    if (cleaned.isEmpty) return 0.0;
    return double.tryParse(cleaned) ?? 0.0;
  }
}
