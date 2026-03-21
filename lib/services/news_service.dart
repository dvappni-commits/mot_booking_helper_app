import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/mot_notification_service.dart'; // 👈 ADD THIS

class NewsService {
  NewsService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('trade').doc('news');

  static Stream<Map<String, dynamic>?> streamNews() {
    return _doc.snapshots().map((snap) => snap.data());
  }

  static Future<Map<String, dynamic>?> getNewsOnce() async {
    final snap = await _doc.get();
    return snap.data();
  }

  static Future<void> saveNews({
    required String title,
    required String line1,
    required String line2,
    required String body,
  }) async {
    await _doc.set(
      <String, dynamic>{
        'title': title.trim(),
        'line1': line1.trim(),
        'line2': line2.trim(),
        'body': body.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ✅ SEND PUSH NOTIFICATION AFTER SAVE
    await MotNotificationService.notifyTradeNewsUpdated(
      title: title,
      line1: line1,
      line2: line2,
    );
  }
}
