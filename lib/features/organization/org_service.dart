import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'models/event_model.dart';
import 'models/organization_model.dart';
import 'models/report_model.dart';

class OrgService {
  final ApiClient _api = ApiClient();

  // Ambil daftar organisasi yang terafiliasi dengan pengguna aktif
  Future<List<OrganizationModel>> getOrganizations() async {
    final response = await _api.get(ApiEndpoints.organizations);
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((item) => OrganizationModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  // Ambil daftar kegiatan aktif per organisasi
  Future<List<EventModel>> getEvents(String orgId) async {
    final response = await _api.get(ApiEndpoints.events(orgId));
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((item) => EventModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  // Ambil ringkasan finansial dan rekonsiliasi Anggaran vs Realisasi
  Future<BudgetVsActualReportModel> getBudgetReport(String eventId) async {
    final response = await _api.get(ApiEndpoints.reportBudgetVsActual(eventId));
    final data = response['data'] as Map<String, dynamic>;
    return BudgetVsActualReportModel.fromJson(data);
  }
}
