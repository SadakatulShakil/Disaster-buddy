/// Shared local-calendar-day helpers used by the daily challenge and streak
/// logic. Centralised so every date comparison in that feature uses the
/// exact same "local midnight" normalisation and `yyyy-MM-dd` key format —
/// getting this wrong in just one place would silently break streak math
/// across a timezone/day rollover.
class LocalDay {
  LocalDay._();

  /// Strips the time-of-day, keeping only the local calendar date.
  static DateTime normalize(DateTime dateTime) => DateTime(dateTime.year, dateTime.month, dateTime.day);

  /// A stable `yyyy-MM-dd` key for [dateTime]'s local calendar date, used as
  /// the Floor primary key for one day's completion row.
  static String keyFor(DateTime dateTime) {
    final day = normalize(dateTime);
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$year-$month-$date';
  }

  /// Parses a key produced by [keyFor] back into a normalized local date.
  static DateTime parseKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}
