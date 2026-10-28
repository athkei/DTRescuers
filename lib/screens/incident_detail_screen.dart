import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/incident.dart';
import '../services/auth_service.dart';
import '../services/incident_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class IncidentDetailScreen extends StatefulWidget {
  final Incident incident;
  final UserProfile profile;

  const IncidentDetailScreen(
      {super.key, required this.incident, required this.profile});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final _db = FirebaseDatabase.instance.ref();
  bool _busy = false;

  bool get _isAssignedToMyTeam =>
      widget.profile.role == 'Rescue Team' &&
      widget.incident.team == widget.profile.teamId;

  Future<void> _updateStatus(String newStatus,
      {Map<String, dynamic>? outcome}) async {
    setState(() => _busy = true);
    try {
      final logText = '${widget.profile.name} updated status to $newStatus';
      final patch = <String, dynamic>{'status': newStatus};

      if (outcome != null) {
        patch['outcome'] = outcome;
      }

      await IncidentService.instance
          .updateIncident(widget.incident.id, patch, logText);
      if (mounted) showSnack(context, 'Status updated to $newStatus');
    } catch (e) {
      print('🔥 STATUS UPDATE ERROR: $e');
      if (mounted)
        showSnack(context,
            'Failed to update status. Check permissions or connection.',
            error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showResolveDialog() {
    final peopleCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: peopleCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'People rescued'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Resolution notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final outcome = {
                'peopleRescued': int.tryParse(peopleCtrl.text) ?? 0,
                'notes': notesCtrl.text.trim(),
                'completedAt': DateTime.now().toUtc().toIso8601String(),
                'recordedBy': widget.profile.name,
              };
              _updateStatus('Resolved', outcome: outcome);
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y · h:mm a');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.incident.id,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: StatusChip(widget.incident.status)),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _db.child('incidents/${widget.incident.id}').onValue,
        builder: (context, snap) {
          if (snap.hasError) {
            print('🔥 INCIDENT DETAIL STREAM ERROR: ${snap.error}');
            return const Center(
                child: Text('Failed to load incident details.'));
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawData = snap.data!.snapshot.value as Map<dynamic, dynamic>;
          final rawPhotos = rawData['photoData'];
          final List<String> photos = [];
          if (rawPhotos is List) {
            photos.addAll(rawPhotos.map((e) => e.toString()));
          } else if (rawPhotos is Map) {
            photos.addAll(rawPhotos.values.map((e) => e.toString()));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(widget.incident.type,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(widget.incident.location,
                  style: const TextStyle(color: AppColors.muted, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoPill(Icons.priority_high, widget.incident.priority,
                      color: widget.incident.priority == 'Critical'
                          ? Colors.red
                          : AppColors.primary),
                  const SizedBox(width: 8),
                  _InfoPill(Icons.person, widget.incident.reporter),
                  const SizedBox(width: 8),
                  _InfoPill(Icons.phone, widget.incident.phone),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text(widget.incident.description,
                  style: const TextStyle(height: 1.4)),
              const SizedBox(height: 24),
              if (photos.isNotEmpty) ...[
                const Text('Photos',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      try {
                        final base64Str = photos[i].split(',').last;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(base64Decode(base64Str),
                              width: 120, height: 120, fit: BoxFit.cover),
                        );
                      } catch (e) {
                        print('🔥 PHOTO DECODE ERROR: $e');
                        return const SizedBox(
                            width: 120,
                            height: 120,
                            child: Center(
                                child: Icon(Icons.broken_image,
                                    color: AppColors.muted)));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (widget.incident.lat != null &&
                  widget.incident.lng != null) ...[
                OutlinedButton.icon(
                  onPressed: () =>
                      _openMaps(widget.incident.lat, widget.incident.lng),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Google Maps'),
                ),
                const SizedBox(height: 24),
              ],
              if (_isAssignedToMyTeam &&
                  widget.incident.status == 'Team Assigned') ...[
                FilledButton.icon(
                  onPressed: _busy ? null : () => _updateStatus('In Progress'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Response (In Progress)'),
                ),
                const SizedBox(height: 12),
              ],
              if (_isAssignedToMyTeam &&
                  widget.incident.status == 'In Progress') ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success),
                  onPressed: _busy ? null : _showResolveDialog,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Resolved'),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.profile.role != 'Rescue Team' ||
                  !_isAssignedToMyTeam) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: AppColors.muted),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'Only the assigned rescue team can update the status of this incident.',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.muted))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text('Activity Log',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ...widget.incident.activity.reversed.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.text,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(fmt.format(log.at),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoPill(this.icon, this.text, {this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
