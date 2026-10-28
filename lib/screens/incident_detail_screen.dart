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
      if (outcome != null) patch['outcome'] = outcome;
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
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: peopleCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'People rescued',
                prefixIcon: Icon(Icons.people_outline)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Resolution notes', alignLabelWithHint: true),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus('Resolved', outcome: {
                'peopleRescued': int.tryParse(peopleCtrl.text) ?? 0,
                'notes': notesCtrl.text.trim(),
                'completedAt': DateTime.now().toUtc().toIso8601String(),
                'recordedBy': widget.profile.name,
              });
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

  Widget _metaRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 92,
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.muted),
                const SizedBox(width: 6)
              ],
              Text(label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ])),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y · h:mm a');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.incident.id,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: StatusChip(widget.incident.status)))
        ],
      ),
      body: StreamBuilder(
        stream: _db.child('incidents/${widget.incident.id}').onValue,
        builder: (context, snap) {
          if (snap.hasError)
            return const Center(
                child: Text('Failed to load incident details.'));
          if (!snap.hasData || snap.data!.snapshot.value == null)
            return const Center(child: CircularProgressIndicator());

          final rawData = snap.data!.snapshot.value as Map<dynamic, dynamic>;
          final rawPhotos = rawData['photoData'];
          final List<String> photos = [];
          if (rawPhotos is List)
            photos.addAll(rawPhotos.map((e) => e.toString()));
          else if (rawPhotos is Map)
            photos.addAll(rawPhotos.values.map((e) => e.toString()));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(widget.incident.type,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line)),
                child: Column(children: [
                  _metaRow('Reporter', widget.incident.reporter,
                      icon: Icons.person_outline),
                  const Divider(height: 24),
                  _metaRow('Contact', widget.incident.phone,
                      icon: Icons.phone_outlined),
                  const Divider(height: 24),
                  _metaRow('Priority', widget.incident.priority,
                      icon: Icons.priority_high),
                ]),
              ),
              const SizedBox(height: 20),

              // 🗺️ NO-PACKAGE STATIC MAP (Works perfectly in FlutLab!)
              if (widget.incident.lat != null &&
                  widget.incident.lng != null) ...[
                const Text('Location',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 190,
                    child: Stack(children: [
                      // Free OpenStreetMap Static Image
                      Image.network(
                        'https://staticmap.openstreetmap.de/staticmap.php?center=${widget.incident.lat},${widget.incident.lng}&zoom=15&size=400x190&maptype=mapnik&markers=${widget.incident.lat},${widget.incident.lng},red-pushpin',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 190,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.muted.withValues(alpha: 0.1),
                            child: const Center(
                                child: Icon(Icons.map,
                                    size: 48, color: AppColors.muted)),
                          );
                        },
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Material(
                          color: Colors.white,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _openMaps(
                                widget.incident.lat, widget.incident.lng),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.directions,
                                        size: 16, color: AppColors.primary),
                                    SizedBox(width: 6),
                                    Text('Open in Maps',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary)),
                                  ]),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text('Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(widget.incident.description,
                  style: const TextStyle(height: 1.5, color: AppColors.ink)),
              const SizedBox(height: 24),

              if (photos.isNotEmpty) ...[
                const Text('Photos',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      try {
                        final base64Str = photos[i].split(',').last;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(base64Decode(base64Str),
                              width: 90, height: 90, fit: BoxFit.cover),
                        );
                      } catch (e) {
                        return const SizedBox(
                            width: 90,
                            height: 90,
                            child: Center(
                                child: Icon(Icons.broken_image,
                                    color: AppColors.muted)));
                      }
                    },
                  ),
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
                const WarningNote(
                    'Only the assigned rescue team can update the status of this incident.'),
                const SizedBox(height: 24),
              ],

              const Text('Activity Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...widget.incident.activity.reversed.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.text,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
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
