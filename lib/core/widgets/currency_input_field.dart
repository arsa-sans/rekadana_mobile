import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../utils/currency_formatter.dart';

class CurrencyInputField extends StatefulWidget {
  final String label;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextEditingController? controller;

  const CurrencyInputField({
    super.key,
    required this.label,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.validator,
    this.controller,
  });

  @override
  State<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends State<CurrencyInputField> {
  late TextEditingController _controller;
  final NumberFormat _thousandFormatter = NumberFormat.decimalPattern('id_ID');

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  void _formatInput(String value) {
    final clean = CurrencyFormatter.cleanToNumeric(value);
    if (clean.isEmpty) {
      _controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      widget.onChanged?.call('');
      return;
    }

    final number = int.tryParse(clean) ?? 0;
    final formatted = _thousandFormatter.format(number);

    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    widget.onChanged?.call(clean);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: _formatInput,
          validator: widget.validator,
          style: AppTheme.moneyStyle,
          decoration: InputDecoration(
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.border, width: 1)),
                color: AppColors.surfaceRaised,
              ),
              child: Text(
                'Rp',
                style: AppTheme.moneyStyle.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            hintText: '0',
            hintStyle: AppTheme.moneyStyle.copyWith(color: AppColors.textMuted),
            helperText: widget.helperText,
            errorText: widget.errorText,
          ),
        ),
      ],
    );
  }
}
