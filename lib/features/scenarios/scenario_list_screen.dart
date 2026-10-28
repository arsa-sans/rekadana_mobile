import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
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

  const ScenarioListScreen({
    super.key,
    required this.organization,
    required this.event,
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
    _fetchScenarios();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Skenario?'),
        content: Text(
          'Skenario "${scenario.name}" akan dibekukan menjadi versi draf anggaran dan diajukan ke Bendahara untuk diverifikasi. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Ajukan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.submitScenario(scenario.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skenario berhasil diajukan ke Bendahara.'),
          backgroundColor: AppColors.statusApprovedBg,
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
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Scenario Lab'),
        actions: [
          if (_scenarios != null && _scenarios!.length < 3)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
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
          color: AppColors.primary700,
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
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFD97706)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Skenario bukan anggaran resmi sampai disetujui Bendahara. Gunakan perbandingan di bawah untuk memilih opsi terbaik.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF92400E),
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
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pagu Dana Tersedia:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                CurrencyFormatter.format(widget.event.availableFunds),
                style: AppTheme.moneyStyle.copyWith(
                  fontSize: 14,
                  color: AppColors.primary700,
                ),
              ),
            ],
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
                          color: AppColors.textPrimary,
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
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_down, size: 14, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'Defisit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrik Skenario
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Estimasi:',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        CurrencyFormatter.format(sc.scenarioTotal),
                        style: AppTheme.moneyStyle.copyWith(
                          fontSize: 14,
                          color: sc.isDeficit ? const Color(0xFFDC2626) : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selisih Pagu:',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${sc.fundGap >= 0 ? "+" : ""}${CurrencyFormatter.format(sc.fundGap)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sc.fundGap < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biaya / Peserta (${sc.participantCount} org):',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        sc.costPerParticipant != null
                            ? CurrencyFormatter.format(sc.costPerParticipant!)
                            : '-',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (sc.unfundedItemsCount > 0) ...[
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kebutuhan Wajib Belum Terdanai:',
                          style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                        ),
                        Text(
                          '${sc.unfundedItemsCount} item',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '• ${it.name} (${it.quantity.toStringAsFixed(it.quantity.truncateToDouble() == it.quantity ? 0 : 1)}x)',
                            style: TextStyle(
                              fontSize: 12,
                              color: it.isIncluded ? AppColors.textPrimary : AppColors.textSecondary,
                              decoration: it.isIncluded ? null : TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(it.itemTotal),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: it.isIncluded ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (sc.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '+ ${sc.items.length - 3} item lainnya...',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 14),
            ],

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Tambah Item',
                    icon: Icons.add,
                    isOutlined: true,
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
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Ajukan ke Bendahara',
                    icon: Icons.send_outlined,
                    backgroundColor: AppColors.primary700,
                    onPressed: sc.isDeficit
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Skenario defisit tidak dapat diajukan. Kurangi estimasi anggaran terlebih dahulu.'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                          }
                        : () => _confirmSubmit(sc),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
