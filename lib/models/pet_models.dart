import 'dart:math';

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

/// 宠物固定人格（写死后不变）
class PetSoul {
  final String name;
  final String personality;
  final String speakingStyle;
  final String tone;
  final bool useEmoji;
  final String defaultGreeting;
  final String type; // 'fox'|'wolf'|...|'blackcat'
  final String petEmoji; // emoji 如 '🦊'

  const PetSoul({
    required this.name,
    required this.personality,
    required this.speakingStyle,
    required this.tone,
    required this.useEmoji,
    required this.defaultGreeting,
    required this.type,
    required this.petEmoji,
  });

  factory PetSoul.fromJson(Map<String, dynamic> json) => PetSoul(
    name: json['name'] ?? '炭炭',
    personality: json['personality'] ?? '温暖、有洞察、不说教、不讲大道理。',
    speakingStyle: json['speakingStyle'] ?? '像朋友一样简短、有温度。',
    tone: json['tone'] ?? 'casual',
    useEmoji: json['useEmoji'] ?? true,
    defaultGreeting: json['defaultGreeting'] ?? '嗨，我是你的AI伙伴炭炭。',
    type: json['type'] ?? 'fox',
    petEmoji: json['petEmoji'] ?? '🦊',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'personality': personality,
    'speakingStyle': speakingStyle,
    'tone': tone,
    'useEmoji': useEmoji,
    'defaultGreeting': defaultGreeting,
    'type': type,
    'petEmoji': petEmoji,
  };

  factory PetSoul.defaultSoul() => const PetSoul(
    name: '炭炭',
    personality: '温暖、有洞察、不说教、不讲大道理。遇到挫折会陪着你，不会责备你。',
    speakingStyle: '像朋友一样简短、有温度。偶尔轻松活泼，但不过度。',
    tone: 'casual',
    useEmoji: true,
    defaultGreeting: '嗨，我是你AI伙伴炭炭。有什么想聊的？',
    type: 'fox',
    petEmoji: '🦊',
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

  bool get isPermanent => type == 'milestone' || type == 'identity' || type == 'lesson';

  bool get isExpired {
    if (isPermanent) return false;
    // 30天后自然淘汰
    return DateTime.now().difference(createdAt).inDays > 30;
  }
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

/// 宠物币交易记录原因
enum PetCoinReason {
  dailyCheckIn,   // 每日打卡
  streak7,        // 连续7天
  streak30,       // 连续30天
  bossComplete,   // 完成月度Boss
  buySnack,       // 购买零食
  buyCostume,     // 购买外观
  buyDecoration,  // 购买家居
}

/// 宠物币交易记录
class PetCoinTransaction {
  final String id;
  final int amount; // 正数=获得，负数=消耗
  final PetCoinReason reason;
  final DateTime createdAt;

  PetCoinTransaction({
    required this.id,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'reason': reason.index,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PetCoinTransaction.fromJson(Map<String, dynamic> json) =>
      PetCoinTransaction(
        id: json['id'] ?? '',
        amount: json['amount'] ?? 0,
        reason: PetCoinReason.values[json['reason'] ?? 0],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

/// 宠物商店物品分类
enum PetShopCategory {
  costume,     // 外观
  snack,       // 零食
  decoration,  // 家居
}

/// 宠物商店物品
class PetShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final PetShopCategory category;
  final String icon;
  final int effect; // 零食的心情恢复值，0=无效果

  const PetShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.icon,
    this.effect = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category': category.index,
    'icon': icon,
    'effect': effect,
  };

  factory PetShopItem.fromJson(Map<String, dynamic> json) => PetShopItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    price: json['price'] ?? 0,
    category: PetShopCategory.values[json['category'] ?? 0],
    icon: json['icon'] ?? '',
    effect: json['effect'] ?? 0,
  );
}

/// 宠物背包物品（已购买的）
class PetOwnedItem {
  final String itemId;
  final DateTime purchasedAt;
  final bool equipped; // 是否正在穿戴/使用

  PetOwnedItem({
    required this.itemId,
    required this.purchasedAt,
    this.equipped = false,
  });

  PetOwnedItem copyWith({bool? equipped}) => PetOwnedItem(
    itemId: itemId,
    purchasedAt: purchasedAt,
    equipped: equipped ?? this.equipped,
  );

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'purchasedAt': purchasedAt.toIso8601String(),
    'equipped': equipped,
  };

  factory PetOwnedItem.fromJson(Map<String, dynamic> json) => PetOwnedItem(
    itemId: json['itemId'] ?? '',
    purchasedAt: DateTime.parse(json['purchasedAt']),
    equipped: json['equipped'] ?? false,
  );
}

// ====== 15种宠物类型配置 ======
class PetTypeConfig {
  final String id;
  final String name;
  final String emoji;
  final String personality; // 'warm'|'driven'|'gentle'|'healing'|'patient'|'cheerful'|'active'|'focused'|'steady'|'reliable'|'wise'|'lazy'|'calm'|'dreamy'|'mysterious'
  final String type; // 'fox'|'wolf'|'rabbit'|'deer'|'hedgehog'|'bird'|'squirrel'|'raccoon'|'bear'|'penguin'|'owl'|'koala'|'panda'|'butterfly'|'blackcat'
  final double probability; // 出现概率，0.0-1.0
  final String specialAbility; // 特殊能力描述
  final String greeting; // 打招呼时说的话

  const PetTypeConfig({
    required this.id,
    required this.name,
    required this.emoji,
    required this.personality,
    required this.type,
    required this.probability,
    required this.specialAbility,
    required this.greeting,
  });
}

const List<PetTypeConfig> petTypes = [
  PetTypeConfig(
    id: 'fox',
    name: '炭炭',
    emoji: '🦊',
    personality: 'warm',
    type: 'fox',
    probability: 0.18,
    specialAbility: '温暖鼓励型，总能在你最低落时说对话',
    greeting: '嗨，我是炭炭，你的森林伙伴。有什么想聊聊的吗？',
  ),
  PetTypeConfig(
    id: 'wolf',
    name: '闪焰',
    emoji: '🐺',
    personality: 'driven',
    type: 'wolf',
    probability: 0.08,
    specialAbility: '激情驱动型，带动你的行动力',
    greeting: '嗷呜！我是闪焰！今天也要燃起来！冲！',
  ),
  PetTypeConfig(
    id: 'rabbit',
    name: '波波',
    emoji: '🐰',
    personality: 'gentle',
    type: 'rabbit',
    probability: 0.12,
    specialAbility: '温柔倾听型，最擅长陪伴和倾听',
    greeting: '嗨～我是波波，蹦蹦跳跳来陪你啦。有什么事可以告诉我哦。',
  ),
  PetTypeConfig(
    id: 'deer',
    name: '滴露',
    emoji: '🦌',
    personality: 'healing',
    type: 'deer',
    probability: 0.10,
    specialAbility: '治愈陪伴型，给你最温柔的陪伴',
    greeting: '我是滴露，很高兴认识你。今天过得怎么样？',
  ),
  PetTypeConfig(
    id: 'hedgehog',
    name: '小草',
    emoji: '🦔',
    personality: 'patient',
    type: 'hedgehog',
    probability: 0.10,
    specialAbility: '耐心成长型，陪你一起慢慢变好',
    greeting: '你好呀，我是小草。我们一起慢慢来吧，每天进步一点点。',
  ),
  PetTypeConfig(
    id: 'bird',
    name: '花花',
    emoji: '🐦',
    personality: 'cheerful',
    type: 'bird',
    probability: 0.08,
    specialAbility: '温暖绽放型，用乐观感染你',
    greeting: '啾啾！我是花花～今天也要开心地度过哦！',
  ),
  PetTypeConfig(
    id: 'squirrel',
    name: '雷雷',
    emoji: '🐿️',
    personality: 'active',
    type: 'squirrel',
    probability: 0.08,
    specialAbility: '行动激活型，推动你立刻行动',
    greeting: '嘿！我是雷雷！有什么想做的？走，现在就去！',
  ),
  PetTypeConfig(
    id: 'raccoon',
    name: '电网',
    emoji: '🦝',
    personality: 'focused',
    type: 'raccoon',
    probability: 0.06,
    specialAbility: '专注效率型，帮你保持高效专注',
    greeting: '我是电网，专注模式启动！你今天的目标是什么？',
  ),
  PetTypeConfig(
    id: 'bear',
    name: '岩岩',
    emoji: '🐻',
    personality: 'steady',
    type: 'bear',
    probability: 0.08,
    specialAbility: '稳定坚持型，陪你日复一日不放弃',
    greeting: '嗨，我是岩岩。不用着急，我在这里陪你一起坚持。',
  ),
  PetTypeConfig(
    id: 'penguin',
    name: '煤球',
    emoji: '🐧',
    personality: 'reliable',
    type: 'penguin',
    probability: 0.06,
    specialAbility: '踏实可靠型，永远值得信赖',
    greeting: '咕咕～我是煤球！交给我，你只管往前走就好。',
  ),
  PetTypeConfig(
    id: 'owl',
    name: '风风',
    emoji: '🦉',
    personality: 'wise',
    type: 'owl',
    probability: 0.07,
    specialAbility: '自由智慧型，给你更宽广的视角',
    greeting: '我是风风，黑夜中也能看得很远。有什么困惑吗？',
  ),
  PetTypeConfig(
    id: 'koala',
    name: '云云',
    emoji: '🐨',
    personality: 'lazy',
    type: 'koala',
    probability: 0.07,
    specialAbility: '慵懒治愈型，累了就一起休息一下吧',
    greeting: '嗯～我是云云，今天有点累？抱抱，不用勉强自己哦。',
  ),
  PetTypeConfig(
    id: 'panda',
    name: '雪团',
    emoji: '🐼',
    personality: 'calm',
    type: 'panda',
    probability: 0.05,
    specialAbility: '冷静理智型，帮你梳理情绪',
    greeting: '你好，我是雪团。深呼吸，我们慢慢来一起想办法。',
  ),
  PetTypeConfig(
    id: 'butterfly',
    name: '星光',
    emoji: '🦋',
    personality: 'dreamy',
    type: 'butterfly',
    probability: 0.05,
    specialAbility: '梦想激励型，点燃你心中的愿景',
    greeting: '嗨～我是星光，今天也在追着光飞。你心中的梦想是什么？',
  ),
  PetTypeConfig(
    id: 'blackcat',
    name: '月影',
    emoji: '🖤',
    personality: 'mysterious',
    type: 'blackcat',
    probability: 0.08,
    specialAbility: '神秘优雅型，总是有独特的见解',
    greeting: '喵～我是月影。今晚的月亮很美，要一起看看吗？',
  ),
];

/// 按概率加权随机分配宠物类型
PetTypeConfig assignRandomPet() {
  final random = Random();
  final r = random.nextDouble();
  double cumulative = 0;
  for (final pet in petTypes) {
    cumulative += pet.probability;
    if (r <= cumulative) return pet;
  }
  return petTypes.first;
}

/// 根据宠物类型 id 查找配置
PetTypeConfig? getPetTypeConfig(String type) {
  try {
    return petTypes.firstWhere((p) => p.type == type);
  } catch (_) {
    return null;
  }
}

/// 外观等级配置
class PetAppearanceLevel {
  final int level; // 1-5
  final String name;
  final String emoji;
  final int requiredDays; // 累计或连续天数要求

  const PetAppearanceLevel({
    required this.level,
    required this.name,
    required this.emoji,
    required this.requiredDays,
  });

  static const List<PetAppearanceLevel> levels = [
    PetAppearanceLevel(level: 1, name: '初始', emoji: '🌱', requiredDays: 0),
    PetAppearanceLevel(level: 2, name: '成长', emoji: '🌿', requiredDays: 14),
    PetAppearanceLevel(level: 3, name: '进化', emoji: '🌳', requiredDays: 30),
    PetAppearanceLevel(level: 4, name: '绽放', emoji: '💐', requiredDays: 60),
    PetAppearanceLevel(level: 5, name: '传说', emoji: '✨', requiredDays: 100),
  ];

  /// 根据连续天数计算外观等级（取最高满足条件的等级）
  static int calculateLevel(int consecutiveDays) {
    int result = 1;
    for (final lv in levels) {
      if (consecutiveDays >= lv.requiredDays) {
        result = lv.level;
      }
    }
    return result;
  }

  static PetAppearanceLevel? getLevel(int level) {
    try {
      return levels.firstWhere((l) => l.level == level);
    } catch (_) {
      return null;
    }
  }
}

// ====== 宠物商店商品配置 ======
class PetShopConfig {
  static const List<PetShopItem> allItems = [
    // ===== 外观：颜色变体 =====
    PetShopItem(id: 'costume_spring', name: '春色', description: '粉色渐变', price: 30, category: PetShopCategory.costume, icon: '🌸'),
    PetShopItem(id: 'costume_summer', name: '夏色', description: '绿松石渐变', price: 30, category: PetShopCategory.costume, icon: '🌊'),
    PetShopItem(id: 'costume_autumn', name: '秋色', description: '金色渐变', price: 30, category: PetShopCategory.costume, icon: '🍂'),
    PetShopItem(id: 'costume_winter', name: '冬色', description: '冰蓝渐变', price: 30, category: PetShopCategory.costume, icon: '❄️'),
    PetShopItem(id: 'costume_neon', name: '霓虹', description: '赛博朋克风格', price: 50, category: PetShopCategory.costume, icon: '🌃'),
    // ===== 外观：配件 =====
    PetShopItem(id: 'costume_hat', name: '小帽子', description: '萌系小帽', price: 20, category: PetShopCategory.costume, icon: '🎩'),
    PetShopItem(id: 'costume_glasses', name: '太阳镜', description: '酷酷的', price: 25, category: PetShopCategory.costume, icon: '🕶️'),
    PetShopItem(id: 'costume_scarf', name: '围巾', description: '暖和的围巾', price: 25, category: PetShopCategory.costume, icon: '🧣'),
    PetShopItem(id: 'costume_cape', name: '小披风', description: '超级英雄风', price: 40, category: PetShopCategory.costume, icon: '🛡️'),
    // ===== 外观：特效 =====
    PetShopItem(id: 'costume_fire', name: '火焰光环', description: '火焰围绕', price: 60, category: PetShopCategory.costume, icon: '🔥'),
    PetShopItem(id: 'costume_star', name: '星光粒子', description: '星星闪烁', price: 60, category: PetShopCategory.costume, icon: '✨'),
    // ===== 零食 =====
    PetShopItem(id: 'snack_fish', name: '小鱼干', description: '心情+1', price: 5, category: PetShopCategory.snack, icon: '🐟', effect: 1),
    PetShopItem(id: 'snack_biscuit', name: '能量饼干', description: '心情+2', price: 8, category: PetShopCategory.snack, icon: '🍪', effect: 2),
    PetShopItem(id: 'snack_candy', name: '星星糖', description: '心情+5', price: 15, category: PetShopCategory.snack, icon: '⭐', effect: 5),
    PetShopItem(id: 'snack_mystic', name: '神秘果', description: '心情+10', price: 30, category: PetShopCategory.snack, icon: '🔮', effect: 10),
    // ===== 家居 =====
    PetShopItem(id: 'deco_cushion', name: '软垫', description: '舒适的床', price: 15, category: PetShopCategory.decoration, icon: '🛋️'),
    PetShopItem(id: 'deco_plant', name: '盆栽', description: '绿色植物装饰', price: 20, category: PetShopCategory.decoration, icon: '🌱'),
    PetShopItem(id: 'deco_frame', name: '相框', description: '放打卡照片', price: 20, category: PetShopCategory.decoration, icon: '🖼️'),
    PetShopItem(id: 'deco_lantern', name: '小灯笼', description: '温暖的灯光', price: 25, category: PetShopCategory.decoration, icon: '🏮'),
    PetShopItem(id: 'deco_tapestry', name: '挂毯', description: '背景装饰', price: 30, category: PetShopCategory.decoration, icon: '🧶'),
    PetShopItem(id: 'deco_starlight', name: '星星灯', description: '梦幻氛围', price: 40, category: PetShopCategory.decoration, icon: '💫'),
    PetShopItem(id: 'deco_window', name: '落地窗', description: '可以看窗外', price: 50, category: PetShopCategory.decoration, icon: '🪟'),
  ];

  static List<PetShopItem> byCategory(PetShopCategory cat) =>
      allItems.where((i) => i.category == cat).toList();

  static PetShopItem? getById(String id) {
    try {
      return allItems.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}
