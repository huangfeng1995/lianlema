import 'package:flutter/material.dart';

/// Badge专属颜色
Color getBadgeColor(String iconPath, {bool isUnlocked = true}) {
  final match = RegExp(r'badge_(\d+)_(\w+)').firstMatch(iconPath.split('/').last);
  final num = match?.group(1);

  const unlockedColors = {
    '01': Color(0xFFFF6B35), // 初醒 - 炭火橙
    '02': Color(0xFFFF4500), // 7天 - 火焰红
    '03': Color(0xFFFFD700), // 14天 - 金色
    '04': Color(0xFF9B59B6), // 30天 - 紫色
    '05': Color(0xFFFF6B35), // 100天 - 传说橙
    '06': Color(0xFFE74C3C), // 第一个挑战 - 红
    '07': Color(0xFF2ECC71), // 月度冠军 - 绿
    '08': Color(0xFF34495E), // 反愿景 - 深灰
    '09': Color(0xFF3498DB), // 完美月 - 蓝
    '10': Color(0xFF1ABC9C), // 重新出发 - 青
    '11': Color(0xFFE67E22), // 规划者 - 橙
    '12': Color(0xFF1ABC9C), // 愿景家 - 青绿
    '13': Color(0xFFE74C3C), // 年度目标 - 红
    '14': Color(0xFF95A5A6), // 底线 - 灰
    '15': Color(0xFFFF6B35), // 完整规划 - 炭火橙
  };

  final lockedColor = const Color(0xFFBDC3C7); // 统一锁定灰色

  return isUnlocked ? (unlockedColors[num] ?? const Color(0xFFFF6B35)) : lockedColor;
}

/// Badge icon ID to Flutter Icon mapping
IconData getBadgeIcon(String iconPath) {
  // Extract the badge ID from the path (e.g., "assets/images/icon/badge_01_hatch.jpg" -> "badge_01_hatch")
  final match = RegExp(r'badge_(\d+)_(\w+)').firstMatch(iconPath.split('/').last);
  if (match == null) return Icons.star;

  final num = match.group(1);
  switch (num) {
    case '01':
      return Icons.rocket_launch;
    case '02':
      return Icons.local_fire_department;
    case '03':
      return Icons.bolt;
    case '04':
      return Icons.diamond;
    case '05':
      return Icons.workspace_premium;
    case '06':
      return Icons.track_changes;
    case '07':
      return Icons.emoji_events;
    case '08':
      return Icons.shield;
    case '09':
      return Icons.calendar_today;
    case '10':
      return Icons.eco;
    case '11':
      return Icons.edit_calendar;
    case '12':
      return Icons.auto_awesome;
    case '13':
      return Icons.flag;
    case '14':
      return Icons.rule;
    case '15':
      return Icons.stars;
    default:
      return Icons.star;
  }
}
