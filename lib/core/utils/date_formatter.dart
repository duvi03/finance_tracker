import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _shortDate = DateFormat('dd MMM yyyy');
  static final DateFormat _dayMonth = DateFormat('dd MMM');
  static final DateFormat _fullDate = DateFormat('EEEE, dd MMMM yyyy');

  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatShort(DateTime date) => _shortDate.format(date);
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);
  static String formatFull(DateTime date) => _fullDate.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(target).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    if (diffDays == -1) return 'Tomorrow';
    if (diffDays > 1 && diffDays < 7) return '$diffDays days ago';

    return _shortDate.format(date);
  }
}
