import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.textColor),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getStatusConfig(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'approved':
        return _BadgeConfig(
          label: 'Disetujui',
          icon: Icons.check_circle_outline,
          textColor: AppColors.statusApprovedText,
          backgroundColor: AppColors.statusApprovedBg,
          borderColor: AppColors.statusApprovedBorder,
        );
      case 'submitted':
      case 'pending':
        return _BadgeConfig(
          label: 'Diajukan',
          icon: Icons.access_time,
          textColor: AppColors.statusSubmittedText,
          backgroundColor: AppColors.statusSubmittedBg,
          borderColor: AppColors.statusSubmittedBorder,
        );
      case 'rejected':
        return _BadgeConfig(
          label: 'Ditolak',
          icon: Icons.cancel_outlined,
          textColor: AppColors.statusRejectedText,
          backgroundColor: AppColors.statusRejectedBg,
          borderColor: AppColors.statusRejectedBorder,
        );
      case 'paid':
        return _BadgeConfig(
          label: 'Lunas',
          icon: Icons.task_alt,
          textColor: AppColors.statusPaidText,
          backgroundColor: AppColors.statusPaidBg,
          borderColor: AppColors.statusPaidBorder,
        );
      case 'partially_paid':
        return _BadgeConfig(
          label: 'Dibayar Sebagian',
          icon: Icons.hourglass_bottom,
          textColor: AppColors.statusPartialText,
          backgroundColor: AppColors.statusPartialBg,
          borderColor: AppColors.statusPartialBorder,
        );
      case 'draft':
      default:
        return _BadgeConfig(
          label: 'Draf',
          icon: Icons.edit_note,
          textColor: AppColors.statusDraftText,
          backgroundColor: AppColors.statusDraftBg,
          borderColor: AppColors.statusDraftBorder,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  _BadgeConfig({
    required this.label,
    required this.icon,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
