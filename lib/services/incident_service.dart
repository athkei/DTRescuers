import 'package:firebase_database/firebase_database.dart';
import '../models/incident.dart';

class IncidentService {
  IncidentService._();
  static final instance = IncidentService._();

  final _db = FirebaseDatabase.instance.ref();

  Stream<List<Incident>> watchIncidents() {
    return _db.child('incidents').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final list = <Incident>[];

      for (final entry in data.entries) {
        if (entry.value is Map) {
          list.add(Incident.fromMap(entry.key.toString(), entry.value as Map));
        }
      }

      final order = {'Critical': 0, 'High': 1, 'Medium': 2, 'Low': 3};
      list.sort((a, b) {
        final pA = order[a.priority] ?? 4;
        final pB = order[b.priority] ?? 4;
        if (pA != pB) return pA.compareTo(pB);
        return b.createdAt.compareTo(a.createdAt);
      });

      return list;
    });
  }

  Stream<Incident?> watchIncident(String id) {
    return _db.child('incidents/$id').onValue.map((event) {
      final v = event.snapshot.value;
      return v is Map ? Incident.fromMap(id, v) : null;
    });
  }

  /// RESCUE TEAM PATH.
  /// Rules grant writes on incidents/{id}/status and /activity ONLY,
  /// so we must NOT overwrite the whole incident node here.
  Future<void> updateAssignedIncident(
    String id,
    String newStatus,
    String logText, {
    Map<String, dynamic>? outcome,
  }) async {
    final ref = _db.child('incidents/$id');

    // 1. Write the status (granted to the assigned team).
    await ref.child('status').set(newStatus);

    // 2. Append the activity line transactionally (granted to assigned team).
    await ref.child('activity').runTransaction((current) {
      final list = asList(current);
      list.add({
        'text': logText,
        'at': DateTime.now().toUtc().toIso8601String(),
      });
      return Transaction.success(list);
    });

    // 3. Optional outcome. Requires the extra outcome .write rule (see notes).
    if (outcome != null) {
      await ref.child('outcome').set(outcome);
    }
  }

  /// ADMIN PATH. Admins may overwrite the whole node, so we can use the
  /// same safe full-node transaction as the web console.
  Future<void> updateIncident(
    String id,
    Map<String, dynamic> patch,
    String? logText,
  ) async {
    await _db.child('incidents/$id').runTransaction((current) {
      if (current == null) return Transaction.abort();

      final next = Map<String, dynamic>.from(current as Map);

      for (final entry in patch.entries) {
        if (entry.value == null) {
          next.remove(entry.key);
        } else {
          next[entry.key] = entry.value;
        }
      }

      if (logText != null && logText.isNotEmpty) {
        final list = asList(next['activity']);
        list.add({
          'text': logText,
          'at': DateTime.now().toUtc().toIso8601String(),
        });
        next['activity'] = list;
      }

      return Transaction.success(next);
    });
  }
}
