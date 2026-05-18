import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final _local = FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) showLocal(title: n.title ?? 'Student+', body: n.body ?? '');
    });
    final token = await fcm.getToken();
    if (token != null) await _saveToken(token);
    fcm.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> _saveToken(String token) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', uid);
    } catch (_) {}
  }

  static Future<void> showLocal({required String title, required String body, int id = 0}) async {
    const androidDetails = AndroidNotificationDetails(
      'student_plus', 'Student+',
      channelDescription: 'Student+ notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _local.show(id, title, body,
        const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()));
  }

  static Future<void> notifyParentsForAbsent({
    required List<String> absentStudentIds,
    required String subjectName,
    required String date,
    required int periodNumber,
  }) async {
    for (final studentId in absentStudentIds) {
      try {
        await Supabase.instance.client.functions.invoke('notify-parent', body: {
          'student_id':    studentId,
          'date':          date,
          'period_number': periodNumber,
          'subject_name':  subjectName,
          'absent_count':  1,
        });
      } catch (_) {}
    }
  }
}
