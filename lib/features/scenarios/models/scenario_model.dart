class ScenarioItemModel {
  final String id;
  final String name;
  final String? category;
  final String? priority;
  final double quantity;
  final double estimatedUnitCost;
  final double itemTotal;
  final bool isIncluded;
  final String? notes;

  const ScenarioItemModel({
    required this.id,
    required this.name,
    this.category,
    this.priority,
    required this.quantity,
    required this.estimatedUnitCost,
    required this.itemTotal,
    required this.isIncluded,
    this.notes,
  });

  factory ScenarioItemModel.fromJson(Map<String, dynamic> json) {
    return ScenarioItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      priority: json['priority'] as String?,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      estimatedUnitCost: double.tryParse(json['estimatedUnitCost']?.toString() ?? '0') ?? 0,
      itemTotal: double.tryParse(json['itemTotal']?.toString() ?? '0') ?? 0,
      isIncluded: json['isIncluded'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }
}

class ScenarioModel {
  final String id;
  final String name;
  final String? description;
  final int participantCount;
  final double availableFunds;
  final double scenarioTotal;
  final double? costPerParticipant;
  final double fundGap;
  final bool isDeficit;
  final int unfundedItemsCount;
  final List<ScenarioItemModel> items;

  const ScenarioModel({
    required this.id,
    required this.name,
    this.description,
    required this.participantCount,
    required this.availableFunds,
    required this.scenarioTotal,
    this.costPerParticipant,
    required this.fundGap,
    required this.isDeficit,
    required this.unfundedItemsCount,
    this.items = const [],
  });

  factory ScenarioModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ScenarioModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      participantCount: json['participantCount'] as int? ?? 0,
      availableFunds: double.tryParse(json['availableFunds']?.toString() ?? '0') ?? 0,
      scenarioTotal: double.tryParse(json['scenarioTotal']?.toString() ?? '0') ?? 0,
      costPerParticipant: json['costPerParticipant'] != null
          ? double.tryParse(json['costPerParticipant'].toString())
          : null,
      fundGap: double.tryParse(json['fundGap']?.toString() ?? '0') ?? 0,
      isDeficit: json['isDeficit'] as bool? ?? false,
      unfundedItemsCount: json['unfundedItemsCount'] as int? ?? 0,
      items: rawItems
          .map((e) => ScenarioItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
