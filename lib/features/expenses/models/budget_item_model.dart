class BudgetItemModel {
  final String id;
  final String name;
  final String? category;
  final String priority;
  final String estimatedUnitCost;
  final String quantity;
  final String? remaining;

  BudgetItemModel({
    required this.id,
    required this.name,
    this.category,
    required this.priority,
    required this.estimatedUnitCost,
    required this.quantity,
    this.remaining,
  });

  factory BudgetItemModel.fromJson(Map<String, dynamic> json) {
    return BudgetItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      estimatedUnitCost: json['estimatedUnitCost']?.toString() ?? '0',
      quantity: json['quantity']?.toString() ?? '1',
      remaining: json['remaining']?.toString(),
    );
  }

  double get totalEstimatedCost {
    final unit = double.tryParse(estimatedUnitCost) ?? 0;
    final qty = double.tryParse(quantity) ?? 1;
    return unit * qty;
  }
}
