class GoalSchedule {
  const GoalSchedule({required this.startAt, required this.endAt});

  final DateTime startAt;
  final DateTime endAt;
}

final _hourDelay = RegExp(r'(\d+)\s*시간(?:\s*(\d+)\s*분)?\s*(?:뒤|후)에?(?!반)');
final _minuteDelay = RegExp(r'(\d+)\s*분\s*(?:뒤|후)에?(?!반)');

Duration? relativeDelay(String sentence) {
  final hour = _earliest(_hourDelay, sentence);
  final minute = _earliest(_minuteDelay, sentence);
  if (hour == null && minute == null) {
    return null;
  }
  if (hour != null && (minute == null || hour.start <= minute.start)) {
    return Duration(
      hours: int.parse(hour.group(1)!),
      minutes: int.parse(hour.group(2) ?? '0'),
    );
  }
  return Duration(minutes: int.parse(minute!.group(1)!));
}

GoalSchedule scheduleAtRegistration({
  required String sentence,
  required DateTime startAt,
  required DateTime endAt,
  required DateTime registeredAt,
}) {
  final delay = relativeDelay(sentence);
  if (delay == null) {
    return GoalSchedule(startAt: startAt, endAt: endAt);
  }
  final shiftedStart = registeredAt.add(delay);
  final duration = endAt.difference(startAt);
  final shiftedEnd = duration.isNegative ? shiftedStart : shiftedStart.add(duration);
  return GoalSchedule(startAt: shiftedStart, endAt: shiftedEnd);
}

RegExpMatch? _earliest(RegExp pattern, String sentence) {
  RegExpMatch? earliest;
  for (final match in pattern.allMatches(sentence)) {
    if (earliest == null || match.start < earliest.start) {
      earliest = match;
    }
  }
  return earliest;
}
