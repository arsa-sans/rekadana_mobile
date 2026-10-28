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
import 'budget_version_detail_screen.dart';
import 'models/budget_version_model.dart';
import 'models/event_model.dart';
import 'models/organization_model.dart';

class BudgetVersionListScreen extends StatefulWidget {
  final OrganizationModel organization;
  final EventModel event;

  const BudgetVersionListScreen({
    super.key,
    required this.organization,
    required this.event,
  });

  @override
  State<BudgetVersionListScreen> createState() => _BudgetVersionListScreenState();
}

class _BudgetVersionListScreenState extends State<BudgetVersionListScreen> {
  final BudgetService _budgetService = BudgetService();
  final SecureStorageService _storage = SecureStorageService();

  List<BudgetVersionModel> _versions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

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
    _fetchVersions();
  }

  Future<void> _fetchVersions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _budgetService.listBudgetVersions(widget.event.id);
      if (!mounted) return;
      setState(() {
        _versions = list;
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

  Future<void> _handleApprove(BudgetVersionModel version) async {
    if (version.submittedBy != null && version.submittedBy == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Prinsip pemisahan tugas: Pemohon tidak diizinkan menyetujui pengajuannya sendiri. Akun Bendahara lain harus menyetujui.',
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
          'Versi anggaran sebesar ${CurrencyFormatter.format(version.snapshotTotal)} akan diaktifkan sebagai acuan pengeluaran resmi kegiatan. Versi anggaran sebelumnya akan didemosi menjadi draf.',
      confirmLabel: 'Setujui Anggaran',
      confirmColor: AppColors.primary900,
    );

    if (confirmed == true) {
      try {
        await _budgetService.approveBudgetVersion(version.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Versi Anggaran #${version.versionNumber} berhasil disetujui.'),
            backgroundColor: AppColors.statusApprovedText,
          ),
        );
        _fetchVersions();
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

  Future<void> _handleReject(BudgetVersionModel version) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Versi Anggaran #${version.versionNumber} ditolak dengan alasan tercatat.'),
            backgroundColor: AppColors.statusRejectedText,
          ),
        );
        _fetchVersions();
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
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Riwayat Versi Anggaran'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kegiatan: ${widget.event.name}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchVersions,
          color: AppColors.primary700,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Memuat histori versi anggaran...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchVersions,
      );
    }

    if (_versions.isEmpty) {
      return const EmptyStateView(
        icon: Icons.history_toggle_off,
        title: 'Belum Ada Versi Anggaran',
        description:
            'Versi anggaran dibuat saat skenario diajukan dari Scenario Lab untuk persetujuan Bendahara.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _versions.length,
      itemBuilder: (ctx, index) {
        final version = _versions[index];
        return _buildVersionCard(version);
      },
    );
  }

  Widget _buildVersionCard(BudgetVersionModel version) {
    final isBendahara = widget.organization.isBendahara;
    final isSelfSubmission = version.submittedBy == _currentUserId;
    final isApprovedActive = version.isApproved;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isApprovedActive ? AppColors.primary500 : AppColors.border,
          width: isApprovedActive ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => BudgetVersionDetailScreen(
                organization: widget.organization,
                event: widget.event,
                versionId: version.id,
              ),
            ),
          );
          if (changed == true) {
            _fetchVersions();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Versi Resmi Aktif
              if (isApprovedActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: AppColors.primary700),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Anggaran Resmi Aktif (Batas Komitmen Kegiatan)',
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
              ],

              // Header: Nomor Versi & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isApprovedActive ? AppColors.primary900 : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${version.versionNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isApprovedActive ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Versi Anggaran #${version.versionNumber}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(status: version.status),
                ],
              ),
              const SizedBox(height: 12),

              // Submitter & Waktu
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
                const SizedBox(height: 6),
              ],

              // Reviewer info jika ada
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
                const SizedBox(height: 8),
              ],

              // Snapshot Finansial Box
              Container(
                padding: const EdgeInsets.all(12),
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
                            'Total Snapshot',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(version.snapshotTotal),
                            style: AppTheme.moneyStyle.copyWith(
                              color: AppColors.primary900,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: AppColors.border),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pagu Saat Diajukan',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(version.snapshotAvailableFunds),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Peserta',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${version.snapshotParticipantCount} org',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Alasan penolakan jika status rejected
              if (version.isRejected && version.rejectionReason != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusRejectedBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.statusRejectedBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alasan Penolakan oleh Bendahara:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusRejectedText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        version.rejectionReason!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.statusRejectedText,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Peringatan Self-Approval untuk Bendahara
              if (isBendahara && version.isSubmitted && isSelfSubmission) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
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
                          'Anda mengajukan versi ini. Sesuai prinsip pemisahan tugas, akun Bendahara lain harus menyetujui.',
                          style: TextStyle(fontSize: 11, color: AppColors.statusPartialText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Footer: Tombol Aksi Bendahara atau Link Detail
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Rincian item & perbandingan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary700,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.primary700),
                    ],
                  ),

                  // Aksi Approve/Reject hanya untuk Bendahara pada versi submitted
                  if (isBendahara && version.isSubmitted) ...[
                    Row(
                      children: [
                        AppButton(
                          label: 'Tolak',
                          isOutlined: true,
                          foregroundColor: AppColors.statusRejectedText,
                          onPressed: isSelfSubmission ? null : () => _handleReject(version),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Setujui',
                          backgroundColor: AppColors.primary900,
                          onPressed: isSelfSubmission ? null : () => _handleApprove(version),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
