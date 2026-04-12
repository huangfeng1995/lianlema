import 'dart:math';
import '../models/pet_models.dart';
import '../utils/storage_service.dart';
import '../utils/pet_service.dart';

/// 宠物主动推送类型
enum PushType {
  /// 打卡提醒（前期）
  streakReminder,
  /// 里程碑逼近（权重最高）
  milestoneApproaching,
  /// 懈怠关怀
  idleWarning,
  /// 周复盘
  weeklySummary,
  /// 挑战进度
  challengeProgress,
  /// 障碍引导（Day2 或 streak 断了后，WOOP 探索）
  obstacleGuidance,
  /// 年度计划引导（使用7天后，未填写愿景/目标）
  annualPlanGuide,
}

/// 一条推送
class PetPush {
  final String id;
  final PushType type;
  final String title;
  final String body;
  final DateTime createdAt;
  double weight;

  PetPush({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.weight = 1.0,
  });
}

/// 宠物主动推送服务
/// 负责：
/// 1. 每日推送队列生成
/// 2. 权重动态调整
/// 3. 行为反馈记录
/// 4. 激励有效性学习
class PetPushService {
  static final PetPushService instance = PetPushService._();
  PetPushService._();
  static const int _maxDailyPushes = 4;
  static const int _minIntervalHours = 4;
  static const double _maxWeight = 2.0;
  static const double _minWeight = 0.1;
  static const int _decayDays = 14; // streakReminder 衰减周期

  Random _random = Random();

  /// 推断 PushType 对应的激励类型
  EncouragementType _inferEncouragementType(PushType type, String body) {
    final lower = body.toLowerCase();
    if (lower.contains('数据') || lower.contains('%') || lower.contains('率')) {
      return EncouragementType.dataDriven;
    }
    if (lower.contains('厉害') || lower.contains('太棒') || lower.contains('加油') ||
        lower.contains('坚持') || lower.contains('进步')) {
      return EncouragementType.encouragement;
    }
    if (lower.contains('想') || lower.contains('陪') || lower.contains('理解') ||
        lower.contains('休息')) {
      return EncouragementType.warmCompanion;
    }
    if (lower.contains('？') && lower.length < 40) {
      return EncouragementType.silentSupport;
    }
    switch (type) {
      case PushType.streakReminder:
        return EncouragementType.encouragement;
      case PushType.milestoneApproaching:
        return EncouragementType.encouragement;
      case PushType.idleWarning:
        return EncouragementType.warmCompanion;
      case PushType.weeklySummary:
        return EncouragementType.dataDriven;
      case PushType.challengeProgress:
        return EncouragementType.dataDriven;
      case PushType.obstacleGuidance:
        return EncouragementType.warmCompanion;
      case PushType.annualPlanGuide:
        return EncouragementType.warmCompanion;
    }
  }

  /// 发送推送时调用：记录激励类型供后续评估
  Future<void> onPushSent(PetPush push) async {
    final type = _inferEncouragementType(push.type, push.body);
    await PetService.instance.recordEncouragement(type, push.body);
  }

  /// 用户打卡时调用：评估昨日激励的有效性
  Future<void> onCheckIn({required bool checkedInToday}) async {
    await PetService.instance.evaluateEncouragementEffectiveness(
      checkedInToday: checkedInToday,
    );
  }

  /// 生成自主感支持版本的打卡督促（用于推送和 UI 展示）
  String generateAutonomousNudge(PetContext ctx) {
    return PetService.instance.generateAutonomousCheckInNudge(ctx);
  }

  /// 生成今日推送队列（基于用户上下文）
  Future<List<PetPush>> generateDailyPushes(PetContext ctx) async {
    final pushes = <PetPush>[];

    // 1. 里程碑逼近（最高优先级）
    if (_nearMilestone(ctx.streak)) {
      pushes.add(PetPush(
        id: 'm${DateTime.now().millisecondsSinceEpoch}',
        type: PushType.milestoneApproaching,
        title: _milestoneTitle(ctx.streak),
        body: _milestoneBody(ctx.streak),
        createdAt: DateTime.now(),
        weight: 1.0,
      ));
    }

    // 2. 懈怠关怀（根据用户激励偏好定制）
    if (!ctx.checkedInToday && ctx.streak > 3) {
      final bestType = PetService.instance.getMostEffectiveType();
      pushes.add(PetPush(
        id: 'i${DateTime.now().millisecondsSinceEpoch}',
        type: PushType.idleWarning,
        title: _getIdleWarningTitle(bestType),
        body: _generatePersonalizedIdleWarning(bestType, ctx),
        createdAt: DateTime.now(),
        weight: 1.0,
      ));
    }

    // 3. 打卡提醒（仅前14天，根据激励偏好定制）
    if (ctx.totalCheckIns < 14) {
      final bestType = PetService.instance.getMostEffectiveType();
      pushes.add(PetPush(
        id: 's${DateTime.now().millisecondsSinceEpoch}',
        type: PushType.streakReminder,
        title: _getStreakReminderTitle(bestType),
        body: _generatePersonalizedReminder(bestType, ctx),
        createdAt: DateTime.now(),
        weight: 1.0,
      ));
    }

    // 4. 挑战进度（月末冲刺）
    if (_isMonthEnd() && ctx.currentBossHp > ctx.currentBossTotal * 0.5) {
      pushes.add(PetPush(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        type: PushType.challengeProgress,
        title: '本月挑战冲刺 🏃',
        body: '还差 ${ctx.currentBossTotal - ctx.currentBossHp} 天就完成了，月底冲刺！',
        createdAt: DateTime.now(),
        weight: 0.8,
      ));
    }

    // 5. 周复盘（周日）
    if (DateTime.now().weekday == DateTime.sunday) {
      pushes.add(PetPush(
        id: 'w${DateTime.now().millisecondsSinceEpoch}',
        type: PushType.weeklySummary,
        title: '本周复盘 📋',
        body: '这周你坚持了 ${min(7, ctx.streak)} 天，有没有哪件小事让你觉得有进步？',
        createdAt: DateTime.now(),
        weight: 0.6,
      ));
    }

    // 6. 障碍引导（Day2 或 streak 断了）
    // 条件：用户已有 lever 且 obstacle 尚未填写
    final levers = await _getLeversWithoutObstacle();
    if (levers.isNotEmpty) {
      final shouldTrigger = _shouldTriggerObstacleGuidance(ctx);
      if (shouldTrigger) {
        final petService = PetService.instance;
        final body = petService.generateObstacleExploration(levers.first, ctx);
        pushes.add(PetPush(
          id: 'o${DateTime.now().millisecondsSinceEpoch}',
          type: PushType.obstacleGuidance,
          title: '聊聊障碍 🧭',
          body: body.length > 60 ? '${body.substring(0, 60)}...' : body,
          createdAt: DateTime.now(),
          weight: 0.7,
        ));
      }
    }

    // 7. 年度计划引导（使用7天后，未填写愿景/目标）
    final storage = await StorageService.getInstance();
    if (storage.needsAnnualPlanGuide()) {
      final lastGuideStr = storage.getLastAnnualPlanGuideDate();
      final lastGuide = lastGuideStr.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse(lastGuideStr) ?? DateTime.fromMillisecondsSinceEpoch(0);
      // 每7天最多触发一次
      if (DateTime.now().difference(lastGuide).inDays >= 7) {
        final body = await PetService.instance.generateAnnualPlanSuggestion();
        pushes.add(PetPush(
          id: 'a${DateTime.now().millisecondsSinceEpoch}',
          type: PushType.annualPlanGuide,
          title: '一起规划今年？ 🌟',
          body: body,
          createdAt: DateTime.now(),
          weight: 0.5,
        ));
        await storage.saveLastAnnualPlanGuideDate(DateTime.now());
      }
    }

    // 按权重排序后取前4条
    pushes.sort((a, b) => b.weight.compareTo(a.weight));
    return pushes.take(_maxDailyPushes).toList();
  }

  /// 记录用户对某条推送的反馈
  Future<void> recordFeedback(PushType type, bool clicked) async {
    final storage = await StorageService.getInstance();
    final weights = storage.getPushWeights();

    final current = weights[type.index] ?? 1.0;
    final updated = clicked
        ? (current * 1.2).clamp(_minWeight, _maxWeight)
        : (current * 0.8).clamp(_minWeight, _maxWeight);

    weights[type.index] = updated;
    await storage.savePushWeights(weights);
  }

  /// 获取某类型的当前权重
  Future<double> getWeight(PushType type) async {
    final storage = await StorageService.getInstance();
    final weights = storage.getPushWeights();
    return weights[type.index] ?? 1.0;
  }

  // ===== 辅助方法 =====

  bool _nearMilestone(int streak) {
    const milestones = [7, 30, 100, 200, 365];
    for (final m in milestones) {
      if ((streak - m).abs() <= 2) return true;
    }
    return false;
  }

  String _milestoneTitle(int streak) {
    if (streak < 10) return '里程碑在望 🎯';
    if (streak < 35) return '7天里程碑快到了 🔥';
    if (streak < 105) return '30天里程碑在等你 💎';
    return '百日里程碑 🌟';
  }

  String _milestoneBody(int streak) {
    const milestones = [7, 30, 100];
    for (final m in milestones) {
      if ((streak - m).abs() <= 2) {
        return '你已经坚持了 $streak 天，再坚持 ${m - streak} 天就能到达第 $m 天！';
      }
    }
    return '你在接近一个重要里程碑，继续加油！';
  }

  bool _isMonthEnd() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return daysInMonth - now.day <= 3;
  }

  /// 获取尚未填写 obstacle 的 lever plan 列表
  Future<List<String>> _getLeversWithoutObstacle() async {
    final storage = await StorageService.getInstance();
    final levers = storage.getDailyLevers();
    return levers
        .where((l) => l['obstacle']?.isEmpty == true && (l['plan']?.isNotEmpty == true))
        .map((l) => l['plan'] ?? '')
        .toList();
  }

  /// 判断是否应该触发障碍引导
  /// 触发时机：
  /// 1. Day 2：用户刚完成第一次打卡，尚未打卡第二天
  /// 2. Streak 断了：昨天没打卡且 streak > 0
  bool _shouldTriggerObstacleGuidance(PetContext ctx) {
    // Day 2 触发：已完成首次打卡（totalCheckIns >= 1），今天还没打卡
    final isDay2 = ctx.totalCheckIns >= 1 && !ctx.checkedInToday;

    // Streak 断了：之前有 streak，昨天/前天没打卡
    final idleDays = ctx.lastActiveTime != null
        ? DateTime.now().difference(ctx.lastActiveTime!).inDays
        : 0;
    final isStreakBroken = ctx.streak > 0 && !ctx.checkedInToday && idleDays >= 1;

    return isDay2 || isStreakBroken;
  }

  // ===== 个性化推送内容生成 =====

  /// 根据用户激励偏好获取懈怠关怀标题
  String _getIdleWarningTitle(EncouragementType? bestType) {
    if (bestType == EncouragementType.toughLove) return '别找借口 😏';
    if (bestType == EncouragementType.encouragement) return '炭炭想你了 🥺';
    if (bestType == EncouragementType.humor) return '打卡小助手上线 😄';
    if (bestType == EncouragementType.warmCompanion) return '我在这里等你 🤗';
    if (bestType == EncouragementType.dataDriven) return '数据在等你 📊';
    return '炭炭想你了 🥺';
  }

  /// 生成个性化懈怠关怀内容
  String _generatePersonalizedIdleWarning(EncouragementType? bestType, PetContext ctx) {
    final streak = ctx.streak;

    if (bestType == EncouragementType.toughLove) {
      return '都${streak}天了，别告诉我你要在这里放弃？';
    }
    if (bestType == EncouragementType.encouragement) {
      return '今天还没打卡，但我知道你有你的理由。准备好了随时动一下～';
    }
    if (bestType == EncouragementType.humor) {
      return '今日份的打卡还没完成哦，是被什么绊住了？🦘';
    }
    if (bestType == EncouragementType.warmCompanion) {
      return '今天有点累？没关系的，我陪你，不急。';
    }
    if (bestType == EncouragementType.dataDriven) {
      return '你的坚持率${_calcSuccessRate(ctx)}%，今天动一下就保持在高位了 📈';
    }
    if (bestType == EncouragementType.silentSupport) {
      return '......（炭炭安静地看着你，不催）';
    }

    // 默认：温暖陪伴
    return '今天还没打卡，不着急，我陪着你 🌱';
  }

  /// 计算坚持率
  String _calcSuccessRate(PetContext ctx) {
    if (ctx.totalCheckIns == 0) return '100';
    final rate = (ctx.streak / ctx.totalCheckIns * 100).round();
    return '$rate';
  }

  /// 根据用户激励偏好获取打卡提醒标题
  String _getStreakReminderTitle(EncouragementType? bestType) {
    if (bestType == EncouragementType.toughLove) return '起床干活 💪';
    if (bestType == EncouragementType.encouragement) return '每日打卡 ☀️';
    if (bestType == EncouragementType.humor) return '今日任务待领取 🎁';
    if (bestType == EncouragementType.warmCompanion) return '新的一天 🌱';
    if (bestType == EncouragementType.dataDriven) return '今日数据 📊';
    return '每日打卡提醒 ☀️';
  }

  /// 生成个性化打卡提醒内容
  String _generatePersonalizedReminder(EncouragementType? bestType, PetContext ctx) {
    if (bestType == EncouragementType.toughLove) {
      return '别躺了，就差今天这一步。动起来！';
    }
    if (bestType == EncouragementType.encouragement) {
      return '今天的行动完成了吗？哪怕只做一点点也是进步 💪';
    }
    if (bestType == EncouragementType.humor) {
      return '今日打卡任务还没领哦，再不来就要被扣分了 🏃';
    }
    if (bestType == EncouragementType.warmCompanion) {
      return '今天打算什么时候动一下？不急，我在这里等你。';
    }
    if (bestType == EncouragementType.dataDriven) {
      return '今日打卡率待更新，你来完成今天这 1% 📈';
    }
    if (bestType == EncouragementType.silentSupport) {
      return '......（你什么时候方便就什么时候来）';
    }
    return '今天的行动完成了吗？哪怕只做一点点也是进步 💪';
  }
}
