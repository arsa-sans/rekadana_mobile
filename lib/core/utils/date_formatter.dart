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

    // Menggunakan nama bulan Bahasa Indonesia
    final formatter = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
    return '${formatter.format(dt.toLocal())} WIB';
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

    final formatter = DateFormat('d MMMM yyyy', 'id_ID');
    return formatter.format(dt.toLocal());
  }
}
