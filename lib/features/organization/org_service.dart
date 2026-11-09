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

  // Buat organisasi baru
  Future<OrganizationModel> createOrganization({
    required String name,
    required String slug,
  }) async {
    final response = await _api.post(
      ApiEndpoints.organizations,
      data: {
        'name': name.trim(),
        'slug': slug.trim(),
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return OrganizationModel.fromJson(data);
  }

  // Buat kegiatan baru pada organisasi
  Future<EventModel> createEvent(
    String orgId, {
    required String name,
    String? description,
    int participantCount = 0,
    String availableFunds = '0',
  }) async {
    final response = await _api.post(
      ApiEndpoints.events(orgId),
      data: {
        'name': name.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'participantCount': participantCount,
        'availableFunds': availableFunds,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return EventModel.fromJson(data);
  }

  // Ambil ringkasan finansial dan rekonsiliasi Anggaran vs Realisasi
  Future<BudgetVsActualReportModel> getBudgetReport(String eventId) async {
    final response = await _api.get(ApiEndpoints.reportBudgetVsActual(eventId));
    final data = response['data'] as Map<String, dynamic>;
    return BudgetVsActualReportModel.fromJson(data);
  }
}
