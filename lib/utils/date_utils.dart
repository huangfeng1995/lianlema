import 'package:intl/intl.dart';

class AppDateUtils {
  /// 判断两个日期是否是同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判断日期是否是今天
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// 判断日期是否是昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// 将日期格式化为 yyyy-MM-dd
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 将日期格式化为 MM月dd日
  static String formatMonthDay(DateTime date) {
    return DateFormat('MM月dd日').format(date);
  }

  /// 将日期格式化为中文星期
  static String formatWeekday(DateTime date) {
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekdays[date.weekday - 1];
  }

  /// 获取日期所在月的第一天
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取日期所在月的最后一天
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 获取某月的总天数
  static int daysInMonth(DateTime date) {
    return lastDayOfMonth(date).day;
  }

  /// 获取某月第一天是星期几（1=周一, 7=周日）
  static int firstWeekdayOfMonth(DateTime date) {
    return firstDayOfMonth(date).weekday;
  }

  /// 获取两个日期之间的天数（不含首尾）
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  /// 获取连续打卡天数
  static int calculateStreak(List<DateTime> checkInDates) {
    if (checkInDates.isEmpty) return 0;

    // 排序（降序）
    final sortedDates = checkInDates.toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterdayOnly = todayOnly.subtract(const Duration(days: 1));

    // 检查今天或昨天是否打卡
    final latestDate = DateTime(sortedDates.first.year, sortedDates.first.month, sortedDates.first.day);
    if (!isSameDay(latestDate, todayOnly) && !isSameDay(latestDate, yesterdayOnly)) {
      return 0;
    }

    int streak = 1;
    DateTime current = latestDate;

    for (int i = 1; i < sortedDates.length; i++) {
      final prev = DateTime(sortedDates[i].year, sortedDates[i].month, sortedDates[i].day);
      final diff = current.difference(prev).inDays;

      if (diff == 1) {
        streak++;
        current = prev;
      } else if (diff == 0) {
        // 同一天不计算
        continue;
      } else {
        break;
      }
    }

    return streak;
  }

  /// 获取本月打卡天数
  static int getMonthlyCheckInCount(List<DateTime> checkInDates) {
    final now = DateTime.now();
    return checkInDates.where((d) => d.year == now.year && d.month == now.month).length;
  }

  /// 解析日期字符串
  static DateTime? parseDate(String? str) {
    if (str == null || str.isEmpty) return null;
    try {
      return DateTime.parse(str);
    } catch (_) {
      return null;
    }
  }
}
