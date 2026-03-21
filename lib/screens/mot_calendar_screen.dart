import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mot_appointment.dart';
import '../services/mot_calendar_service.dart';
import '../services/mot_notification_service.dart';
import '../services/subscription_service.dart';
import 'mot_import_email_screen.dart';
import 'paywall_screen.dart';

class MotCalendarScreen extends StatefulWidget {
  const MotCalendarScreen({super.key});

  @override
  State<MotCalendarScreen> createState() => _MotCalendarScreenState();
}

class _MotCalendarScreenState extends State<MotCalendarScreen> {
  static const String _howToSeenKey = 'mot_calendar_howto_seen_v1';

  // ✅ YouTube help video (opens externally)
  static const String _importHelpVideo =
      'https://youtube.com/shorts/OcL0CoM_LgA?si=DGWuFT6aPh4i4Sop';

  DateTime _focusedDay = DateTime.now();
  late DateTime _selectedDay;

  Map<DateTime, int> _countsByDay = {};
  List<MotAppointment> _selectedDayItems = [];
  MotAppointment? _nextDue;

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);

    _refreshAll();

    // Auto-show tutorial once (first time user opens Calendar)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowHowToOnce();
    });
  }

  Future<void> _openHelpVideo() async {
    final uri = Uri.parse(_importHelpVideo);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openPaywall() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
    if (mounted) setState(() {}); // refresh after subscribe
  }

  void _showPaywall() {
    _openPaywall();
  }

  Future<void> _maybeShowHowToOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_howToSeenKey) ?? false;
      if (seen) return;

      if (!mounted) return;
      _showHowTo();

      await prefs.setBool(_howToSeenKey, true);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _refreshAll() async {
    final counts = await MotCalendarService.countsByDay();
    final selected = await MotCalendarService.listForDay(_selectedDay);
    final next = await MotCalendarService.nextDue();

    if (!mounted) return;
    setState(() {
      _countsByDay = counts.map((k, v) => MapEntry(_dayOnly(k), v));
      _selectedDayItems = selected;
      _nextDue = next;
    });
  }

  int _eventCountForDay(DateTime day) => _countsByDay[_dayOnly(day)] ?? 0;

  Future<void> _openEditor({MotAppointment? existing}) async {
    // Soft paywall: edit/add requires subscription
    if (!SubscriptionService.isSubscribed) {
      _showPaywall();
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AppointmentEditor(
          day: _selectedDay,
          existing: existing,
        ),
      ),
    );

    if (changed == true) {
      await _refreshAll();

      // Only reschedule notifications if subscribed
      if (SubscriptionService.isSubscribed) {
        await MotNotificationService.rescheduleTradeTodayAlerts();
      }
    }
  }

  Future<void> _delete(MotAppointment item) async {
    // Soft paywall: delete requires subscription
    if (!SubscriptionService.isSubscribed) {
      _showPaywall();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          'Delete ${item.registration.toUpperCase()} on ${_fmtDate(item.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await MotCalendarService.remove(item.id);

    if (SubscriptionService.isSubscribed) {
      await MotNotificationService.rescheduleTradeTodayAlerts();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry deleted')),
    );

    await _refreshAll();
  }

  void _showHowTo() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: cs.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'How to add an appointment from an email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                // ✅ YouTube button (new)
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _openHelpVideo,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Watch Video Guide'),
                  ),
                ),

                const SizedBox(height: 12),

                _howToStep(
                  number: '1',
                  title: 'Open your appointment confirmation email',
                  body: 'Find the email from DVA that contains your booking details.',
                ),
                const SizedBox(height: 10),
                _howToStep(
                  number: '2',
                  title: 'Copy the email text',
                  body:
                  'Press and hold on the text in the email, & select all in the appointment letter. Tap Copy.',
                ),
                const SizedBox(height: 10),
                _howToStep(
                  number: '3',
                  title: 'Tap “Import from Email” in MOT Booking helper App',
                  body:
                  'In the MOT Booking Helper App, open the trade tab, open the calendar, tap the button at the top of the screen "Import from Email".',
                ),
                const SizedBox(height: 10),
                _howToStep(
                  number: '4',
                  title: 'Paste the text and import',
                  body:
                  'Press and hold in the box, tap “Paste”, then tap Import. MOT Booking Helper App will fill the fields for you.',
                ),
                const SizedBox(height: 10),
                _howToStep(
                  number: '5',
                  title: 'Check & Save',
                  body:
                  'Make sure date/time/centre look correct, then tap Save. You’ll now see it in your calendar.',
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tip: If import misses anything, you can still edit the entry by tapping it.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);

                      if (!SubscriptionService.isSubscribed) {
                        if (mounted) _showPaywall();
                        return;
                      }

                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MotImportEmailScreen()),
                      );

                      if (changed == true) {
                        await _refreshAll();
                        if (SubscriptionService.isSubscribed) {
                          await MotNotificationService.rescheduleTradeTodayAlerts();
                        }
                      }
                    },
                    icon: const Icon(Icons.content_paste),
                    label: const Text('Open Import from Email'),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _howToStep({
    required String number,
    required String title,
    required String body,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

  @override
  Widget build(BuildContext context) {
    final next = _nextDue;
    final isPro = SubscriptionService.isSubscribed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MOT Calendar'),
        actions: [
          IconButton(
            tooltip: 'How to',
            icon: const Icon(Icons.help_outline),
            onPressed: _showHowTo,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          children: [
            // IMPORT BUTTON (visible always, gated)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  if (!isPro) {
                    _showPaywall();
                    return;
                  }

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final seen = prefs.getBool(_howToSeenKey) ?? false;
                    if (!seen && mounted) {
                      _showHowTo();
                      await prefs.setBool(_howToSeenKey, true);
                    }
                  } catch (_) {
                    // ignore
                  }

                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MotImportEmailScreen()),
                  );

                  if (changed == true) {
                    await _refreshAll();
                    if (SubscriptionService.isSubscribed) {
                      await MotNotificationService.rescheduleTradeTodayAlerts();
                    }
                  }
                },
                icon: Icon(isPro ? Icons.content_paste : Icons.lock_outline),
                label: const Text('Import from Email'),
              ),
            ),
            if (!isPro) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'Trade feature — unlock to import from email',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // CALENDAR (view-only is fine)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    titleCentered: true,
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.35),
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    formatButtonPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Help importing',
                  },
                  onFormatChanged: (_) => _showHowTo(),
                  onDaySelected: (selectedDay, focusedDay) async {
                    final dayOnly = _dayOnly(selectedDay);
                    setState(() {
                      _selectedDay = dayOnly;
                      _focusedDay = focusedDay;
                    });

                    final items = await MotCalendarService.listForDay(dayOnly);
                    if (!mounted) return;
                    setState(() => _selectedDayItems = items);
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: (day) {
                    final c = _eventCountForDay(day);
                    return c == 0 ? const [] : List.filled(c, 'x');
                  },
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // NEXT DUE (view-only is fine)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: next == null
                    ? const Text('Next due: none yet')
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Next due',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      '${_fmtDate(next.date)} • ${next.registration.toUpperCase()} • ${next.time}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text('${next.testCentre} • Lane ${next.lane}'),
                    if ((next.bookingRef ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Booking Ref: ${next.bookingRef}'),
                    ],
                    if (next.lastChangeDateTime != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Change/cancel by: ${_fmtDateTime(next.lastChangeDateTime!)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // SELECTED DAY LIST (header)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.event_note_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entries for ${_fmtDate(_selectedDay)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedDayItems.isEmpty
                                ? 'No appointments saved'
                                : '${_selectedDayItems.length} appointment${_selectedDayItems.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.65),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _openEditor(),
                      icon: Icon(isPro ? Icons.add : Icons.lock_outline),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (_selectedDayItems.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No entries on this day. Tap + to add one.'),
              )
            else
              ..._selectedDayItems.map((item) {
                final lines = <String>[
                  item.testCentre,
                  'Lane: ${item.lane} • Time: ${item.time}',
                ];
                if ((item.bookingRef ?? '').trim().isNotEmpty) {
                  lines.add('Booking Ref: ${item.bookingRef}');
                }
                if (item.lastChangeDateTime != null) {
                  lines.add(
                      'Change/cancel by: ${_fmtDateTime(item.lastChangeDateTime!)}');
                }

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(
                      item.registration.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(lines.join('\n')),
                    isThreeLine: true,
                    onTap: () => _openEditor(existing: item), // paywall if locked
                    trailing: IconButton(
                      icon: Icon(isPro ? Icons.delete_outline : Icons.lock_outline),
                      onPressed: () => _delete(item), // paywall if locked
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Auto-formats digits into HH:mm while typing.
class _TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();

    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buf.write(':');
      buf.write(digits[i]);
    }

    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _AppointmentEditor extends StatefulWidget {
  final DateTime day;
  final MotAppointment? existing;

  const _AppointmentEditor({
    required this.day,
    this.existing,
  });

  @override
  State<_AppointmentEditor> createState() => _AppointmentEditorState();
}

class _AppointmentEditorState extends State<_AppointmentEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _regCtrl;
  late final TextEditingController _centreCtrl;
  late final TextEditingController _laneCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _bookingRefCtrl;
  late final TextEditingController _lastChangeTimeCtrl;

  bool _saving = false;
  bool _openingDva = false;

  // ✅ Allows digits and "/" only while typing
  static final TextInputFormatter _digitsSlashOnly =
  FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'));

  // ✅ Valid: "12345678" or "12345678/2"
  bool _isValidBookingRef(String s) {
    return RegExp(r'^\d+(\/\d+)?$').hasMatch(s);
  }

  @override
  void initState() {
    super.initState();
    _regCtrl = TextEditingController(text: widget.existing?.registration ?? '');
    _centreCtrl = TextEditingController(text: widget.existing?.testCentre ?? '');
    _laneCtrl = TextEditingController(text: widget.existing?.lane ?? '');
    _timeCtrl = TextEditingController(text: widget.existing?.time ?? '');
    _bookingRefCtrl =
        TextEditingController(text: widget.existing?.bookingRef ?? '');

    final lcdt = widget.existing?.lastChangeDateTime;
    _lastChangeTimeCtrl = TextEditingController(
      text: lcdt == null
          ? ''
          : '${lcdt.hour.toString().padLeft(2, '0')}:${lcdt.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _regCtrl.dispose();
    _centreCtrl.dispose();
    _laneCtrl.dispose();
    _timeCtrl.dispose();
    _bookingRefCtrl.dispose();
    _lastChangeTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openDvaManageBooking() async {
    final reg = _regCtrl.text.trim();
    final ref = _bookingRefCtrl.text.trim();

    if (reg.isEmpty || ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add Registration and Booking reference first.')),
      );
      return;
    }

    setState(() => _openingDva = true);

    try {
      await Clipboard.setData(ClipboardData(text: '$ref $reg'));

      final uri =
      Uri.parse('https://dva-bookings.nidirect.gov.uk/MyBookings/Find');
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Copied. Paste into Booking reference, then cut REG into the REG box.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open DVA page.')),
      );
    } finally {
      if (mounted) setState(() => _openingDva = false);
    }
  }

  String? _timeValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter a time (HH:mm)';
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return 'Use HH:mm (e.g. 09:30)';

    final parts = s.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return 'Use HH:mm (e.g. 09:30)';
    if (h < 0 || h > 23 || m < 0 || m > 59) return 'Invalid time';
    return null;
  }

  DateTime? _parseLastChangeForDay(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return null;

    final parts = s.split(':');
    final hh = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    if (hh == null || mm == null) return null;
    if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;

    return DateTime(widget.day.year, widget.day.month, widget.day.day, hh, mm);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final now = DateTime.now();
    final id = widget.existing?.id ?? now.millisecondsSinceEpoch.toString();

    final bookingRef = _bookingRefCtrl.text.trim();
    final lastChange = _parseLastChangeForDay(_lastChangeTimeCtrl.text);

    final item = widget.existing == null
        ? MotAppointment(
      id: id,
      date: DateTime(widget.day.year, widget.day.month, widget.day.day),
      registration: _regCtrl.text.trim(),
      testCentre: _centreCtrl.text.trim(),
      lane: _laneCtrl.text.trim(),
      time: _timeCtrl.text.trim(),
      bookingRef: bookingRef.isEmpty ? null : bookingRef,
      lastChangeDateTime: lastChange,
      createdAt: now,
    )
        : widget.existing!.copyWith(
      date: DateTime(widget.day.year, widget.day.month, widget.day.day),
      registration: _regCtrl.text.trim(),
      testCentre: _centreCtrl.text.trim(),
      lane: _laneCtrl.text.trim(),
      time: _timeCtrl.text.trim(),
      bookingRef: bookingRef.isEmpty ? null : bookingRef,
      lastChangeDateTime: lastChange,
    );

    await MotCalendarService.upsert(item);

    if (SubscriptionService.isSubscribed) {
      await MotNotificationService.rescheduleTradeTodayAlerts();
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit entry' : 'Add entry')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Date: ${widget.day.day}/${widget.day.month}/${widget.day.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _regCtrl,
                decoration: const InputDecoration(labelText: 'Registration'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter registration' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _centreCtrl,
                decoration: const InputDecoration(labelText: 'Test centre'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter test centre' : null,
              ),

              const SizedBox(height: 12),

              // ✅ Lane: numbers only
              TextFormField(
                controller: _laneCtrl,
                decoration: const InputDecoration(labelText: 'Lane'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Enter lane';
                  if (!RegExp(r'^\d+$').hasMatch(s)) {
                    return 'Lane must be numbers only';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Time (HH:mm)',
                  hintText: '09:30',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _TimeTextInputFormatter(),
                ],
                validator: _timeValidator,
              ),

              const SizedBox(height: 12),

              // ✅ Booking reference: digits + optional "/digits"
              TextFormField(
                controller: _bookingRefCtrl,
                decoration: const InputDecoration(
                  labelText: 'Booking reference (optional)',
                  hintText: '12345678/2',
                ),
                keyboardType: TextInputType.text,
                inputFormatters: [
                  _digitsSlashOnly,
                  LengthLimitingTextInputFormatter(20),
                ],
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null; // optional
                  if (!_isValidBookingRef(s)) {
                    return 'Use numbers or numbers/number (e.g. 12345678/2)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _openingDva ? null : _openDvaManageBooking,
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(_openingDva ? 'Opening…' : 'Change Appointment'),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Copies “BookingRef Registration” and opens the DVA page. Paste into Booking reference, then cut REG into the REG box.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _lastChangeTimeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last change/cancel time (optional, HH:mm)',
                  hintText: '10:45',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _TimeTextInputFormatter(),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}