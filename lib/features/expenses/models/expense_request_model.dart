class EvidenceModel {
  final String id;
  final String originalFileName;
  final String detectedFileType;
  final int fileSizeBytes;
  final String? createdAt;

  EvidenceModel({
    required this.id,
    required this.originalFileName,
    required this.detectedFileType,
    required this.fileSizeBytes,
    this.createdAt,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'] as String,
      originalFileName: json['originalFileName'] as String? ?? '',
      detectedFileType: json['detectedFileType'] as String? ?? 'jpeg',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString(),
    );
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ExpenseRequestModel {
  final String id;
  final String eventId;
  final String? budgetVersionId;
  final String? budgetItemId;
  final String? requestedBy;
  final String? requesterName;
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
    this.requesterName,
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
      requesterName: json['requesterName'] as String?,
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

class PaymentReversalModel {
  final String id;
  final String amount;
  final String reason;
  final String reversedBy;
  final String? reversedByName;
  final String? reversedAt;

  PaymentReversalModel({
    required this.id,
    required this.amount,
    required this.reason,
    required this.reversedBy,
    this.reversedByName,
    this.reversedAt,
  });

  factory PaymentReversalModel.fromJson(Map<String, dynamic> json) {
    return PaymentReversalModel(
      id: json['id'] as String,
      amount: json['amount']?.toString() ?? '0',
      reason: json['reason'] as String? ?? '',
      reversedBy: json['reversedBy'] as String? ?? '',
      reversedByName: json['reversedByName'] as String?,
      reversedAt: json['reversedAt']?.toString(),
    );
  }

  double get amountValue => double.tryParse(amount) ?? 0;
}

class PaymentModel {
  final String id;
  final String amount;
  final String postedBy;
  final String? postedByName;
  final String? postedAt;
  final String? notes;
  final bool isReversed;
  final String idempotencyKey;
  final double netAmount;
  final List<PaymentReversalModel> reversals;

  PaymentModel({
    required this.id,
    required this.amount,
    required this.postedBy,
    this.postedByName,
    this.postedAt,
    this.notes,
    required this.isReversed,
    required this.idempotencyKey,
    required this.netAmount,
    required this.reversals,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final rawReversals = json['reversals'] as List<dynamic>? ?? [];
    return PaymentModel(
      id: json['id'] as String,
      amount: json['amount']?.toString() ?? '0',
      postedBy: json['postedBy'] as String? ?? '',
      postedByName: json['postedByName'] as String?,
      postedAt: json['postedAt']?.toString(),
      notes: json['notes'] as String?,
      isReversed: json['isReversed'] as bool? ?? false,
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0,
      reversals: rawReversals
          .map((r) => PaymentReversalModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  double get originalAmount => double.tryParse(amount) ?? 0;

  double get totalReversedAmount =>
      reversals.fold(0.0, (sum, r) => sum + r.amountValue);

  double get remainingReversibleAmount =>
      (originalAmount - totalReversedAmount).clamp(0, double.infinity);
}

class ExpenseSummaryModel {
  final double requestedAmount;
  final double approvedAmount;
  final double totalPaidNet;
  final double remainingBalance;
  final bool isFullyPaid;
  final int paymentCount;

  ExpenseSummaryModel({
    required this.requestedAmount,
    required this.approvedAmount,
    required this.totalPaidNet,
    required this.remainingBalance,
    required this.isFullyPaid,
    required this.paymentCount,
  });

  factory ExpenseSummaryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSummaryModel(
      requestedAmount: (json['requestedAmount'] as num?)?.toDouble() ?? 0,
      approvedAmount: (json['approvedAmount'] as num?)?.toDouble() ?? 0,
      totalPaidNet: (json['totalPaidNet'] as num?)?.toDouble() ?? 0,
      remainingBalance: (json['remainingBalance'] as num?)?.toDouble() ?? 0,
      isFullyPaid: json['isFullyPaid'] as bool? ?? false,
      paymentCount: (json['paymentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExpenseRequestDetailModel {
  final ExpenseRequestModel request;
  final List<PaymentModel> payments;
  final ExpenseSummaryModel summary;

  ExpenseRequestDetailModel({
    required this.request,
    required this.payments,
    required this.summary,
  });

  factory ExpenseRequestDetailModel.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['payments'] as List<dynamic>? ?? [];
    return ExpenseRequestDetailModel(
      request: ExpenseRequestModel.fromJson(json['request'] as Map<String, dynamic>),
      payments: rawPayments
          .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      summary: ExpenseSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }
}
