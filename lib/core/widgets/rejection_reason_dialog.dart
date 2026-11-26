import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_button.dart';
import 'app_text_field.dart';

// Dialog khusus penolakan yang mewajibkan input alasan audit
class RejectionReasonDialog extends StatefulWidget {
  final String title;
  final String message;

  const RejectionReasonDialog({
    super.key,
    required this.title,
    this.message = 'Sertakan alasan penolakan secara jelas sebagai catatan audit resmi.',
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RejectionReasonDialog(
        title: title,
        message: message ?? 'Sertakan alasan penolakan secara jelas sebagai catatan audit resmi.',
      ),
    );
  }

  @override
  State<RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<RejectionReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _reasonController,
                  label: 'Alasan Penolakan',
                  hint: 'Contoh: Pos anggaran ini belum dialokasikan untuk kegiatan lapangan.',
                  maxLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().length < 5) {
                      return 'Alasan wajib diisi minimal 5 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.ghost(
                        label: 'Batal',
                        onPressed: () => Navigator.of(context).pop(null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Tolak Resmi',
                        backgroundColor: AppColors.statusRejectedText,
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            Navigator.of(context).pop(_reasonController.text.trim());
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
  }
}
