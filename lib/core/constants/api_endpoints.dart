import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Alamat dasar server dapat disesuaikan pada runtime (misalnya emulator vs perangkat fisik)
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) {
      // 10.0.2.2 adalah alias loopback host development pada emulator standar Android
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  // Endpoint Autentikasi
  static const String login = '/api/v1/auth/login';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/me';

  // Endpoint Organisasi & Kegiatan
  static const String organizations = '/api/v1/organizations';
  static String events(String orgId) => '/api/v1/organizations/$orgId/events';
  static String eventDetail(String eventId) => '/api/v1/events/$eventId';

  // Endpoint Anggaran
  static String budgets(String eventId) => '/api/v1/events/$eventId/budgets';
  static String budgetVersion(String versionId) => '/api/v1/budget-versions/$versionId';
  static String approveBudget(String versionId) => '/api/v1/budget-versions/$versionId/approve';
  static String rejectBudget(String versionId) => '/api/v1/budget-versions/$versionId/reject';

  // Endpoint Permintaan Pengeluaran
  static String expenseRequests(String eventId) => '/api/v1/events/$eventId/expense-requests';
  static String expenseRequestDetail(String requestId) => '/api/v1/expense-requests/$requestId';
  static String approveExpense(String requestId) => '/api/v1/expense-requests/$requestId/approve';
  static String rejectExpense(String requestId) => '/api/v1/expense-requests/$requestId/reject';
  static String postPayment(String requestId) => '/api/v1/expense-requests/$requestId/payments';
  static String reversePayment(String paymentId) => '/api/v1/payments/$paymentId/reverse';

  // Endpoint Bukti Transaksi
  static const String evidence = '/api/v1/evidence';
  static String evidenceDownload(String evidenceId) => '/api/v1/evidence/$evidenceId/download';

  // Endpoint Laporan Realisasi
  static String reportBudgetVsActual(String eventId) => '/api/v1/events/$eventId/reports/budget-vs-actual';

  // Endpoint Scenario Lab
  static String budgetScenarios(String eventId) => '/api/v1/events/$eventId/budget-scenarios';
  static String scenarioItems(String scenarioId) => '/api/v1/budget-scenarios/$scenarioId/items';
  static String submitScenario(String scenarioId) => '/api/v1/budget-scenarios/$scenarioId/submit';
}
