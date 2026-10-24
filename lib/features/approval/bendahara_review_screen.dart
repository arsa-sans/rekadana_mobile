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
import '../expenses/expense_service.dart';
import '../expenses/models/expense_request_model.dart';
import '../organization/models/event_model.dart';
import '../organization/models/organization_model.dart';

class BendaharaReviewScreen extends StatefulWidget {
  final OrganizationModel organization;
  final EventModel event;

  const BendaharaReviewScreen({
    super.key,
    required this.organization,
    required this.event,
  });

  @override
  State<BendaharaReviewScreen> createState() => _BendaharaReviewScreenState();
}

class _BendaharaReviewScreenState extends State<BendaharaReviewScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final SecureStorageService _storage = SecureStorageService();

  List<ExpenseRequestModel> _allRequests = [];
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
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _expenseService.listExpenseRequests(widget.event.id);
      if (!mounted) return;
      setState(() {
        _allRequests = list;
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

  Future<void> _handleApprove(ExpenseRequestModel request) async {
    // Validasi pencegahan self-approval di sisi klien
    if (request.requestedBy != null && request.requestedBy == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prinsip pemisahan tugas: Anda tidak diizinkan menyetujui pengajuan Anda sendiri.'),
          backgroundColor: AppColors.statusRejectedText,
        ),
      );
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Persetujuan Pengeluaran',
      message:
          'Setujui pengeluaran "${request.title}" sebesar ${CurrencyFormatter.format(request.requestedAmount)}? Dana akan dialokasikan sebagai komitmen resmi.',
      confirmLabel: 'Setujui Pengeluaran',
      confirmColor: AppColors.statusApprovedText,
    );

    if (confirmed == true) {
      try {
        await _expenseService.approveExpense(request.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengeluaran "${request.title}" berhasil disetujui.'),
            backgroundColor: AppColors.statusApprovedText,
          ),
        );
        _fetchRequests();
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

  Future<void> _handleReject(ExpenseRequestModel request) async {
    final reason = await RejectionReasonDialog.show(
      context,
      title: 'Tolak Permintaan Pengeluaran',
      message: 'Masukkan alasan penolakan untuk "${request.title}" sebagai catatan audit resmi.',
    );

    if (reason != null && reason.trim().isNotEmpty) {
      try {
        await _expenseService.rejectExpense(request.id, reason: reason);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permintaan "${request.title}" telah ditolak dengan alasan tercatat.'),
            backgroundColor: AppColors.statusRejectedText,
          ),
        );
        _fetchRequests();
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surfaceMuted,
        appBar: AppBar(
          title: const Text('Review Pengeluaran Bendahara'),
          bottom: const TabBar(
            labelColor: AppColors.primary700,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary700,
            tabs: [
              Tab(text: 'Menunggu Review'),
              Tab(text: 'Semua Riwayat'),
            ],
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchRequests,
            color: AppColors.primary700,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Memuat data pengajuan pengeluaran...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchRequests,
      );
    }

    final pendingList = _allRequests.where((r) => r.isPending).toList();

    return TabBarView(
      children: [
        _buildPendingTab(pendingList),
        _buildAllTab(_allRequests),
      ],
    );
  }

  Widget _buildPendingTab(List<ExpenseRequestModel> pendingList) {
    if (pendingList.isEmpty) {
      return const EmptyStateView(
        icon: Icons.check_circle_outline,
        title: 'Semua Pengajuan Telah Direview',
        description: 'Tidak ada pengajuan kebutuhan lapangan yang sedang menunggu persetujuan.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: pendingList.length,
      itemBuilder: (ctx, index) {
        final item = pendingList[index];
        return _buildReviewCard(item);
      },
    );
  }

  Widget _buildAllTab(List<ExpenseRequestModel> allList) {
    if (allList.isEmpty) {
      return const EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'Belum Ada Riwayat',
        description: 'Belum ada transaksi pengeluaran yang tercatat untuk kegiatan ini.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: allList.length,
      itemBuilder: (ctx, index) {
        final item = allList[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildReviewCard(ExpenseRequestModel request) {
    final isSelfSubmission = request.requestedBy == _currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const StatusBadge(status: 'submitted'),
                Text(
                  DateFormatter.formatDateTime(request.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              request.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (request.description != null && request.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                request.description!,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 14),

            // Nominal Besar & Jelas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nominal Diajukan:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(request.requestedAmount),
                    style: AppTheme.moneyLargeStyle.copyWith(color: AppColors.primary700),
                  ),
                ],
              ),
            ),

            if (isSelfSubmission) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusRejectedBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.statusRejectedText),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Anda adalah pemohon pengeluaran ini. Self-approval tidak diizinkan.',
                        style: TextStyle(fontSize: 12, color: AppColors.statusRejectedText),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            // Dua tombol aksi cepat: Tolak dan Setujui
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Tolak',
                    isOutlined: true,
                    foregroundColor: AppColors.statusRejectedText,
                    onPressed: () => _handleReject(request),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Setujui',
                    backgroundColor: AppColors.statusApprovedText,
                    onPressed: isSelfSubmission ? null : () => _handleApprove(request),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ExpenseRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status: request.status),
                Text(
                  DateFormatter.formatDateTime(request.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nominal:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  CurrencyFormatter.format(request.requestedAmount),
                  style: AppTheme.moneyStyle,
                ),
              ],
            ),
            if (request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusRejectedBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Alasan penolakan: ${request.rejectionReason}',
                  style: const TextStyle(fontSize: 12, color: AppColors.statusRejectedText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
