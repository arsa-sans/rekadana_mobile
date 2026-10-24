import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/state_views.dart';
import '../approval/bendahara_review_screen.dart';
import '../expenses/expense_create_screen.dart';
import '../expenses/expense_list_screen.dart';
import 'models/event_model.dart';
import 'models/organization_model.dart';
import 'models/report_model.dart';
import 'org_service.dart';

class EventsListScreen extends StatefulWidget {
  final OrganizationModel organization;

  const EventsListScreen({
    super.key,
    required this.organization,
  });

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final OrgService _orgService = OrgService();

  List<EventModel>? _events;
  final Map<String, BudgetVsActualReportModel> _reportsMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _orgService.getEvents(widget.organization.id);
      if (!mounted) return;
      setState(() {
        _events = list;
        _isLoading = false;
      });

      // Muat ringkasan finansial untuk masing-masing kegiatan
      for (final ev in list) {
        _loadEventReport(ev.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEventReport(String eventId) async {
    try {
      final report = await _orgService.getBudgetReport(eventId);
      if (mounted) {
        setState(() {
          _reportsMap[eventId] = report;
        });
      }
    } catch (_) {
      // Abaikan error laporan parsial agar kartu tetap dapat berinteraksi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: Text(widget.organization.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Peran Anda: ${widget.organization.roleDisplayTitle}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary700,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchEvents,
          color: AppColors.primary700,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Memuat daftar kegiatan organisasi...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchEvents,
      );
    }

    if (_events == null || _events!.isEmpty) {
      return const EmptyStateView(
        icon: Icons.event_busy_outlined,
        title: 'Belum Ada Kegiatan',
        description: 'Organisasi ini belum memiliki agenda kegiatan yang aktif.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _events!.length,
      itemBuilder: (ctx, index) {
        final event = _events![index];
        final report = _reportsMap[event.id];
        return _buildEventCard(event, report);
      },
    );
  }

  Widget _buildEventCard(EventModel event, BudgetVsActualReportModel? report) {
    final canReview = widget.organization.isBendahara || widget.organization.isKetua;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Kegiatan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary200, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 14, color: AppColors.primary700),
                      const SizedBox(width: 4),
                      Text(
                        '${event.participantCount} Peserta',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ringkasan Finansial 4 Metrik
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          'Pagu Dana',
                          CurrencyFormatter.format(event.availableFunds),
                          AppColors.textPrimary,
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Expanded(
                        child: _buildMetricItem(
                          'Anggaran Resmi',
                          report != null
                              ? CurrencyFormatter.format(report.approvedBudgetTotal)
                              : 'Memuat...',
                          AppColors.primary700,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          'Realisasi Bersih',
                          report != null
                              ? CurrencyFormatter.format(report.actualNet)
                              : 'Memuat...',
                          AppColors.statusPaidText,
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Expanded(
                        child: _buildMetricItem(
                          'Sisa Kontrol',
                          report != null
                              ? CurrencyFormatter.format(report.remainingControlBudget)
                              : 'Memuat...',
                          AppColors.statusApprovedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tombol Aksi Lapangan
            Column(
              children: [
                // Tombol utama: Ajukan Pengeluaran
                AppButton(
                  label: 'Ajukan Pengeluaran Lapangan',
                  icon: Icons.add_circle_outline,
                  onPressed: () async {
                    final res = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExpenseCreateScreen(
                          organization: widget.organization,
                          event: event,
                        ),
                      ),
                    );
                    if (res == true) {
                      _fetchEvents();
                    }
                  },
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Daftar Pengeluaran',
                        isOutlined: true,
                        icon: Icons.receipt_long_outlined,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExpenseListScreen(
                                organization: widget.organization,
                                event: event,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (canReview) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: 'Review Bendahara',
                          icon: Icons.rate_review_outlined,
                          backgroundColor: AppColors.primary900,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BendaharaReviewScreen(
                                  organization: widget.organization,
                                  event: event,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.moneyStyle.copyWith(
              color: valueColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
