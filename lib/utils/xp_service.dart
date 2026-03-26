import '../models/models.dart';

class XpService {
  /// 打卡基础 XP
  static const int baseCheckInXP = 10;

  /// 完成全部杠杆额外奖励 XP
  static const int allLeversBonusXP = 5;

  /// 连续打卡额外奖励（每7天）
  static const int streakBonusXP = 3;

  /// 每日首次登录奖励
  static const int dailyLoginXP = 2;

  /// 计算打卡获得的 XP
  static int calculateCheckInXP({
    required int completedLevers,
    required int totalLevers,
    required int currentStreak,
  }) {
    int xp = baseCheckInXP;

    // 完成全部杠杆
    if (completedLevers == totalLevers && totalLevers > 0) {
      xp += allLeversBonusXP;
    }

    // 连续打卡加成（每7天）
    final streakBonus = (currentStreak ~/ 7) * streakBonusXP;
    xp += streakBonus;

    return xp;
  }

  /// 计算升级所需 XP（每级需要的 XP = 等级 * 100）
  static int xpForLevel(int level) {
    return level * 100;
  }

  /// 计算当前等级
  static int calculateLevel(int totalXP) {
    int level = 1;
    int xpUsed = 0;
    while (true) {
      int needed = xpForLevel(level);
      if (xpUsed + needed > totalXP) {
        break;
      }
      xpUsed += needed;
      level++;
    }
    return level;
  }

  /// 计算当前等级剩余 XP
  static int calculateCurrentLevelXP(int totalXP) {
    int level = 1;
    int xpUsed = 0;
    while (true) {
      int needed = xpForLevel(level);
      if (xpUsed + needed > totalXP) {
        break;
      }
      xpUsed += needed;
      level++;
    }
    return totalXP - xpUsed;
  }

  /// 升级后获得的经验（用于过渡动画）
  static int xpToNextLevel(int level) {
    return xpForLevel(level);
  }

  /// 升级进度百分比
  static double levelProgress(int totalXP) {
    final level = calculateLevel(totalXP);
    final currentXP = calculateCurrentLevelXP(totalXP);
    final needed = xpForLevel(level);
    if (needed == 0) return 1.0;
    return currentXP / needed;
  }

  /// 从 UserStats 计算升级后的新状态
  static UserStats addXP(UserStats stats, int xp) {
    final newTotalXP = stats.totalXP + xp;
    final newLevel = calculateLevel(newTotalXP);
    final newCurrentXP = calculateCurrentLevelXP(newTotalXP);

    return UserStats(
      level: newLevel,
      currentXP: newCurrentXP,
      totalXP: newTotalXP,
      streak: stats.streak,
      totalCheckIns: stats.totalCheckIns,
    );
  }

  /// 检查是否升级了
  static bool didLevelUp(UserStats oldStats, UserStats newStats) {
    return newStats.level > oldStats.level;
  }

  /// 徽章解锁规则检查
  static List<AppBadge> checkBadgeUnlocks({
    required List<AppBadge> currentBadges,
    required int totalCheckIns,
    required int currentStreak,
    required bool yearGoalAchieved,
  }) {
    final updated = currentBadges.map((badge) {
      if (badge.isUnlocked) return badge;

      bool shouldUnlock = false;

      switch (badge.id) {
        case '1':
          // 初次行动
          shouldUnlock = totalCheckIns >= 1;
          break;
        case '2':
          // 连续7天
          shouldUnlock = currentStreak >= 7;
          break;
        case '3':
          // 连续30天
          shouldUnlock = currentStreak >= 30;
          break;
        case '4':
          // 完成100次
          shouldUnlock = totalCheckIns >= 100;
          break;
        case '5':
          // 年度目标达成
          shouldUnlock = yearGoalAchieved;
          break;
      }

      if (shouldUnlock) {
        return AppBadge(
          id: badge.id,
          name: badge.name,
          description: badge.description,
          icon: badge.icon,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
      }

      return badge;
    }).toList();

    return updated;
  }

  /// 获取新解锁的徽章
  static List<AppBadge> getNewlyUnlockedBadges(List<AppBadge> oldBadges, List<AppBadge> newBadges) {
    final newList = <AppBadge>[];
    for (int i = 0; i < newBadges.length; i++) {
      if (newBadges[i].isUnlocked && !oldBadges[i].isUnlocked) {
        newList.add(newBadges[i]);
      }
    }
    return newList;
  }

  /// 等级名称
  static String levelTitle(int level) {
    if (level <= 5) return '初出茅庐';
    if (level <= 10) return '小有所成';
    if (level <= 20) return '稳步前行';
    if (level <= 30) return '渐入佳境';
    if (level <= 50) return '驾轻就熟';
    if (level <= 80) return '炉火纯青';
    if (level <= 100) return '出神入化';
    return '登峰造极';
  }
}
