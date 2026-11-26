import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/state_views.dart';
import '../organization/models/event_model.dart';
import '../organization/models/organization_model.dart';
import 'models/scenario_model.dart';
import 'scenario_create_screen.dart';
import 'scenario_item_form_screen.dart';
import 'scenario_service.dart';

class ScenarioListScreen extends StatefulWidget {
  final OrganizationModel organization;
  final EventModel event;
  final List<ScenarioModel>? initialScenarios;

  const ScenarioListScreen({
    super.key,
    required this.organization,
    required this.event,
    this.initialScenarios,
  });

  @override
  State<ScenarioListScreen> createState() => _ScenarioListScreenState();
}

class _ScenarioListScreenState extends State<ScenarioListScreen> {
  final ScenarioService _service = ScenarioService();

  List<ScenarioModel>? _scenarios;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialScenarios != null) {
      _scenarios = widget.initialScenarios;
      _isLoading = false;
    } else {
      _fetchScenarios();
    }
  }

  Future<void> _fetchScenarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getScenarios(widget.event.id);
      if (!mounted) return;
      setState(() {
        _scenarios = list;
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

  Future<void> _confirmSubmit(ScenarioModel scenario) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Ajukan Skenario?',
      message:
          'Skenario "${scenario.name}" akan dibekukan menjadi versi draf anggaran dan diajukan ke Bendahara untuk diverifikasi. Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Ya, Ajukan',
      confirmColor: AppColors.forest,
    );

    if (confirmed != true) return;

    try {
      await _service.submitScenario(scenario.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skenario berhasil diajukan ke Bendahara.'),
          backgroundColor: AppColors.statusApprovedText,
        ),
      );
      _fetchScenarios();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text('Scenario Lab'),
        actions: [
          if (_scenarios != null && _scenarios!.length < 3)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.forest),
              tooltip: 'Buat Skenario Baru',
              onPressed: () async {
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ScenarioCreateScreen(
                      organization: widget.organization,
                      event: widget.event,
                    ),
                  ),
                );
                if (res == true) _fetchScenarios();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchScenarios,
          color: AppColors.forest,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Memuat data simulasi skenario anggaran...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchScenarios,
      );
    }

    if (_scenarios == null || _scenarios!.isEmpty) {
      return EmptyStateView(
        icon: Icons.science_outlined,
        title: 'Belum Ada Skenario',
        description: 'Buat hingga 3 skenario anggaran untuk membandingkan opsi biaya sebelum diajukan ke Bendahara.',
        actionLabel: 'Buat Skenario Pertama',
        onAction: () async {
          final res = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => ScenarioCreateScreen(
                organization: widget.organization,
                event: widget.event,
              ),
            ),
          );
          if (res == true) _fetchScenarios();
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Peringatan Resmi
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusPartialBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.statusPartialBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Skenario bukan anggaran resmi sampai disetujui Bendahara. Gunakan perbandingan di bawah untuk memilih opsi terbaik.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.statusPartialText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Info Pagu Dana Kegiatan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: _buildResponsiveKeyValueRow(
            label: 'Pagu Dana Tersedia:',
            value: CurrencyFormatter.format(widget.event.availableFunds),
            valueStyle: AppTheme.moneyStyle.copyWith(
              fontSize: 14,
              color: AppColors.forest,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Daftar Kartu Skenario
        ..._scenarios!.map((sc) => _buildScenarioCard(sc)),
      ],
    );
  }

  Widget _buildScenarioCard(ScenarioModel sc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Kartu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sc.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                        ),
                      ),
                      if (sc.description != null && sc.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          sc.description!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (sc.isDeficit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusRejectedBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.statusRejectedBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_down, size: 14, color: AppColors.statusRejectedText),
                        SizedBox(width: 4),
                        Text(
                          'Defisit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusRejectedText,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrik Skenario (jarak 8px antar baris sesuai skala spacing DESIGN.md)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildResponsiveKeyValueRow(
                    label: 'Total Estimasi:',
                    value: CurrencyFormatter.format(sc.scenarioTotal),
                    valueStyle: AppTheme.moneyStyle.copyWith(
                      fontSize: 14,
                      color: sc.isDeficit ? AppColors.statusRejectedText : AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildResponsiveKeyValueRow(
                    label: 'Selisih Pagu:',
                    value: '${sc.fundGap >= 0 ? "+" : ""}${CurrencyFormatter.format(sc.fundGap)}',
                    valueStyle: AppTheme.moneyStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sc.fundGap < 0
                          ? AppColors.statusRejectedText
                          : AppColors.statusApprovedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildResponsiveKeyValueRow(
                    label: 'Biaya / Peserta (${sc.participantCount} org):',
                    value: sc.costPerParticipant != null
                        ? CurrencyFormatter.format(sc.costPerParticipant!)
                        : '-',
                    valueStyle: AppTheme.moneyStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forest,
                    ),
                  ),
                  if (sc.unfundedItemsCount > 0) ...[
                    const SizedBox(height: 8),
                    _buildResponsiveKeyValueRow(
                      label: 'Kebutuhan Wajib Belum Terdanai:',
                      labelStyle: const TextStyle(fontSize: 12, color: AppColors.statusPartialText),
                      value: '${sc.unfundedItemsCount} item',
                      valueStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusPartialText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Item preview summary
            if (sc.items.isNotEmpty) ...[
              Text(
                'Daftar Kebutuhan (${sc.items.length} item):',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ...sc.items.take(3).map((it) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: _buildResponsiveKeyValueRow(
                      label:
                          '› ${it.name} (${it.quantity.toStringAsFixed(it.quantity.truncateToDouble() == it.quantity ? 0 : 1)}x)',
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: it.isIncluded ? AppColors.forest : AppColors.textSecondary,
                        decoration: it.isIncluded ? null : TextDecoration.lineThrough,
                      ),
                      value: CurrencyFormatter.format(it.itemTotal),
                      valueStyle: AppTheme.moneyStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: it.isIncluded ? AppColors.forest : AppColors.textSecondary,
                      ),
                    ),
                  )),
              if (sc.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '+ ${sc.items.length - 3} item lainnya...',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(height: 14),
            ],

            // Tombol Aksi
            LayoutBuilder(
              builder: (context, constraints) {
                final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
                final stackButtons = constraints.maxWidth < 260 || highScale;
                final addBtn = AppButton.ghost(
                  label: 'Tambah Item',
                  icon: Icons.add,
                  size: AppButtonSize.compact,
                  fullWidth: stackButtons,
                  onPressed: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ScenarioItemFormScreen(
                          organization: widget.organization,
                          event: widget.event,
                          scenarioId: sc.id,
                          scenarioName: sc.name,
                        ),
                      ),
                    );
                    if (res == true) _fetchScenarios();
                  },
                );
                final submitBtn = AppButton(
                  label: 'Ajukan ke Bendahara',
                  icon: Icons.send_outlined,
                  size: AppButtonSize.compact,
                  backgroundColor: AppColors.forest,
                  fullWidth: stackButtons,
                  onPressed: sc.isDeficit
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Skenario defisit tidak dapat diajukan. Kurangi estimasi anggaran terlebih dahulu.',
                              ),
                              backgroundColor: AppColors.statusRejectedText,
                            ),
                          );
                        }
                      : () => _confirmSubmit(sc),
                );

                if (stackButtons) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      addBtn,
                      const SizedBox(height: 8),
                      submitBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: addBtn),
                    const SizedBox(width: 8),
                    Expanded(child: submitBtn),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveKeyValueRow({
    required String label,
    required String value,
    TextStyle? labelStyle,
    required TextStyle valueStyle,
  }) {
    final effectiveLabelStyle =
        labelStyle ?? const TextStyle(fontSize: 13, color: AppColors.textSecondary);
    return LayoutBuilder(
      builder: (context, constraints) {
        final highScale = MediaQuery.textScalerOf(context).scale(14) > 18;
        if (highScale || constraints.maxWidth < 250) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: effectiveLabelStyle),
              const SizedBox(height: 2),
              Text(value, style: valueStyle),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: effectiveLabelStyle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
