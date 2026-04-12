export 'goal_templates.dart';

class AntiVision {
  final String content;
  final DateTime createdAt;

  AntiVision({
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AntiVision.fromJson(Map<String, dynamic> json) => AntiVision(
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class Vision {
  final String content;
  final DateTime createdAt;

  Vision({required this.content, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Vision.fromJson(Map<String, dynamic> json) => Vision(
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class YearGoal {
  final String content;
  final DateTime createdAt;
  final int year;

  YearGoal({required this.content, required this.createdAt, required this.year});

  Map<String, dynamic> toJson() => {
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'year': year,
  };

  factory YearGoal.fromJson(Map<String, dynamic> json) => YearGoal(
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    year: json['year'],
  );
}

class MonthlyBoss {
  final String content;
  final int month;
  final int year;
  final int totalDays;
  final int hp; // 当前HP = 打卡天数

  MonthlyBoss({
    required this.content,
    required this.month,
    required this.year,
    required this.totalDays,
    required this.hp,
  });

  double get hpPercent => hp / totalDays;

  Map<String, dynamic> toJson() => {
    'content': content,
    'month': month,
    'year': year,
    'totalDays': totalDays,
    'hp': hp,
  };

  factory MonthlyBoss.fromJson(Map<String, dynamic> json) => MonthlyBoss(
    content: json['content'],
    month: json['month'],
    year: json['year'],
    totalDays: json['totalDays'],
    hp: json['hp'],
  );
}

class DailyLever {
  final String id;
  final String obstacle; // 内心障碍（WOOP的O）
  final String plan; // IF-THEN 计划（WOOP的P）
  final int order;
  bool isCompleted;

  DailyLever({
    required this.id,
    required this.obstacle,
    required this.plan,
    required this.order,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'obstacle': obstacle,
    'plan': plan,
    'order': order,
    'isCompleted': isCompleted,
  };

  factory DailyLever.fromJson(Map<String, dynamic> json) => DailyLever(
    id: json['id'] ?? '',
    obstacle: json['obstacle'] ?? '',
    plan: json['plan'] ?? '',
    order: json['order'] ?? 0,
    isCompleted: json['isCompleted'] ?? false,
  );
}

class Constraint {
  final String content;
  final DateTime createdAt;

  Constraint({required this.content, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Constraint.fromJson(Map<String, dynamic> json) => Constraint(
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class CheckIn {
  final DateTime date;
  final List<String> leverIds; // 完成的杠杆ID

  CheckIn({required this.date, required this.leverIds});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'leverIds': leverIds,
  };

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
    date: DateTime.parse(json['date']),
    leverIds: List<String>.from(json['leverIds']),
  );
}

class AppBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory AppBadge.fromJson(Map<String, dynamic> json) => AppBadge(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    icon: json['icon'],
    isUnlocked: json['isUnlocked'] ?? false,
    unlockedAt: json['unlockedAt'] != null 
      ? DateTime.parse(json['unlockedAt']) 
      : null,
  );
}

class UserStats {
  final int level;
  final int currentXP;
  final int totalXP;
  final int streak;
  final int totalCheckIns;

  UserStats({
    required this.level,
    required this.currentXP,
    required this.totalXP,
    required this.streak,
    required this.totalCheckIns,
  });

  int get xpToNextLevel => (level * 100) - currentXP;
  double get levelProgress => currentXP / (level * 100);

  Map<String, dynamic> toJson() => {
    'level': level,
    'currentXP': currentXP,
    'totalXP': totalXP,
    'streak': streak,
    'totalCheckIns': totalCheckIns,
  };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    level: json['level'] ?? 1,
    currentXP: json['currentXP'] ?? 0,
    totalXP: json['totalXP'] ?? 0,
    streak: json['streak'] ?? 0,
    totalCheckIns: json['totalCheckIns'] ?? 0,
  );
}
