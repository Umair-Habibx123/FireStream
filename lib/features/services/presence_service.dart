import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralised online-presence writer.
///
/// Call [setOnline]/[setOffline] from a single app-level lifecycle observer
/// (see ChatListScreen) so the user shows as online whenever the app is in the
/// foreground — not only while a chat screen is open.
class PresenceService {
  PresenceService(this.userEmail);

  final String userEmail;

  Future<void> setOnline() => _write(true);
  Future<void> setOffline() => _write(false);

  Future<void> _write(bool online) async {
    if (userEmail.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .set({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort; ignore transient/offline failures.
    }
  }
}
