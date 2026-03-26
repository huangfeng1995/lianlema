/// 日报模型
class DailyReport {
  final DateTime date;
  final int completedLevers;
  final int totalLevers;
  final int xpEarned;
  final int streak;
  final List<String> completedContents;

  DailyReport({
    required this.date,
    required this.completedLevers,
    required this.totalLevers,
    required this.xpEarned,
    required this.streak,
    required this.completedContents,
  });
}

/// 周报模型
class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int checkInDays;
  final int totalDays;
  final int longestStreak;
  final int xpEarned;
  final int previousWeekDays;
  final List<String> highlights;

  WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.checkInDays,
    required this.totalDays,
    required this.longestStreak,
    required this.xpEarned,
    required this.previousWeekDays,
    required this.highlights,
  });
}

/// 月报模型
class MonthlyReport {
  final int year;
  final int month;
  final int checkInDays;
  final int totalDays;
  final bool bossDefeated;
  final int bossTotalHp;
  final int longestStreak;
  final int xpEarned;
  final List<String> badgesEarned;
  final String? newIdentity;

  MonthlyReport({
    required this.year,
    required this.month,
    required this.checkInDays,
    required this.totalDays,
    required this.bossDefeated,
    required this.bossTotalHp,
    required this.longestStreak,
    required this.xpEarned,
    required this.badgesEarned,
    this.newIdentity,
  });
}

/// 年报模型
class YearlyReport {
  final int year;
  final int totalCheckInDays;
  final int bossesDefeated;
  final int longestStreak;
  final int totalXP;
  final int level;
  final List<String> badgesEarned;
  final String? yearlyReflection;

  YearlyReport({
    required this.year,
    required this.totalCheckInDays,
    required this.bossesDefeated,
    required this.longestStreak,
    required this.totalXP,
    required this.level,
    required this.badgesEarned,
    this.yearlyReflection,
  });
}
