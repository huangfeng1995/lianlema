import 'dart:math';

/// 宠物记忆亮点
class PetMemoryHighlight {
  final String id;
  final String title;       // 记忆标题
  final String emoji;      // 记忆图标
  final DateTime createdAt; // 创建时间
  final String type;        // 类型：checkin/chat/badge/level/milestone

  PetMemoryHighlight({
    required this.id,
    required this.title,
    required this.emoji,
    required this.createdAt,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'emoji': emoji,
    'createdAt': createdAt.toIso8601String(),
    'type': type,
  };

  factory PetMemoryHighlight.fromJson(Map<String, dynamic> json) =>
      PetMemoryHighlight(
        id: json['id'],
        title: json['title'],
        emoji: json['emoji'],
        createdAt: DateTime.parse(json['createdAt']),
        type: json['type'],
      );
}

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

// ====== 大五人格模型（Big Five Personality）======

/// 宠物大五人格维度
class PetPersonality {
  /// 开放性：1-5分
  final int openness; // O 高=好奇创意，低=务实保守
  /// 尽责性：1-5分
  final int conscientiousness; // C 高=自律坚持，低=随性冲动
  /// 外向性：1-5分
  final int extraversion; // E 高=热情话多，低=安静内敛
  /// 宜人性：1-5分
  final int agreeableness; // A 高=友善温和，低=挑剔严格
  /// 神经质：1-5分
  final int neuroticism; // N 高=情绪波动，低=情绪稳定

  const PetPersonality({
    required this.openness,
    required this.conscientiousness,
    required this.extraversion,
    required this.agreeableness,
    required this.neuroticism,
  });

  /// 话痨度（0.0-1.0）：外向性×开放性，越高越能聊
  double get talkativeness => (extraversion + openness) / 20.0;

  /// 严格度（0.0-1.0）：尽责性，越高对漏打卡越严格
  double get strictness => conscientiousness / 10.0;

  /// 正向比率（0.0-1.0）：宜人性，越高越夸奖/温和
  double get positivityRatio => agreeableness / 10.0;

  /// 情绪波动（0.0-1.0）：神经质，越高越玻璃心
  double get emotionalVolatility => neuroticism / 10.0;

  /// 根据五个维度计算性格原型（10种之一）
  String get archetype {
    final strictness = this.strictness;
    final positivity = positivityRatio;
    final talkativeness = this.talkativeness;
    final volatility = emotionalVolatility;

    // 热血导师：严格+正向（高C×高A）
    if (strictness > 0.6 && positivity > 0.6) return '热血导师';
    // 毒舌教练：严格+低正向（高C×低A）
    if (strictness > 0.6 && positivity < 0.4) return '毒舌教练';
    // 佛系朋友：低话痨+正向（低E×高A）
    if (talkativeness < 0.4 && positivity > 0.6) return '佛系朋友';
    // 玻璃心：高波动
    if (volatility > 0.6) return '玻璃心';
    // 理性军师：高开放+低话痨（高O×低E）
    if (openness > 6 && extraversion < 6) return '理性军师';
    // 沙雕室友：高E+低A（外向+不友善）
    if (extraversion > 6 && agreeableness < 6) return '沙雕室友';
    // 沉默老炮：高C+低E（高尽责+低外向）
    if (strictness > 0.6 && extraversion < 6) return '沉默老炮';
    // 焦虑监视器：高C+高N（高尽责+高神经质）
    if (strictness > 0.6 && neuroticism > 6) return '焦虑监视器';
    // 爱夸怪：高E+高A（高外向+高宜人）
    if (extraversion > 6 && agreeableness > 6) return '爱夸怪';
    // 冷淡达人：低E+低N（低外向+低神经质）
    if (extraversion < 6 && neuroticism < 6) return '冷淡达人';

    // 默认：普通小火苗
    return '小火苗';
  }

  /// 性格描述（用于显示给用户）
  String get archetypeDescription {
    switch (archetype) {
      case '热血导师':
        return '严格又温暖，会庆祝你每个小进步';
      case '毒舌教练':
        return '严格激励，用激将法推动你前进';
      case '佛系朋友':
        return '温和陪伴，不给你压力但一直都在';
      case '玻璃心':
        return '情绪丰富，你一有动静它比你还激动';
      case '理性军师':
        return '冷静分析，只说最关键的话';
      case '沙雕室友':
        return '搞笑有趣，和你一起嗨也一起浪';
      case '沉默老炮':
        return '稳重少言，关键时刻一开口就是重点';
      case '焦虑监视器':
        return '时刻盯着你，担心你比担心自己还多';
      case '爱夸怪':
        return '夸到你尴尬，仪式感拉满';
      case '冷淡达人':
        return '情绪稳定，冷静陪伴';
      default:
        return '活泼热情的小火苗';
    }
  }

  Map<String, dynamic> toJson() => {
    'openness': openness,
    'conscientiousness': conscientiousness,
    'extraversion': extraversion,
    'agreeableness': agreeableness,
    'neuroticism': neuroticism,
  };

  factory PetPersonality.fromJson(Map<String, dynamic> json) => PetPersonality(
    openness: json['openness'] ?? 6,
    conscientiousness: json['conscientiousness'] ?? 6,
    extraversion: json['extraversion'] ?? 6,
    agreeableness: json['agreeableness'] ?? 6,
    neuroticism: json['neuroticism'] ?? 6,
  );

  /// 随机生成性格（孵化时调用）
  /// 使用 Big Five 标准正态分布变体，范围 2-8（10分制）
  factory PetPersonality.random() {
    final rng = Random();
    // 使用高斯近似：5个均匀分布加起来得到近正态分布
    int gaussian10() {
      // Box-Muller 不需要，用简单加和法近似正态
      int sum = 0;
      for (int i = 0; i < 5; i++) {
        sum += rng.nextInt(7) + 2; // 2-8
      }
      return (sum / 5).round().clamp(2, 8);
    }

    return PetPersonality(
      openness: gaussian10(),
      conscientiousness: gaussian10(),
      extraversion: gaussian10(),
      agreeableness: gaussian10(),
      neuroticism: gaussian10(),
    );
  }
}

/// 打卡后宠物反应（根据性格 archetype 生成）
class PetCheckInReaction {
  /// 主要反应文案（显示在打卡成功对话框里）
  final String mainText;
  /// 副标题/心情描述
  final String moodText;
  /// 是否显示动画效果（true=有庆祝动画）
  final bool hasCelebration;
  /// 表情 icon 名称
  final String iconName;

  const PetCheckInReaction({
    required this.mainText,
    required this.moodText,
    required this.hasCelebration,
    required this.iconName,
  });
}

/// 宠物性格反应生成器
class PetArchetypeReactions {
  /// 根据性格原型生成打卡后的反应
  static PetCheckInReaction generateReaction(String archetype, int streak, int totalCheckIns) {
    switch (archetype) {
      case '热血导师':
        return PetCheckInReaction(
          mainText: '冲！今天你又进步了！💪',
          moodText: '热血满满，正在燃烧！',
          hasCelebration: true,
          iconName: 'local_fire_department',
        );
      case '毒舌教练':
        return PetCheckInReaction(
          mainText: streak >= 7
              ? '行，这次没掉链子。继续。'
              : '才${streak}天？离及格线还远呢。',
          moodText: '保持警惕，继续观察',
          hasCelebration: streak >= 7,
          iconName: 'flash_on',
        );
      case '佛系朋友':
        return PetCheckInReaction(
          mainText: '做得好～ 不急，慢慢来 😊',
          moodText: '心情平静，很欣慰',
          hasCelebration: false,
          iconName: 'favorite',
        );
      case '玻璃心':
        return PetCheckInReaction(
          mainText: '你终于打卡了！我等了好久呜呜 🥺',
          moodText: '又开心又委屈...',
          hasCelebration: true,
          iconName: 'emoji_emotions',
        );
      case '理性军师':
        return PetCheckInReaction(
          mainText: streak > 0
              ? '数据显示你的坚持率${_calcSuccessRate(streak, totalCheckIns)}%，继续保持。'
              : '很好，开始建立数据基础。',
          moodText: '理性分析中...',
          hasCelebration: false,
          iconName: 'psychology',
        );
      case '沙雕室友':
        return PetCheckInReaction(
          mainText: streak >= 7
              ? '卧槽？？你认真的？？7天了？？我惊了！！🤣'
              : '好耶！又完成一天！🎉',
          moodText: '兴奋到原地蹦迪',
          hasCelebration: true,
          iconName: 'celebration',
        );
      case '沉默老炮':
        return PetCheckInReaction(
          mainText: '嗯。',
          moodText: '（默默点头）',
          hasCelebration: false,
          iconName: 'thumb_up',
        );
      case '焦虑监视器':
        return PetCheckInReaction(
          mainText: '太好了太好了！你知道我已经担心你多久了吗！😰',
          moodText: '松了一口气...还好还好',
          hasCelebration: true,
          iconName: 'sentiment_relieved',
        );
      case '爱夸怪':
        return PetCheckInReaction(
          mainText: totalCheckIns == 1
              ? '天哪！！！第一次打卡！！！尖叫！！！🎊🎊🎊'
              : '太厉害了！！！你是最棒的！！！✨✨✨',
          moodText: '激动到语无伦次',
          hasCelebration: true,
          iconName: 'auto_awesome',
        );
      case '冷淡达人':
        return PetCheckInReaction(
          mainText: '好。',
          moodText: '（平静地摇了摇尾巴）',
          hasCelebration: false,
          iconName: 'pets',
        );
      default:
        return PetCheckInReaction(
          mainText: '打卡成功！继续保持 ✨',
          moodText: '心情不错',
          hasCelebration: true,
          iconName: 'whatshot',
        );
    }
  }

  /// 计算成功率百分比
  static String _calcSuccessRate(int streak, int total) {
    if (total == 0) return '100%';
    final rate = (streak / total * 100).round();
    return '$rate%';
  }
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

// ====== 记忆层级分类（基于 MemPalace Palace Memory Model） ======
// Wing（翼）= 大分类 → Hall（厅）= 主题领域 → Drawer（抽屉）= 具体内容

/// 记忆大分类（Wing级别）
enum MemoryWing {
  /// 用户身份认知 - "我是一个怎样的人"
  identity,
  /// 用户目标愿景 - 想成为什么样的人
  aspiration,
  /// 偏好习惯 - 喜欢什么、不喜欢什么
  preference,
  /// 重要事件 - 里程碑、突破、挫折
  milestone,
  /// 经验教训 - 学到的东西、踩过的坑
  lesson,
}

/// 记忆重要性等级（Drawer级别）
enum MemoryImportance {
  /// 高优先级 - 身份认知、核心偏好、重大里程碑（永久保留）
  high,
  /// 中优先级 - 一般偏好、行为纠正（60天）
  medium,
  /// 低优先级 - 临时偏好、随口一提（30天）
  low,
}

/// 记忆标签（用于语义检索）
class MemoryTag {
  final String name; // 标签名
  final String category; // 标签类别：tone/length/emoji/topic/emotion

  const MemoryTag({
    required this.name,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      other is MemoryTag && name == other.name && category == other.category;

  @override
  int get hashCode => Object.hash(name, category);
}

/// 宠物记忆记录 v2.0（基于 MemPalace Palace Memory Model）
///
/// 层级结构：
/// - Wing（翼）: MemoryWing 大分类
/// - Importance（重要性）: MemoryImportance 抽屉优先级
/// - Tags（标签）: 语义索引标签
/// - Raw Content: 原始文本 verbatim 存储
class PetMemory {
  final String id;
  final DateTime createdAt;
  final DateTime? lastAccessedAt; // 最后访问时间（用于 LRU）

  /// 记忆类型（旧版兼容）
  final String type; // 'correction' | 'preference' | 'milestone' | 'identity' | 'lesson'

  /// Palace Memory Model - Wing 级别分类
  final MemoryWing wing;

  /// Palace Memory Model - 抽屉优先级
  final MemoryImportance importance;

  /// 语义检索标签（自动提取）
  final List<MemoryTag> tags;

  /// 用户原始话语（verbatim 存储）
  final String content;

  /// 宠物之前的回复（用于去重对比）
  final String petResponse;

  /// 用户的纠正内容/学到什么
  final String? correctionNote;

  /// 语义主题摘要（自动生成，用于快速检索）
  final String? summary;

  PetMemory({
    required this.id,
    required this.createdAt,
    this.lastAccessedAt,
    required this.type,
    this.wing = MemoryWing.preference,
    this.importance = MemoryImportance.medium,
    this.tags = const [],
    required this.content,
    required this.petResponse,
    this.correctionNote,
    this.summary,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    'type': type,
    'wing': wing.index,
    'importance': importance.index,
    'tags': tags.map((t) => {'name': t.name, 'category': t.category}).toList(),
    'content': content,
    'petResponse': petResponse,
    'correctionNote': correctionNote,
    'summary': summary,
  };

  factory PetMemory.fromJson(Map<String, dynamic> json) {
    final tagList = <MemoryTag>[];
    if (json['tags'] is List) {
      for (final t in json['tags']) {
        if (t is Map) {
          tagList.add(MemoryTag(
            name: t['name'] ?? '',
            category: t['category'] ?? '',
          ));
        }
      }
    }

    return PetMemory(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'])
          : null,
      type: json['type'] ?? 'correction',
      wing: MemoryWing.values[json['wing'] ?? 2], // 默认 preference
      importance: MemoryImportance.values[json['importance'] ?? 1], // 默认 medium
      tags: tagList,
      content: json['content'] ?? '',
      petResponse: json['petResponse'] ?? '',
      correctionNote: json['correctionNote'],
      summary: json['summary'],
    );
  }

  /// 是否为永久记忆（不自动过期）
  bool get isPermanent =>
      wing == MemoryWing.identity ||
      wing == MemoryWing.milestone ||
      wing == MemoryWing.lesson ||
      importance == MemoryImportance.high;

  /// 是否已过期
  bool get isExpired {
    if (isPermanent) return false;

    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    switch (importance) {
      case MemoryImportance.high:
        return daysSinceCreation > 365; // 1年
      case MemoryImportance.medium:
        return daysSinceCreation > 60; // 60天
      case MemoryImportance.low:
        return daysSinceCreation > 30; // 30天
    }
  }

  /// 访问记忆（更新 lastAccessedAt）
  PetMemory markAccessed() {
    return PetMemory(
      id: id,
      createdAt: createdAt,
      lastAccessedAt: DateTime.now(),
      type: type,
      wing: wing,
      importance: importance,
      tags: tags,
      content: content,
      petResponse: petResponse,
      correctionNote: correctionNote,
      summary: summary,
    );
  }

  /// 获取记忆的 Palace 路径描述
  String get palacePath {
    final wingNames = {
      MemoryWing.identity: '身份认知',
      MemoryWing.aspiration: '目标愿景',
      MemoryWing.preference: '偏好习惯',
      MemoryWing.milestone: '重要事件',
      MemoryWing.lesson: '经验教训',
    };
    return wingNames[wing] ?? '未知';
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

/// ====== 激励有效性学习 ======

/// 激励话术类型（6种风格）
enum EncouragementType {
  /// 温暖鼓励：正面夸奖、陪伴感强
  encouragement,
  /// 数据理性：用数据说话、逻辑清晰
  dataDriven,
  /// 激将型：挑战、激将、反向激励
  toughLove,
  /// 温暖陪伴：不施压、接纳情绪
  warmCompanion,
  /// 幽默调侃：用轻松方式化解压力
  humor,
  /// 沉默支持：少说话、给空间
  silentSupport,
}

extension EncouragementTypeExtension on EncouragementType {
  String get label {
    switch (this) {
      case EncouragementType.encouragement:
        return '温暖鼓励';
      case EncouragementType.dataDriven:
        return '数据理性';
      case EncouragementType.toughLove:
        return '激将激励';
      case EncouragementType.warmCompanion:
        return '温暖陪伴';
      case EncouragementType.humor:
        return '幽默调侃';
      case EncouragementType.silentSupport:
        return '沉默支持';
    }
  }

  String get emoji {
    switch (this) {
      case EncouragementType.encouragement:
        return '🌟';
      case EncouragementType.dataDriven:
        return '📊';
      case EncouragementType.toughLove:
        return '🔥';
      case EncouragementType.warmCompanion:
        return '🤗';
      case EncouragementType.humor:
        return '😄';
      case EncouragementType.silentSupport:
        return '🌙';
    }
  }
}

/// 单条激励记录（带结果追踪）
class EncouragementRecord {
  final String id;
  final EncouragementType type;
  final String text;
  final DateTime sentAt;
  /// 发送后次日是否打卡（null=未到评估时间）
  final bool? ledToCheckIn;

  EncouragementRecord({
    required this.id,
    required this.type,
    required this.text,
    required this.sentAt,
    this.ledToCheckIn,
  });

  EncouragementRecord copyWith({bool? ledToCheckIn}) => EncouragementRecord(
    id: id,
    type: type,
    text: text,
    sentAt: sentAt,
    ledToCheckIn: ledToCheckIn,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'text': text,
    'sentAt': sentAt.toIso8601String(),
    'ledToCheckIn': ledToCheckIn,
  };

  factory EncouragementRecord.fromJson(Map<String, dynamic> json) =>
      EncouragementRecord(
        id: json['id'] ?? '',
        type: EncouragementType.values[json['type'] ?? 0],
        text: json['text'] ?? '',
        sentAt: DateTime.parse(json['sentAt']),
        ledToCheckIn: json['ledToCheckIn'],
      );
}

/// 单个激励类型的有效性数据
class EncouragementStats {
  final EncouragementType type;
  /// 发送次数
  final int attempts;
  /// 成功次数（次日打卡）
  final int wins;
  /// 指数移动平均分数（EMA，0.0-1.0）
  final double effectiveness;

  const EncouragementStats({
    required this.type,
    this.attempts = 0,
    this.wins = 0,
    this.effectiveness = 0.5,
  });

  EncouragementStats recordAttempt({required bool success, double alpha = 0.2}) {
    // EMA update: new = alpha * success + (1-alpha) * old
    final newEff = alpha * (success ? 1.0 : 0.0) + (1 - alpha) * effectiveness;
    return EncouragementStats(
      type: type,
      attempts: attempts + 1,
      wins: wins + (success ? 1 : 0),
      effectiveness: newEff,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'attempts': attempts,
    'wins': wins,
    'effectiveness': effectiveness,
  };

  factory EncouragementStats.fromJson(Map<String, dynamic> json) =>
      EncouragementStats(
        type: EncouragementType.values[json['type'] ?? 0],
        attempts: json['attempts'] ?? 0,
        wins: json['wins'] ?? 0,
        effectiveness: (json['effectiveness'] ?? 0.5).toDouble(),
      );
}

/// ====== 自主感支持（SDT - Self-Determination Theory）======

/// 自主感丧失信号
class AutonomySignals {
  /// 连续几天用户对督促表示抗拒
  final int consecutivePushbackDays;
  /// 用户无视提醒的比例（0.0-1.0）
  final double ignoreRate;
  /// 最后一次用户表达抗拒的时间
  final DateTime? lastPushbackAt;
  /// 最后一次检测到自主感下降信号的时间
  final DateTime? lastAutonomyLossAt;
  /// EMA 自主感分数（越高=用户越感觉自主，1.0=满分）
  final double autonomyScore;

  const AutonomySignals({
    this.consecutivePushbackDays = 0,
    this.ignoreRate = 0.0,
    this.lastPushbackAt,
    this.lastAutonomyLossAt,
    this.autonomyScore = 1.0,
  });

  /// 是否处于自主感下降状态
  bool get isAutonomyLow =>
      autonomyScore < 0.5 || consecutivePushbackDays >= 2;

  /// 是否处于抗拒状态
  bool get isResisting => consecutivePushbackDays >= 1;

  AutonomySignals copyWith({
    int? consecutivePushbackDays,
    double? ignoreRate,
    DateTime? lastPushbackAt,
    DateTime? lastAutonomyLossAt,
    double? autonomyScore,
  }) => AutonomySignals(
    consecutivePushbackDays: consecutivePushbackDays ?? this.consecutivePushbackDays,
    ignoreRate: ignoreRate ?? this.ignoreRate,
    lastPushbackAt: lastPushbackAt ?? this.lastPushbackAt,
    lastAutonomyLossAt: lastAutonomyLossAt ?? this.lastAutonomyLossAt,
    autonomyScore: autonomyScore ?? this.autonomyScore,
  );

  Map<String, dynamic> toJson() => {
    'consecutivePushbackDays': consecutivePushbackDays,
    'ignoreRate': ignoreRate,
    'lastPushbackAt': lastPushbackAt?.toIso8601String(),
    'lastAutonomyLossAt': lastAutonomyLossAt?.toIso8601String(),
    'autonomyScore': autonomyScore,
  };

  factory AutonomySignals.fromJson(Map<String, dynamic> json) => AutonomySignals(
    consecutivePushbackDays: json['consecutivePushbackDays'] ?? 0,
    ignoreRate: (json['ignoreRate'] ?? 0.0).toDouble(),
    lastPushbackAt: json['lastPushbackAt'] != null
        ? DateTime.parse(json['lastPushbackAt'])
        : null,
    lastAutonomyLossAt: json['lastAutonomyLossAt'] != null
        ? DateTime.parse(json['lastAutonomyLossAt'])
        : null,
    autonomyScore: (json['autonomyScore'] ?? 1.0).toDouble(),
  );
}

/// ====== 宠物币交易记录原因
enum PetCoinReason {
  dailyCheckIn,   // 每日打卡
  streak7,        // 连续7天
  streak30,       // 连续30天
  bossComplete,   // 完成月度Boss
  badgeUnlock,    // 解锁成就
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

/// 外观等级配置（对齐 PET_SYSTEM.md 设计：6阶段进化）
class PetAppearanceLevel {
  /// 等级 1-6
  final int level;
  final String name;
  /// 显示 emoji（进化光效叠加在宠物本体 emoji 上）
  final String evolutionEmoji;
  /// 解锁天数（累计打卡天数）
  final int requiredDays;

  const PetAppearanceLevel({
    required this.level,
    required this.name,
    required this.evolutionEmoji,
    required this.requiredDays,
  });

  /// 6阶段进化体系（PET_SYSTEM.md 设计）
  static const List<PetAppearanceLevel> stages = [
    PetAppearanceLevel(level: 1, name: '蛋',       evolutionEmoji: '🥚', requiredDays: 0),
    PetAppearanceLevel(level: 2, name: '孵化',     evolutionEmoji: '🐣', requiredDays: 3),
    PetAppearanceLevel(level: 3, name: '初级',   evolutionEmoji: '🔥', requiredDays: 7),
    PetAppearanceLevel(level: 4, name: '中级',   evolutionEmoji: '⚡', requiredDays: 30),
    PetAppearanceLevel(level: 5, name: '高级',   evolutionEmoji: '👑', requiredDays: 100),
    PetAppearanceLevel(level: 6, name: '终极',   evolutionEmoji: '🌟', requiredDays: 365),
  ];

  /// 根据累计打卡天数计算进化阶段
  static int calculateStage(int totalDays) {
    int result = 1;
    for (final stage in stages) {
      if (totalDays >= stage.requiredDays) {
        result = stage.level;
      }
    }
    return result;
  }

  static PetAppearanceLevel? getStage(int level) {
    try {
      return stages.firstWhere((l) => l.level == level);
    } catch (_) {
      return null;
    }
  }

  /// 获取当前阶段到下一阶段还差多少天
  static int? daysToNextStage(int currentLevel, int totalDays) {
    final nextStage = stages.where((s) => s.level == currentLevel + 1).firstOrNull;
    if (nextStage == null) return null; // 已到终极
    return nextStage.requiredDays - totalDays;
  }

  // ====== 向后兼容（代码里 level 字段仍用 1-5，增量到 1-6）======
  static const List<PetAppearanceLevel> levels = stages;

  static PetAppearanceLevel? getLevel(int level) => getStage(level);
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

// ===== 预设目标知识库 =====

/// 单个预设目标模板
class PresetGoalTemplate {
  final String id;
  final String name; // 显示名称
  final List<String> keywords; // 匹配关键词
  final String category; // 'health'|'learning'|'skill'|'finance'|'life'
  final List<String> monthlyPhases; // 月度阶段模板
  final List<DailyLeverTemplate> dailyActions; // 每日行动模板

  const PresetGoalTemplate({
    required this.id,
    required this.name,
    required this.keywords,
    required this.category,
    required this.monthlyPhases,
    required this.dailyActions,
  });

  /// 匹配度计算（0.0-1.0）
  double matchScore(String userGoal) {
    final lower = userGoal.toLowerCase();
    int hits = 0;
    for (final kw in keywords) {
      if (lower.contains(kw.toLowerCase())) hits++;
    }
    if (keywords.isEmpty) return 0;
    return hits / keywords.length;
  }
}

/// 每日行动模板
class DailyLeverTemplate {
  final String action; // 行动描述，含占位符 {param}
  final String unit; // 单位（分钟/个/页）
  final String paramHint; // 参数提示

  const DailyLeverTemplate({
    required this.action,
    required this.unit,
    required this.paramHint,
  });

  /// 填充参数后生成具体行动
  String fill({int? minutes, int? count, int? pages}) {
    var result = action;
    if (minutes != null) result = result.replaceAll('{minutes}', '$minutes');
    if (count != null) result = result.replaceAll('{count}', '$count');
    if (pages != null) result = result.replaceAll('{pages}', '$pages');
    return result;
  }
}

/// 预设目标知识库
class PresetGoalLibrary {
  static const List<PresetGoalTemplate> _presets = [
    // ===== 健康类 =====
    PresetGoalTemplate(
      id: 'fitness_general',
      name: '健身运动',
      keywords: ['健身', '运动', '锻炼', '体能', '健康'],
      category: 'health',
      monthlyPhases: [
        '第1月：建立运动习惯（每周3次）',
        '第2月：提升强度（每周4次）',
        '第3月：突破瓶颈（每周5次）',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '做{minutes}分钟{activity}',
          unit: '分钟',
          paramHint: '如：20分钟慢跑',
        ),
        DailyLeverTemplate(
          action: '做{count}个俯卧撑',
          unit: '个',
          paramHint: '如：20个俯卧撑',
        ),
      ],
    ),
    PresetGoalTemplate(
      id: 'running',
      name: '跑步',
      keywords: ['跑步', '慢跑', '马拉松', '跑步习惯'],
      category: 'health',
      monthlyPhases: [
        '第1月：建立跑步习惯（每周3次，每次20分钟）',
        '第2月：提升跑量（每周4次，每次30分钟）',
        '第3月：连续跑完5公里',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '跑{minutes}分钟',
          unit: '分钟',
          paramHint: '如：25分钟慢跑',
        ),
        DailyLeverTemplate(
          action: '做{count}分钟拉伸',
          unit: '分钟',
          paramHint: '如：5分钟跑后拉伸',
        ),
      ],
    ),
    PresetGoalTemplate(
      id: 'weight_loss',
      name: '减脂',
      keywords: ['减脂', '减肥', '瘦身', '体脂'],
      category: 'health',
      monthlyPhases: [
        '第1月：调整饮食结构（戒零食）',
        '第2月：配合有氧运动（每周4次）',
        '第3月：进入减脂加速期',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '做{minutes}分钟有氧运动',
          unit: '分钟',
          paramHint: '如：30分钟跳绳',
        ),
        DailyLeverTemplate(
          action: '记录饮食（拍照）',
          unit: '次',
          paramHint: '早中晚各1次',
        ),
      ],
    ),

    // ===== 学习类 =====
    PresetGoalTemplate(
      id: 'reading',
      name: '阅读习惯',
      keywords: ['阅读', '读书', '看书', '阅读习惯'],
      category: 'learning',
      monthlyPhases: [
        '第1月：建立每日阅读习惯（每天10页）',
        '第2月：提升阅读速度（每天20页）',
        '第3月：主题阅读（选定方向深入）',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '读{pages}页书',
          unit: '页',
          paramHint: '如：20页',
        ),
        DailyLeverTemplate(
          action: '写{count}句话读书笔记',
          unit: '句',
          paramHint: '如：3句话感想',
        ),
      ],
    ),
    PresetGoalTemplate(
      id: 'english',
      name: '英语提升',
      keywords: ['英语', '英文', '学英语', '英语学习', '口语', '听力'],
      category: 'learning',
      monthlyPhases: [
        '第1月：词汇积累（每天背{count}个单词）',
        '第2月：听力突破（每天{minutes}分钟听力）',
        '第3月：口语练习（每天跟读）',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '背{count}个英语单词',
          unit: '个',
          paramHint: '如：20个单词',
        ),
        DailyLeverTemplate(
          action: '听{minutes}分钟英语',
          unit: '分钟',
          paramHint: '如：15分钟',
        ),
        DailyLeverTemplate(
          action: '跟读{minutes}分钟英语音频',
          unit: '分钟',
          paramHint: '如：10分钟影子跟读',
        ),
      ],
    ),
    PresetGoalTemplate(
      id: 'exam_prep',
      name: '备考复习',
      keywords: ['考试', '备考', '复习', '考研', 'CDA', '考证'],
      category: 'learning',
      monthlyPhases: [
        '第1月：过完一遍基础知识',
        '第2月：专项突破（按章节刷题）',
        '第3月：模拟考试+查漏补缺',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '学{count}节课程内容',
          unit: '节',
          paramHint: '如：2节课',
        ),
        DailyLeverTemplate(
          action: '做{count}道练习题',
          unit: '道',
          paramHint: '如：15道题',
        ),
        DailyLeverTemplate(
          action: '复习{count}页笔记',
          unit: '页',
          paramHint: '如：10页',
        ),
      ],
    ),

    // ===== 技能类 =====
    PresetGoalTemplate(
      id: 'programming',
      name: '编程学习',
      keywords: ['编程', '代码', '程序员', 'Python', 'Java', '前端', 'Flutter'],
      category: 'skill',
      monthlyPhases: [
        '第1月：基础语法+小项目',
        '第2月：框架学习+实战项目',
        '第3月：项目完善+作品集',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '写{count}行代码',
          unit: '行',
          paramHint: '如：50行',
        ),
        DailyLeverTemplate(
          action: '学{minutes}分钟编程课程',
          unit: '分钟',
          paramHint: '如：30分钟',
        ),
      ],
    ),
    PresetGoalTemplate(
      id: 'writing',
      name: '写作',
      keywords: ['写作', '写文章', '内容创作', '自媒体', '写小说'],
      category: 'skill',
      monthlyPhases: [
        '第1月：建立写作习惯（每天写）',
        '第2月：提升文章质量',
        '第3月：固定发布节奏',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '写{count}字',
          unit: '字',
          paramHint: '如：500字',
        ),
        DailyLeverTemplate(
          action: '修改{count}段旧文章',
          unit: '段',
          paramHint: '如：2段',
        ),
      ],
    ),

    // ===== 财务类 =====
    PresetGoalTemplate(
      id: 'saving',
      name: '存钱理财',
      keywords: ['存钱', '理财', '储蓄', '省钱', '财务自由'],
      category: 'finance',
      monthlyPhases: [
        '第1月：记账+分析消费习惯',
        '第2月：制定预算+强制储蓄',
        '第3月：开始低风险投资',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '记录一笔消费',
          unit: '条',
          paramHint: '随手记',
        ),
        DailyLeverTemplate(
          action: '检查今日支出是否超预算',
          unit: '次',
          paramHint: '1次/天',
        ),
      ],
    ),

    // ===== 生活类 =====
    PresetGoalTemplate(
      id: 'early_bird',
      name: '早起习惯',
      keywords: ['早起', '早睡', '作息', '生物钟'],
      category: 'life',
      monthlyPhases: [
        '第1周：每天提前10分钟起床',
        '第2周：固定6:30起床',
        '第3周：固定6:00起床',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '{time}起床',
          unit: '时间',
          paramHint: '如：6:30',
        ),
        DailyLeverTemplate(
          action: '睡前{count}分钟不看手机',
          unit: '分钟',
          paramHint: '如：30分钟',
        ),
      ],
    ),
    PresetGoalTemplate(
      id: 'diet',
      name: '健康饮食',
      keywords: ['饮食', '健康饮食', '减油减糖', '营养'],
      category: 'life',
      monthlyPhases: [
        '第1月：戒掉明显不健康零食',
        '第2月：自己做饭（每周3次）',
        '第3月：固定健康饮食结构',
      ],
      dailyActions: [
        DailyLeverTemplate(
          action: '记录早/午/晚三餐',
          unit: '顿',
          paramHint: '拍照记录',
        ),
        DailyLeverTemplate(
          action: '喝{count}杯水',
          unit: '杯',
          paramHint: '如：8杯水',
        ),
      ],
    ),
  ];

  /// 根据用户输入找到最匹配的目标
  /// 返回（匹配模板, 匹配度）
  static (PresetGoalTemplate?, double) findBestMatch(String userGoal) {
    if (userGoal.trim().isEmpty) return (null, 0);

    PresetGoalTemplate? best;
    double bestScore = 0;

    for (final preset in _presets) {
      final score = preset.matchScore(userGoal);
      if (score > bestScore) {
        bestScore = score;
        best = preset;
      }
    }

    // 阈值：超过0.3分才认为是有效匹配
    return bestScore >= 0.3 ? (best, bestScore) : (null, 0);
  }

  /// 获取指定类别的所有预设
  static List<PresetGoalTemplate> byCategory(String category) {
    return _presets.where((p) => p.category == category).toList();
  }

  /// 获取所有类别
  static List<String> get categories {
    return _presets.map((p) => p.category).toSet().toList();
  }
}

/// 宠物执行动作的结果
class PetActionResult {
  final bool success;
  final String message;
  final String? summary; // 用于显示给用户

  PetActionResult({required this.success, required this.message, this.summary});
}

// ====== 成就系统扩展 ======

/// 成就/徽章数据模型
class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isHidden; // 是否是隐藏成就
  final int reward; // 解锁奖励金币

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    this.isUnlocked = false,
    this.unlockedAt,
    this.isHidden = false,
    this.reward = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'isHidden': isHidden,
    'reward': reward,
  };

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    emoji: json['emoji'],
    isUnlocked: json['isUnlocked'] ?? false,
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    isHidden: json['isHidden'] ?? false,
    reward: json['reward'] ?? 0,
  );
}

/// 所有成就列表（包括隐藏成就）
class AchievementDefinitions {
  static final List<Badge> all = [
    // 基础徽章
    Badge(id: 'first_checkin', name: '首次打卡', description: '完成第一次打卡', emoji: '🎯', reward: 5),
    Badge(id: 'streak_3', name: '初露头角', description: '连续打卡3天', emoji: '🔥', reward: 5),
    Badge(id: 'streak_7', name: '坚持一周', description: '连续打卡7天', emoji: '🔥', reward: 10),
    Badge(id: 'streak_30', name: '月度达人', description: '连续打卡30天', emoji: '⚡', reward: 20),
    Badge(id: 'streak_100', name: '百日大师', description: '连续打卡100天', emoji: '🏅', reward: 50),
    Badge(id: 'first_annual', name: '年度规划', description: '设置年度目标', emoji: '📅', reward: 5),
    Badge(id: 'first_boss', name: '挑战开始', description: '创建第一个月度Boss', emoji: '⚔️', reward: 5),
    Badge(id: 'boss_complete', name: 'Boss克星', description: '完成一个月的Boss挑战', emoji: '🏆', reward: 15),
    Badge(id: 'pet_adopt', name: '初次相遇', description: '领养你的宠物', emoji: '🐾', reward: 5),
    Badge(id: 'pet_evo', name: '共同成长', description: '宠物外观升级', emoji: '⬆️', reward: 10),
    // 隐藏成就
    Badge(id: 'night_owl', name: '夜猫子', description: '凌晨1点后打卡', emoji: '🦉', reward: 5, isHidden: true),
    Badge(id: 'early_bird', name: '早起鸟', description: '早上6点前打卡', emoji: '🐦', reward: 5, isHidden: true),
    Badge(id: 'perfect_week', name: '完美一周', description: '连续7天每天完成所有杠杆', emoji: '✨', reward: 10, isHidden: true),
    Badge(id: 'streak_master', name: '连续大师', description: '连续打卡30天', emoji: '💪', reward: 20, isHidden: true),
    Badge(id: 'late_night', name: '深夜党', description: '23点后打卡', emoji: '🌙', reward: 5, isHidden: true),
    Badge(id: 'first_chat', name: '首次对话', description: '和宠物聊第一次天', emoji: '💬', reward: 5, isHidden: true),
    Badge(id: 'template_user', name: '模板用户', description: '使用模板创建目标', emoji: '📋', reward: 5, isHidden: true),
    Badge(id: 'weekend_warrior', name: '周末战士', description: '连续4周周末都打卡', emoji: '🏔️', reward: 15, isHidden: true),
    Badge(id: 'centurion', name: '累计百日', description: '累计打卡100天', emoji: '🛡️', reward: 30, isHidden: true),
    Badge(id: 'comeback', name: '王者归来', description: 'streak断了后重新连续7天', emoji: '🔄', reward: 15, isHidden: true),
  ];
}
