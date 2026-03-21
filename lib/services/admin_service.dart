import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  AdminService._();

  static const Set<String> _adminEmails = {
    'ciaranconnolly1@googlemail.com',
  };

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static bool get isLoggedIn => _auth.currentUser != null;

  static bool get isAdmin {
    final email = _auth.currentUser?.email?.toLowerCase();
    if (email == null) return false;
    return _adminEmails.contains(email);
  }

  static Future<void> forceSignOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  static Future<void> signOut() => _auth.signOut();
}
