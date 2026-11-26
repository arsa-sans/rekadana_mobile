import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/rejection_reason_dialog.dart';
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
  final BudgetVersionDetailModel? initialDetail;

  const BudgetVersionDetailScreen({
    super.key,
    required this.organization,
    required this.event,
    required this.versionId,
    this.initialDetail,
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
    if (widget.initialDetail != null) {
      _detail = widget.initialDetail;
      _isLoading = false;
    } else {
      _loadUserAndData();
    }
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
      confirmColor: AppColors.statusApprovedText,
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
        backgroundColor: AppColors.cloud,
        appBar: AppBar(
          title: Text(_detail != null ? 'Versi #${_detail!.version.versionNumber}' : 'Detail Versi Anggaran'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
            onPressed: () => Navigator.of(context).pop(_hasMutated),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchDetail,
            color: AppColors.forest,
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
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.growth),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_outlined, size: 20, color: AppColors.forest),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anggaran resmi aktif: Semua pengeluaran lapangan diverifikasi mengacu pada snapshot ini.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                      final titleWidget = Text(
                        'Versi Anggaran #${version.versionNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                        ),
                      );
                      if (highScale || constraints.maxWidth < 280) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleWidget,
                            const SizedBox(height: 8),
                            StatusBadge(status: version.status),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: titleWidget),
                          const SizedBox(width: 8),
                          StatusBadge(status: version.status),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  if (version.submittedAt != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
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
                        const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
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
                            Icon(Icons.lock_outlined, size: 15, color: AppColors.statusPartialText),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                        final stackButtons = constraints.maxWidth < 260 || highScale;
                        final rejectBtn = AppButton.ghost(
                          label: 'Tolak Anggaran',
                          size: AppButtonSize.compact,
                          fullWidth: stackButtons,
                          foregroundColor: AppColors.statusRejectedText,
                          borderColor: AppColors.statusRejectedText,
                          onPressed: isSelfSubmission ? null : _handleReject,
                        );
                        final approveBtn = AppButton(
                          label: 'Setujui Anggaran',
                          size: AppButtonSize.compact,
                          fullWidth: stackButtons,
                          backgroundColor: AppColors.statusApprovedText,
                          foregroundColor: AppColors.onPrimary,
                          onPressed: isSelfSubmission ? null : _handleApprove,
                        );
                        if (stackButtons) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              rejectBtn,
                              const SizedBox(height: 8),
                              approveBtn,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: rejectBtn),
                            const SizedBox(width: 12),
                            Expanded(child: approveBtn),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metrik Finansial
          LayoutBuilder(
            builder: (context, constraints) {
              final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
              if (highScale || constraints.maxWidth < 280) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMetricCard(
                      'Total Anggaran',
                      CurrencyFormatter.format(version.snapshotTotal),
                      AppColors.forest,
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricCard(
                      'Pagu Saat Diajukan',
                      CurrencyFormatter.format(version.snapshotAvailableFunds),
                      AppColors.forest,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricCard(
                      'Peserta',
                      '${version.snapshotParticipantCount} orang',
                      AppColors.forest,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Anggaran',
                      CurrencyFormatter.format(version.snapshotTotal),
                      AppColors.forest,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Pagu Saat Diajukan',
                      CurrencyFormatter.format(version.snapshotAvailableFunds),
                      AppColors.forest,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Peserta',
                      '${version.snapshotParticipantCount} orang',
                      AppColors.forest,
                    ),
                  ),
                ],
              );
            },
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                      final titleWidget = Text(
                        'Rincian Item (${items.length} item)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                        ),
                      );
                      const subtitleWidget = Text(
                        'Snapshot Terkunci',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      );
                      if (highScale || constraints.maxWidth < 260) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleWidget,
                            const SizedBox(height: 2),
                            subtitleWidget,
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleWidget),
                          const SizedBox(width: 8),
                          const Flexible(child: subtitleWidget),
                        ],
                      );
                    },
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                              final itemInfo = Column(
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
                              );
                              final totalText = Text(
                                CurrencyFormatter.format(item.total),
                                style: AppTheme.moneyStyle.copyWith(
                                  color: AppColors.forest,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                              if (highScale || constraints.maxWidth < 260) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    itemInfo,
                                    const SizedBox(height: 4),
                                    totalText,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: itemInfo),
                                  const SizedBox(width: 8),
                                  Flexible(child: totalText),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],

                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                        const labelWidget = Text(
                          'Total Anggaran Snapshot:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        );
                        final amountWidget = FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(version.snapshotTotal),
                            style: AppTheme.moneyLargeStyle.copyWith(
                              color: AppColors.forest,
                              fontSize: 16,
                            ),
                          ),
                        );
                        if (highScale || constraints.maxWidth < 280) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              labelWidget,
                              const SizedBox(height: 4),
                              amountWidget,
                            ],
                          );
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: labelWidget),
                            const SizedBox(width: 8),
                            Flexible(child: amountWidget),
                          ],
                        );
                      },
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTheme.moneyStyle.copyWith(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor,
              ),
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
                const Icon(Icons.compare_arrows, size: 18, color: AppColors.forest),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Perbandingan vs Versi #${comparison.previousVersionNumber}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary metrik perubahan (latar putih agar label 11px #64748B lolos WCAG AA 4.76:1)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                  final deltaCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selisih Total:',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${comparison.deltaTotal >= 0 ? '+' : ''}${CurrencyFormatter.format(comparison.deltaTotal)} (${comparison.deltaTotalPercentage >= 0 ? '+' : ''}${comparison.deltaTotalPercentage}%)',
                        style: AppTheme.moneyStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: comparison.deltaTotal > 0
                              ? AppColors.statusPartialText
                              : comparison.deltaTotal < 0
                              ? AppColors.statusApprovedText
                              : AppColors.forest,
                        ),
                      ),
                    ],
                  );
                  final itemChangesCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perubahan Item:',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+${comparison.addedItemsCount} baru, ${comparison.modifiedItemsCount} ubah',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  );

                  if (highScale || constraints.maxWidth < 260) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        deltaCol,
                        const Divider(height: 14),
                        itemChangesCol,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: deltaCol),
                      Container(width: 1, height: 28, color: AppColors.border),
                      const SizedBox(width: 10),
                      Expanded(child: itemChangesCol),
                    ],
                  );
                },
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                        final badge = Container(
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
                        );
                        final diffName = Text(
                          diff.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        );
                        final diffAmount = Text(
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
                        );

                        if (highScale || constraints.maxWidth < 260) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [badge, diffName],
                              ),
                              const SizedBox(height: 4),
                              diffAmount,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            badge,
                            const SizedBox(width: 8),
                            Expanded(child: diffName),
                            const SizedBox(width: 8),
                            Flexible(child: diffAmount),
                          ],
                        );
                      },
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
