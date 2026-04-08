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
class PetPushService {
  static final PetPushService instance = PetPushService._();
  PetPushService._();
  static const int _maxDailyPushes = 4;
  static const int _minIntervalHours = 4;
  static const double _maxWeight = 2.0;
  static const double _minWeight = 0.1;
  static const int _decayDays = 14; // streakReminder 衰减周期

  Random _random = Random();

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

    // 2. 懈怠关怀
    if (!ctx.checkedInToday && ctx.streak > 3) {
      pushes.add(PetPush(
        id: 'i${DateTime.now().millisecondsSinceEpoch}',
        type: PushType.idleWarning,
        title: '炭炭想你了 🥺',
        body: '今天还没打卡，streak 要断了哦，要不要现在就动一下？',
        createdAt: DateTime.now(),
        weight: 1.0,
      ));
    }

    // 3. 打卡提醒（仅前14天）
    if (ctx.totalCheckIns < 14) {
      pushes.add(PetPush(
        id: 's${DateTime.now().millisecondsSinceEpoch}',
        type: PushType.streakReminder,
        title: '每日打卡提醒 ☀️',
        body: '今天的行动完成了吗？哪怕只做一点点也是进步 💪',
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
}
