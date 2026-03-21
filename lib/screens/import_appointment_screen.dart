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

    // Hide keyboard after import so user can see the preview + save button
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveToCalendar() async {
    final p = _parsed;
    if (p == null) return;

    if (p.date == null || (p.time == null || p.time!.trim().isEmpty)) {
      setState(() {
        _error =
        'Missing Date or Time. Please check the pasted email includes both.';
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
        bookingRef: (p.bookingRef ?? '').trim(),
        lastChangeDateTime: p.lastChangeDateTime, // ✅ THIS WAS MISSING
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
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
                'Last change/cancel: ${fmtDate(p.lastChangeDateTime)} '
                    '${p.lastChangeDateTime!.hour.toString().padLeft(2, '0')}:'
                    '${p.lastChangeDateTime!.minute.toString().padLeft(2, '0')}',
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBarPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import MOT from Email'),
      ),
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + navBarPadding),
          children: [
            const Text('Paste the appointment email text below, then tap Import.'),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  // optional: show help modal
                },
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Help importing'),
              ),
            ),

            const SizedBox(height: 8),

            // ✅ Smaller paste box
            SizedBox(
              height: 160,
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

            const SizedBox(height: 12),

            // ✅ Import button UNDER the text box
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

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
