import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UserProfile {
  final String uid;
  final String name;
  final String username;
  final String role;
  final String status;
  final String? teamId;

  UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    required this.role,
    required this.status,
    this.teamId,
  });

  factory UserProfile.fromMap(
      String uid, String role, Map<dynamic, dynamic> map) {
    String s(String k) => (map[k] ?? '').toString();
    return UserProfile(
      uid: uid,
      name: s('name'),
      username: s('username'),
      role: role,
      status: s('status').isEmpty ? 'Active' : s('status'),
      teamId: s('teamId').isEmpty ? null : s('teamId'),
    );
  }
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authChanges => _auth.authStateChanges();

  UserProfile? _currentUserProfile;
  UserProfile? get currentUserProfile => _currentUserProfile;

  String _usernameToEmail(String username) {
    return '${username.trim().toLowerCase()}@disastrack.app';
  }

  Future<UserProfile> signIn(String username, String password) async {
    try {
      final email = _usernameToEmail(username);
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final uid = cred.user!.uid;

      final roleSnap = await _db.child('userRoles/$uid').get();
      final role = (roleSnap.value ?? '').toString();

      if (role != 'Rescue Team' &&
          role != 'Disaster Management Officer' &&
          role != 'Admin') {
        await _auth.signOut();
        throw AuthException(
            'Access denied. This account is not authorized for the Rescuer app.');
      }

      String folder = role == 'Rescue Team'
          ? 'RescueTeamMembers'
          : role == 'Disaster Management Officer'
              ? 'DisasterManagementOfficers'
              : 'Admins';

      final profileSnap = await _db.child('users/$folder/$uid').get();
      if (!profileSnap.exists) {
        await _auth.signOut();
        throw AuthException(
            'Profile not found. Please contact an administrator.');
      }

      final profile = UserProfile.fromMap(
          uid, role, profileSnap.value as Map<dynamic, dynamic>);

      if (profile.status.toLowerCase() != 'active') {
        await _auth.signOut();
        throw AuthException(
            'Your account is ${profile.status.toLowerCase()}. Please contact your DRRM office.');
      }

      if (role == 'Rescue Team' && profile.teamId == null) {
        await _auth.signOut();
        throw AuthException(
            'Your account is not assigned to a rescue team. Please contact an administrator.');
      }

      await _audit(
          profile.name, uid, role, 'Login', 'Signed in to Rescuer app');
      _currentUserProfile = profile;

      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    } catch (e) {
      throw AuthException('An unexpected error occurred: $e');
    }
  }

  /// Fetches the user profile from the database if it's not already in memory.
  /// This fixes the "stuck on loading" issue after a Hot Restart.
  Future<UserProfile?> ensureProfileLoaded() async {
    if (_currentUserProfile != null) return _currentUserProfile;

    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final roleSnap = await _db.child('userRoles/${user.uid}').get();
      final role = (roleSnap.value ?? '').toString();

      String folder = role == 'Rescue Team'
          ? 'RescueTeamMembers'
          : role == 'Disaster Management Officer'
              ? 'DisasterManagementOfficers'
              : 'Admins';

      final profileSnap = await _db.child('users/$folder/${user.uid}').get();
      if (!profileSnap.exists) return null;

      _currentUserProfile = UserProfile.fromMap(
          user.uid, role, profileSnap.value as Map<dynamic, dynamic>);
      return _currentUserProfile;
    } catch (e) {
      print('🔥 PROFILE LOAD ERROR: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    _currentUserProfile = null;
    await _auth.signOut();
  }

  Future<void> _audit(String actor, String uid, String role, String category,
      String action) async {
    try {
      await _db.child('auditLogs').push().set({
        'action': action,
        'actor': actor,
        'actorId': uid,
        'category': category,
        'details': 'Rescuer app session',
        'role': role,
        'target': 'Rescuer App',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect username or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
