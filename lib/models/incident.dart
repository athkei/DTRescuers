class ActivityLog {
  final String text;
  final DateTime at;

  ActivityLog({required this.text, required this.at});

  factory ActivityLog.fromMap(Map<dynamic, dynamic> map) {
    String s(String k) => (map[k] ?? '').toString();
    return ActivityLog(
      text: s('text'),
      at: DateTime.tryParse(s('at'))?.toLocal() ?? DateTime.now(),
    );
  }
}

/// Tolerates Firebase returning a list as either a List or a Map.
List<dynamic> asList(dynamic raw) {
  if (raw is List) return List<dynamic>.from(raw);
  if (raw is Map) return raw.values.toList();
  return [];
}

class Incident {
  final String id;
  final String type;
  final String location;
  final String reporter;
  final String reporterId;
  final String phone;
  final String priority;
  final String status;
  final String description;
  final int photos;
  final List<String> photoData;
  final String? duplicateOf;
  final double? match;
  final double? lat;
  final double? lng;
  final String? team;
  final DateTime createdAt;
  final List<ActivityLog> activity;
  final Map<String, dynamic>? outcome;

  Incident({
    required this.id,
    required this.type,
    required this.location,
    required this.reporter,
    required this.reporterId,
    required this.phone,
    required this.priority,
    required this.status,
    required this.description,
    required this.photos,
    required this.photoData,
    required this.createdAt,
    required this.activity,
    this.duplicateOf,
    this.match,
    this.lat,
    this.lng,
    this.team,
    this.outcome,
  });

  factory Incident.fromMap(String id, Map<dynamic, dynamic> map) {
    String s(String k) => (map[k] ?? '').toString();

    final photoList = asList(map['photoData'])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    final rawOutcome = map['outcome'];

    return Incident(
      id: s('id').isEmpty ? id : s('id'),
      type: s('type'),
      location: s('location'),
      reporter: s('reporter'),
      reporterId: s('reporterId'),
      phone: s('phone'),
      priority: s('priority').isEmpty ? 'Medium' : s('priority'),
      status: s('status').isEmpty ? 'Pending' : s('status'),
      description: s('description'),
      photos: int.tryParse(s('photos')) ?? photoList.length,
      photoData: photoList,
      duplicateOf: s('duplicateOf').isEmpty ? null : s('duplicateOf'),
      match: double.tryParse(s('match')),
      lat: double.tryParse(s('lat')),
      lng: double.tryParse(s('lng')),
      team: s('team').isEmpty ? null : s('team'),
      createdAt: DateTime.tryParse(s('createdAt'))?.toLocal() ?? DateTime.now(),
      activity: asList(map['activity'])
          .whereType<Map>()
          .map((e) => ActivityLog.fromMap(e))
          .toList(),
      outcome: rawOutcome is Map ? Map<String, dynamic>.from(rawOutcome) : null,
    );
  }

  bool get isActive => const [
        'Pending',
        'Verified',
        'Awaiting Assignment',
        'Team Assigned',
        'In Progress',
      ].contains(status);
}
