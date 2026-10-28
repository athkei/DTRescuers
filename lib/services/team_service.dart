import 'package:firebase_database/firebase_database.dart';

const teamStatuses = <String>[
  'Available',
  'Standby',
  'Deployed',
  'Off duty',
];

class TeamService {
  TeamService._();
  static final instance = TeamService._();

  final _db = FirebaseDatabase.instance.ref();

  Stream<Map<String, dynamic>?> watchTeam(String teamId) {
    return _db.child('rescueTeams/$teamId').onValue.map((e) {
      final v = e.snapshot.value;
      return v is Map ? Map<String, dynamic>.from(v) : null;
    });
  }

  Future<void> updateTeamStatus(String teamId, String status) async {
    if (!teamStatuses.contains(status)) {
      throw Exception('Unknown team status.');
    }
    // Rules grant this only to a member whose teamId matches.
    await _db.child('rescueTeams/$teamId/status').set(status);
  }

  Future<void> updateTeamLocation(String teamId, double lat, double lng) async {
    // Must match database.rules.json, or the write is denied.
    if (lat < 14.6 || lat > 15.35 || lng < 120.65 || lng > 121.4) {
      throw Exception(
          'You are outside the Bulacan coverage area, so location cannot be saved.');
    }

    await _db.child('rescueTeams/$teamId/location').set({
      'lat': lat,
      'lng': lng,
      // Rules require a NUMBER here (Date.now()), not an ISO string.
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
