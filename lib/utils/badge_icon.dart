import 'package:flutter/material.dart';

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
    default:
      return Icons.star;
  }
}
