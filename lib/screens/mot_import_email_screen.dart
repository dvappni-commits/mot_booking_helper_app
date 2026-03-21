import 'package:flutter/material.dart';

import '../models/mot_appointment.dart';
import '../services/mot_calendar_service.dart';
import '../utils/email_appointment_parser.dart';

class MotImportEmailScreen extends StatefulWidget {
  const MotImportEmailScreen({super.key});

  @override
  State<MotImportEmailScreen> createState() => _MotImportEmailScreenState();
}

class _MotImportEmailScreenState extends State<MotImportEmailScreen> {
  final _textCtrl = TextEditingController();

  ParsedAppointment? _parsed;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _showHowTo() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;

        Widget step({
          required String number,
          required String title,
          required String body,
        }) {
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
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

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
                        'How to import an appointment from an email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                step(
                  number: '1',
                  title: 'Open your appointment confirmation email',
                  body:
                  'Open the email from DVA that contains your booking details.',
                ),
                const SizedBox(height: 10),
                step(
                  number: '2',
                  title: 'Copy the email text',
                  body:
                  'Press and hold on the text in the email, select all (or drag the handles) to highlight everything, then tap Copy.',
                ),
                const SizedBox(height: 10),
                step(
                  number: '3',
                  title: 'Go to calendar',
                  body:
                  'In the app go to the trade tab and open the calendar and click on import from email',
                ),
                const SizedBox(height: 10),
                step(
                  number: '4',
                  title: 'Tap “Import”',
                  body:
                  'Paste the copied text into the import box and tap import. The app will auto-fill fields',
                ),
                const SizedBox(height: 10),
                step(
                  number: '5',
                  title: 'Check & Save',
                  body:
                  'Confirm date/time/centre look correct, then tap Save to calendar.',
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
                          'Tip: If import misses anything, you can still edit the entry later in the calendar.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _parse() {
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _parsed = null;
        _error = 'Paste the appointment email text first.';
      });
      return;
    }

    final parsed = EmailAppointmentParser.parse(raw);

    if (!parsed.hasAnything) {
      setState(() {
        _parsed = null;
        _error =
        'Could not detect appointment details. Make sure you pasted the full “Appointment Details” section.';
      });
      return;
    }

    setState(() {
      _parsed = parsed;
      _error = null;
    });
  }

  Future<void> _saveToCalendar() async {
    final p = _parsed;
    if (p == null) return;

    if (p.date == null || (p.time == null || p.time!.trim().isEmpty)) {
      setState(() {
        _error = 'Missing Date or Time. Please check the pasted email includes both.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final id = now.millisecondsSinceEpoch.toString();

      final item = MotAppointment(
        id: id,
        date: DateTime(p.date!.year, p.date!.month, p.date!.day),
        registration: (p.registration ?? '').trim(),
        testCentre: (p.testCentre ?? '').trim(),
        lane: (p.lane ?? '').trim(),
        time: (p.time ?? '').trim(),
        bookingRef: (p.bookingRef ?? '').trim().isEmpty
            ? null
            : (p.bookingRef ?? '').trim(),
        lastChangeDateTime: p.lastChangeDateTime,
        createdAt: now,
      );

      await MotCalendarService.upsert(item);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Failed to save. Try again.';
      });
    }
  }

  Widget _previewCard(BuildContext context) {
    final p = _parsed;
    if (p == null) return const SizedBox.shrink();

    String fmtDate(DateTime? d) {
      if (d == null) return '-';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    String fmtTime(DateTime d) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preview',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _kv('Reg', (p.registration ?? '-').toUpperCase()),
            _kv('Test centre', (p.testCentre ?? '-')),
            _kv('Lane', p.lane ?? '-'),
            _kv('Time', p.time ?? '-'),
            _kv('Date', fmtDate(p.date)),
            _kv('Booking ref', p.bookingRef ?? '-'),
            if (p.lastChangeDateTime != null) ...[
              const SizedBox(height: 6),
              Text(
                'Last change/cancel: ${fmtDate(p.lastChangeDateTime)} ${fmtTime(p.lastChangeDateTime!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _saveToCalendar,
                child: Text(_saving ? 'Saving…' : 'Save to calendar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBarPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import MOT from Email'),
        actions: [
          IconButton(
            tooltip: 'Help importing',
            icon: const Icon(Icons.help_outline),
            onPressed: _showHowTo,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + navBarPadding),
        children: [
          const Text('Paste the appointment email text below, then tap Import.'),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _showHowTo,
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Help importing'),
            ),
          ),

          const SizedBox(height: 8),

          // Smaller paste box
          SizedBox(
            height: 170,
            child: TextField(
              controller: _textCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste the “Appointment Details” text here…',
              ),
            ),
          ),

          // Import button under the textbox
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _parse,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Import'),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 12),
          _previewCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}