import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';
import '../organization/models/organization_model.dart';
import 'expense_service.dart';
import 'models/expense_request_model.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseRequestModel expense;
  final OrganizationModel organization;
  final ExpenseService? service;
  final ExpenseRequestDetailModel? initialDetail;
  final List<EvidenceModel>? initialEvidence;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.organization,
    this.service,
    this.initialDetail,
    this.initialEvidence,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late final ExpenseService _service;
  ExpenseRequestDetailModel? _detail;
  late bool _isLoading;
  String? _errorMessage;

  List<EvidenceModel> _evidenceList = [];
  final Map<String, Future<Uint8List?>> _thumbnailFutures = {};
  bool _isLoadingEvidence = false;
  bool _isUploadingEvidence = false;
  double _evidenceUploadProgress = 0.0;
  final ImagePicker _picker = ImagePicker();

  bool get _canFetchThumbnails =>
      widget.service != null || widget.initialEvidence == null;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ExpenseService();
    _detail = widget.initialDetail;
    _isLoading = widget.initialDetail == null;
    if (widget.initialDetail == null) {
      _loadDetail();
    }
    _evidenceList = widget.initialEvidence ?? [];
    _isLoadingEvidence = widget.initialEvidence == null && widget.initialDetail == null;
    if (widget.initialEvidence == null && widget.initialDetail == null) {
      _loadEvidence();
    } else if (_canFetchThumbnails) {
      _primeThumbnailFutures(_evidenceList);
    }
  }

  void _primeThumbnailFutures(List<EvidenceModel> items) {
    for (final item in items) {
      final isImage = item.detectedFileType == 'jpeg' || item.detectedFileType == 'png';
      if (isImage) {
        _thumbnailFutures.putIfAbsent(item.id, () => _fetchThumbnailBytes(item.id));
      }
    }
  }

  Future<Uint8List?> _fetchThumbnailBytes(String evidenceId) async {
    try {
      final bytes = await _service.downloadEvidenceBytes(evidenceId);
      if (bytes.isEmpty) return null;
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _service.getExpenseDetail(widget.expense.id);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat rincian pembayaran terbaru.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEvidence() async {
    setState(() => _isLoadingEvidence = true);
    try {
      final list = await _service.listEvidence(widget.expense.id);
      if (mounted) {
        setState(() {
          _evidenceList = list;
          _isLoadingEvidence = false;
          if (_canFetchThumbnails) {
            _primeThumbnailFutures(list);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingEvidence = false);
    }
  }

  Future<void> _handleUploadEvidenceFromDetail() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final fileLength = await picked.length();
    if (fileLength > kMaxEvidenceBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran file foto melebihi batas 5 MiB. Pilih foto yang lebih kecil.'),
            backgroundColor: AppColors.statusRejectedText,
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploadingEvidence = true;
      _evidenceUploadProgress = 0.0;
    });

    try {
      await _service.uploadEvidence(
        organizationId: widget.organization.id,
        expenseRequestId: widget.expense.id,
        filePath: picked.path,
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() => _evidenceUploadProgress = sent / total);
          }
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti transaksi berhasil diunggah.'),
          backgroundColor: AppColors.statusApprovedText,
        ),
      );
      _loadEvidence();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.statusRejectedText,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingEvidence = false);
    }
  }

  Future<void> _openEvidenceDownload(EvidenceModel item) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return FutureBuilder<List<int>>(
          future: _service.downloadEvidenceBytes(item.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Mengambil bukti transaksi...'),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: AppColors.surface,
                title: const Text(
                  'Gagal Membuka Bukti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.forest),
                ),
                content: Text(
                  'Terjadi kendala saat mengunduh berkas: ${snapshot.error}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              );
            }

            final bytes = snapshot.data;
            if (bytes == null || bytes.isEmpty) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: AppColors.surface,
                title: const Text(
                  'Berkas Kosong',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.forest),
                ),
                content: const Text(
                  'File bukti tidak berisi data.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              );
            }

            final isImage = item.detectedFileType == 'jpeg' || item.detectedFileType == 'png';

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.originalFileName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.forest,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            tooltip: 'Tutup pratinjau',
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      if (isImage)
                        Flexible(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: InteractiveViewer(
                              child: Image.memory(
                                Uint8List.fromList(bytes),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Column(
                            children: [
                              const Icon(Icons.picture_as_pdf, size: 64, color: AppColors.statusRejectedText),
                              const SizedBox(height: 16),
                              Text(
                                item.originalFileName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ukuran: ${item.formattedSize} • Format: PDF',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Dokumen PDF tersimpan aman di private storage dan diverifikasi.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Selesai'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  ExpenseRequestModel get _currentExpense =>
      _detail?.request ?? widget.expense;

  double get _approvedAmount {
    if (_detail != null) return _detail!.summary.approvedAmount;
    return double.tryParse(_currentExpense.approvedAmount ?? '0') ?? 0;
  }

  double get _totalPaidNet {
    if (_detail != null) return _detail!.summary.totalPaidNet;
    return 0;
  }

  double get _remainingBalance {
    if (_detail != null) return _detail!.summary.remainingBalance;
    return _approvedAmount;
  }

  // Dialog setujui pengeluaran
  Future<void> _showApproveDialog() async {
    final requestedVal = double.tryParse(_currentExpense.requestedAmount) ?? 0;
    final controller = TextEditingController(text: _currentExpense.requestedAmount);
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: AppColors.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Setujui Pengeluaran',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nominal diajukan: ${CurrencyFormatter.format(requestedVal)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: controller,
                      label: 'Nominal Disetujui (Rp)',
                      hint: 'Masukkan nominal',
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
                            label: 'Konfirmasi Setujui',
                            backgroundColor: AppColors.statusApprovedText,
                            isLoading: isSubmitting,
                            onPressed: () async {
                              final entered = double.tryParse(controller.text.trim()) ?? 0;
                              if (entered <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nominal harus lebih dari 0.'),
                                    backgroundColor: AppColors.statusRejectedText,
                                  ),
                                );
                                return;
                              }
                              if (entered > requestedVal) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nominal disetujui tidak boleh melebihi pengajuan.'),
                                    backgroundColor: AppColors.statusRejectedText,
                                  ),
                                );
                                return;
                              }

                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(ctx);
                              setDialogState(() => isSubmitting = true);
                              try {
                                await _service.approveExpense(
                                  _currentExpense.id,
                                  approvedAmount: entered.toString(),
                                );
                                if (ctx.mounted) navigator.pop();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Pengeluaran berhasil disetujui.'),
                                    backgroundColor: AppColors.statusApprovedText,
                                  ),
                                );
                                _loadDetail();
                              } catch (err) {
                                setDialogState(() => isSubmitting = false);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyetujui: $err'),
                                    backgroundColor: AppColors.statusRejectedText,
                                  ),
                                );
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
          );
        },
      ),
    );
    controller.dispose();
  }

  // Dialog tolak pengeluaran
  Future<void> _showRejectDialog() async {
    final controller = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: AppColors.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tolak Pengeluaran',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Berikan alasan penolakan yang spesifik dan jelas (minimal 5 karakter):',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: controller,
                      label: 'Alasan Penolakan',
                      hint: 'Alasan penolakan pengajuan...',
                      maxLines: 3,
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
                            label: 'Konfirmasi Tolak',
                            backgroundColor: AppColors.statusRejectedText,
                            isLoading: isSubmitting,
                            onPressed: () async {
                              final reason = controller.text.trim();
                              if (reason.length < 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Alasan penolakan wajib minimal 5 karakter.'),
                                    backgroundColor: AppColors.statusRejectedText,
                                  ),
                                );
                                return;
                              }

                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(ctx);
                              setDialogState(() => isSubmitting = true);
                              try {
                                await _service.rejectExpense(_currentExpense.id, reason: reason);
                                if (ctx.mounted) navigator.pop();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Pengeluaran berhasil ditolak.'),
                                    backgroundColor: AppColors.statusRejectedText,
                                  ),
                                );
                                _loadDetail();
                              } catch (err) {
                                setDialogState(() => isSubmitting = false);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menolak: $err'),
                                    backgroundColor: AppColors.statusRejectedText,
                                  ),
                                );
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
          );
        },
      ),
    );
    controller.dispose();
  }

  // Dialog catat pembayaran
  String _buildDefaultIdempotencyKey() {
    final prefix = (_currentExpense.id.length >= 8
            ? _currentExpense.id.substring(0, 8)
            : _currentExpense.id)
        .toUpperCase();
    return 'PAY-$prefix-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _showRecordPaymentDialog() async {
    final remaining = _remainingBalance;
    final amountController = TextEditingController(text: remaining.toStringAsFixed(0));
    final defaultKey = _buildDefaultIdempotencyKey();
    final keyController = TextEditingController(text: defaultKey);
    final notesController = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final entered = double.tryParse(amountController.text.trim()) ?? 0;
          final isOver = entered > remaining;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: AppColors.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catat Pembayaran',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sisa Belum Dibayar:',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            CurrencyFormatter.format(remaining),
                            style: AppTheme.moneyStyle.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppButton.ghost(
                          label: 'Bayar Lunas',
                          size: AppButtonSize.compact,
                          onPressed: () {
                            setDialogState(() {
                              amountController.text = remaining.toStringAsFixed(0);
                            });
                          },
                        ),
                        if (remaining > 10000)
                          AppButton.ghost(
                            label: '50% Sisa',
                            size: AppButtonSize.compact,
                            onPressed: () {
                              setDialogState(() {
                                amountController.text = (remaining / 2).floor().toString();
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: amountController,
                      label: 'Nominal Dibayar (Rp)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      errorText: isOver ? 'Melebihi sisa belum dibayar.' : null,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: keyController,
                      label: 'Kunci Idempotensi',
                      helperText: 'Mencegah duplikasi pembayaran transaksi',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: AppColors.forest),
                        tooltip: 'Buat Kunci Baru',
                        onPressed: () {
                          setDialogState(() {
                            keyController.text = _buildDefaultIdempotencyKey();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: notesController,
                      label: 'Catatan (opsional)',
                      hint: 'Referensi transfer / bank',
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
                            label: 'Simpan Pembayaran',
                            isLoading: isSubmitting,
                            onPressed: isSubmitting || isOver || entered <= 0
                                ? null
                                : () async {
                                    final key = keyController.text.trim();
                                    if (key.length < 8) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Kunci idempotensi minimal 8 karakter.'),
                                          backgroundColor: AppColors.statusRejectedText,
                                        ),
                                      );
                                      return;
                                    }

                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);
                                    setDialogState(() => isSubmitting = true);
                                    try {
                                      final result = await _service.recordPayment(
                                        _currentExpense.id,
                                        idempotencyKey: key,
                                        amount: entered.toString(),
                                        notes: notesController.text.trim(),
                                      );

                                      final isDup = result['isDuplicateReplay'] == true;
                                      if (ctx.mounted) navigator.pop();
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isDup
                                                ? 'Pembayaran sudah tercatat sebelumnya (replay idempotensi).'
                                                : 'Pembayaran berhasil dibukukan.',
                                          ),
                                          backgroundColor: AppColors.statusApprovedText,
                                        ),
                                      );
                                      _loadDetail();
                                    } catch (err) {
                                      setDialogState(() => isSubmitting = false);
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal mencatat pembayaran: $err'),
                                          backgroundColor: AppColors.statusRejectedText,
                                        ),
                                      );
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
          );
        },
      ),
    );
    amountController.dispose();
    keyController.dispose();
    notesController.dispose();
  }

  // Dialog pembatalan pembayaran (reversal)
  Future<void> _showReverseDialog(PaymentModel payment) async {
    final maxReversible = payment.remainingReversibleAmount;
    final amountController = TextEditingController(text: maxReversible.toStringAsFixed(0));
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final entered = double.tryParse(amountController.text.trim()) ?? 0;
          final isExceeding = entered > maxReversible;
          final isReasonValid = reasonController.text.trim().length >= 5;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: AppColors.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Batalkan Pembayaran',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.statusRejectedBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.statusRejectedBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nominal Asli: ${CurrencyFormatter.format(payment.originalAmount)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.statusRejectedText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Maksimal Batal: ${CurrencyFormatter.format(maxReversible)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusRejectedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: amountController,
                      label: 'Nominal yang Dibatalkan (Rp)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      errorText: isExceeding ? 'Melebihi batas maksimal.' : null,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: reasonController,
                      label: 'Alasan Pembatalan',
                      hint: 'Jelaskan alasan pembatalan transaksi...',
                      helperText: '${reasonController.text.trim().length}/5 karakter minimum',
                      maxLines: 2,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.ghost(
                            label: 'Kembali',
                            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Konfirmasi Pembatalan',
                            backgroundColor: AppColors.statusRejectedText,
                            isLoading: isSubmitting,
                            onPressed: isSubmitting || isExceeding || entered <= 0 || !isReasonValid
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);
                                    setDialogState(() => isSubmitting = true);
                                    try {
                                      await _service.reversePayment(
                                        payment.id,
                                        amount: entered.toString(),
                                        reason: reasonController.text.trim(),
                                      );
                                      if (ctx.mounted) navigator.pop();
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Pembatalan pembayaran berhasil dicatat.'),
                                          backgroundColor: AppColors.statusApprovedText,
                                        ),
                                      );
                                      _loadDetail();
                                    } catch (err) {
                                      setDialogState(() => isSubmitting = false);
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal membatalkan: $err'),
                                          backgroundColor: AppColors.statusRejectedText,
                                        ),
                                      );
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
          );
        },
      ),
    );
    amountController.dispose();
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expense = _currentExpense;
    final isBendahara = widget.organization.isBendahara;
    final canApproveOrReject = isBendahara && expense.isPending;
    final canPay = isBendahara &&
        (expense.isApproved || expense.isPartiallyPaid) &&
        _remainingBalance > 0;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text('Detail Pengeluaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui Data',
            onPressed: _loadDetail,
          ),
        ],
      ),
      bottomNavigationBar: (canApproveOrReject || canPay)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (canApproveOrReject) ...[
                      Expanded(
                        child: AppButton(
                          label: 'Setujui',
                          backgroundColor: AppColors.statusApprovedText,
                          onPressed: _showApproveDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton.ghost(
                          label: 'Tolak',
                          foregroundColor: AppColors.statusRejectedText,
                          borderColor: AppColors.statusRejectedText,
                          onPressed: _showRejectDialog,
                        ),
                      ),
                    ],
                    if (canPay) ...[
                      Expanded(
                        child: AppButton(
                          label: 'Catat Pembayaran (${CurrencyFormatter.format(_remainingBalance)})',
                          icon: Icons.payment,
                          onPressed: _showRecordPaymentDialog,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDetail,
          color: AppColors.forest,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusRejectedBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.statusRejectedBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.statusRejectedText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: AppColors.statusRejectedText),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Kartu Status Utama
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(status: expense.status),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              DateFormatter.formatDateTime(expense.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (expense.description != null && expense.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          expense.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Kartu Ringkasan Finansial
                _buildFinancialSummaryCard(expense),

                // Alasan Penolakan (Jika ditolak)
                if (expense.rejectionReason != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.statusRejectedBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.statusRejectedBorder, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: AppColors.statusRejectedText,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Alasan Penolakan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.statusRejectedText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          expense.rejectionReason!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.statusRejectedText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Riwayat Pembayaran
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Riwayat Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    if (_detail != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${_detail!.payments.length} transaksi',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                if (_isLoading && _detail == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.forest),
                          SizedBox(height: 12),
                          Text(
                            'Memuat riwayat pembayaran...',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_detail == null || _detail!.payments.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Belum ada riwayat pembayaran yang dicatat.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _detail!.payments.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) =>
                          _buildPaymentItem(_detail!.payments[idx], isBendahara),
                    ),
                  ),

                // Bagian Bukti Transaksi
                const SizedBox(height: 24),
                _buildEvidenceSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(ExpenseRequestModel expense) {
    final paidRatio = _approvedAmount > 0
        ? (_totalPaidNet / _approvedAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Finansial',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 12),
          _buildRow(
            'Nominal Diajukan',
            CurrencyFormatter.format(expense.requestedAmount),
          ),
          const Divider(height: 16),
          if (_detail == null)
            _buildRow(
              'Nominal Disetujui',
              CurrencyFormatter.format(_approvedAmount),
              isEmphasized: true,
              customColor: AppColors.forest,
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 260) {
                  return Column(
                    children: [
                      _buildRow(
                        'Nominal Disetujui',
                        CurrencyFormatter.format(_approvedAmount),
                        customColor: AppColors.forest,
                      ),
                      const SizedBox(height: 8),
                      _buildRow(
                        'Total Dibayar (Net)',
                        CurrencyFormatter.format(_totalPaidNet),
                        customColor: AppColors.statusPaidText,
                      ),
                      const SizedBox(height: 8),
                      _buildRow(
                        'Sisa Belum Dibayar',
                        CurrencyFormatter.format(_remainingBalance),
                        customColor: _remainingBalance > 0
                            ? AppColors.statusPartialText
                            : AppColors.statusApprovedText,
                      ),
                    ],
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildHorizontalMetric(
                          'Nominal Disetujui',
                          CurrencyFormatter.format(_approvedAmount),
                          AppColors.forest,
                        ),
                      ),
                      const VerticalDivider(width: 16, thickness: 1),
                      Expanded(
                        child: _buildHorizontalMetric(
                          'Total Dibayar (Net)',
                          CurrencyFormatter.format(_totalPaidNet),
                          AppColors.statusPaidText,
                        ),
                      ),
                      const VerticalDivider(width: 16, thickness: 1),
                      Expanded(
                        child: _buildHorizontalMetric(
                          'Sisa Belum Dibayar',
                          CurrencyFormatter.format(_remainingBalance),
                          _remainingBalance > 0
                              ? AppColors.statusPartialText
                              : AppColors.statusApprovedText,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_approvedAmount > 0) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Progres Pembayaran',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(paidRatio * 100).round()}% terbayar',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: paidRatio,
                  minHeight: 2,
                  backgroundColor: AppColors.mint,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.growth),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.25),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTheme.moneyStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Bukti Transaksi / Nota',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_isLoadingEvidence)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forest),
              )
            else
              Text(
                '${_evidenceList.length} file',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Daftar bukti
        if (!_isLoadingEvidence && _evidenceList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 24,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada bukti transaksi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lampirkan foto nota, struk pembelian, atau dokumen PDF untuk verifikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ...(_evidenceList.map((item) => _buildEvidenceCard(item))),

        const SizedBox(height: 12),

        // Tombol unggah bukti baru
        if (_isUploadingEvidence) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _evidenceUploadProgress > 0 ? _evidenceUploadProgress : null,
              minHeight: 3,
              backgroundColor: AppColors.mint,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.growth),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _evidenceUploadProgress > 0
                ? 'Mengunggah: ${(_evidenceUploadProgress * 100).toInt()}%'
                : 'Mempersiapkan unggahan...',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
        ] else
          AppButton.ghost(
            label: 'Lampirkan Bukti Baru',
            icon: Icons.add_a_photo_outlined,
            size: AppButtonSize.compact,
            fullWidth: true,
            borderColor: AppColors.border,
            onPressed: _handleUploadEvidenceFromDetail,
          ),
      ],
    );
  }

  Widget _buildEvidenceCard(EvidenceModel item) {
    final isPdf = item.detectedFileType == 'pdf';
    final thumbFuture = (!isPdf && _canFetchThumbnails)
        ? _thumbnailFutures.putIfAbsent(item.id, () => _fetchThumbnailBytes(item.id))
        : null;

    Widget leadingPreview;
    if (isPdf) {
      leadingPreview = Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.statusRejectedBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.statusRejectedBorder),
        ),
        child: const Icon(
          Icons.picture_as_pdf_outlined,
          size: 22,
          color: AppColors.statusRejectedText,
        ),
      );
    } else if (thumbFuture != null) {
      leadingPreview = FutureBuilder<Uint8List?>(
        future: thumbFuture,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes != null && bytes.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                bytes,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            );
          }
          return _buildImagePlaceholderIcon();
        },
      );
    } else {
      leadingPreview = _buildImagePlaceholderIcon();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          leadingPreview,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.originalFileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.forest,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.formattedSize,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openEvidenceDownload(item),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.forest,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholderIcon() {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 22,
        color: AppColors.forest,
      ),
    );
  }

  Widget _buildPaymentItem(PaymentModel payment, bool isBendahara) {
    final canReverse = isBendahara && payment.remainingReversibleAmount > 0;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(payment.originalAmount),
                style: AppTheme.moneyStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  DateFormatter.formatDateTime(payment.postedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kunci: ${payment.idempotencyKey}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Catatan: ${payment.notes}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],

          if (payment.reversals.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.statusRejectedBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.statusRejectedBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dibatalkan: ${CurrencyFormatter.format(payment.totalReversedAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.statusRejectedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...payment.reversals.map(
                    (rev) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Alasan: ${rev.reason} (${CurrencyFormatter.format(rev.amountValue)})',
                        style: const TextStyle(fontSize: 11, color: AppColors.statusRejectedText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (canReverse) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.statusRejectedText,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _showReverseDialog(payment),
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Batalkan Pembayaran'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isEmphasized = false,
    Color? customColor,
  }) {
    Color textColor = AppColors.textPrimary;
    if (customColor != null) {
      textColor = customColor;
    } else if (isEmphasized) {
      textColor = AppColors.statusApprovedText;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: isEmphasized
              ? AppTheme.moneyLargeStyle.copyWith(color: textColor)
              : AppTheme.moneyStyle.copyWith(color: textColor),
        ),
      ],
    );
  }
}
