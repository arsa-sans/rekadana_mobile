import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import 'budget_service.dart';
import 'models/budget_version_model.dart';
import 'models/event_model.dart';
import 'models/organization_model.dart';

class BudgetVersionDetailScreen extends StatefulWidget {
  final OrganizationModel organization;
  final EventModel event;
  final String versionId;

  const BudgetVersionDetailScreen({
    super.key,
    required this.organization,
    required this.event,
    required this.versionId,
  });

  @override
  State<BudgetVersionDetailScreen> createState() => _BudgetVersionDetailScreenState();
}

class _BudgetVersionDetailScreenState extends State<BudgetVersionDetailScreen> {
  final BudgetService _budgetService = BudgetService();
  final SecureStorageService _storage = SecureStorageService();

  BudgetVersionDetailModel? _detail;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;
  bool _hasMutated = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final user = await _storage.getUser();
    if (user != null) {
      _currentUserId = user['id'] as String?;
    }
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _budgetService.getBudgetVersionDetail(widget.versionId);
      if (!mounted) return;
      setState(() {
        _detail = res;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove() async {
    if (_detail == null) return;
    final version = _detail!.version;

    if (version.submittedBy != null && version.submittedBy == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Prinsip pemisahan tugas: Pemohon tidak diizinkan menyetujui pengajuannya sendiri.',
          ),
          backgroundColor: AppColors.statusRejectedText,
        ),
      );
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Setujui Versi Anggaran #${version.versionNumber}',
      message:
          'Versi anggaran sebesar ${CurrencyFormatter.format(version.snapshotTotal)} akan diaktifkan sebagai anggaran resmi kegiatan. Tindakan ini tercatat dalam audit log.',
      confirmLabel: 'Setujui Anggaran',
      confirmColor: AppColors.primary900,
    );

    if (confirmed == true) {
      try {
        await _budgetService.approveBudgetVersion(version.id);
        if (!mounted) return;
        _hasMutated = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Versi Anggaran #${version.versionNumber} berhasil disetujui.'),
            backgroundColor: AppColors.statusApprovedText,
          ),
        );
        _fetchDetail();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.statusRejectedText,
          ),
        );
      }
    }
  }

  Future<void> _handleReject() async {
    if (_detail == null) return;
    final version = _detail!.version;

    if (version.submittedBy != null && version.submittedBy == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Prinsip pemisahan tugas: Pemohon tidak diizinkan menolak atau memproses pengajuannya sendiri.',
          ),
          backgroundColor: AppColors.statusRejectedText,
        ),
      );
      return;
    }

    final reason = await RejectionReasonDialog.show(
      context,
      title: 'Tolak Versi Anggaran #${version.versionNumber}',
      message: 'Masukkan alasan penolakan secara jelas untuk perbaikan skenario anggaran.',
    );

    if (reason != null && reason.trim().isNotEmpty) {
      try {
        await _budgetService.rejectBudgetVersion(version.id, reason: reason);
        if (!mounted) return;
        _hasMutated = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Versi Anggaran #${version.versionNumber} telah ditolak.'),
            backgroundColor: AppColors.statusRejectedText,
          ),
        );
        _fetchDetail();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.statusRejectedText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _hasMutated) {
          // Hasil mutasi sudah ditangani oleh pop
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceMuted,
        appBar: AppBar(
          title: Text(_detail != null ? 'Versi #${_detail!.version.versionNumber}' : 'Detail Versi Anggaran'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasMutated),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchDetail,
            color: AppColors.primary700,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Memuat rincian versi anggaran...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchDetail,
      );
    }

    if (_detail == null) {
      return const EmptyStateView(
        icon: Icons.error_outline,
        title: 'Versi Anggaran Tidak Ditemukan',
        description: 'Data versi anggaran tidak tersedia atau telah dihapus.',
      );
    }

    final version = _detail!.version;
    final items = _detail!.items;
    final comparison = _detail!.comparison;
    final isBendahara = widget.organization.isBendahara;
    final isSelfSubmission = version.submittedBy == _currentUserId;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Resmi Aktif
          if (version.isApproved) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, size: 20, color: AppColors.primary700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anggaran resmi aktif: Semua pengeluaran lapangan diverifikasi mengacu pada snapshot ini.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Kartu Header Versi
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Versi Anggaran #${version.versionNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      StatusBadge(status: version.status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (version.submittedAt != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Diajukan ${DateFormatter.formatDateTime(version.submittedAt!)}${version.submittedByName != null ? ' oleh ${version.submittedByName}' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  if (version.reviewedAt != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${version.isApproved ? 'Disetujui' : version.isRejected ? 'Ditolak' : 'Direview'} oleh ${version.reviewedByName ?? 'Bendahara'} pada ${DateFormatter.formatDateTime(version.reviewedAt!)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Tombol Review Bendahara di dalam Header jika status submitted
                  if (isBendahara && version.isSubmitted) ...[
                    const Divider(height: 24),
                    if (isSelfSubmission) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.statusPartialBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.statusPartialBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 15, color: AppColors.statusPartialText),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Anda adalah pemohon versi ini. Prinsip pemisahan tugas mewajibkan persetujuan oleh Bendahara lain.',
                                style: TextStyle(fontSize: 11, color: AppColors.statusPartialText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Tolak Anggaran',
                            isOutlined: true,
                            foregroundColor: AppColors.statusRejectedText,
                            onPressed: isSelfSubmission ? null : _handleReject,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Setujui Anggaran',
                            backgroundColor: AppColors.primary900,
                            onPressed: isSelfSubmission ? null : _handleApprove,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metrik Finansial
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Anggaran',
                  CurrencyFormatter.format(version.snapshotTotal),
                  AppColors.primary900,
                  isBold: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Pagu Saat Diajukan',
                  CurrencyFormatter.format(version.snapshotAvailableFunds),
                  AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Peserta',
                  '${version.snapshotParticipantCount} orang',
                  AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alasan Penolakan
          if (version.isRejected && version.rejectionReason != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusRejectedBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.statusRejectedBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan Alasan Penolakan oleh Bendahara:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusRejectedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    version.rejectionReason!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.statusRejectedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Fitur Perbandingan Versi (Diff Snapshot)
          if (comparison != null) ...[
            _buildComparisonCard(comparison),
            const SizedBox(height: 16),
          ],

          // Rincian Item Anggaran Snapshot
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rincian Item (${items.length} item)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Snapshot Terkunci',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),

                  if (items.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'Tidak ada rincian item tercatat.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final item = items[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.category != null ? '${item.category} • ' : ''}${item.quantity} × ${CurrencyFormatter.format(item.unitCost)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(item.total),
                                style: AppTheme.moneyStyle.copyWith(
                                  color: AppColors.primary900,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Anggaran Snapshot:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(version.snapshotTotal),
                          style: AppTheme.moneyLargeStyle.copyWith(
                            color: AppColors.primary900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color valueColor, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(BudgetComparisonModel comparison) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, size: 18, color: AppColors.primary900),
                const SizedBox(width: 8),
                Text(
                  'Perbandingan vs Versi #${comparison.previousVersionNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary metrik perubahan
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selisih Total:',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${comparison.deltaTotal >= 0 ? '+' : ''}${CurrencyFormatter.format(comparison.deltaTotal)} (${comparison.deltaTotalPercentage >= 0 ? '+' : ''}${comparison.deltaTotalPercentage}%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: comparison.deltaTotal > 0
                                ? AppColors.statusPartialText
                                : comparison.deltaTotal < 0
                                ? AppColors.statusApprovedText
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppColors.border),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perubahan Item:',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+${comparison.addedItemsCount} baru, ${comparison.modifiedItemsCount} ubah',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (comparison.diffs.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Daftar Perubahan Item:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comparison.diffs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final diff = comparison.diffs[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: diff.type == 'added'
                                ? AppColors.statusApprovedBg
                                : diff.type == 'removed'
                                ? AppColors.statusRejectedBg
                                : AppColors.statusPartialBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            diff.type == 'added'
                                ? 'Baru'
                                : diff.type == 'removed'
                                ? 'Dihapus'
                                : 'Diubah',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: diff.type == 'added'
                                  ? AppColors.statusApprovedText
                                  : diff.type == 'removed'
                                  ? AppColors.statusRejectedText
                                  : AppColors.statusPartialText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            diff.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                        ),
                        Text(
                          '${diff.totalDifference >= 0 ? '+' : ''}${CurrencyFormatter.format(diff.totalDifference)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: diff.totalDifference > 0
                                ? AppColors.statusPartialText
                                : diff.totalDifference < 0
                                ? AppColors.statusApprovedText
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
