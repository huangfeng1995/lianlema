/// 宠物心情状态枚举
enum PetMood {
  /// 开心 — 打卡后或刚互动
  happy,
  /// 困倦 — 懈怠太久（超过2天）
  sleepy,
  /// 平静 — 日常等待
  calm,
  /// 兴奋 — 里程碑达成
  excited,
  /// 思考中 — 用户提问时
  thinking,
  /// 休息中 — 完全离线或API失败
  resting,
}

/// 宠物心情数据模型
class PetMoodState {
  final PetMood mood;
  final DateTime updatedAt;
  final int consecutiveIdleDays; // 连续懈怠天数

  PetMoodState({
    required this.mood,
    required this.updatedAt,
    this.consecutiveIdleDays = 0,
  });

  PetMoodState copyWith({
    PetMood? mood,
    DateTime? updatedAt,
    int? consecutiveIdleDays,
  }) {
    return PetMoodState(
      mood: mood ?? this.mood,
      updatedAt: updatedAt ?? this.updatedAt,
      consecutiveIdleDays: consecutiveIdleDays ?? this.consecutiveIdleDays,
    );
  }

  Map<String, dynamic> toJson() => {
    'mood': mood.index,
    'updatedAt': updatedAt.toIso8601String(),
    'consecutiveIdleDays': consecutiveIdleDays,
  };

  factory PetMoodState.fromJson(Map<String, dynamic> json) => PetMoodState(
    mood: PetMood.values[json['mood'] ?? 0],
    updatedAt: DateTime.parse(json['updatedAt']),
    consecutiveIdleDays: json['consecutiveIdleDays'] ?? 0,
  );

  /// 默认平静状态
  factory PetMoodState.initial() => PetMoodState(
    mood: PetMood.calm,
    updatedAt: DateTime.now(),
    consecutiveIdleDays: 0,
  );
}

/// 宠物建议类型
enum PetAdviceType {
  /// 主动建议（出谋划策）
  suggestion,
  /// 温暖鼓励（陪伴提醒）
  encouragement,
  /// 知识问答回复
  knowledgeAnswer,
  /// 快捷指令响应
  quickCommand,
}

/// 宠物建议数据模型
class PetAdvice {
  final PetAdviceType type;
  final String content;
  final String? actionLabel; // 可执行的操作标签，如"查打卡"、"设提醒"
  final String? actionKey; // 操作key
  final DateTime createdAt;

  PetAdvice({
    required this.type,
    required this.content,
    this.actionLabel,
    this.actionKey,
    required this.createdAt,
  });
}

/// 里程碑类型
enum MilestoneType {
  /// 连续7天
  streak7,
  /// 连续14天
  streak14,
  /// 连续30天
  streak30,
  /// 连续100天
  streak100,
  /// 月度Boss击败
  bossDefeated,
  /// 首次打卡
  firstCheckIn,
  /// 完美月份
  perfectMonth,
}

/// 里程碑数据模型
class PetMilestone {
  final MilestoneType type;
  final DateTime achievedAt;

  PetMilestone({required this.type, required this.achievedAt});

  String get title {
    switch (type) {
      case MilestoneType.streak7:
        return '连续7天打卡！';
      case MilestoneType.streak14:
        return '两周坚持！';
      case MilestoneType.streak30:
        return '一个月！你太棒了！';
      case MilestoneType.streak100:
        return '百日达人！';
      case MilestoneType.bossDefeated:
        return 'Boss已击败！';
      case MilestoneType.firstCheckIn:
        return '完成首次打卡！';
      case MilestoneType.perfectMonth:
        return '完美月份！';
    }
  }

  String get emoji {
    switch (type) {
      case MilestoneType.streak7:
        return '🔥';
      case MilestoneType.streak14:
        return '⚡';
      case MilestoneType.streak30:
        return '🌟';
      case MilestoneType.streak100:
        return '👑';
      case MilestoneType.bossDefeated:
        return '🏆';
      case MilestoneType.firstCheckIn:
        return '🌱';
      case MilestoneType.perfectMonth:
        return '📅';
    }
  }
}

/// 宠物交互命令
enum PetCommand {
  /// 查打卡记录
  checkInRecord,
  /// 设提醒
  setReminder,
  /// 问成长问题
  askGrowth,
  /// 看看状态
  status,
  /// 喂食（打卡）
  feed,
}

/// 宠物快捷指令
class PetQuickCommand {
  final PetCommand command;
  final String label;
  final String description;
  final String icon;

  const PetQuickCommand({
    required this.command,
    required this.label,
    required this.description,
    required this.icon,
  });

  static const List<PetQuickCommand> all = [
    PetQuickCommand(
      command: PetCommand.checkInRecord,
      label: '查打卡',
      description: '查看本周打卡情况',
      icon: '📋',
    ),
    PetQuickCommand(
      command: PetCommand.setReminder,
      label: '设提醒',
      description: '设置专注时段提醒',
      icon: '⏰',
    ),
    PetQuickCommand(
      command: PetCommand.askGrowth,
      label: '问成长',
      description: '关于习惯养成的建议',
      icon: '💡',
    ),
    PetQuickCommand(
      command: PetCommand.status,
      label: '状态',
      description: '查看当前打卡状态',
      icon: '📊',
    ),
  ];
}

/// 宠物记忆记录（反思机制）
class PetMemory {
  final String id;
  final DateTime createdAt;
  final String type; // 'correction' | 'preference' | 'milestone'
  final String content; // 用户说的话
  final String petResponse; // 宠物之前的回复
  final String? correctionNote; // 用户的纠正内容

  PetMemory({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.content,
    required this.petResponse,
    this.correctionNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'type': type,
    'content': content,
    'petResponse': petResponse,
    'correctionNote': correctionNote,
  };

  factory PetMemory.fromJson(Map<String, dynamic> json) => PetMemory(
    id: json['id'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    type: json['type'] ?? 'correction',
    content: json['content'] ?? '',
    petResponse: json['petResponse'] ?? '',
    correctionNote: json['correctionNote'],
  );
}

/// 宠物偏好设置（基于用户反馈动态调整）
class PetPreferences {
  /// 对话风格：'formal' | 'casual' | 'playful'
  final String tone;
  /// 是否使用表情符号
  final bool useEmoji;
  /// 回复长度偏好：'short' | 'medium' | 'long'
  final String responseLength;
  /// 用户名（可选，用于更个性化的称呼）
  final String? userName;
  /// 最后更新时间
  final DateTime updatedAt;

  PetPreferences({
    this.tone = 'casual',
    this.useEmoji = true,
    this.responseLength = 'short',
    this.userName,
    required this.updatedAt,
  });

  PetPreferences copyWith({
    String? tone,
    bool? useEmoji,
    String? responseLength,
    String? userName,
    DateTime? updatedAt,
  }) => PetPreferences(
    tone: tone ?? this.tone,
    useEmoji: useEmoji ?? this.useEmoji,
    responseLength: responseLength ?? this.responseLength,
    userName: userName ?? this.userName,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'tone': tone,
    'useEmoji': useEmoji,
    'responseLength': responseLength,
    'userName': userName,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PetPreferences.fromJson(Map<String, dynamic> json) => PetPreferences(
    tone: json['tone'] ?? 'casual',
    useEmoji: json['useEmoji'] ?? true,
    responseLength: json['responseLength'] ?? 'short',
    userName: json['userName'],
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now(),
  );

  /// 默认偏好
  factory PetPreferences.defaultPrefs() => PetPreferences(
    updatedAt: DateTime.now(),
  );
}
