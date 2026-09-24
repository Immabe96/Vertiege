import 'dart:async';

import 'package:flutter/material.dart';

/// Returns a human-readable relative time string for the given [dateTime].
///
/// Example outputs:
/// - "just now" for durations under 1 minute
/// - "5m ago" for durations under 60 minutes
/// - "3h ago" for durations under 24 hours
/// - "2d ago" for durations under 7 days
/// - "1w ago" for durations under 30 days
/// - "3mo ago" for durations under 12 months
/// - "2y ago" for durations of 12 months or more
String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) {
    return 'just now';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  } else if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  } else if (diff.inDays < 30) {
    return '${diff.inDays ~/ 7}w ago';
  } else if (diff.inDays < 365) {
    return '${diff.inDays ~/ 30}mo ago';
  } else {
    return '${diff.inDays ~/ 365}y ago';
  }
}

/// A [StatefulWidget] that displays a relative time string via [timeAgo] and
/// auto-updates every minute.
///
/// Takes a [DateTime] and an optional [TextStyle]. Rebuilds when the widget is
/// still mounted to keep the label current (e.g. "just now" -> "1m ago").
class TimeAgo extends StatefulWidget {
  const TimeAgo(this.dateTime, {super.key, this.style});

  final DateTime dateTime;
  final TextStyle? style;

  @override
  State<TimeAgo> createState() => _TimeAgoState();
}

class _TimeAgoState extends State<TimeAgo> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(timeAgo(widget.dateTime), style: widget.style);
  }
}

/// Formats a [DateTime] for chat message timestamps.
///
/// Returns:
/// - "Today 2:30 PM" when the message occurred today
/// - "Yesterday" when the message occurred yesterday
/// - "Mon, 2:30 PM" when within the last 7 days
/// - "Jan 15, 2:30 PM" when within the current year
/// - "Jan 15, 2024, 2:30 PM" for older dates
String formatChatTime(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = today.difference(dateDay).inDays;

  final hour = dateTime.hour > 12
      ? dateTime.hour - 12
      : dateTime.hour == 0
      ? 12
      : dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  final timeStr = '$hour:$minute $period';

  if (diff == 0) {
    return 'Today $timeStr';
  } else if (diff == 1) {
    return 'Yesterday';
  } else if (diff < 7) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[dateTime.weekday - 1]}, $timeStr';
  } else if (dateTime.year == now.year) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, $timeStr';
  } else {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}, $timeStr';
  }
}
