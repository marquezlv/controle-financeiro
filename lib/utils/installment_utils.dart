/// Adds [months] months to [date], clamping the day to the last day of the
/// resulting month so that e.g. January 31 + 1 month = February 28/29.
DateTime addMonths(DateTime date, int months) {
  final year = date.year + ((date.month - 1 + months) ~/ 12);
  final month = ((date.month - 1 + months) % 12) + 1;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final day = date.day.clamp(1, lastDayOfMonth);
  return DateTime(year, month, day, date.hour, date.minute, date.second,
      date.millisecond, date.microsecond);
}
