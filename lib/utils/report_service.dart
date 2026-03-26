import '../models/models.dart';
import '../models/report_models.dart';
import 'storage_service.dart';
import 'xp_service.dart';
import 'date_utils.dart' as app_date;

class ReportService {
  final StorageService _storage;

  ReportService(this._storage);

  /// 生成日报
  DailyReport generateDailyReport(DateTime date) {
    final levers = _storage.getDailyLevers();
    final checkIns = _storage.getCheckIns();

    final dateStr = app_date.AppDateUtils.formatDate(date);
    final todayCheckIn = checkIns.where(
      (c) => app_date.AppDateUtils.formatDate(c.date) == dateStr,
    ).toList();

    final completedIds = todayCheckIn.isNotEmpty ? todayCheckIn.first.leverIds : <String>[];
    final completedLevers = completedIds.length;
    final totalLevers = levers.length;

    final completedContents = levers.asMap().entries
        .where((e) => completedIds.contains('${e.key}'))
        .map((e) => e.value)
        .toList();

    final checkInDates = checkIns.map((c) => c.date).toList();
    final streak = app_date.AppDateUtils.calculateStreak(checkInDates);

    final xpEarned = XpService.calculateCheckInXP(
      completedLevers: completedLevers,
      totalLevers: totalLevers,
      currentStreak: streak,
    );

    return DailyReport(
      date: date,
      completedLevers: completedLevers,
      totalLevers: totalLevers,
      xpEarned: xpEarned,
      streak: streak,
      completedContents: completedContents,
    );
  }

  /// 生成周报
  WeeklyReport generateWeeklyReport(DateTime weekEnd) {
    final weekStart = weekEnd.subtract(const Duration(days: 6));
    final checkIns = _storage.getCheckIns();
    final levers = _storage.getDailyLevers();

    final thisWeekDays = <DateTime>[];
    for (int i = 0; i < 7; i++) {
      final d = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
      final dStr = app_date.AppDateUtils.formatDate(d);
      final hasCheckIn = checkIns.any((c) => app_date.AppDateUtils.formatDate(c.date) == dStr);
      if (hasCheckIn) {
        thisWeekDays.add(d);
      }
    }

    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevWeekDays = <DateTime>[];
    for (int i = 0; i < 7; i++) {
      final d = DateTime(prevWeekStart.year, prevWeekStart.month, prevWeekStart.day + i);
      final dStr = app_date.AppDateUtils.formatDate(d);
      final hasCheckIn = checkIns.any((c) => app_date.AppDateUtils.formatDate(c.date) == dStr);
      if (hasCheckIn) {
        prevWeekDays.add(d);
      }
    }

    final checkInDates = checkIns.map((c) => c.date).toList();
    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? prevDate;

    final allSorted = [...checkInDates]..sort();
    for (final d in allSorted) {
      if (prevDate == null) {
        currentStreak = 1;
      } else {
        final diff = d.difference(prevDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          if (currentStreak > longestStreak) longestStreak = currentStreak;
          currentStreak = 1;
        }
      }
      prevDate = d;
    }
    if (currentStreak > longestStreak) longestStreak = currentStreak;

    int weekXp = 0;
    for (final d in thisWeekDays) {
      final dStr = app_date.AppDateUtils.formatDate(d);
      final checkIn = checkIns.where(
        (c) => app_date.AppDateUtils.formatDate(c.date) == dStr,
      ).toList();
      if (checkIn.isNotEmpty) {
        final completedLevers = checkIn.first.leverIds.length;
        weekXp += XpService.calculateCheckInXP(
          completedLevers: completedLevers,
          totalLevers: levers.length,
          currentStreak: 0,
        );
      }
    }

    final highlights = _generateWeeklyHighlights(thisWeekDays.length, prevWeekDays.length);

    return WeeklyReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      checkInDays: thisWeekDays.length,
      totalDays: 7,
      longestStreak: longestStreak,
      xpEarned: weekXp,
      previousWeekDays: prevWeekDays.length,
      highlights: highlights,
    );
  }

  List<String> _generateWeeklyHighlights(int thisWeek, int prevWeek) {
    final highlights = <String>[];
    if (thisWeek >= 7) {
      highlights.add('🌟 本周全勤！太棒了');
    } else if (thisWeek > prevWeek) {
      highlights.add('📈 比上周多了${thisWeek - prevWeek}天，继续加油');
    } else if (thisWeek < prevWeek) {
      highlights.add('💪 下周要迎头赶上');
    }
    if (thisWeek >= 5) {
      highlights.add('🔥 打卡习惯已养成');
    }
    return highlights;
  }

  /// 生成月报
  MonthlyReport generateMonthlyReport(int year, int month) {
    final checkIns = _storage.getCheckIns();
    final levers = _storage.getDailyLevers();
    final badges = _storage.getBadges();
    final monthlyBoss = _storage.getMonthlyBoss();
    final stats = _storage.getUserStats();

    final monthCheckIns = checkIns.where((c) => c.date.year == year && c.date.month == month).toList();
    final checkInDays = monthCheckIns.length;

    final totalDays = DateTime(year, month + 1, 0).day;

    final checkInDates = checkIns.map((c) => c.date).toList();
    final streak = app_date.AppDateUtils.calculateStreak(checkInDates);

    final monthLevers = levers.length;
    int monthXp = 0;
    for (final c in monthCheckIns) {
      monthXp += XpService.calculateCheckInXP(
        completedLevers: c.leverIds.length,
        totalLevers: monthLevers,
        currentStreak: 0,
      );
    }

    bool bossDefeated = false;
    int bossTotalHp = 0;
    if (monthlyBoss != null && monthlyBoss.year == year && monthlyBoss.month == month) {
      bossTotalHp = monthlyBoss.totalDays;
      bossDefeated = monthlyBoss.hp >= monthlyBoss.totalDays;
    }

    final now = DateTime.now();
    final badgesEarnedThisMonth = badges
        .where((b) => b.isUnlocked && b.unlockedAt != null &&
            b.unlockedAt!.year == year && b.unlockedAt!.month == month)
        .map((b) => '${b.icon} ${b.name}')
        .toList();

    String? newIdentity;
    if (now.year == year && now.month == month) {
      newIdentity = XpService.levelTitle(stats.level);
    }

    return MonthlyReport(
      year: year,
      month: month,
      checkInDays: checkInDays,
      totalDays: totalDays,
      bossDefeated: bossDefeated,
      bossTotalHp: bossTotalHp,
      longestStreak: streak,
      xpEarned: monthXp,
      badgesEarned: badgesEarnedThisMonth,
      newIdentity: newIdentity,
    );
  }

  /// 生成年报
  YearlyReport generateYearlyReport(int year) {
    final checkIns = _storage.getCheckIns();
    final badges = _storage.getBadges();
    final stats = _storage.getUserStats();

    final yearCheckIns = checkIns.where((c) => c.date.year == year).toList();
    final totalCheckInDays = yearCheckIns.length;

    final checkInDates = checkIns.map((c) => c.date).toList();
    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? prevDate;

    final sortedDates = [...checkInDates]..sort((a, b) => a.compareTo(b));
    for (final d in sortedDates) {
      if (prevDate == null) {
        currentStreak = 1;
      } else {
        final diff = d.difference(prevDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          if (currentStreak > longestStreak) longestStreak = currentStreak;
          currentStreak = 1;
        }
      }
      prevDate = d;
    }
    if (currentStreak > longestStreak) longestStreak = currentStreak;

    int bossesDefeated = 0;
    for (int m = 1; m <= 12; m++) {
      final boss = _getMonthlyBossForMonth(year, m);
      if (boss != null && boss.hp >= boss.totalDays) {
        bossesDefeated++;
      }
    }

    final badgesEarnedThisYear = badges
        .where((b) => b.isUnlocked && b.unlockedAt != null &&
            b.unlockedAt!.year == year)
        .map((b) => '${b.icon} ${b.name}')
        .toList();

    return YearlyReport(
      year: year,
      totalCheckInDays: totalCheckInDays,
      bossesDefeated: bossesDefeated,
      longestStreak: longestStreak,
      totalXP: stats.totalXP,
      level: stats.level,
      badgesEarned: badgesEarnedThisYear,
      yearlyReflection: null,
    );
  }

  MonthlyBoss? _getMonthlyBossForMonth(int year, int month) {
    final boss = _storage.getMonthlyBoss();
    if (boss == null) return null;
    if (boss.year == year && boss.month == month) {
      return boss;
    }
    return null;
  }

  /// 获取一句话日报摘要
  String getDailySummary() {
    final today = DateTime.now();
    final report = generateDailyReport(today);
    if (report.completedLevers == 0) {
      return '今天还没有打卡，快去完成行动吧！';
    } else if (report.completedLevers == report.totalLevers) {
      return '🎉 今天完美完成！获得${report.xpEarned}XP，连续${report.streak}天';
    } else {
      return '今日已完成${report.completedLevers}/${report.totalLevers}个杠杆 🔥${report.streak}天连续';
    }
  }

  /// 获取一句话周报摘要
  String getWeeklySummary() {
    final now = DateTime.now();
    final weekEnd = DateTime(now.year, now.month, now.day);
    final report = generateWeeklyReport(weekEnd);
    if (report.checkInDays == 0) {
      return '本周还没有打卡记录';
    } else if (report.checkInDays >= 6) {
      return '🌟 本周出勤${report.checkInDays}/7天，继续保持！';
    } else {
      final diff = (report.checkInDays - report.previousWeekDays).abs();
      return '本周打卡${report.checkInDays}/7天，比上周${report.checkInDays > report.previousWeekDays ? '多' : '少'}$diff天';
    }
  }

  /// 检查某天是否有打卡
  bool hasCheckInOnDay(DateTime date) {
    final checkIns = _storage.getCheckIns();
    final dateStr = app_date.AppDateUtils.formatDate(date);
    return checkIns.any((c) => app_date.AppDateUtils.formatDate(c.date) == dateStr);
  }

  /// 获取某天的打卡杠杆数
  int getCheckInLeversCount(DateTime date) {
    final checkIns = _storage.getCheckIns();
    final dateStr = app_date.AppDateUtils.formatDate(date);
    final todayCheckIn = checkIns.where(
      (c) => app_date.AppDateUtils.formatDate(c.date) == dateStr,
    ).toList();
    return todayCheckIn.isNotEmpty ? todayCheckIn.first.leverIds.length : 0;
  }
}
