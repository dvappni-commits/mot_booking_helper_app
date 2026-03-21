import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mot_appointment.dart';
import 'mot_notification_service.dart';
import 'subscription_service.dart';

class MotCalendarService {
  MotCalendarService._();

  static const String _key = 'mot_calendar_items_v2';

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _safeDateOnly(MotAppointment a) =>
      DateTime(a.date.year, a.date.month, a.date.day);

  static DateTime _apptDateTime(MotAppointment a) {
    final parts = a.time.trim().split(':');
    if (parts.length != 2) return _safeDateOnly(a);

    final hh = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    if (hh == null || mm == null) return _safeDateOnly(a);

    return DateTime(a.date.year, a.date.month, a.date.day, hh, mm);
  }

  // ===================== LOAD / SAVE =====================

  static Future<List<MotAppointment>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    final items = decoded
        .whereType<Map>()
        .map((m) => MotAppointment.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    // newest created first
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<void> saveAll(List<MotAppointment> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<void> upsert(MotAppointment item) async {
    final items = await list();
    final idx = items.indexWhere((x) => x.id == item.id);

    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.insert(0, item);
    }

    await saveAll(items);

    // ✅ Paywall: only schedule trade notifications if subscribed
    if (SubscriptionService.isSubscribed) {
      await MotNotificationService.rescheduleTradeTodayAlerts();
    }
  }

  static Future<void> remove(String id) async {
    final items = await list();
    items.removeWhere((x) => x.id == id);
    await saveAll(items);

    // ✅ Paywall: only schedule trade notifications if subscribed
    if (SubscriptionService.isSubscribed) {
      await MotNotificationService.rescheduleTradeTodayAlerts();
    }
  }

  // ===================== CALENDAR HELPERS =====================

  static Future<List<MotAppointment>> listForDay(DateTime day) async {
    final d = _dayOnly(day);
    final items = await list();

    final out = items.where((x) => _dayOnly(x.date) == d).toList();

    // sort by time within the day
    out.sort((a, b) => _apptDateTime(a).compareTo(_apptDateTime(b)));
    return out;
  }

  static Future<Map<DateTime, int>> countsByDay() async {
    final items = await list();
    final Map<DateTime, int> counts = {};

    for (final a in items) {
      final d = _dayOnly(a.date);
      counts[d] = (counts[d] ?? 0) + 1;
    }

    return counts;
  }

  // ===================== NEXT APPOINTMENT =====================

  /// Closest upcoming appointment (date + time)
  static Future<MotAppointment?> nextDue() async {
    final items = await list();
    if (items.isEmpty) return null;

    final now = DateTime.now();

    final upcoming = <MotAppointment>[];
    for (final a in items) {
      final dt = _apptDateTime(a);
      if (!dt.isBefore(now)) {
        upcoming.add(a);
      }
    }

    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) => _apptDateTime(a).compareTo(_apptDateTime(b)));
    return upcoming.first;
  }

  /// ✅ Home screen calendar tile preview
  /// Format: date • reg • centre • time
  static Future<String?> nextAppointmentPreview() async {
    final next = await nextDue();
    if (next == null) return null;

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final date = fmtDate(next.date);
    final reg = next.registration.toUpperCase();
    final centre = next.testCentre;
    final time = next.time;

    return '$date • $reg • $centre • $time';
  }
}