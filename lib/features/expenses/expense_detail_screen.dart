import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/status_badge.dart';
import '../organization/models/organization_model.dart';
import 'models/expense_request_model.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseRequestModel expense;
  final OrganizationModel organization;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.organization,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Detail Pengeluaran'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Status Utama
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(status: expense.status),
                        Text(
                          DateFormatter.formatDateTime(expense.createdAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      expense.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (expense.description != null && expense.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        expense.description!,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rincian Finansial
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    _buildRow('Nominal Diajukan', CurrencyFormatter.format(expense.requestedAmount)),
                    if (expense.approvedAmount != null) ...[
                      const Divider(height: 20),
                      _buildRow(
                        'Nominal Disetujui',
                        CurrencyFormatter.format(expense.approvedAmount),
                        isEmphasized: true,
                      ),
                    ],
                  ],
                ),
              ),

              // Alasan Penolakan (Jika ditolak)
              if (expense.rejectionReason != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.statusRejectedBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusRejectedBorder, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.statusRejectedText),
                          SizedBox(width: 8),
                          Text(
                            'Alasan Penolakan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusRejectedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expense.rejectionReason!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.statusRejectedText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isEmphasized = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: isEmphasized
              ? AppTheme.moneyLargeStyle.copyWith(color: AppColors.statusApprovedText)
              : AppTheme.moneyStyle,
        ),
      ],
    );
  }
}
