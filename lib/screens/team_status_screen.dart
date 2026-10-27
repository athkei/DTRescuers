import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TeamStatusScreen extends StatefulWidget {
  const TeamStatusScreen({super.key});

  @override
  State<TeamStatusScreen> createState() => _TeamStatusScreenState();
}

class _TeamStatusScreenState extends State<TeamStatusScreen> {
  final _db = FirebaseDatabase.instance.ref();
  final _profile = AuthService.instance.currentUserProfile!;
  bool _locating = false;

  final List<String> _statuses = [
    'Available',
    'Standby',
    'Deployed',
    'Off duty'
  ];

  Future<void> _updateStatus(String status) async {
    try {
      await TeamService.instance.updateTeamStatus(_profile.teamId!, status);
      if (mounted) showSnack(context, 'Team status updated to $status');
    } catch (e) {
      print('🔥 TEAM STATUS UPDATE ERROR: $e');
      if (mounted)
        showSnack(context, 'Failed to update status. Check your connection.',
            error: true);
    }
  }

  Future<void> _shareLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled)
        throw 'Location services are disabled on this device.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw 'Location permissions were denied. Please enable them in device settings.';
      }

      if (permission == LocationPermission.deniedForever)
        throw 'Location permissions are permanently denied. Please enable them in device settings.';

      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await TeamService.instance.updateTeamLocation(
          _profile.teamId!, position.latitude, position.longitude);

      if (mounted) showSnack(context, 'Live location shared successfully!');
    } catch (e) {
      print('🔥 LOCATION SHARE ERROR: $e');
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Team ${_profile.teamId}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder(
        stream: _db.child('rescueTeams/${_profile.teamId}').onValue,
        builder: (context, snap) {
          if (snap.hasError) {
            print('🔥 TEAM STATUS STREAM ERROR: ${snap.error}');
            return const Center(child: Text('Failed to load team data.'));
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.snapshot.value as Map<dynamic, dynamic>;
          final currentStatus = data['status']?.toString() ?? 'Unknown';
          final location = data['location'] as Map<dynamic, dynamic>?;

          String lastUpdated = 'Never';
          if (location != null && location['updatedAt'] != null) {
            final ms = location['updatedAt'] is int
                ? location['updatedAt'] as int
                : int.tryParse(location['updatedAt'].toString()) ?? 0;
            if (ms > 0) {
              lastUpdated = DateFormat('h:mm a')
                  .format(DateTime.fromMillisecondsSinceEpoch(ms));
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Team Status',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                itemCount: _statuses.length,
                itemBuilder: (context, index) {
                  final status = _statuses[index];
                  final isSelected = status == currentStatus;
                  return Padding(
                    padding: const EdgeInsets.all(6),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            isSelected ? AppColors.primary : Colors.white,
                        foregroundColor:
                            isSelected ? Colors.white : AppColors.ink,
                        side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE5E7EB)),
                        minimumSize: const Size.fromHeight(60),
                      ),
                      onPressed: () => _updateStatus(status),
                      child: Text(status,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('Live Location',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Last updated: $lastUpdated',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (location != null) ...[
                      const SizedBox(height: 8),
                      Text('Lat: ${location['lat']}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                      Text('Lng: ${location['lng']}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text('No location shared yet.',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _locating ? null : _shareLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.share_location),
                label:
                    Text(_locating ? 'Getting GPS...' : 'Share Live Location'),
              ),
            ],
          );
        },
      ),
    );
  }
}
