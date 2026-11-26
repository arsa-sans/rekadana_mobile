import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/currency_input_field.dart';
import '../../core/widgets/state_views.dart';
import '../approval/bendahara_review_screen.dart';
import '../expenses/expense_create_screen.dart';
import '../expenses/expense_list_screen.dart';
import '../scenarios/scenario_list_screen.dart';
import 'models/event_model.dart';
import 'models/organization_model.dart';
import 'models/report_model.dart';
import 'org_service.dart';
import 'budget_version_list_screen.dart';

class EventsListScreen extends StatefulWidget {
  final OrganizationModel organization;
  final List<EventModel>? initialEvents;
  final Map<String, BudgetVsActualReportModel>? initialReports;

  const EventsListScreen({
    super.key,
    required this.organization,
    this.initialEvents,
    this.initialReports,
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
    if (widget.initialEvents != null) {
      _events = widget.initialEvents;
      if (widget.initialReports != null) {
        _reportsMap.addAll(widget.initialReports!);
      }
      _isLoading = false;
    } else {
      _fetchEvents();
    }
  }

  @override
  void didUpdateWidget(covariant EventsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEvents != null && widget.initialEvents != oldWidget.initialEvents) {
      _events = widget.initialEvents;
      _reportsMap
        ..clear()
        ..addAll(widget.initialReports ?? {});
      _isLoading = false;
    }
  }

  // Sentinel untuk membedakan "sedang loading" (null) vs "selesai dimuat tapi tidak ada" (error/no budget)
  final Map<String, bool> _reportLoadingMap = {};
  bool _hasReportLoadError = false;

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasReportLoadError = false;
    });

    try {
      final list = await _orgService.getEvents(widget.organization.id);
      if (!mounted) return;
      setState(() {
        _events = list;
        _isLoading = false;
        // Tandai semua event sebagai sedang loading report
        for (final ev in list) {
          _reportLoadingMap[ev.id] = true;
        }
      });

      // Muat ringkasan finansial: maksimal 3 event secara bersamaan (D.3)
      await _loadAllReportsBounded(list);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Sequential + bounded concurrent loading: maks 3 request paralel sekaligus
  Future<void> _loadAllReportsBounded(List<EventModel> events) async {
    const int concurrency = 3;
    bool anyFailure = false;
    for (int i = 0; i < events.length; i += concurrency) {
      final batch = events.skip(i).take(concurrency).toList();
      final results = await Future.wait(batch.map((ev) => _loadEventReport(ev.id)));
      if (results.any((success) => !success)) {
        anyFailure = true;
      }
    }
    if (mounted && anyFailure && _reportsMap.isEmpty && events.isNotEmpty) {
      setState(() {
        _hasReportLoadError = true;
      });
    }
  }

  Future<bool> _loadEventReport(String eventId) async {
    try {
      final report = await _orgService.getBudgetReport(eventId);
      if (mounted) {
        setState(() {
          _reportsMap[eventId] = report;
          _reportLoadingMap[eventId] = false;
        });
      }
      return true;
    } catch (_) {
      // Selesai loading, tetapi tidak ada anggaran atau koneksi gagal.
      if (mounted) {
        setState(() {
          _reportLoadingMap[eventId] = false;
        });
      }
      return false;
    }
  }

  Future<void> _showCreateEventDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final fundsCtrl = TextEditingController();
    final participantsCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: AppColors.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buat Kegiatan Baru',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.statusRejectedBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.statusRejectedBorder),
                          ),
                          child: Text(
                            dialogError!,
                            style: const TextStyle(fontSize: 12, color: AppColors.statusRejectedText),
                          ),
                        ),
                      ],
                      AppTextField(
                        controller: nameCtrl,
                        label: 'Nama Kegiatan',
                        hint: 'Contoh: LDKS 2026',
                        validator: (v) {
                          if (v == null || v.trim().length < 3) {
                            return 'Nama kegiatan minimal 3 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: descCtrl,
                        label: 'Deskripsi Kegiatan (opsional)',
                        hint: 'Ringkasan tujuan kegiatan',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      CurrencyInputField(
                        controller: fundsCtrl,
                        label: 'Pagu Dana Tersedia (Rp)',
                        helperText: 'Alokasi pagu dana kas organisasi',
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: participantsCtrl,
                        label: 'Target Peserta',
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.ghost(
                              label: 'Batal',
                              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'Simpan Kegiatan',
                              isLoading: isSubmitting,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                final messenger = ScaffoldMessenger.of(context);
                                setDialogState(() {
                                  isSubmitting = true;
                                  dialogError = null;
                                });
                                try {
                                  final cleanFunds = CurrencyFormatter.cleanToNumeric(fundsCtrl.text);
                                  final participants = int.tryParse(participantsCtrl.text.trim()) ?? 0;
                                  await _orgService.createEvent(
                                    widget.organization.id,
                                    name: nameCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    participantCount: participants,
                                    availableFunds: cleanFunds.isEmpty ? '0' : cleanFunds,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Kegiatan berhasil dibuat.'),
                                      backgroundColor: AppColors.statusApprovedText,
                                    ),
                                  );
                                  _fetchEvents();
                                } catch (err) {
                                  setDialogState(() {
                                    isSubmitting = false;
                                    dialogError = err.toString();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    nameCtrl.dispose();
    descCtrl.dispose();
    fundsCtrl.dispose();
    participantsCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: Text(widget.organization.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
            tooltip: 'Ganti Organisasi',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
                  color: AppColors.forest,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: (widget.organization.isKetua || widget.organization.isBendahara)
          ? FloatingActionButton.extended(
              onPressed: _showCreateEventDialog,
              icon: const Icon(Icons.add, color: AppColors.onPrimary),
              label: const Text('Buat Kegiatan', style: TextStyle(color: AppColors.onPrimary)),
              backgroundColor: AppColors.forest,
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchEvents,
          color: AppColors.forest,
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
        icon: Icons.event_note_outlined,
        title: 'Belum Ada Kegiatan',
        description: 'Organisasi ini belum memiliki agenda kegiatan yang aktif.',
      );
    }

    final showPartialErrorBanner = _hasReportLoadError && _reportsMap.isEmpty;

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 84.0),
      itemCount: _events!.length + (showPartialErrorBanner ? 1 : 0),
      itemBuilder: (ctx, index) {
        if (showPartialErrorBanner && index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.statusPartialBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.statusPartialBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.sync_problem_outlined, size: 16, color: AppColors.statusPartialText),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sebagian ringkasan keuangan tidak dapat dimuat. Tarik ke bawah untuk memuat ulang.',
                    style: TextStyle(fontSize: 12, color: AppColors.statusPartialText),
                  ),
                ),
              ],
            ),
          );
        }
        final eventIndex = showPartialErrorBanner ? index - 1 : index;
        final event = _events![eventIndex];
        final report = _reportsMap[event.id];
        return _buildEventCard(event, report);
      },
    );
  }

  Widget _buildEventCard(EventModel event, BudgetVsActualReportModel? report) {
    final canReview = widget.organization.isBendahara || widget.organization.isKetua;
    final remainingVal = double.tryParse(report?.remainingControlBudget ?? '0') ?? 0;

    final isReportLoading = _reportLoadingMap[event.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Kegiatan
            LayoutBuilder(
              builder: (context, constraints) {
                final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
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
                );
                final participantBadge = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 14, color: AppColors.forest),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${event.participantCount} Peserta',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (highScale || constraints.maxWidth < 280) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      const SizedBox(height: 8),
                      participantBadge,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 10),
                    participantBadge,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Ringkasan Finansial 4 Metrik (latar surfaceRaised menjaga rasio kontras statusApprovedText 4.58:1)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: isReportLoading
                  // Shimmer placeholder saat report sedang loading per card (D.3)
                  ? _buildMetricShimmer()
                  : report != null
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricItem(
                                    'Pagu Dana',
                                    CurrencyFormatter.format(event.availableFunds),
                                    AppColors.forest,
                                  ),
                                ),
                                Container(width: 1, height: 40, color: AppColors.border),
                                Expanded(
                                  child: _buildMetricItem(
                                    'Anggaran Resmi',
                                    CurrencyFormatter.format(report.approvedBudgetTotal),
                                    AppColors.forest,
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
                                    CurrencyFormatter.format(report.actualNet),
                                    AppColors.statusPaidText,
                                  ),
                                ),
                                Container(width: 1, height: 40, color: AppColors.border),
                                Expanded(
                                  child: _buildMetricItem(
                                    'Sisa Kontrol',
                                    CurrencyFormatter.format(report.remainingControlBudget),
                                    remainingVal < 0
                                        ? AppColors.statusRejectedText
                                        : AppColors.statusApprovedText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      // D.1: report null setelah selesai loading = belum ada anggaran resmi
                      : _buildNoBudgetPlaceholder(),
            ),
            const SizedBox(height: 16),

            // Hierarki 3 tingkat aksi: Utama (Forest penuh), Sekunder (50:50 Ghost), Tersier (50:50 Text)
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

            LayoutBuilder(
              builder: (context, constraints) {
                final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                final stackSecondary = canReview && (constraints.maxWidth < 260 || highScale);
                final expenseListButton = AppButton.ghost(
                  label: 'Daftar Pengeluaran',
                  icon: Icons.receipt_long_outlined,
                  size: AppButtonSize.compact,
                  fullWidth: !canReview || stackSecondary,
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
                );

                if (!canReview) {
                  return expenseListButton;
                }

                final reviewButton = AppButton.ghost(
                  label: 'Review Bendahara',
                  icon: Icons.rate_review_outlined,
                  size: AppButtonSize.compact,
                  fullWidth: stackSecondary,
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
                );

                if (stackSecondary) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      expenseListButton,
                      const SizedBox(height: 8),
                      reviewButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: expenseListButton),
                    const SizedBox(width: 8),
                    Expanded(child: reviewButton),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),

            LayoutBuilder(
              builder: (context, constraints) {
                final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                final scenarioBtn = _buildTertiaryAction(
                  label: 'Scenario Lab',
                  icon: Icons.science_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScenarioListScreen(
                          organization: widget.organization,
                          event: event,
                        ),
                      ),
                    );
                  },
                );
                final versionBtn = _buildTertiaryAction(
                  label: 'Versi Anggaran',
                  icon: Icons.history_edu_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BudgetVersionListScreen(
                          organization: widget.organization,
                          event: event,
                        ),
                      ),
                    );
                  },
                );

                if (constraints.maxWidth < 260 || highScale) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      scenarioBtn,
                      versionBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: scenarioBtn),
                    const SizedBox(width: 8),
                    Expanded(child: versionBtn),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTertiaryAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.forest,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.forest),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.forest,
              ),
            ),
          ),
        ],
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.moneyStyle.copyWith(
              color: valueColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // D.3: Shimmer placeholder saat report per card sedang loading
  Widget _buildMetricShimmer() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _shimmerBlock(label: 'Pagu Dana')),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(child: _shimmerBlock(label: 'Anggaran Resmi')),
          ],
        ),
        const Divider(height: 16),
        Row(
          children: [
            Expanded(child: _shimmerBlock(label: 'Realisasi Bersih')),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(child: _shimmerBlock(label: 'Sisa Kontrol')),
          ],
        ),
      ],
    );
  }

  Widget _shimmerBlock({required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Container(
            height: 14,
            width: 72,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // D.1: Placeholder saat event belum punya anggaran resmi
  Widget _buildNoBudgetPlaceholder() {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Belum ada anggaran resmi untuk kegiatan ini.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
