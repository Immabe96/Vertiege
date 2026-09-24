import 'time_ago.dart';

/// Bridge to new relative-time formatter so all existing callers
/// automatically gain weekly / monthly / yearly granularity.
String formatTimestamp(int ts) =>
    timeAgo(DateTime.fromMillisecondsSinceEpoch(ts));
