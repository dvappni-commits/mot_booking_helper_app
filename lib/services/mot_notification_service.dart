import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'mot_calendar_service.dart';
import '../models/mot_appointment.dart';

class MotNotificationService {
  MotNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'mot_alerts';
  static const String _channelName = 'MOT alerts';
  static const String _channelDesc = 'Alerts for MOT appointments';

  static bool _inited = false;

  // Stable IDs (keep consistent)
  static const int _tradeTodaySummaryId = 9100;
  static const int _tradeTomorrowSummaryId = 9101;
  static const int _tradeNewsUpdatedId = 9102;

  static Future<void> init() async {
    if (_inited) return;
    _inited = true;

    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> requestPermissionIfNeeded() async {
    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {
      // ignore
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Call this whenever appointments change OR app launches.
  /// Schedules:
  /// - 07:30 summary for TODAY (if there are MOTs today)
  /// - 20:00 summary for TOMORROW (ALWAYS; if none => "No MOTs tomorrow ✅")
  /// - 1 hour before each appointment today
  static Future<void> rescheduleTradeTodayAlerts() async {
    await init();

    // Cancel previous “trade” notifications
    await _plugin.cancel(_tradeTodaySummaryId);
    await _plugin.cancel(_tradeTomorrowSummaryId);
    await _cancelTradeOneHourBeforeForToday();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // -------------------------
    // TODAY: 07:30 summary + 1 hour before each
    // -------------------------
    final todayItems = await MotCalendarService.listForDay(today);

    if (todayItems.isNotEmpty) {
      todayItems.sort((a, b) => _apptDateTime(a).compareTo(_apptDateTime(b)));

      // 07:30 summary (if already past 07:30, schedule it 1 minute from now)
      final sevenThirty = DateTime(now.year, now.month, now.day, 7, 30);
      final summaryTime = now.isAfter(sevenThirty)
          ? now.add(const Duration(minutes: 1))
          : sevenThirty;

      await _scheduleIfFuture(
        id: _tradeTodaySummaryId,
        when: summaryTime,
        title: "Today's MOTs",
        body: _buildMotSummaryBody(todayItems, prefixCount: true),
      );

      // 1 hour before each appointment today
      for (final a in todayItems) {
        final dt = _apptDateTime(a);
        final oneHourBefore = dt.subtract(const Duration(hours: 1));

        if (!oneHourBefore.isAfter(DateTime.now())) continue;

        final id = _tradeOneHourIdFor(a, today);

        final reg = a.registration.trim().toUpperCase();
        final time = a.time.trim().isEmpty ? '--:--' : a.time.trim();
        final centre = a.testCentre.trim();

        await _scheduleIfFuture(
          id: id,
          when: oneHourBefore,
          title: 'MOT in 1 hour',
          body: '$time $reg • $centre',
        );
      }
    }

    // -------------------------
    // TOMORROW: 20:00 summary ALWAYS
    // -------------------------
    final eightPm = DateTime(now.year, now.month, now.day, 20, 0);

    // If it's already past 20:00 today, don't schedule tonight’s reminder.
    // (It will be scheduled again on next app launch / next reschedule.)
    if (eightPm.isAfter(now)) {
      final tomorrowItems = await MotCalendarService.listForDay(tomorrow);
      tomorrowItems.sort((a, b) => _apptDateTime(a).compareTo(_apptDateTime(b)));

      final body = tomorrowItems.isEmpty
          ? 'No MOTs tomorrow ✅'
          : _buildMotSummaryBody(tomorrowItems, prefixCount: false);

      await _scheduleIfFuture(
        id: _tradeTomorrowSummaryId,
        when: eightPm,
        title: "Tomorrow's MOTs",
        body: body,
      );
    }
  }

  /// Call this right after you publish/update the Trade News in Firestore/admin screen.
  /// Example:
  /// MotNotificationService.notifyTradeNewsUpdated(title: title, line1: line1, line2: line2);
  static Future<void> notifyTradeNewsUpdated({
    String? title,
    String? line1,
    String? line2,
  }) async {
    await init();

    final t = (title ?? '').trim();
    final l1 = (line1 ?? '').trim();
    final l2 = (line2 ?? '').trim();

    final notifTitle = t.isEmpty ? 'Trade update' : t;

    final previewLines = <String>[
      if (l1.isNotEmpty) l1,
      if (l2.isNotEmpty) l2,
    ];

    final body = previewLines.isEmpty
        ? 'A new trade update is available.'
        : previewLines.join('\n');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    // Replace any previous "news updated" notification so it doesn't spam
    await _plugin.show(_tradeNewsUpdatedId, notifTitle, body, details);
  }

  // ---------- helpers ----------

  /// Summary body shows TIME + REG (as requested).
  /// Example: "2: 09:30 AB12CDE, 13:10 XY99ZZZ …"
  static String _buildMotSummaryBody(
      List<MotAppointment> items, {
        required bool prefixCount,
      }) {
    final count = items.length;

    final preview = items.take(3).map((a) {
      final reg = a.registration.trim().toUpperCase();
      final time = a.time.trim().isEmpty ? '--:--' : a.time.trim();
      return '$time $reg';
    }).join(', ');

    final core = count <= 3 ? preview : '$preview …';
    return prefixCount ? '$count: $core' : core;
  }

  static DateTime _apptDateTime(MotAppointment a) {
    final parts = a.time.trim().split(':');
    if (parts.length != 2) {
      return DateTime(a.date.year, a.date.month, a.date.day, 9, 0);
    }
    final hh = int.tryParse(parts[0]) ?? 9;
    final mm = int.tryParse(parts[1]) ?? 0;
    return DateTime(a.date.year, a.date.month, a.date.day, hh, mm);
  }

  static int _tradeOneHourIdFor(MotAppointment a, DateTime dayOnly) {
    final key = 'trade_1h_${dayOnly.toIso8601String()}_${a.id}';
    return 920000 + (key.hashCode & 0x3FFFFF);
  }

  static Future<void> _cancelTradeOneHourBeforeForToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = await MotCalendarService.listForDay(today);
    for (final a in items) {
      await _plugin.cancel(_tradeOneHourIdFor(a, today));
    }
  }

  static Future<void> _scheduleIfFuture({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (!when.isAfter(DateTime.now())) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}