import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'models/budget_version_model.dart';

class BudgetService {
  final ApiClient _api = ApiClient();

  // Ambil daftar riwayat versi anggaran kegiatan
  Future<List<BudgetVersionModel>> listBudgetVersions(String eventId) async {
    final response = await _api.get(ApiEndpoints.budgets(eventId));
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((item) => BudgetVersionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Ambil detail versi anggaran beserta item snapshot dan perbandingan
  Future<BudgetVersionDetailModel> getBudgetVersionDetail(String versionId) async {
    final response = await _api.get(ApiEndpoints.budgetVersion(versionId));
    final data = response['data'] as Map<String, dynamic>;
    return BudgetVersionDetailModel.fromJson(data);
  }

  // Setujui versi anggaran (khusus role Bendahara)
  Future<BudgetVersionModel> approveBudgetVersion(String versionId) async {
    final response = await _api.post(ApiEndpoints.approveBudget(versionId));
    final data = response['data'] as Map<String, dynamic>;
    return BudgetVersionModel.fromJson(data);
  }

  // Tolak versi anggaran dengan alasan wajib tercatat (khusus role Bendahara)
  Future<BudgetVersionModel> rejectBudgetVersion(String versionId, {required String reason}) async {
    final response = await _api.post(
      ApiEndpoints.rejectBudget(versionId),
      data: {'reason': reason.trim()},
    );
    final data = response['data'] as Map<String, dynamic>;
    return BudgetVersionModel.fromJson(data);
  }
}
