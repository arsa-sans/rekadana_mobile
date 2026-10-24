class ExpenseRequestModel {
  final String id;
  final String eventId;
  final String? budgetVersionId;
  final String? budgetItemId;
  final String? requestedBy;
  final String title;
  final String? description;
  final String requestedAmount;
  final String? approvedAmount;
  final String status;
  final String? rejectionReason;
  final String? createdAt;

  ExpenseRequestModel({
    required this.id,
    required this.eventId,
    this.budgetVersionId,
    this.budgetItemId,
    this.requestedBy,
    required this.title,
    this.description,
    required this.requestedAmount,
    this.approvedAmount,
    required this.status,
    this.rejectionReason,
    this.createdAt,
  });

  factory ExpenseRequestModel.fromJson(Map<String, dynamic> json) {
    return ExpenseRequestModel(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      budgetVersionId: json['budgetVersionId'] as String?,
      budgetItemId: json['budgetItemId'] as String?,
      requestedBy: json['requestedBy'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      requestedAmount: json['requestedAmount']?.toString() ?? '0',
      approvedAmount: json['approvedAmount']?.toString(),
      status: json['status'] as String? ?? 'submitted',
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt']?.toString(),
    );
  }

  bool get isPending => status == 'submitted';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPaid => status == 'paid';
  bool get isPartiallyPaid => status == 'partially_paid';
}
