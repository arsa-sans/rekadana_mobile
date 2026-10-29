import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'models/budget_item_model.dart';
import 'models/expense_request_model.dart';

class ExpenseService {
  final ApiClient _api = ApiClient();

  // Ambil daftar pengajuan pengeluaran untuk kegiatan tertentu
  Future<List<ExpenseRequestModel>> listExpenseRequests(String eventId) async {
    final response = await _api.get(ApiEndpoints.expenseRequests(eventId));
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((item) => ExpenseRequestModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Ambil item pos anggaran dari versi anggaran aktif yang disetujui
  Future<List<BudgetItemModel>> getActiveBudgetItems(String eventId) async {
    try {
      final budgetsResponse = await _api.get(ApiEndpoints.budgets(eventId));
      final versions = budgetsResponse['data'] as List<dynamic>? ?? [];

      // Cari versi yang berstatus 'approved'
      final approvedVersion = versions.firstWhere(
        (v) => (v as Map<String, dynamic>)['status'] == 'approved',
        orElse: () => null,
      );

      if (approvedVersion == null) {
        return [];
      }

      final versionId = (approvedVersion as Map<String, dynamic>)['id'] as String;
      final detailResponse = await _api.get(ApiEndpoints.budgetVersion(versionId));
      final data = detailResponse['data'] as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      return items
          .map((item) => BudgetItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Ajukan permintaan pengeluaran baru dari lapangan
  Future<ExpenseRequestModel> createExpenseRequest(
    String eventId, {
    required String title,
    required String requestedAmount,
    String? budgetItemId,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'requestedAmount': requestedAmount,
    };

    if (budgetItemId != null && budgetItemId.isNotEmpty) {
      payload['budgetItemId'] = budgetItemId;
    }
    if (description != null && description.trim().isNotEmpty) {
      payload['description'] = description.trim();
    }

    final response = await _api.post(
      ApiEndpoints.expenseRequests(eventId),
      data: payload,
    );

    final data = response['data'] as Map<String, dynamic>;
    return ExpenseRequestModel.fromJson(data);
  }

  // Unggah foto atau dokumen bukti transaksi ke penyimpanan privat
  Future<void> uploadEvidence({
    required String organizationId,
    required String expenseRequestId,
    required String filePath,
    void Function(int, int)? onProgress,
  }) async {
    final file = File(filePath);
    final fileName = p.basename(filePath);
    final ext = p.extension(filePath).toLowerCase();

    MediaType mediaType;
    if (ext == '.png') {
      mediaType = MediaType('image', 'png');
    } else if (ext == '.pdf') {
      mediaType = MediaType('application', 'pdf');
    } else {
      mediaType = MediaType('image', 'jpeg');
    }

    final formData = FormData.fromMap({
      'organizationId': organizationId,
      'expenseRequestId': expenseRequestId,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: mediaType,
      ),
    });

    await _api.postMultipart(
      ApiEndpoints.evidence,
      formData,
      onSendProgress: onProgress,
    );
  }

  // Ambil rincian lengkap pengeluaran termasuk ringkasan saldo & riwayat pembayaran
  Future<ExpenseRequestDetailModel> getExpenseDetail(String requestId) async {
    final response = await _api.get(ApiEndpoints.expenseRequestDetail(requestId));
    final data = response['data'] as Map<String, dynamic>;
    return ExpenseRequestDetailModel.fromJson(data);
  }

  // Persetujuan pengeluaran oleh Bendahara (larangan self-approval otomatis dicek server)
  Future<void> approveExpense(
    String requestId, {
    String? approvedAmount,
  }) async {
    final payload = <String, dynamic>{};
    if (approvedAmount != null && approvedAmount.isNotEmpty) {
      payload['approvedAmount'] = approvedAmount;
    }

    await _api.post(
      ApiEndpoints.approveExpense(requestId),
      data: payload,
    );
  }

  // Penolakan pengeluaran oleh Bendahara dengan alasan beraudit
  Future<void> rejectExpense(
    String requestId, {
    required String reason,
  }) async {
    await _api.post(
      ApiEndpoints.rejectExpense(requestId),
      data: {'reason': reason.trim()},
    );
  }

  // Pencatatan pembayaran oleh Bendahara dengan idempotensi
  Future<Map<String, dynamic>> recordPayment(
    String requestId, {
    required String idempotencyKey,
    required String amount,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'idempotencyKey': idempotencyKey.trim(),
      'amount': amount.trim(),
    };
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final response = await _api.post(
      ApiEndpoints.postPayment(requestId),
      data: payload,
    );

    return response['data'] as Map<String, dynamic>? ?? {};
  }

  // Pembatalan pembayaran (reversal) oleh Bendahara
  Future<Map<String, dynamic>> reversePayment(
    String paymentId, {
    required String amount,
    required String reason,
  }) async {
    final response = await _api.post(
      ApiEndpoints.reversePayment(paymentId),
      data: {
        'amount': amount.trim(),
        'reason': reason.trim(),
      },
    );

    return response['data'] as Map<String, dynamic>? ?? {};
  }
}
