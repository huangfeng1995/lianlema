import 'package:flutter/material.dart';

// 缓存已解析结果的缓存
final Map<String, String> _badgeIdCache = {};
final Map<String, IconData> _badgeIconCache = {};
final Map<String, Color> _badgeColorCache = {};

// 徽章颜色映射表
const Map<String, Color> _unlockedColors = {
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

const Color _lockedColor = Color(0xFFBDC3C7); // 统一锁定灰色
const Color _defaultColor = Color(0xFFFF6B35);

// 徽章图标映射表
const Map<String, IconData> _badgeIconMap = {
  '01': Icons.rocket_launch,
  '02': Icons.local_fire_department,
  '03': Icons.bolt,
  '04': Icons.diamond,
  '05': Icons.workspace_premium,
  '06': Icons.track_changes,
  '07': Icons.emoji_events,
  '08': Icons.shield,
  '09': Icons.calendar_today,
  '10': Icons.eco,
  '11': Icons.edit_calendar,
  '12': Icons.auto_awesome,
  '13': Icons.flag,
  '14': Icons.rule,
  '15': Icons.stars,
};

/// 从路径提取徽章ID（带缓存）
String? _extractBadgeId(String iconPath) {
  if (_badgeIdCache.containsKey(iconPath)) {
    return _badgeIdCache[iconPath];
  }
  final match = RegExp(r'badge_(\d+)_(\w+)').firstMatch(iconPath.split('/').last);
  final id = match?.group(1);
  if (id != null) {
    _badgeIdCache[iconPath] = id;
  }
  return id;
}

/// Badge专属颜色（带缓存优化）
Color getBadgeColor(String iconPath, {bool isUnlocked = true}) {
  final cacheKey = '$iconPath|$isUnlocked';
  if (_badgeColorCache.containsKey(cacheKey)) {
    return _badgeColorCache[cacheKey]!;
  }

  final badgeId = _extractBadgeId(iconPath);
  final result = isUnlocked ? (_unlockedColors[badgeId] ?? _defaultColor) : _lockedColor;
  _badgeColorCache[cacheKey] = result;
  return result;
}

/// Badge icon ID to Flutter Icon mapping（带缓存优化）
IconData getBadgeIcon(String iconPath) {
  if (_badgeIconCache.containsKey(iconPath)) {
    return _badgeIconCache[iconPath]!;
  }

  final badgeId = _extractBadgeId(iconPath);
  final result = _badgeIconMap[badgeId] ?? Icons.star;
  _badgeIconCache[iconPath] = result;
  return result;
}
