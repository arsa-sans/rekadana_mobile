import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/currency_input_field.dart';
import '../organization/models/event_model.dart';
import '../organization/models/organization_model.dart';
import 'expense_service.dart';
import 'models/budget_item_model.dart';

class ExpenseCreateScreen extends StatefulWidget {
  final OrganizationModel organization;
  final EventModel event;

  const ExpenseCreateScreen({
    super.key,
    required this.organization,
    required this.event,
  });

  @override
  State<ExpenseCreateScreen> createState() => _ExpenseCreateScreenState();
}

class _ExpenseCreateScreenState extends State<ExpenseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expenseService = ExpenseService();
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _requestedAmountNumeric = '';

  List<BudgetItemModel> _budgetItems = [];
  String? _selectedBudgetItemId;
  bool _isLoadingItems = true;

  XFile? _selectedImage;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBudgetItems();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadBudgetItems() async {
    try {
      final items = await _expenseService.getActiveBudgetItems(widget.event.id);
      if (mounted) {
        setState(() {
          _budgetItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedImage = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat mengakses kamera atau galeri: $e'),
            backgroundColor: AppColors.statusRejectedText,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Lampirkan Bukti Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary700),
                title: const Text('Ambil Foto Kamera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary700),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requestedAmountNumeric.isEmpty ||
        (double.tryParse(_requestedAmountNumeric) ?? 0) <= 0) {
      setState(() {
        _errorMessage = 'Nominal pengeluaran harus lebih besar dari Rp0.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });

    try {
      // 1. Buat permohonan pengeluaran ke server
      final createdRequest = await _expenseService.createExpenseRequest(
        widget.event.id,
        title: _titleController.text.trim(),
        requestedAmount: _requestedAmountNumeric,
        budgetItemId: _selectedBudgetItemId,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );

      // 2. Unggah file bukti jika dipilih
      if (_selectedImage != null) {
        await _expenseService.uploadEvidence(
          organizationId: widget.organization.id,
          expenseRequestId: createdRequest.id,
          filePath: _selectedImage!.path,
          onProgress: (sent, total) {
            if (total > 0 && mounted) {
              setState(() {
                _uploadProgress = sent / total;
              });
            }
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan pengeluaran berhasil diajukan ke Bendahara.'),
          backgroundColor: AppColors.statusApprovedText,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Pengajuan Kebutuhan Lapangan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Konteks Kegiatan
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note, color: AppColors.primary700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.event.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusRejectedBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.statusRejectedBorder, width: 1),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.statusRejectedText,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Pilihan Pos Anggaran Resmi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pos Anggaran (Opsional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_isLoadingItems)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Memuat rincian pos anggaran...',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          )
                        else if (_budgetItems.isEmpty)
                          const Text(
                            'Belum ada pos anggaran disetujui untuk kegiatan ini.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBudgetItemId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              hintText: 'Pilih pos alokasi anggaran',
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Tidak merujuk pos tertentu (Non-pos)'),
                              ),
                              ..._budgetItems.map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.id,
                                  child: Text(
                                    '${item.name} (${CurrencyFormatter.format(item.totalEstimatedCost)})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedBudgetItemId = val;
                              });
                            },
                          ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _titleController,
                          label: 'Keperluan Pengeluaran',
                          hint: 'Contoh: Pembelian konsumsi panitia gladi resik',
                          validator: (val) {
                            if (val == null || val.trim().length < 3) {
                              return 'Keperluan pengeluaran minimal 3 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        CurrencyInputField(
                          label: 'Nominal Diajukan (Rupiah)',
                          helperText: 'Masukkan angka nominal sesuai kwitansi atau estimasi.',
                          onChanged: (val) {
                            _requestedAmountNumeric = val;
                          },
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _descController,
                          label: 'Catatan Tambahan (Opsional)',
                          hint: 'Keterangan vendor, rincian barang, atau urgensi lapangan',
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bagian Lampiran Foto Bukti
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lampiran Foto Bukti / Kwitansi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Dapat berupa nota pembelian, kwitansi toko, atau foto barang di lapangan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (_selectedImage == null)
                          OutlinedButton.icon(
                            onPressed: _showImagePickerOptions,
                            icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                            label: const Text('Ambil atau Pilih Foto Bukti'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              side: const BorderSide(color: AppColors.primary500, width: 1),
                              foregroundColor: AppColors.primary700,
                            ),
                          )
                        else ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImage!.path),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _showImagePickerOptions,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Ganti Foto'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isSubmitting && _selectedImage != null && _uploadProgress > 0) ...[
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AppColors.primary50,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mengunggah berkas bukti: ${(_uploadProgress * 100).toInt()}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                  ],

                  AppButton(
                    label: 'Kirim Pengajuan Pengeluaran',
                    isLoading: _isSubmitting,
                    onPressed: _handleSubmit,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
