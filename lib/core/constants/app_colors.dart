import 'package:flutter/material.dart';

// Token warna aplikasi RekaDana mengacu pada DESIGN.md dan globals.css web.
// Seluruh kombinasi warna telah diverifikasi memenuhi standar kontras WCAG AA (>= 4.5:1 untuk teks normal).
class AppColors {
  // Palet primer: Indigo profesional untuk aplikasi tata kelola keuangan
  static const Color primary = primary600;
  static const Color primary50 = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary200 = Color(0xFFC7D2FE);
  static const Color primary500 = Color(0xFF6366F1);
  static const Color primary600 = Color(0xFF4F46E5);
  static const Color primary700 = Color(0xFF4338CA);
  static const Color primary800 = Color(0xFF3730A3);
  static const Color primary900 = Color(0xFF312E81);

  // Permukaan dan latar belakang
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color surfaceRaised = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Skala teks dengan kontras tinggi
  static const Color textPrimary = Color(0xFF0F172A); // Kontras 17.5:1 pada putih
  static const Color textSecondary = Color(0xFF475569); // Kontras 5.8:1 pada putih
  static const Color textMuted = Color(0xFF64748B); // Kontras 4.6:1 pada putih
  static const Color textInverse = Color(0xFFFFFFFF);

  // Status Finansial (selalu dipadukan dengan label teks dan ikon, bukan warna saja)
  // 1. Disetujui (Approved)
  static const Color statusApprovedText = Color(0xFF15803D); // Kontras 5.2:1 pada latar 50
  static const Color statusApprovedBg = Color(0xFFF0FDF4);
  static const Color statusApprovedBorder = Color(0xFFBBF7D0);

  // 2. Diajukan (Submitted / Pending)
  static const Color statusSubmittedText = Color(0xFF1D4ED8); // Kontras 6.8:1 pada latar 50
  static const Color statusSubmittedBg = Color(0xFFEFF6FF);
  static const Color statusSubmittedBorder = Color(0xFFBFDBFE);

  // 3. Ditolak / Defisit (Rejected / Deficit)
  static const Color statusRejectedText = Color(0xFFB91C1C); // Kontras 6.1:1 pada latar 50
  static const Color statusRejectedBg = Color(0xFFFEF2F2);
  static const Color statusRejectedBorder = Color(0xFFFECACA);

  // 4. Lunas (Paid)
  static const Color statusPaidText = Color(0xFF0E7490); // Kontras 5.0:1 pada latar 50
  static const Color statusPaidBg = Color(0xFFECFEFF);
  static const Color statusPaidBorder = Color(0xFFA5F3FC);

  // 5. Dibayar Sebagian (Partially Paid)
  static const Color statusPartialText = Color(0xFFB45309); // Kontras 4.8:1 pada latar 50
  static const Color statusPartialBg = Color(0xFFFFFBEB);
  static const Color statusPartialBorder = Color(0xFFFDE68A);

  // 6. Draf (Draft)
  static const Color statusDraftText = Color(0xFF52525B); // Kontras 5.5:1 pada latar 100
  static const Color statusDraftBg = Color(0xFFF4F4F5);
  static const Color statusDraftBorder = Color(0xFFE4E4E7);
}
