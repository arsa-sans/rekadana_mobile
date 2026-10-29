import 'package:intl/intl.dart';

class DateFormatter {
  // Format tanggal dan waktu untuk zona waktu Indonesia
  static String formatDateTime(dynamic date) {
    if (date == null) return '-';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return '-';
    }

    // Menggunakan nama bulan Bahasa Indonesia dengan fallback aman
    try {
      final formatter = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
      return '${formatter.format(dt.toLocal())} WIB';
    } catch (_) {
      final formatter = DateFormat('d MMM yyyy, HH:mm');
      return '${formatter.format(dt.toLocal())} WIB';
    }
  }

  static String formatDate(dynamic date) {
    if (date == null) return '-';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return '-';
    }

    try {
      final formatter = DateFormat('d MMMM yyyy', 'id_ID');
      return formatter.format(dt.toLocal());
    } catch (_) {
      final formatter = DateFormat('d MMMM yyyy');
      return formatter.format(dt.toLocal());
    }
  }
}
