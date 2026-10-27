import 'package:flutter/material.dart';

String goalTimeLabel(BuildContext context, DateTime time) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatShortDate(time);
  final clock = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(time),
    alwaysUse24HourFormat: true,
  );
  return '$date $clock';
}

String remainingMinutesSeconds(DateTime until, DateTime now) {
  final remaining = until.difference(now);
  final duration = remaining.isNegative ? Duration.zero : remaining;
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String goalWindowLabel(BuildContext context, DateTime start, DateTime end) {
  final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
  final startLabel = goalTimeLabel(context, start);
  if (!sameDay) {
    return '$startLabel ~ ${goalTimeLabel(context, end)}';
  }
  final endClock = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(end),
    alwaysUse24HourFormat: true,
  );
  return '$startLabel ~ $endClock';
}
