import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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
        return AppColors.primary; // Brandy
      case 'Verified':
      case 'Awaiting Assignment':
        return AppColors.warning; // Tuscan Sun
      case 'Rejected':
      case 'Duplicate':
        return AppColors.muted; // Blue Slate
      default:
        return const Color(0xFFB26A00); // Pending (Amber)
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

class WarningNote extends StatelessWidget {
  final String text;
  const WarningNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.ink, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

String? requiredField(String? v, [String label = 'This field']) =>
    (v == null || v.trim().isEmpty) ? '$label is required' : null;

String? phoneValidator(String? v) {
  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Phone number is required';
  if (digits.length < 10 || digits.length > 13)
    return 'Enter a valid phone number';
  return null;
}

String? usernameValidator(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Username is required';
  if (!RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(t)) {
    return '3-20 letters, numbers or underscores';
  }
  return null;
}

Future<void> confirmLogout(BuildContext context) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content:
          const Text('You will need to log in again to access the dashboard.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out')),
      ],
    ),
  );
  if (yes == true) await AuthService.instance.signOut();
}
