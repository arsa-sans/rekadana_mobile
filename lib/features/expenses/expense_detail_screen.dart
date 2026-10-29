import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/status_badge.dart';
import '../organization/models/organization_model.dart';
import 'expense_service.dart';
import 'models/expense_request_model.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseRequestModel expense;
  final OrganizationModel organization;
  final ExpenseService? service;
  final ExpenseRequestDetailModel? initialDetail;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.organization,
    this.service,
    this.initialDetail,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late final ExpenseService _service;
  ExpenseRequestDetailModel? _detail;
  late bool _isLoading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ExpenseService();
    _detail = widget.initialDetail;
    _isLoading = widget.initialDetail == null;
    if (widget.initialDetail == null) {
      _loadDetail();
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

  // --- Dialog Setujui Pengeluaran ---
  void _showApproveDialog() {
    final requestedVal = double.tryParse(_currentExpense.requestedAmount) ?? 0;
    final controller = TextEditingController(text: _currentExpense.requestedAmount);
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Setujui Pengeluaran'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nominal diajukan: ${CurrencyFormatter.format(requestedVal)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Disetujui (Rp)',
                    hintText: 'Masukkan nominal',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final entered = double.tryParse(controller.text.trim()) ?? 0;
                        if (entered <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nominal harus lebih dari 0.')),
                          );
                          return;
                        }
                        if (entered > requestedVal) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nominal disetujui tidak boleh melebihi pengajuan.'),
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
                            const SnackBar(content: Text('Pengeluaran berhasil disetujui.')),
                          );
                          _loadDetail();
                        } catch (err) {
                          setDialogState(() => isSubmitting = false);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Gagal menyetujui: $err')),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Konfirmasi Setujui'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Dialog Tolak Pengeluaran ---
  void _showRejectDialog() {
    final controller = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tolak Pengeluaran'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Berikan alasan penolakan yang spesifik dan jelas (minimal 5 karakter):',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Alasan penolakan pengajuan...',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusRejectedText,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final reason = controller.text.trim();
                        if (reason.length < 5) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alasan penolakan wajib minimal 5 karakter.'),
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
                            const SnackBar(content: Text('Pengeluaran berhasil ditolak.')),
                          );
                          _loadDetail();
                        } catch (err) {
                          setDialogState(() => isSubmitting = false);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Gagal menolak: $err')),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Konfirmasi Tolak'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Dialog Catat Pembayaran ---
  void _showRecordPaymentDialog() {
    final remaining = _remainingBalance;
    final amountController = TextEditingController(text: remaining.toStringAsFixed(0));
    final defaultKey =
        'PAY-${_currentExpense.id.substring(0, 8).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
    final keyController = TextEditingController(text: defaultKey);
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final entered = double.tryParse(amountController.text.trim()) ?? 0;
          final isOver = entered > remaining;

          return AlertDialog(
            title: const Text('Catat Pembayaran'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sisa Belum Dibayar:', style: TextStyle(fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(remaining),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            amountController.text = remaining.toStringAsFixed(0);
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Bayar Lunas'),
                      ),
                      const SizedBox(width: 8),
                      if (remaining > 10000)
                        OutlinedButton(
                          onPressed: () {
                            setDialogState(() {
                              amountController.text =
                                  (remaining / 2).floor().toString();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('50% Sisa'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Nominal Dibayar (Rp)',
                      errorText: isOver ? 'Melebihi sisa belum dibayar!' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyController,
                    decoration: InputDecoration(
                      labelText: 'Kunci Idempotensi',
                      helperText: 'Mencegah duplikasi pembayaran transaksi',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Buat Kunci Baru',
                        onPressed: () {
                          setDialogState(() {
                            keyController.text =
                                'PAY-${_currentExpense.id.substring(0, 8).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      hintText: 'Referensi transfer / bank',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSubmitting || isOver || entered <= 0
                    ? null
                    : () async {
                        final key = keyController.text.trim();
                        if (key.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kunci idempotensi minimal 8 karakter.'),
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
                            ),
                          );
                          _loadDetail();
                        } catch (err) {
                          setDialogState(() => isSubmitting = false);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Gagal mencatat pembayaran: $err')),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan Pembayaran'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Dialog Pembatalan Pembayaran (Reversal) ---
  void _showReverseDialog(PaymentModel payment) {
    final maxReversible = payment.remainingReversibleAmount;
    final amountController =
        TextEditingController(text: maxReversible.toStringAsFixed(0));
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final entered = double.tryParse(amountController.text.trim()) ?? 0;
          final isExceeding = entered > maxReversible;
          final isReasonValid = reasonController.text.trim().length >= 5;

          return AlertDialog(
            title: const Text('Batalkan Pembayaran'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusRejectedBg,
                      borderRadius: BorderRadius.circular(8),
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
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusRejectedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Nominal yang Dibatalkan (Rp)',
                      errorText: isExceeding ? 'Melebihi batas maksimal!' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Alasan Pembatalan',
                      hintText: 'Jelaskan alasan pembatalan transaksi...',
                      helperText: '${reasonController.text.trim().length}/5 karakter minimum',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Kembali'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusRejectedText,
                ),
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
                            ),
                          );
                          _loadDetail();
                        } catch (err) {
                          setDialogState(() => isSubmitting = false);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Gagal membatalkan: $err')),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Konfirmasi Pembatalan'),
              ),
            ],
          );
        },
      ),
    );
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
      backgroundColor: AppColors.surfaceMuted,
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
                        child: ElevatedButton(
                          onPressed: _showApproveDialog,
                          child: const Text('Setujui'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusRejectedText,
                            side: const BorderSide(color: AppColors.statusRejectedBorder),
                          ),
                          onPressed: _showRejectDialog,
                          child: const Text('Tolak'),
                        ),
                      ),
                    ],
                    if (canPay) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showRecordPaymentDialog,
                          icon: const Icon(Icons.payment, size: 18),
                          label: Text(
                            'Catat Pembayaran (${CurrencyFormatter.format(_remainingBalance)})',
                          ),
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
                      borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(status: expense.status),
                          Text(
                            DateFormatter.formatDateTime(expense.createdAt),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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

                // Kartu Ringkasan Finansial 4 Metrik
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
                        'Ringkasan Finansial',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        'Nominal Diajukan',
                        CurrencyFormatter.format(expense.requestedAmount),
                      ),
                      const Divider(height: 16),
                      _buildRow(
                        'Nominal Disetujui',
                        CurrencyFormatter.format(_approvedAmount),
                        isEmphasized: true,
                      ),
                      if (_detail != null) ...[
                        const Divider(height: 16),
                        _buildRow(
                          'Total Dibayar (Net)',
                          CurrencyFormatter.format(_totalPaidNet),
                          customColor: AppColors.primary,
                        ),
                        const Divider(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _buildRow(
                            'Sisa Belum Dibayar',
                            CurrencyFormatter.format(_remainingBalance),
                            isEmphasized: true,
                            customColor: _remainingBalance > 0
                                ? AppColors.primary
                                : AppColors.statusApprovedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Alasan Penolakan (Jika ditolak)
                if (expense.rejectionReason != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.statusRejectedBg,
                      borderRadius: BorderRadius.circular(12),
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
                    const Text(
                      'Riwayat Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_detail != null)
                      Text(
                        '${_detail!.payments.length} transaksi',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_isLoading && _detail == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_detail == null || _detail!.payments.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
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
                  ..._detail!.payments.map((p) => _buildPaymentCard(p, isBendahara)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment, bool isBendahara) {
    final canReverse = isBendahara && payment.remainingReversibleAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(payment.originalAmount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                DateFormatter.formatDateTime(payment.postedAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kunci: ${payment.idempotencyKey}',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
          ),
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Catatan: ${payment.notes}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],

          // Reversals list
          if (payment.reversals.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.statusRejectedBg,
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.statusRejectedText,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _showReverseDialog(payment),
                icon: const Icon(Icons.undo, size: 14),
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
