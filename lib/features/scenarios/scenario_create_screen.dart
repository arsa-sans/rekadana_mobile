import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../organization/models/event_model.dart';
import '../organization/models/organization_model.dart';
import 'scenario_item_form_screen.dart';
import 'scenario_service.dart';

class ScenarioCreateScreen extends StatefulWidget {
  final OrganizationModel organization;
  final EventModel event;

  const ScenarioCreateScreen({
    super.key,
    required this.organization,
    required this.event,
  });

  @override
  State<ScenarioCreateScreen> createState() => _ScenarioCreateScreenState();
}

class _ScenarioCreateScreenState extends State<ScenarioCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _participantCountController = TextEditingController();

  final ScenarioService _service = ScenarioService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _participantCountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final participantCount = int.tryParse(_participantCountController.text.trim());
      final scenario = await _service.createScenario(
        eventId: widget.event.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        participantCount: participantCount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skenario berhasil dibuat. Tambahkan kebutuhan barang atau jasa.'),
          backgroundColor: AppColors.statusApprovedBg,
        ),
      );

      // Buka form tambah item untuk skenario yang baru saja dibuat
      final addedItem = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ScenarioItemFormScreen(
            organization: widget.organization,
            event: widget.event,
            scenarioId: scenario.id,
            scenarioName: scenario.name,
          ),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(addedItem ?? true);
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
        title: const Text('Buat Skenario Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Identitas Skenario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Buat skenario alternatif (misalnya: Hemat, Standar, Premium) untuk dibandingkan sebelum diajukan ke Bendahara.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nama Skenario
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Skenario *',
                            hintText: 'Contoh: Skenario Hemat',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'Nama skenario minimal 2 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Deskripsi
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi / Asumsi (Opsional)',
                            hintText: 'Catatan singkat tentang dasar perencanaan skenario ini...',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Jumlah Peserta Override
                        TextFormField(
                          controller: _participantCountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Peserta Khusus (Opsional)',
                            hintText: 'Default kegiatan: ${widget.event.participantCount} peserta',
                            helperText: 'Kosongkan jika menggunakan jumlah peserta kegiatan.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                AppButton(
                  label: 'Simpan dan Tambah Item',
                  icon: Icons.arrow_forward,
                  isLoading: _isLoading,
                  onPressed: _submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
