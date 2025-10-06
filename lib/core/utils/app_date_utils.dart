class AppDateUtils {
  AppDateUtils._();

  static DateTime? _cachedNow;
  static int? _cacheTimestamp;

  static DateTime get now {
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_cacheTimestamp != currentTimestamp || _cachedNow == null) {
      _cachedNow = DateTime.now();
      _cacheTimestamp = currentTimestamp;
    }
    return _cachedNow!;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime? tryParse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static int daysSinceEpoch(DateTime date) {
    return date.millisecondsSinceEpoch ~/ 86400000;
  }
}
