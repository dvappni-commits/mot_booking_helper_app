class MotAppointment {
  final String id;

  /// The day the appointment is on (calendar day)
  final DateTime date;

  final String registration;
  final String testCentre;
  final String lane;

  /// HH:mm
  final String time;

  /// Optional booking reference from the letter/email
  final String? bookingRef;

  /// Optional "Last Date to Change or Cancel" timestamp
  final DateTime? lastChangeDateTime;

  /// When the entry was created/last saved in the app
  final DateTime createdAt;

  MotAppointment({
    required this.id,
    required this.date,
    required this.registration,
    required this.testCentre,
    required this.lane,
    required this.time,
    this.bookingRef,
    this.lastChangeDateTime,
    required this.createdAt,
  });

  MotAppointment copyWith({
    String? id,
    DateTime? date,
    String? registration,
    String? testCentre,
    String? lane,
    String? time,
    String? bookingRef,
    DateTime? lastChangeDateTime,
    DateTime? createdAt,
  }) {
    return MotAppointment(
      id: id ?? this.id,
      date: date ?? this.date,
      registration: registration ?? this.registration,
      testCentre: testCentre ?? this.testCentre,
      lane: lane ?? this.lane,
      time: time ?? this.time,
      bookingRef: bookingRef ?? this.bookingRef,
      lastChangeDateTime: lastChangeDateTime ?? this.lastChangeDateTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'registration': registration,
    'testCentre': testCentre,
    'lane': lane,
    'time': time,
    'bookingRef': bookingRef,
    'lastChangeDateTime': lastChangeDateTime?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  static MotAppointment fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v, {DateTime? fallback}) {
      if (v is String) {
        final d = DateTime.tryParse(v);
        if (d != null) return d;
      }
      return fallback ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic v) {
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final booking = json['bookingRef'];
    final bookingStr = booking == null ? '' : booking.toString().trim();

    return MotAppointment(
      id: (json['id'] ?? '').toString(),
      date: parseDate(json['date']),
      registration: (json['registration'] ?? '').toString(),
      testCentre: (json['testCentre'] ?? '').toString(),
      lane: (json['lane'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      bookingRef: bookingStr.isEmpty ? null : bookingStr,
      lastChangeDateTime: parseNullableDate(json['lastChangeDateTime']),
      createdAt: parseDate(json['createdAt']),
    );
  }
}