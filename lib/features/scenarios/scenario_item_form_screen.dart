import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../organization/models/event_model.dart';
import '../organization/models/organization_model.dart';
import 'scenario_service.dart';

class ScenarioItemFormScreen extends StatefulWidget {
  final OrganizationModel organization;
  final EventModel event;
  final String scenarioId;
  final String scenarioName;

  const ScenarioItemFormScreen({
    super.key,
    required this.organization,
    required this.event,
    required this.scenarioId,
    required this.scenarioName,
  });

  @override
  State<ScenarioItemFormScreen> createState() => _ScenarioItemFormScreenState();
}

class _ScenarioItemFormScreenState extends State<ScenarioItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitCostController = TextEditingController();
  final _notesController = TextEditingController();

  String _priority = 'normal';
  bool _isIncluded = true;
  bool _isLoading = false;

  final ScenarioService _service = ScenarioService();

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(() => setState(() {}));
    _unitCostController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _itemTotalPreview {
    final q = double.tryParse(_quantityController.text.trim()) ?? 0;
    final c = double.tryParse(_unitCostController.text.trim().replaceAll('.', '')) ?? 0;
    return q * c;
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.parse(_quantityController.text.trim());
      final estimatedUnitCost = double.parse(
        _unitCostController.text.trim().replaceAll('.', ''),
      );

      await _service.addScenarioItem(
        scenarioId: widget.scenarioId,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
        priority: _priority,
        quantity: quantity,
        estimatedUnitCost: estimatedUnitCost,
        isIncluded: _isIncluded,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item kebutuhan berhasil ditambahkan.'),
          backgroundColor: AppColors.statusApprovedBg,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
        title: const Text('Tambah Item Kebutuhan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner skenario target
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science_outlined, size: 18, color: AppColors.primary700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Skenario: ${widget.scenarioName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Kebutuhan
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Kebutuhan *',
                            hintText: 'Contoh: Spanduk 3x1 m, Konsumsi Siang',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'Nama kebutuhan minimal 2 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Kategori & Prioritas
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _categoryController,
                                decoration: const InputDecoration(
                                  labelText: 'Kategori (Opsional)',
                                  hintText: 'Logistik, Konsumsi',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _priority,
                                decoration: const InputDecoration(
                                  labelText: 'Prioritas',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'required',
                                    child: Text('Wajib (Kritis)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'normal',
                                    child: Text('Normal'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'optional',
                                    child: Text('Opsional'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _priority = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Kuantitas & Harga Satuan
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Kuantitas *',
                                  hintText: '1',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  final q = double.tryParse(v.trim());
                                  if (q == null || q <= 0) {
                                    return 'Harus > 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _unitCostController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Biaya Satuan (Rp) *',
                                  prefixText: 'Rp ',
                                  hintText: '50000',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  final c = double.tryParse(v.trim().replaceAll('.', ''));
                                  if (c == null || c < 0) {
                                    return 'Tidak valid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Kalkulasi Total Real-time Preview
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Estimasi Total Item:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_itemTotalPreview),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Checkbox Sertakan dalam skenario
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Sertakan dalam total skenario',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Nonaktifkan jika ingin menyimpan item sebagai cadangan simulasi.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          value: _isIncluded,
                          activeThumbColor: AppColors.primary600,
                          onChanged: (v) => setState(() => _isIncluded = v),
                        ),
                        const SizedBox(height: 8),

                        // Catatan
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Catatan Spesifikasi (Opsional)',
                            hintText: 'Merk, ukuran, link referensi toko...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                AppButton(
                  label: 'Simpan Item Kebutuhan',
                  icon: Icons.check,
                  isLoading: _isLoading,
                  onPressed: _saveItem,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
