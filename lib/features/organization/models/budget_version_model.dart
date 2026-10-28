class BudgetVersionModel {
  final String id;
  final String eventId;
  final String? sourceScenarioId;
  final int versionNumber;
  final String status;
  final double snapshotTotal;
  final int snapshotParticipantCount;
  final double snapshotAvailableFunds;
  final String? submittedBy;
  final String? submittedByName;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BudgetVersionModel({
    required this.id,
    required this.eventId,
    this.sourceScenarioId,
    required this.versionNumber,
    required this.status,
    required this.snapshotTotal,
    required this.snapshotParticipantCount,
    required this.snapshotAvailableFunds,
    this.submittedBy,
    this.submittedByName,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory BudgetVersionModel.fromJson(Map<String, dynamic> json) {
    return BudgetVersionModel(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      sourceScenarioId: json['sourceScenarioId'] as String?,
      versionNumber: (json['versionNumber'] as num?)?.toInt() ?? 1,
      status: (json['status'] as String?)?.toLowerCase() ?? 'draft',
      snapshotTotal: double.tryParse(json['snapshotTotal']?.toString() ?? '0') ?? 0.0,
      snapshotParticipantCount: (json['snapshotParticipantCount'] as num?)?.toInt() ?? 0,
      snapshotAvailableFunds: double.tryParse(json['snapshotAvailableFunds']?.toString() ?? '0') ?? 0.0,
      submittedBy: json['submittedBy'] as String?,
      submittedByName: json['submittedByName'] as String?,
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'] as String) : null,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedByName: json['reviewedByName'] as String?,
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'] as String) : null,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  bool get isApproved => status == 'approved';
  bool get isSubmitted => status == 'submitted';
  bool get isRejected => status == 'rejected';
  bool get isDraft => status == 'draft';

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'submitted':
        return 'Diajukan';
      case 'rejected':
        return 'Ditolak';
      case 'draft':
      default:
        return 'Draf';
    }
  }
}

class BudgetItemDetailModel {
  final String id;
  final String budgetVersionId;
  final String name;
  final String? category;
  final double quantity;
  final double unitCost;
  final double total;

  BudgetItemDetailModel({
    required this.id,
    required this.budgetVersionId,
    required this.name,
    this.category,
    required this.quantity,
    required this.unitCost,
    required this.total,
  });

  factory BudgetItemDetailModel.fromJson(Map<String, dynamic> json) {
    return BudgetItemDetailModel(
      id: json['id'] as String,
      budgetVersionId: json['budgetVersionId'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      unitCost: double.tryParse(json['unitCost']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class BudgetItemDiffModel {
  final String name;
  final String? category;
  final String type; // 'added' | 'removed' | 'modified'
  final String? oldQuantity;
  final String? newQuantity;
  final String? oldUnitCost;
  final String? newUnitCost;
  final String? oldTotal;
  final String? newTotal;
  final double totalDifference;

  BudgetItemDiffModel({
    required this.name,
    this.category,
    required this.type,
    this.oldQuantity,
    this.newQuantity,
    this.oldUnitCost,
    this.newUnitCost,
    this.oldTotal,
    this.newTotal,
    required this.totalDifference,
  });

  factory BudgetItemDiffModel.fromJson(Map<String, dynamic> json) {
    return BudgetItemDiffModel(
      name: json['name'] as String,
      category: json['category'] as String?,
      type: json['type'] as String? ?? 'modified',
      oldQuantity: json['oldQuantity']?.toString(),
      newQuantity: json['newQuantity']?.toString(),
      oldUnitCost: json['oldUnitCost']?.toString(),
      newUnitCost: json['newUnitCost']?.toString(),
      oldTotal: json['oldTotal']?.toString(),
      newTotal: json['newTotal']?.toString(),
      totalDifference: double.tryParse(json['totalDifference']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class BudgetComparisonModel {
  final String previousVersionId;
  final int previousVersionNumber;
  final double previousSnapshotTotal;
  final int previousParticipantCount;
  final double deltaTotal;
  final double deltaTotalPercentage;
  final int deltaParticipantCount;
  final int addedItemsCount;
  final int removedItemsCount;
  final int modifiedItemsCount;
  final List<BudgetItemDiffModel> diffs;

  BudgetComparisonModel({
    required this.previousVersionId,
    required this.previousVersionNumber,
    required this.previousSnapshotTotal,
    required this.previousParticipantCount,
    required this.deltaTotal,
    required this.deltaTotalPercentage,
    required this.deltaParticipantCount,
    required this.addedItemsCount,
    required this.removedItemsCount,
    required this.modifiedItemsCount,
    required this.diffs,
  });

  factory BudgetComparisonModel.fromJson(Map<String, dynamic> json) {
    final rawDiffs = json['diffs'] as List<dynamic>? ?? [];
    return BudgetComparisonModel(
      previousVersionId: json['previousVersionId'] as String? ?? '',
      previousVersionNumber: (json['previousVersionNumber'] as num?)?.toInt() ?? 1,
      previousSnapshotTotal: double.tryParse(json['previousSnapshotTotal']?.toString() ?? '0') ?? 0.0,
      previousParticipantCount: (json['previousParticipantCount'] as num?)?.toInt() ?? 0,
      deltaTotal: double.tryParse(json['deltaTotal']?.toString() ?? '0') ?? 0.0,
      deltaTotalPercentage: double.tryParse(json['deltaTotalPercentage']?.toString() ?? '0') ?? 0.0,
      deltaParticipantCount: (json['deltaParticipantCount'] as num?)?.toInt() ?? 0,
      addedItemsCount: (json['addedItemsCount'] as num?)?.toInt() ?? 0,
      removedItemsCount: (json['removedItemsCount'] as num?)?.toInt() ?? 0,
      modifiedItemsCount: (json['modifiedItemsCount'] as num?)?.toInt() ?? 0,
      diffs: rawDiffs.map((d) => BudgetItemDiffModel.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

class BudgetVersionDetailModel {
  final BudgetVersionModel version;
  final List<BudgetItemDetailModel> items;
  final BudgetComparisonModel? comparison;

  BudgetVersionDetailModel({
    required this.version,
    required this.items,
    this.comparison,
  });

  factory BudgetVersionDetailModel.fromJson(Map<String, dynamic> json) {
    final versionJson = json['version'] as Map<String, dynamic>;
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final comparisonJson = json['comparison'] as Map<String, dynamic>?;

    return BudgetVersionDetailModel(
      version: BudgetVersionModel.fromJson(versionJson),
      items: itemsJson.map((i) => BudgetItemDetailModel.fromJson(i as Map<String, dynamic>)).toList(),
      comparison: comparisonJson != null ? BudgetComparisonModel.fromJson(comparisonJson) : null,
    );
  }
}
