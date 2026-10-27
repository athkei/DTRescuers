import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/incident_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'incident_detail_screen.dart';
import 'team_status_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.instance.currentUserProfile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dispatch Dashboard',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
                profile.teamId != null
                    ? 'Team: ${profile.teamId}'
                    : 'Role: ${profile.role}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: AppColors.muted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Team Status & Location',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamStatusScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await AuthService.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: IncidentService.instance.watchIncidents(),
        builder: (context, snap) {
          if (snap.hasError) {
            print('🔥 DASHBOARD STREAM ERROR: ${snap.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('Failed to load incidents.',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Details: ${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () {}, child: const Text('Retry'))
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allIncidents = snap.data!;
          final incidents = allIncidents.where((inc) {
            if (profile.role == 'Rescue Team') {
              return inc.team == profile.teamId ||
                  inc.status == 'Pending' ||
                  inc.status == 'Verified' ||
                  inc.status == 'Awaiting Assignment';
            }
            return true;
          }).toList();

          if (incidents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No active incidents in your queue.',
                    style: TextStyle(color: AppColors.muted, fontSize: 16)),
              ),
            );
          }

          final fmt = DateFormat('MMM d, h:mm a');

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final inc = incidents[i];
              final isAssignedToMe =
                  profile.role == 'Rescue Team' && inc.team == profile.teamId;

              return Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isAssignedToMe
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
                    width: isAssignedToMe ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => IncidentDetailScreen(
                              incident: inc, profile: profile)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(inc.id,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted)),
                            const Spacer(),
                            StatusChip(inc.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(inc.type,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Text(inc.location,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.priority_high,
                                size: 16,
                                color: inc.priority == 'Critical'
                                    ? Colors.red
                                    : AppColors.muted),
                            const SizedBox(width: 4),
                            Text(inc.priority,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: inc.priority == 'Critical'
                                        ? Colors.red
                                        : AppColors.muted)),
                            const SizedBox(width: 12),
                            Text(fmt.format(inc.createdAt),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                        if (isAssignedToMe) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                const Text('Assigned to your team',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary)),
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
