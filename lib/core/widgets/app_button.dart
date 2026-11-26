import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum AppButtonVariant {
  primary,
  accent,
  ghost,
}

enum AppButtonSize {
  normal,
  compact,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final AppButtonVariant? variant;
  final AppButtonSize size;
  final bool? fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.variant,
    this.size = AppButtonSize.normal,
    this.fullWidth,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  /// Varian tombol aksen dengan latar Growth Green (#35B88A) dan teks Forest (#153D35).
  const AppButton.accent({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.size = AppButtonSize.normal,
    this.fullWidth,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  }) : variant = AppButtonVariant.accent,
       isOutlined = false;

  /// Varian tombol ghost dengan latar transparan dan border Mint (#D1E8DF).
  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.size = AppButtonSize.normal,
    this.fullWidth,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  }) : variant = AppButtonVariant.ghost,
       isOutlined = true;

  AppButtonVariant get _effectiveVariant =>
      variant ?? (isOutlined ? AppButtonVariant.ghost : AppButtonVariant.primary);

  bool get _isCompact => size == AppButtonSize.compact;

  bool get _isFullWidth => fullWidth ?? !_isCompact;

  @override
  Widget build(BuildContext context) {
    final effectiveVariant = _effectiveVariant;
    final minSize = Size(_isFullWidth ? double.infinity : 0, _isCompact ? 40 : 48);
    final padding = EdgeInsets.symmetric(
      horizontal: _isCompact ? 12 : 16,
      vertical: _isCompact ? 8 : 12,
    );
    final textStyle = GoogleFonts.plusJakartaSans(
      fontSize: _isCompact ? 13 : 15,
      fontWeight: FontWeight.w600,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));

    if (effectiveVariant == AppButtonVariant.ghost) {
      final fg = foregroundColor ?? AppColors.forest;
      final isDisabled = onPressed == null && !isLoading;
      final effectiveContentColor = isDisabled ? AppColors.textSecondary : fg;
      final effectiveBorderColor = borderColor ?? backgroundColor ?? AppColors.border;
      final style = OutlinedButton.styleFrom(
        minimumSize: minSize,
        padding: padding,
        foregroundColor: fg,
        disabledForegroundColor: effectiveContentColor,
        backgroundColor: Colors.transparent,
        shape: shape,
        textStyle: textStyle,
        // Padded menjaga area sentuh >= 48dp saat tinggi visual compact adalah 40px.
        tapTargetSize: MaterialTapTargetSize.padded,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused)) {
            return effectiveBorderColor == AppColors.statusRejectedText
                ? AppColors.statusRejectedBg
                : AppColors.mint;
          }
          return null;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(
              color: effectiveBorderColor == AppColors.statusRejectedText
                  ? AppColors.statusRejectedText
                  : AppColors.forest,
              width: 2,
            );
          }
          return BorderSide(color: effectiveBorderColor, width: 1.5);
        }),
      );

      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: _buildChild(effectiveContentColor),
      );
    }

    final isAccent = effectiveVariant == AppButtonVariant.accent;
    final bg = backgroundColor ?? (isAccent ? AppColors.growth : AppColors.forest);
    final fg = foregroundColor ?? (isAccent ? AppColors.forest : AppColors.onPrimary);
    final isDisabled = onPressed == null && !isLoading;
    final effectiveContentColor = isDisabled ? AppColors.textSecondary : fg;
    final hoverBg = isAccent ? AppColors.growthHover : AppColors.forestHover;
    final focusRing = isAccent ? AppColors.forest : AppColors.growth;

    final style = ElevatedButton.styleFrom(
      minimumSize: minSize,
      padding: padding,
      backgroundColor: bg,
      foregroundColor: fg,
      // Saat loading, pertahankan latar asli agar indikator spinner tetap kontras.
      disabledBackgroundColor: isLoading ? bg : AppColors.surfaceRaised,
      disabledForegroundColor: effectiveContentColor,
      elevation: 0,
      shape: shape,
      textStyle: textStyle,
      tapTargetSize: MaterialTapTargetSize.padded,
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return hoverBg;
        }
        if (states.contains(WidgetState.focused)) {
          return focusRing.withValues(alpha: 0.22);
        }
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: focusRing, width: 2);
        }
        return BorderSide.none;
      }),
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: _buildChild(effectiveContentColor),
    );
  }

  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return Semantics(
        label: 'Memuat $label',
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _isCompact ? 16 : 18, color: textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
