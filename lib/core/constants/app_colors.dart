import 'package:flutter/material.dart';

class AppColors {
  // Palet DESIGN.md (Forest Green). Jangan gunakan growth (#35B88A) sebagai teks pada latar terang (rasio 2.35:1, gagal WCAG AA).
  static const Color forest = Color(0xFF153D35);
  static const Color forestHover = Color(0xFF1A4D43);
  static const Color growth = Color(0xFF35B88A);
  // Hover lebih terang (#45C89A) menjaga kontras 5.70:1 dengan teks forest, karena #2EA87D hanya 4.01:1.
  static const Color growthHover = Color(0xFF45C89A);
  static const Color mint = Color(0xFFEAF5F0);
  static const Color cloud = Color(0xFFF6F8F7);

  static const Color primary = forest;
  static const Color accent = growth;
  static const Color primaryContainer = mint;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = forest;

  // Alias skala primary dipertahankan untuk layar eksisting hingga migrasi per layar pada Fase C.
  static const Color primary50 = mint;
  static const Color primary100 = Color(0xFFD9EDE4);
  static const Color primary200 = border;
  static const Color primary500 = growth;
  static const Color primary600 = forestHover;
  static const Color primary700 = forest;
  static const Color primary800 = Color(0xFF10302A);
  static const Color primary900 = Color(0xFF0C2621);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = cloud;
  static const Color surfaceRaised = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFD1E8DF);
  static const Color borderStrong = Color(0xFF5D9284);

  static const Color textPrimary = forest;
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  // Token status mempertahankan kontras WCAG AA pada latar masing-masing.
  static const Color statusApprovedText = Color(0xFF15803D);
  static const Color statusApprovedBg = Color(0xFFF0FDF4);
  static const Color statusApprovedBorder = Color(0xFFBBF7D0);

  static const Color statusSubmittedText = Color(0xFF1D4ED8);
  static const Color statusSubmittedBg = Color(0xFFEFF6FF);
  static const Color statusSubmittedBorder = Color(0xFFBFDBFE);

  static const Color statusRejectedText = Color(0xFFB91C1C);
  static const Color statusRejectedBg = Color(0xFFFEF2F2);
  static const Color statusRejectedBorder = Color(0xFFFECACA);

  static const Color statusPaidText = Color(0xFF0E7490);
  static const Color statusPaidBg = Color(0xFFECFEFF);
  static const Color statusPaidBorder = Color(0xFFA5F3FC);

  static const Color statusPartialText = Color(0xFFB45309);
  static const Color statusPartialBg = Color(0xFFFFFBEB);
  static const Color statusPartialBorder = Color(0xFFFDE68A);

  static const Color statusDraftText = Color(0xFF52525B);
  static const Color statusDraftBg = Color(0xFFF4F4F5);
  static const Color statusDraftBorder = Color(0xFFE4E4E7);

  static const Color statusCancelledText = Color(0xFF52525B);
  static const Color statusCancelledBg = Color(0xFFF1F5F9);
  static const Color statusCancelledBorder = Color(0xFFE2E8F0);
}
