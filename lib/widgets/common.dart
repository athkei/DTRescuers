import 'package:flutter/material.dart';
import '../theme.dart';

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.ink,
      behavior: SnackBarBehavior.floating,
    ));
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  static Color colorFor(String s) {
    switch (s) {
      case 'Resolved':
      case 'Closed':
        return AppColors.success;
      case 'In Progress':
      case 'Team Assigned':
        return AppColors.primary; // brandy - active states
      case 'Verified':
      case 'Awaiting Assignment':
        return AppColors.warning; // tuscanSun
      case 'Rejected':
      case 'Duplicate':
        return AppColors.muted; // blueSlate
      default:
        return const Color(0xFFB26A00); // Pending - amber
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style:
              TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
