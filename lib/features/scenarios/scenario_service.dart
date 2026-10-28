import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'models/scenario_model.dart';

class ScenarioService {
  final ApiClient _api = ApiClient();

  // Ambil daftar skenario beserta kalkulasi untuk suatu kegiatan
  Future<List<ScenarioModel>> getScenarios(String eventId) async {
    final response = await _api.get(ApiEndpoints.budgetScenarios(eventId));
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((item) => ScenarioModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Buat skenario baru
  Future<ScenarioModel> createScenario({
    required String eventId,
    required String name,
    String? description,
    int? participantCount,
  }) async {
    final body = <String, dynamic>{
      'name': name,
    };
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    if (participantCount != null && participantCount > 0) {
      body['participantCount'] = participantCount;
    }

    final response = await _api.post(
      ApiEndpoints.budgetScenarios(eventId),
      data: body,
    );
    return ScenarioModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  // Tambahkan item kebutuhan baru ke dalam skenario
  Future<void> addScenarioItem({
    required String scenarioId,
    required String name,
    String? category,
    String priority = 'normal',
    required double quantity,
    required double estimatedUnitCost,
    bool isIncluded = true,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'quantity': quantity.toStringAsFixed(2),
      'estimatedUnitCost': estimatedUnitCost.toStringAsFixed(2),
      'priority': priority,
      'isIncluded': isIncluded,
    };
    if (category != null && category.trim().isNotEmpty) {
      body['category'] = category.trim();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    }

    await _api.post(
      ApiEndpoints.scenarioItems(scenarioId),
      data: body,
    );
  }

  // Ajukan skenario menjadi versi anggaran resmi ke Bendahara
  Future<void> submitScenario(String scenarioId) async {
    await _api.post(
      ApiEndpoints.submitScenario(scenarioId),
      data: <String, dynamic>{},
    );
  }
}
