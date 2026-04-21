import 'dart:convert';
import 'models.dart';

/// ====== 行为数据分析报告 ======

/// 单个行为指标
class BehaviorMetric {
  /// 指标类型
  final String type;
  /// 指标名称（用于显示）
  final String label;
  /// 指标值（百分比 0-100，或计数）
  final double value;
  /// 相比上周的变化（正数=提升，负数=下降）
  final double? delta;
  /// 额外描述
  final String? description;

  const BehaviorMetric({
    required this.type,
    required this.label,
    required this.value,
    this.delta,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'label': label,
    'value': value,
    'delta': delta,
    'description': description,
  };

  factory BehaviorMetric.fromJson(Map<String, dynamic> json) => BehaviorMetric(
    type: json['type'] ?? '',
    label: json['label'] ?? '',
    value: (json['value'] ?? 0).toDouble(),
    delta: json['delta'] != null ? (json['delta'] as num).toDouble() : null,
    description: json['description'],
  );
}

/// 周度行为分析报告
class BehaviorReport {
  /// 报告唯一ID
  final String id;
  /// 所属周标识，格式 "YYYY-WW"（2024-15）
  final String weekKey;
  /// 报告生成时间
  final DateTime generatedAt;
  /// 本周打卡天数（0-7）
  final int checkInDays;
  /// 本周应打卡天数
  final int totalDays;
  /// 打卡完成率（0.0-1.0）
  final double completionRate;
  /// 相比上周打卡率的变化（正数=提升）
  final double? completionRateDelta;
  /// 连续打卡天数
  final int currentStreak;
  /// 累计打卡天数
  final int totalCheckIns;
  /// 与宠物对话次数
  final int chatCount;
  /// 相比上周对话次数变化
  final int? chatCountDelta;
  /// 激励消息发送次数
  final int encouragementSent;
  /// 激励消息次日转化率（0.0-1.0）
  final double encouragementConversionRate;
  /// 关键行为指标列表
  final List<BehaviorMetric> metrics;
  /// 重点关注领域（宠物给用户的建议）
  final List<String> focusAreas;
  /// 亮点描述
  final String? highlight;
  /// 待改进描述
  final String? improvement;

  BehaviorReport({
    required this.id,
    required this.weekKey,
    required this.generatedAt,
    required this.checkInDays,
    required this.totalDays,
    required this.completionRate,
    this.completionRateDelta,
    required this.currentStreak,
    required this.totalCheckIns,
    required this.chatCount,
    this.chatCountDelta,
    required this.encouragementSent,
    required this.encouragementConversionRate,
    required this.metrics,
    required this.focusAreas,
    this.highlight,
    this.improvement,
  });

  /// 完成率百分比（0-100）
  int get completionRatePercent => (completionRate * 100).round().clamp(0, 100);

  /// 转化率百分比
  int get conversionRatePercent => (encouragementConversionRate * 100).round().clamp(0, 100);

  /// 是否本周报告
  bool get isThisWeek {
    final now = DateTime.now();
    final currentKey = _computeWeekKey(now);
    return weekKey == currentKey;
  }

  /// 计算指定时间的 year-week key
  static String _computeWeekKey(DateTime dt) {
    // 以1月1日作为第1周的起点，计算当前日期是第几周
    final jan1 = DateTime(dt.year, 1, 1);
    final weekNumber = (dt.difference(jan1).inDays ~/ 7) + 1;
    return '${dt.year}-${weekNumber.toString().padLeft(2, '0')}';
  }

  /// 获取当前周的 key
  static String currentWeekKey() => _computeWeekKey(DateTime.now());

  /// 从 key 解析出年 和 周数
  (int year, int week) parseWeekKey() {
    final parts = weekKey.split('-');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'weekKey': weekKey,
    'generatedAt': generatedAt.toIso8601String(),
    'checkInDays': checkInDays,
    'totalDays': totalDays,
    'completionRate': completionRate,
    'completionRateDelta': completionRateDelta,
    'currentStreak': currentStreak,
    'totalCheckIns': totalCheckIns,
    'chatCount': chatCount,
    'chatCountDelta': chatCountDelta,
    'encouragementSent': encouragementSent,
    'encouragementConversionRate': encouragementConversionRate,
    'metrics': metrics.map((m) => m.toJson()).toList(),
    'focusAreas': focusAreas,
    'highlight': highlight,
    'improvement': improvement,
  };

  factory BehaviorReport.fromJson(Map<String, dynamic> json) => BehaviorReport(
    id: json['id'] ?? '',
    weekKey: json['weekKey'] ?? '',
    generatedAt: DateTime.parse(json['generatedAt']),
    checkInDays: json['checkInDays'] ?? 0,
    totalDays: json['totalDays'] ?? 7,
    completionRate: (json['completionRate'] ?? 0).toDouble(),
    completionRateDelta: json['completionRateDelta'] != null
        ? (json['completionRateDelta'] as num).toDouble() : null,
    currentStreak: json['currentStreak'] ?? 0,
    totalCheckIns: json['totalCheckIns'] ?? 0,
    chatCount: json['chatCount'] ?? 0,
    chatCountDelta: json['chatCountDelta'],
    encouragementSent: json['encouragementSent'] ?? 0,
    encouragementConversionRate:
        (json['encouragementConversionRate'] ?? 0).toDouble(),
    metrics: (json['metrics'] as List? ?? [])
        .map((m) => BehaviorMetric.fromJson(m as Map<String, dynamic>))
        .toList(),
    focusAreas: (json['focusAreas'] as List? ?? []).cast<String>(),
    highlight: json['highlight'],
    improvement: json['improvement'],
  );

  /// 生成简短摘要（用于记忆写入）
  String toShortSummary() {
    return '第$weekKey周：打卡${checkInDays}/$totalDays天'
        '${completionRatePercent}%'
        '${completionRateDelta != null ? '（较上周${completionRateDelta! >= 0 ? '+' : ''}${completionRateDelta!.round()}%）' : ''}'
        '，对话$chatCount次'
        '${currentStreak > 0 ? '，连续$currentStreak天' : ''}';
  }

  /// 从数据生成报告（不直接依赖 StorageService，打破循环依赖）
  /// [checkIns] 所有打卡记录
  /// [dailyLevers] 每日杠杆列表
  /// [monthlyBoss] 月度Boss信息
  /// [userStats] 用户统计信息
  /// [lastWeekReport] 上周报告（用于计算delta）
  /// [behaviorEvents] 行为事件列表
  static BehaviorReport generateFromData({
    required List<CheckIn> checkIns,
    required List<Map<String, String>> dailyLevers,
    required MonthlyBoss? monthlyBoss,
    required UserStats userStats,
    required BehaviorReport? lastWeekReport,
    required List<BehaviorEvent> behaviorEvents,
  }) {
    final now = DateTime.now();
    final weekKey = BehaviorReport.currentWeekKey();

    // 计算本周范围（周一到周日）
    final weekday = now.weekday; // 1=周一，7=周日
    final monday = DateTime(now.year, now.month, now.day - (weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    // 获取本周打卡记录
    final weekCheckIns = checkIns.where((c) {
      final d = DateTime(c.date.year, c.date.month, c.date.day);
      return !d.isBefore(monday) && !d.isAfter(sunday);
    }).toList();

    // 计算本周已过天数（今天之前的实际天数，不含今天）
    final today = DateTime(now.year, now.month, now.day);
    final passedDays = today.difference(monday).inDays; // 0 ~ 6
    final effectiveTotal = passedDays > 0 ? passedDays : 1;

    // 打卡天数（本周去重）
    final checkedDates = weekCheckIns.map((c) =>
        DateTime(c.date.year, c.date.month, c.date.day)).toSet();
    final checkInDays = checkedDates.length;

    // 完成率（基于实际已过天数）
    final completionRate = effectiveTotal > 0
        ? (checkInDays / effectiveTotal).clamp(0.0, 1.0)
        : 0.0;

    // 统计周一到周日每天打卡情况（用于找出最积极/拖延的天）
    final dayOfWeekCounts = <int, int>{};
    for (int i = 1; i <= 7; i++) {
      dayOfWeekCounts[i] = 0;
    }
    for (final ci in weekCheckIns) {
      final dow = ci.date.weekday; // 1=周一
      dayOfWeekCounts[dow] = (dayOfWeekCounts[dow] ?? 0) + 1;
    }

    // 找出本周已出现的最积极天（打卡最多）和最拖延天（已过但未打）
    int? mostActiveDay;
    int? mostProcrastinatedDay;
    int maxCount = 0;
    for (int i = 1; i <= weekday; i++) {
      final count = dayOfWeekCounts[i] ?? 0;
      if (count > maxCount) {
        maxCount = count;
        mostActiveDay = i;
      }
    }
    // 找出今天之前已过但未打卡的天
    for (int i = 1; i < weekday; i++) {
      if ((dayOfWeekCounts[i] ?? 0) == 0) {
        mostProcrastinatedDay = i;
        break;
      }
    }

    // 计算每日杠杆平均完成数
    final leverCount = dailyLevers.length;
    final avgLeversPerDay = leverCount > 0
        ? weekCheckIns.fold<int>(0, (sum, ci) => sum + ci.leverIds.length) /
            (checkInDays > 0 ? checkInDays : 1)
        : 0.0;

    // 获取月度Boss信息
    final bossHp = monthlyBoss?.hp ?? 0;
    final bossTotal = monthlyBoss?.totalDays ?? 0;

    // 计算和上周的delta（百分点）
    double? completionRateDelta;
    if (lastWeekReport != null) {
      completionRateDelta = ((completionRate - lastWeekReport.completionRate) * 100)
          .round()
          .toDouble();
    }

    // 获取行为事件（用于chatCount等）
    final recentEvents = behaviorEvents.where((e) => e.timestamp.isAfter(monday)).toList();
    final chatCount = recentEvents.where((e) => e.eventType == 'chat').length;
    final encouragementSent = recentEvents.where((e) => e.eventType == 'encouragement_clicked').length;

    // 计算激励次日转化率
    double encouragementConversionRate = 0.0;
    if (encouragementSent > 0) {
      final checkInCount = recentEvents.where((e) => e.eventType == 'check_in').length;
      encouragementConversionRate = (checkInCount / encouragementSent).clamp(0.0, 1.0);
    }

    // 生成 focusAreas（根据数据自动判断）
    final focusAreas = <String>[];
    if (mostProcrastinatedDay != null) {
      final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      focusAreas.add('${dayNames[mostProcrastinatedDay - 1]}打卡较少，建议设置提醒');
    }
    if (completionRateDelta != null && completionRateDelta < 0) {
      focusAreas.add('相比上周有所下滑，本周需更加努力');
    } else if (completionRateDelta != null && completionRateDelta > 10) {
      focusAreas.add('表现优异，比上周提升了${completionRateDelta.round()}%');
    }
    if (checkInDays >= 5 && effectiveTotal >= 5) {
      focusAreas.add('本周状态良好继续保持，期待完美收官');
    } else if (checkInDays < 3) {
      focusAreas.add('本周刚开始或中断较多，建议尽快恢复节奏');
    }

    // 亮点和待改进
    String? highlight;
    String? improvement;
    if (userStats.streak >= 7) {
      highlight = '连续打卡${userStats.streak}天，状态稳定';
    }
    if (completionRateDelta != null && completionRateDelta < 0) {
      improvement = '本周完成率下降${(-completionRateDelta).round()}%，注意调整状态';
    }

    // 构建指标列表
    final metrics = <BehaviorMetric>[];
    metrics.add(BehaviorMetric(
      type: 'checkin_rate',
      label: '本周打卡率',
      value: (completionRate * 100).round().toDouble(),
      delta: completionRateDelta,
      description: '本周已过$effectiveTotal天，打卡$checkInDays天',
    ));
    if (leverCount > 0) {
      metrics.add(BehaviorMetric(
        type: 'lever_completion',
        label: '杠杆完成数',
        value: avgLeversPerDay,
        description: '平均每次打卡完成${avgLeversPerDay.toStringAsFixed(1)}个杠杆行动',
      ));
    }
    if (bossTotal > 0) {
      metrics.add(BehaviorMetric(
        type: 'boss_progress',
        label: '月度Boss',
        value: bossHp.toDouble(),
        description: '本月Boss进度 $bossHp/$bossTotal',
      ));
    }
    if (mostActiveDay != null) {
      final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      metrics.add(BehaviorMetric(
        type: 'most_active_day',
        label: '最积极天',
        value: mostActiveDay.toDouble(),
        description: dayNames[mostActiveDay - 1],
      ));
    }

    return BehaviorReport(
      id: '${weekKey}_${now.millisecondsSinceEpoch}',
      weekKey: weekKey,
      generatedAt: now,
      checkInDays: checkInDays,
      totalDays: effectiveTotal,
      completionRate: completionRate,
      completionRateDelta: completionRateDelta,
      currentStreak: userStats.streak,
      totalCheckIns: userStats.totalCheckIns,
      chatCount: chatCount,
      chatCountDelta: lastWeekReport != null
          ? chatCount - lastWeekReport.chatCount
          : null,
      encouragementSent: encouragementSent,
      encouragementConversionRate: encouragementConversionRate,
      metrics: metrics,
      focusAreas: focusAreas,
      highlight: highlight,
      improvement: improvement,
    );
  }
}

/// 行为事件埋点模型
class BehaviorEvent {
  final String eventType; // 'check_in' | 'encouragement_clicked' | 'chat' | 'pet_viewed'
  final DateTime timestamp;
  final Map<String, dynamic> meta;

  const BehaviorEvent({
    required this.eventType,
    required this.timestamp,
    this.meta = const {},
  });

  Map<String, dynamic> toJson() => {
    'eventType': eventType,
    'timestamp': timestamp.toIso8601String(),
    'meta': meta,
  };

  factory BehaviorEvent.fromJson(Map<String, dynamic> json) => BehaviorEvent(
    eventType: json['eventType'] ?? '',
    timestamp: DateTime.parse(json['timestamp' ]),
    meta: Map<String, dynamic>.from(json['meta'] ?? {}),
  );
}
