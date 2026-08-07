import 'package:flutter/material.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'draft' => ('Draft', AppColors.muted),
      'pending_review' => ('Pending', AppColors.warning),
      'rejected' => ('Rejected', AppColors.danger),
      'approved' => ('Approved', AppColors.success),
      _ => (status, AppColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
