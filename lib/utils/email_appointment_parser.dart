class ParsedAppointment {
  final String? registration;
  final String? testCentre; // short name (e.g. Boucher, Ards, Newbuildings)
  final String? lane;
  final String? time; // HH:mm
  final String? bookingRef;
  final DateTime? date;

  /// "Last Date to Change or Cancel: Friday, 19 December 2025 before 10:45"
  final DateTime? lastChangeDateTime;

  const ParsedAppointment({
    this.registration,
    this.testCentre,
    this.lane,
    this.time,
    this.bookingRef,
    this.date,
    this.lastChangeDateTime,
  });

  bool get hasAnything =>
      (registration?.isNotEmpty ?? false) ||
          (testCentre?.isNotEmpty ?? false) ||
          (lane?.isNotEmpty ?? false) ||
          (time?.isNotEmpty ?? false) ||
          (bookingRef?.isNotEmpty ?? false) ||
          date != null ||
          lastChangeDateTime != null;
}

class EmailAppointmentParser {
  static ParsedAppointment parse(String text) {
    final t = _normalise(text);

    final lane = _matchGroup(
      t,
      RegExp(r'on\s*arrival\s*:\s*go\s*to\s*lane\s*(\d+)', caseSensitive: false),
      1,
    );

    final bookingRef = _matchGroup(
      t,
      RegExp(r'booking\s*ref\s*:\s*([0-9]{6,})', caseSensitive: false),
      1,
    );

    final time = _matchGroup(
      t,
      RegExp(r'time\s*:\s*((?:[01]\d|2[0-3]):[0-5]\d)', caseSensitive: false),
      1,
    );

    final registration = _matchGroup(
      t,
      RegExp(
        r'reg\s*mark(?:\/id\s*mark)?\s*:\s*([A-Z0-9]{4,10})',
        caseSensitive: false,
      ),
      1,
    )?.toUpperCase();

    // ✅ Extract, clean, then map to short NI names
    final rawCentre = _matchGroup(
      t,
      RegExp(r'test\s*centre\s*:\s*([A-Z \-]{3,60})', caseSensitive: false),
      1,
    );

    final testCentre = _shortCentreName(rawCentre);

    final dateStr = _matchGroup(
      t,
      RegExp(
        r'date\s*:\s*([A-Za-z]+,\s*\d{1,2}\s+[A-Za-z]+\s+\d{4})',
        caseSensitive: false,
      ),
      1,
    );

    final date = _parseDvaDate(dateStr);

    DateTime? lastChangeDateTime;
    final m = RegExp(
      r'last\s*date\s*to\s*change\s*or\s*cancel\s*:\s*([A-Za-z]+,\s*\d{1,2}\s+[A-Za-z]+\s+\d{4})\s*before\s*([01]\d|2[0-3]):([0-5]\d)',
      caseSensitive: false,
    ).firstMatch(t);

    if (m != null) {
      final d = _parseDvaDate(m.group(1));
      final hh = int.tryParse(m.group(2)!);
      final mm = int.tryParse(m.group(3)!);
      if (d != null && hh != null && mm != null) {
        lastChangeDateTime = DateTime(d.year, d.month, d.day, hh, mm);
      }
    }

    return ParsedAppointment(
      registration: registration,
      testCentre: testCentre,
      lane: lane,
      time: time,
      bookingRef: bookingRef,
      date: date,
      lastChangeDateTime: lastChangeDateTime,
    );
  }

  static String _normalise(String input) {
    final t = input.replaceAll('\r', '');
    final noMd = t.replaceAll(RegExp(r'\*+'), '');
    final collapsedSpaces = noMd.replaceAll(RegExp(r'[ \t]+'), ' ');
    return collapsedSpaces.trim();
  }

  static String? _matchGroup(String input, RegExp re, int group) {
    final m = re.firstMatch(input);
    if (m == null) return null;
    final s = m.group(group);
    if (s == null) return null;
    final out = s.trim();
    return out.isEmpty ? null : out;
  }

  /// ✅ Converts raw DVA centre lines into short names:
  /// Belfast -> Boucher, Newtownards -> Ards, Londonderry -> Newbuildings
  static String? _shortCentreName(String? raw) {
    if (raw == null) return null;

    // Normalise
    var s = raw.trim().toUpperCase();

    // Strip common suffix noise
    const removeWords = [
      'TEST CENTRE',
      'TEST CENTER',
      'ADDRESS',
    ];
    for (final w in removeWords) {
      s = s.replaceAll(w, '');
    }

    // Cleanup
    s = s.replaceAll(',', ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.isEmpty) return null;

    // Map to your preferred short names
    // (use contains() so it still matches e.g. "BELFAST (BOUCHER ROAD)" etc.)
    if (s.contains('BELFAST')) return 'Boucher';
    if (s.contains('NEWTOWNARDS')) return 'Ards';
    if (s.contains('LONDONDERRY') || s.contains('DERRY')) return 'Newbuildings';

    // Default: Title Case (ARMAGH -> Armagh)
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static DateTime? _parseDvaDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    final m = RegExp(r'^[A-Za-z]+,\s*(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$')
        .firstMatch(dateStr.trim());
    if (m == null) return null;

    final day = int.tryParse(m.group(1)!);
    final monthName = m.group(2)!.toLowerCase();
    final year = int.tryParse(m.group(3)!);
    final month = _monthToInt(monthName);

    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  static int? _monthToInt(String m) {
    switch (m) {
      case 'january':
        return 1;
      case 'february':
        return 2;
      case 'march':
        return 3;
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'june':
        return 6;
      case 'july':
        return 7;
      case 'august':
        return 8;
      case 'september':
        return 9;
      case 'october':
        return 10;
      case 'november':
        return 11;
      case 'december':
        return 12;
      default:
        return null;
    }
  }
}