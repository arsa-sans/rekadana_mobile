class BudgetVsActualReportModel {
  final String eventId;
  final String eventName;
  final String availableFunds;
  final bool hasActiveBudget;
  final int? activeBudgetVersionNumber;
  final String approvedBudgetTotal;
  final String actualNet;
  final String openCommitments;
  final String remainingControlBudget;
  final List<BudgetItemBreakdownModel> itemsBreakdown;

  BudgetVsActualReportModel({
    required this.eventId,
    required this.eventName,
    required this.availableFunds,
    required this.hasActiveBudget,
    this.activeBudgetVersionNumber,
    required this.approvedBudgetTotal,
    required this.actualNet,
    required this.openCommitments,
    required this.remainingControlBudget,
    required this.itemsBreakdown,
  });

  factory BudgetVsActualReportModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['itemsBreakdown'] as List<dynamic>? ?? [];
    return BudgetVsActualReportModel(
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      availableFunds: json['availableFunds']?.toString() ?? '0',
      hasActiveBudget: json['hasActiveBudget'] as bool? ?? false,
      activeBudgetVersionNumber: json['activeBudgetVersionNumber'] as int?,
      approvedBudgetTotal: json['approvedBudgetTotal']?.toString() ?? '0',
      actualNet: json['actualNet']?.toString() ?? '0',
      openCommitments: json['openCommitments']?.toString() ?? '0',
      remainingControlBudget: json['remainingControlBudget']?.toString() ?? '0',
      itemsBreakdown: rawItems
          .map((i) => BudgetItemBreakdownModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BudgetItemBreakdownModel {
  final String budgetItemId;
  final String name;
  final String? category;
  final String budgetTotal;
  final String actualNet;
  final String openCommitments;
  final String remaining;

  BudgetItemBreakdownModel({
    required this.budgetItemId,
    required this.name,
    this.category,
    required this.budgetTotal,
    required this.actualNet,
    required this.openCommitments,
    required this.remaining,
  });

  factory BudgetItemBreakdownModel.fromJson(Map<String, dynamic> json) {
    return BudgetItemBreakdownModel(
      budgetItemId: json['budgetItemId'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      budgetTotal: json['budgetTotal']?.toString() ?? '0',
      actualNet: json['actualNet']?.toString() ?? '0',
      openCommitments: json['openCommitments']?.toString() ?? '0',
      remaining: json['remaining']?.toString() ?? '0',
    );
  }
}
