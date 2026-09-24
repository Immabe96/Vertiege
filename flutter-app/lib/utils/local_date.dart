/// Local calendar date helpers for streak check-in (device timezone).
String localDateKey([DateTime? when]) {
  final dt = when ?? DateTime.now();
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Stored on [profiles.timezone] when IANA is unavailable (offset label).
String deviceTimezoneLabel([DateTime? when]) {
  final offset = (when ?? DateTime.now()).timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final totalMinutes = offset.inMinutes.abs();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return 'UTC$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}
