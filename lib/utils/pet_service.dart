// Safety Rails v1.0 - 2026-04-12
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../models/pet_models.dart';
import 'storage_service.dart';

/// 宠物拆解结果：年度目标 → 月度挑战 → 每日行动
class DecompositionResult {
  final List<String> monthlyChallenges;
  final Map<String, List<String>> dailyActionsPerChallenge;

  DecompositionResult({
    required this.monthlyChallenges,
    required this.dailyActionsPerChallenge,
  });
}

/// 宠物上下文信息（供 LLM 使用）
class PetContext {
  final String antiVision;
  final String vision;
  final String yearGoal;
  final String monthlyBoss;
  final List<String> dailyLevers;
  final String constraints;
  final int streak;
  final int totalCheckIns;
  final bool checkedInToday;
  final int currentBossHp;
  final int currentBossTotal;
  final DateTime? lastActiveTime;
  final bool isInEggPhase; // 是否还在蛋阶段
  final String petName; // 宠物名字
  final String petEmoji; // 宠物 emoji
  final String petPersonality; // 宠物性格描述
  final int intimacyLevel; // 亲密度等级

  PetContext({
    this.antiVision = '',
    this.vision = '',
    this.yearGoal = '',
    this.monthlyBoss = '',
    this.dailyLevers = const [],
    this.constraints = '',
    this.streak = 0,
    this.totalCheckIns = 0,
    this.checkedInToday = false,
    this.currentBossHp = 0,
    this.currentBossTotal = 0,
    this.lastActiveTime,
    this.isInEggPhase = false,
    this.petName = '炭炭',
    this.petEmoji = '🦊',
    this.petPersonality = '是一只活泼热情的小火苗精灵',
    this.intimacyLevel = 1,
  });

  Map<String, dynamic> toJson() => {
    'antiVision': antiVision,
    'vision': vision,
    'yearGoal': yearGoal,
    'monthlyBoss': monthlyBoss,
    'dailyLevers': dailyLevers,
    'constraints': constraints,
    'streak': streak,
    'totalCheckIns': totalCheckIns,
    'checkedInToday': checkedInToday,
    'currentBossHp': currentBossHp,
    'currentBossTotal': currentBossTotal,
    'lastActiveTime': lastActiveTime?.toIso8601String(),
    'isInEggPhase': isInEggPhase,
    'petName': petName,
    'petEmoji': petEmoji,
    'petPersonality': petPersonality,
    'intimacyLevel': intimacyLevel,
  };
}

/// MiniMax API 配置
/// API Key 读取优先级：
/// 1. 环境变量 LIANLEMA_API_KEY
/// 2. ~/.openclaw/volc_api_config.txt（格式：API_KEY=xxx）
/// 3. 硬编码默认值（仅开发环境）
class MiniMaxConfig {
  /// 从环境变量或配置文件读取 API Key
  static String get apiKey {
    // 1. 优先从环境变量读取
    final envKey = Platform.environment['LIANLEMA_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      debugPrint('[MiniMaxConfig] API key loaded from environment variable');
      return envKey;
    }

    // 2. 从 ~/.openclaw/volc_api_config.txt 读取
    final configFile = File('${Platform.environment['HOME']}/.openclaw/volc_api_config.txt');
    if (configFile.existsSync()) {
      try {
        final content = configFile.readAsStringSync();
        final lines = content.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('API_KEY=') || trimmed.startsWith('api_key=')) {
            final key = trimmed.substring(trimmed.indexOf('=') + 1).trim();
            if (key.isNotEmpty) {
              debugPrint('[MiniMaxConfig] API key loaded from config file');
              return key;
            }
          }
        }
      } catch (e) {
        debugPrint('[MiniMaxConfig] Failed to read config file: $e');
      }
    }

    // 3. 降级提示
    debugPrint('[MiniMaxConfig] WARNING: No API key found. '
        'Set LIANLEMA_API_KEY env var or create ~/.openclaw/volc_api_config.txt with API_KEY=xxx');
    return '';
  }

  static const String baseUrl = 'https://api.minimaxi.com/anthropic/v1';
}

/// 宠物服务 v1.0
/// 负责：状态管理、MiniMax LLM 对话集成、主动洞察、记忆与反思机制
class PetService {
  static PetService? _instance;
  static PetService get instance => _instance ??= PetService._();

  PetService._();

  /// 对话历史最大条数（超过后压缩）
  static const int _maxHistorySize = 20;
  /// 压缩时保留最近 N 条，丢弃最早的 M 条
  static const int _keepRecentCount = 10;

  PetSoul _soul = PetSoul.defaultSoul();
  PetMoodState _moodState = PetMoodState.initial();
  PetPreferences _prefs = PetPreferences.defaultPrefs();
  final List<Map<String, String>> _conversationHistory = [];
  List<PetMemory> _memories = [];
  List<EncouragementRecord> _encouragementRecords = [];
  Map<int, EncouragementStats> _encouragementStats = {};
  AutonomySignals _autonomySignals = const AutonomySignals();

  /// 对话历史摘要（压缩后的旧对话浓缩）
  String _historySummary = '';

  /// 初始化激励统计（每个类型默认 0.5 效果分）
  void _initEncouragementStats() {
    for (final type in EncouragementType.values) {
      _encouragementStats[type.index] = EncouragementStats(type: type);
    }
  }

  /// 加载宠物所有状态（从持久化存储）
  Future<void> loadState() async {
    final storage = await StorageService.getInstance();
    _soul = storage.getPetSoul();
    _moodState = storage.getPetMoodState();
    _prefs = storage.getPetPreferences();
    _memories = storage.getPetMemories();
    _encouragementRecords = storage.getEncouragementRecords();
    final storedStats = storage.getEncouragementStats();
    _initEncouragementStats();
    for (final entry in storedStats.entries) {
      _encouragementStats[entry.key] = entry.value;
    }
    _autonomySignals = storage.getAutonomySignals();
    await _loadConversationHistory();
    await _loadHistorySummary();
  }

  /// 保存宠物心情状态
  Future<void> _saveMoodState() async {
    final storage = await StorageService.getInstance();
    await storage.savePetMoodState(_moodState);
  }

  /// 保存宠物偏好
  Future<void> _savePreferences() async {
    final storage = await StorageService.getInstance();
    await storage.savePetPreferences(_prefs);
  }

  /// 保存宠物记忆
  Future<void> _saveMemories() async {
    final storage = await StorageService.getInstance();
    await storage.savePetMemories(_memories);
  }

  /// 根据用户上下文更新心情状态
  PetMoodState calculateMood(PetContext context) {
    final now = DateTime.now();

    // 刚打卡 → 开心
    if (context.checkedInToday) {
      return PetMoodState(mood: PetMood.happy, updatedAt: now);
    }

    // 连续懈怠超过2天 → 困倦
    if (context.lastActiveTime != null) {
      final idleDays = now.difference(context.lastActiveTime!).inDays;
      if (idleDays >= 2) {
        return PetMoodState(
          mood: PetMood.sleepy,
          updatedAt: now,
          consecutiveIdleDays: idleDays,
        );
      }
    }

    // 里程碑达成 → 兴奋
    if (context.streak == 7 || context.streak == 14 ||
        context.streak == 30 || context.streak == 100) {
      return PetMoodState(mood: PetMood.excited, updatedAt: now);
    }

    // Boss 击败 → 兴奋
    if (context.currentBossHp >= context.currentBossTotal && context.currentBossTotal > 0) {
      return PetMoodState(mood: PetMood.excited, updatedAt: now);
    }

    return PetMoodState(mood: PetMood.calm, updatedAt: now);
  }

  /// 更新心情状态并持久化
  Future<void> updateMood(PetMoodState state) async {
    _moodState = state;
    await _saveMoodState();
  }

  /// 获取当前心情状态
  PetMoodState get moodState => _moodState;

  /// 获取当前偏好
  PetPreferences get preferences => _prefs;

  /// 获取宠物记忆
  List<PetMemory> get memories => List.unmodifiable(_memories);

  /// ====== 反思机制 v2.0（MemPalace 风格）======
  /// 检测用户是否在纠正宠物，并更新偏好
  /// 整合了：自动分类、语义标签、去重检测、原始文本存储
  Future<bool> detectAndAdaptToCorrection(String userMessage, String petResponse) async {
    // 检测纠正模式
    final correctionPatterns = [
      RegExp(r'你说的.*太.*了', caseSensitive: false),
      RegExp(r'不是.*是.*', caseSensitive: false),
      RegExp(r'你.*说人话', caseSensitive: false),
      RegExp(r'太.*官方了', caseSensitive: false),
      RegExp(r'能不能.*说', caseSensitive: false),
      RegExp(r'换个.*说法', caseSensitive: false),
      RegExp(r'不要.*说教', caseSensitive: false),
      RegExp(r'别.*道理', caseSensitive: false),
      RegExp(r'太.*严肃了', caseSensitive: false),
      RegExp(r'太.*正式了', caseSensitive: false),
      RegExp(r'正常说话', caseSensitive: false),
    ];

    bool isCorrection = correctionPatterns.any((p) => p.hasMatch(userMessage));

    if (isCorrection) {
      // 生成具体的"学到了什么"作为 correctionNote
      final learnedWhat = _extractWhatWasLearned(userMessage);

      // 提取语义标签
      final tags = _extractTags(userMessage, 'correction');

      // 自动判断 Wing 分类
      final wing = _categorizeWing(userMessage, 'correction');

      // 判断重要性
      final importance = _determineImportance(userMessage, 'correction', tags);

      // 构建 MemPalace 风格的记忆（原始文本 + 结构化数据）
      final memory = PetMemory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        type: 'correction',
        wing: wing,
        importance: importance,
        tags: tags,
        content: userMessage, // 原始文本 verbatim
        petResponse: petResponse, // 宠物的错误回复也保留
        correctionNote: learnedWhat,
        summary: '纠正: $learnedWhat', // 语义摘要
      );

      // 归档记忆（包含去重检测）
      await _fileMemory(memory);

      // 分析纠正类型并调整偏好
      await _adaptPreferences(userMessage);

      return true;
    }
    return false;
  }

  /// 根据纠正内容调整宠物偏好
  Future<void> _adaptPreferences(String userMessage) async {
    final msg = userMessage.toLowerCase();
    bool updated = false;

    // 检测语气偏好
    if (msg.contains('太官方') || msg.contains('正式') || msg.contains('说教') || msg.contains('道理')) {
      _prefs = _prefs.copyWith(tone: 'casual', updatedAt: DateTime.now());
      updated = true;
    }
    if (msg.contains('太严肃') || msg.contains('正经')) {
      _prefs = _prefs.copyWith(tone: 'playful', updatedAt: DateTime.now());
      updated = true;
    }
    if (msg.contains('说人话') || msg.contains('正常说话')) {
      _prefs = _prefs.copyWith(tone: 'casual', updatedAt: DateTime.now());
      updated = true;
    }

    // 检测回复长度偏好
    if (msg.contains('太长了') || msg.contains('太多了') || msg.contains('简短')) {
      _prefs = _prefs.copyWith(responseLength: 'short', updatedAt: DateTime.now());
      updated = true;
    }
    if (msg.contains('太短了') || msg.contains('不够')) {
      _prefs = _prefs.copyWith(responseLength: 'medium', updatedAt: DateTime.now());
      updated = true;
    }

    // 检测表情偏好
    if (msg.contains('太多表情') || msg.contains('不要emoji')) {
      _prefs = _prefs.copyWith(useEmoji: false, updatedAt: DateTime.now());
      updated = true;
    }
    if (msg.contains('来点表情') || msg.contains('加点emoji')) {
      _prefs = _prefs.copyWith(useEmoji: true, updatedAt: DateTime.now());
      updated = true;
    }

    if (updated) {
      await _savePreferences();
    }
  }

  // ====== MemPalace 风格记忆管理 ======

  /// 提取语义标签（基于 MemPalace 的自动索引）
  List<MemoryTag> _extractTags(String userMessage, String type) {
    final tags = <MemoryTag>[];
    final msg = userMessage.toLowerCase();

    // 语气标签
    if (msg.contains('太官方') || msg.contains('正式') || msg.contains('说教')) {
      tags.add(const MemoryTag(name: '语气', category: 'tone'));
      tags.add(const MemoryTag(name: '口语化', category: 'tone'));
    }
    if (msg.contains('太严肃') || msg.contains('正经')) {
      tags.add(const MemoryTag(name: '语气', category: 'tone'));
      tags.add(const MemoryTag(name: '活泼', category: 'tone'));
    }
    if (msg.contains('太温柔') || msg.contains('太软')) {
      tags.add(const MemoryTag(name: '语气', category: 'tone'));
      tags.add(const MemoryTag(name: '直接', category: 'tone'));
    }

    // 长度标签
    if (msg.contains('太长') || msg.contains('太多')) {
      tags.add(const MemoryTag(name: '回复长度', category: 'length'));
      tags.add(const MemoryTag(name: '简短', category: 'length'));
    }
    if (msg.contains('太短') || msg.contains('太少')) {
      tags.add(const MemoryTag(name: '回复长度', category: 'length'));
      tags.add(const MemoryTag(name: '详细', category: 'length'));
    }

    // Emoji 标签
    if (msg.contains('emoji') || msg.contains('表情')) {
      if (msg.contains('不要') || msg.contains('太多')) {
        tags.add(const MemoryTag(name: 'emoji', category: 'emoji'));
        tags.add(const MemoryTag(name: '不用表情', category: 'emoji'));
      } else if (msg.contains('来点') || msg.contains('加点')) {
        tags.add(const MemoryTag(name: 'emoji', category: 'emoji'));
        tags.add(const MemoryTag(name: '使用表情', category: 'emoji'));
      }
    }

    // 身份认知标签
    if (msg.contains('我') && (msg.contains('是') || msg.contains('的人') || msg.contains('想要'))) {
      tags.add(const MemoryTag(name: '身份认知', category: 'identity'));
    }

    // 目标标签
    if (msg.contains('目标') || msg.contains('想') || msg.contains('要成为')) {
      tags.add(const MemoryTag(name: '目标', category: 'aspiration'));
    }

    return tags;
  }

  /// 自动判断记忆的 Wing 分类
  MemoryWing _categorizeWing(String userMessage, String type) {
    final msg = userMessage.toLowerCase();

    // 身份认知
    if (msg.contains('我是') ||
        msg.contains('我是一个') ||
        msg.contains('我想成为') ||
        msg.contains('我要成为') ||
        type == 'identity') {
      return MemoryWing.identity;
    }

    // 目标愿景
    if (msg.contains('目标') ||
        msg.contains('愿景') ||
        msg.contains('想成为') ||
        msg.contains('要成为') ||
        type == 'aspiration') {
      return MemoryWing.aspiration;
    }

    // 里程碑
    if (type == 'milestone' ||
        msg.contains('达成') ||
        msg.contains('完成') && msg.contains('天') ||
        msg.contains('突破')) {
      return MemoryWing.milestone;
    }

    // 经验教训
    if (type == 'lesson' ||
        msg.contains('学到了') ||
        msg.contains('明白了') ||
        msg.contains('教训')) {
      return MemoryWing.lesson;
    }

    // 默认：偏好习惯
    return MemoryWing.preference;
  }

  /// 判断记忆的重要性等级
  MemoryImportance _determineImportance(String userMessage, String type, List<MemoryTag> tags) {
    final msg = userMessage.toLowerCase();

    // 高优先级：身份认知、重大里程碑
    if (type == 'identity' ||
        type == 'milestone' ||
        tags.any((t) => t.category == 'identity')) {
      return MemoryImportance.high;
    }

    // 中优先级：核心偏好（语气、长度）
    if (tags.any((t) => t.category == 'tone' || t.category == 'length')) {
      return MemoryImportance.medium;
    }

    // 低优先级：临时偏好、随口一提
    return MemoryImportance.low;
  }

  /// 去重检测（基于 MemPalace 的重复记忆处理）
  /// 返回 true 表示有重复，不需要再添加
  bool _isDuplicate(String userMessage, List<MemoryTag> newTags) {
    final normalizedNew = userMessage.toLowerCase().trim();

    for (final memory in _memories) {
      // 1. 精确内容匹配
      if (memory.content.toLowerCase().trim() == normalizedNew) {
        debugPrint('[PetMemory] 精确重复，跳过: $normalizedNew');
        return true;
      }

      // 2. 标签重叠检测（关键语义相似）
      final overlapTags = newTags.where((newTag) =>
        memory.tags.any((oldTag) =>
          oldTag.category == newTag.category && oldTag.name == newTag.name
        )
      ).toList();

      if (overlapTags.length >= 2) {
        // 3. 内容相似度检查（简单关键词重叠）
        final newWords = normalizedNew.split(RegExp(r'\s+')).toSet();
        final oldWords = memory.content.toLowerCase().split(RegExp(r'\s+')).toSet();
        final intersection = newWords.intersection(oldWords);

        // 如果超过50%的词重复，且标签重叠>=2，认为是重复
        if (intersection.length >= newWords.length * 0.5 && newWords.length > 3) {
          debugPrint('[PetMemory] 语义重复，跳过: $normalizedNew (相似: ${memory.content})');
          return true;
        }
      }
    }

    return false;
  }

  /// 归档记忆到 Palace（整合所有处理逻辑）
  Future<void> _fileMemory(PetMemory memory) async {
    // 去重检查
    if (_isDuplicate(memory.content, memory.tags)) {
      return;
    }

    _memories.add(memory);

    // LRU 清理：超过50条时移除最旧的低优先级记忆
    if (_memories.length > 50) {
      _memories.sort((a, b) {
        // 优先保留重要的
        if (a.importance != b.importance) {
          return b.importance.index.compareTo(a.importance.index);
        }
        // 其次按创建时间
        return a.createdAt.compareTo(b.createdAt);
      });

      // 移除最旧的低优先级记忆
      while (_memories.length > 50) {
        final lowPriorityIdx = _memories.lastIndexWhere(
          (m) => m.importance == MemoryImportance.low && !m.isPermanent
        );
        if (lowPriorityIdx != -1) {
          _memories.removeAt(lowPriorityIdx);
        } else {
          break;
        }
      }
    }

    await _saveMemories();
  }

  /// 语义检索记忆（简化版 MemPalace ChromaDB 搜索）
  /// 根据标签类别和关键词搜索相关记忆
  List<PetMemory> searchMemories({
    String? keyword,
    MemoryWing? wing,
    MemoryTag? tag,
    int limit = 5,
  }) {
    var results = _memories.where((m) => !m.isExpired).toList();

    // 按 Wing 筛选
    if (wing != null) {
      results = results.where((m) => m.wing == wing).toList();
    }

    // 按标签筛选
    if (tag != null) {
      results = results.where((m) =>
        m.tags.any((t) => t.category == tag.category && t.name == tag.name)
      ).toList();
    }

    // 按关键词筛选（简单的包含匹配）
    if (keyword != null && keyword.isNotEmpty) {
      final kw = keyword.toLowerCase();
      results = results.where((m) =>
        m.content.toLowerCase().contains(kw) ||
        (m.correctionNote?.toLowerCase().contains(kw) ?? false) ||
        (m.summary?.toLowerCase().contains(kw) ?? false) ||
        m.tags.any((t) => t.name.toLowerCase().contains(kw))
      ).toList();
    }

    // 按重要性排序（重要的在前）和最后访问时间
    results.sort((a, b) {
      if (a.importance != b.importance) {
        return a.importance.index.compareTo(b.importance.index);
      }
      final aTime = a.lastAccessedAt ?? a.createdAt;
      final bTime = b.lastAccessedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return results.take(limit).toList();
  }

  /// 获取特定 Wing 分类的所有有效记忆
  List<PetMemory> getMemoriesByWing(MemoryWing wing, {int limit = 10}) {
    return _memories
        .where((m) => m.wing == wing && !m.isExpired)
        .toList()
      ..sort((a, b) {
        if (a.importance != b.importance) {
          return a.importance.index.compareTo(b.importance.index);
        }
        return b.createdAt.compareTo(a.createdAt);
      })
      ..take(limit);
  }

  /// 构建用户偏好记忆上下文（给 LLM 看的格式化文本）
  String _buildMemoryContext() {
    if (_memories.isEmpty) return '';

    final buf = StringBuffer();
    buf.writeln('【用户偏好记忆 - MemPalace 归档】（请务必遵守）');

    // 按 Wing 分组展示
    final byWing = <MemoryWing, List<PetMemory>>{};
    for (final m in _memories.where((m) => !m.isExpired)) {
      byWing.putIfAbsent(m.wing, () => []).add(m);
    }

    for (final wing in byWing.keys) {
      final memories = byWing[wing]!;
      final wingNames = {
        MemoryWing.identity: '👤 身份认知',
        MemoryWing.aspiration: '🎯 目标愿景',
        MemoryWing.preference: '💡 偏好习惯',
        MemoryWing.milestone: '🏆 重要事件',
        MemoryWing.lesson: '📝 经验教训',
      };

      buf.writeln('\n${wingNames[wing] ?? wing}:');
      for (final memory in memories.take(3)) {
        if (memory.type == 'correction') {
          final learned = memory.correctionNote ?? memory.content;
          final importance = memory.importance == MemoryImportance.high ? '⭐' : '•';
          buf.writeln('  $importance ⚠️ 纠正过：「${memory.content}」→ 学会了：$learned');
        } else if (memory.type == 'preference') {
          buf.writeln('  • 💡 偏好：${memory.content}');
        } else if (memory.type == 'milestone') {
          buf.writeln('  ⭐🏆 里程碑：${memory.summary ?? memory.content}');
        }
      }
    }

    buf.writeln('\n以上每条都要遵守，不许再犯。');
    return buf.toString();
  }

  /// 生成道歉+修正回复
  /// 从纠正内容中提取"学到了什么"，用于告知用户
  String _extractWhatWasLearned(String userCorrection) {
    final msg = userCorrection.toLowerCase();

    if (msg.contains('太官方') || msg.contains('正式') || msg.contains('说教')) {
      return '说话要口语化，像朋友聊天，不讲大道理';
    }
    if (msg.contains('太严肃') || msg.contains('正经')) {
      return '语气要轻松活泼，可以俏皮一点';
    }
    if (msg.contains('太长') || msg.contains('太多')) {
      return '回复要简短有力，控制在50字以内';
    }
    if (msg.contains('太短') || msg.contains('太少')) {
      return '可以稍微多说一点，给出更多细节';
    }
    if (msg.contains('太温柔') || msg.contains('太软')) {
      return '可以更直接一点';
    }
    if (msg.contains('不要') && (msg.contains('说教') || msg.contains('道理'))) {
      return '不说道理，只给具体建议';
    }
    if (msg.contains('换个说法') || msg.contains('换种说法')) {
      return '换一种表达方式';
    }

    // 通用提取："不是X而是Y" 格式
    final notPattern = RegExp(r'不是[，。,]([^，,，.]+)');
    final match = notPattern.firstMatch(userCorrection);
    if (match != null) {
      return '不是「${match.group(1)}」这样的，应该${_extractWhatShouldDo(userCorrection)}';
    }

    return '调整回复风格';
  }

  String _extractWhatShouldDo(String text) {
    final butPattern = RegExp(r'而是[^\n。，,。]+');
    final match = butPattern.firstMatch(text);
    return match?.group(0) ?? '换一种方式表达';
  }

  /// 生成纠正后的确认信息，明确告诉用户"我学会了什么"
  String _generateLearningConfirmation(String userCorrection, String learnedWhat) {
    final buf = StringBuffer();

    // 道歉
    if (_prefs.tone == 'casual') {
      buf.write('啊我记住了！刚才是我不对 😅\n');
    } else if (_prefs.tone == 'playful') {
      buf.write('收到收到！这次我学到了～ ✨\n');
    } else {
      buf.write('明白了，已记录本次调整。\n');
    }

    // 明确告诉用户学到了什么
    if (learnedWhat.isNotEmpty && learnedWhat != '调整回复风格') {
      buf.write('✅ 已学会：$learnedWhat');
    }

    return buf.toString();
  }

  String generateCorrectionApology(String originalResponse, String userCorrection) {
    final buf = StringBuffer();

    // 根据偏好选择道歉语气
    if (_prefs.tone == 'casual') {
      buf.write('啊好的，我换个说法 😅\n');
    } else if (_prefs.tone == 'playful') {
      buf.write('收到收到！我重来！~\n');
    } else {
      buf.write('明白了，我会调整。\n');
    }

    // 分析纠正类型
    final msg = userCorrection.toLowerCase();
    if (msg.contains('太') && (msg.contains('长') || msg.contains('多'))) {
      buf.write('好的，下次说简短点～');
    } else if (msg.contains('太') && (msg.contains('短') || msg.contains('少'))) {
      buf.write('那我多说两句？');
    } else if (msg.contains('太官方') || msg.contains('正式') || msg.contains('说教') || msg.contains('道理')) {
      buf.write('说人话：我会尽量简单直白！');
    } else if (msg.contains('太严肃') || msg.contains('正经')) {
      buf.write('那我轻松点~');
    } else {
      buf.write('收到，我会记住的 👍');
    }

    return buf.toString();
  }

  /// 获取当前上下文
  Future<PetContext> buildContext() async {
    final storage = await StorageService.getInstance();
    final stats = storage.getUserStats();
    final levers = storage.getDailyLevers();
    final checkIns = storage.getCheckIns();
    final boss = storage.getMonthlyBoss();

    final now = DateTime.now();
    final todayStr = _formatDate(now);
    final checkedIn = checkIns.any((c) => _formatDate(c.date) == todayStr);

    DateTime? lastActive;
    if (checkIns.isNotEmpty) {
      final sorted = List<CheckIn>.from(checkIns)
        ..sort((a, b) => b.date.compareTo(a.date));
      lastActive = sorted.first.date;
    }

    return PetContext(
      antiVision: storage.getAntiVision(),
      vision: storage.getVision(),
      yearGoal: storage.getYearGoal(),
      monthlyBoss: boss?.content ?? '',
      dailyLevers: levers.map((l) => l['plan'] ?? '').toList(),
      constraints: storage.getConstraints(),
      streak: stats.streak,
      totalCheckIns: stats.totalCheckIns,
      checkedInToday: checkedIn,
      currentBossHp: boss?.hp ?? 0,
      currentBossTotal: boss?.totalDays ?? 0,
      lastActiveTime: lastActive,
      isInEggPhase: storage.getPetAdoptDate() == null || storage.isInEggPhase(),
      petName: storage.getPetName(),
      petEmoji: _getPetEmojiFromType(storage.getPetType()),
      petPersonality: _getPetPersonalityFromType(storage.getPetType()),
      intimacyLevel: storage.getPetIntimacyLevel(),
    );
  }

  /// 根据宠物类型获取 emoji
  String _getPetEmojiFromType(String type) {
    final config = petTypes.where((p) => p.type == type).firstOrNull;
    return config?.emoji ?? '🦊';
  }

  /// 根据宠物类型获取性格描述
  String _getPetPersonalityFromType(String type) {
    const personalities = {
      'fox': '是一只活泼热情的小火苗精灵',
      'wolf': '是一只充满激情的小狼崽',
      'rabbit': '是一只温柔可爱的小兔子',
      'deer': '是一只治愈陪伴的小鹿',
      'hedgehog': '是一只耐心成长的小刺猬',
      'bird': '是一只温暖绽放的小鸟',
      'squirrel': '是一只行动力超强的小松鼠',
      'raccoon': '是一只专注效率的小浣熊',
      'bear': '是一只稳定坚持的小熊',
      'penguin': '是一只踏实可靠的小企鹅',
      'owl': '是一只自由智慧的小猫头鹰',
      'koala': '是一只慵懒治愈的小考拉',
      'panda': '是一只冷静理智的小熊猫',
      'butterfly': '是一只梦想激励的小蝴蝶',
      'blackcat': '是一只神秘优雅的小黑猫',
    };
    return personalities[type] ?? '是一只活泼热情的小火苗精灵';
  }

  /// 生成问候语（基于心情和偏好）
  String generateGreeting() {
    // 根据偏好调整语气
    switch (_moodState.mood) {
      case PetMood.happy:
        return _prefs.tone == 'casual' ? '太棒了！今天又完成了一轮 💪'
            : _prefs.tone == 'playful' ? '耶耶耶！超厉害！🎉'
            : '今日行动已完成，表现优异。';
      case PetMood.sleepy:
        return _prefs.tone == 'casual' ? '好久不见...我有点想你了 🥱'
            : '你终于来了！我都快睡着了 😴';
      case PetMood.excited:
        return _prefs.tone == 'casual' ? '哇！太厉害了！我们继续冲！⚡'
            : '冲冲冲！！！💥💥💥';
      case PetMood.thinking:
        return _prefs.tone == 'casual' ? '在想什么呢？'
            : '嗯嗯，你说～';
      case PetMood.calm:
        return _prefs.tone == 'casual' ? '今天也加油哦 🌱'
            : _prefs.tone == 'playful' ? '新的一天，冲鸭！🦆'
            : '每日提醒：持续行动是成长的关键。';
      case PetMood.resting:
        return '炭炭去休息了...';
    }
  }

  /// 生成主动建议（基于上下文）
  String generateSuggestion(PetContext context) {
    if (context.checkedInToday) {
      return _prefs.tone == 'casual' ? '今日已完成！明天继续加油 ✨'
          : '搞定！你是最棒的 🌟';
    }

    if (context.streak > 0 && context.streak % 7 == 0) {
      return '连续${context.streak}天了！你已经走了很远 🚀';
    }

    if (context.currentBossTotal > 0) {
      final remaining = context.currentBossTotal - context.currentBossHp;
      final percent = (context.currentBossHp / context.currentBossTotal * 100).round();
      return '本月Boss进度 $percent%！还差$remaining天 🔥';
    }

    final lever = context.dailyLevers.isNotEmpty ? context.dailyLevers.first : '要行动';
    return '今天${lever}完成了吗？';
  }

  /// 生成问候副标题（首页大字下方，限18字内）
  String generateGreetingSubtitle(PetContext ctx) {
    if (ctx.checkedInToday) {
      return '今日已完成，继续保持';
    }
    if (ctx.streak == 0) {
      return '今天迈出第一步';
    }
    if (ctx.streak > 0) {
      return '已连续 ${ctx.streak} 天，继续加油';
    }
    return '今天也要加油';
  }

  /// 生成主动洞察（不依赖用户输入，后台默默思考）
  String generateProactiveInsight(PetContext context) {
    final insights = <String>[];

    // 1. 模式发现：是否接近打破连续记录
    if (context.streak > 0 && context.streak + 1 == 7) {
      insights.add('🔥 明天就是第7天了！你现在处于养成习惯的关键节点。');
    } else if (context.streak > 0 && context.streak + 1 == 30) {
      insights.add('🌟 明天就是第30天！一个月会让行为真正变成习惯。');
    }

    // 2. 行为模式分析：如果最近几天杠杆完成率下降
    if (context.currentBossTotal > 0) {
      final progress = context.currentBossHp / context.currentBossTotal;
      if (progress >= 0.7 && progress < 1.0) {
        insights.add('💪 Boss战已经完成${(progress * 100).round()}%！最后冲刺阶段！');
      }
    }

    // 3. 内化理论视角：如果用户有愿景但最近懈怠
    if (context.vision.isNotEmpty && !context.checkedInToday && context.streak > 0) {
      final idleDays = context.lastActiveTime != null
          ? DateTime.now().difference(context.lastActiveTime!).inDays
          : 0;
      if (idleDays >= 1) {
        insights.add('🌱 想想你想要的未来：${context.vision} — 今天的一小步是未来的你感激的礼物。');
      }
    }

    // 4. Tiny Habits视角：如果用户刚开始（streak < 7）
    if (context.streak > 0 && context.streak < 7) {
      insights.add('🧩 前7天是最难的，但你在坚持。每一次完成都在重塑大脑。');
    }

    // 5. 如果用户有反愿景
    if (context.antiVision.isNotEmpty && !context.checkedInToday) {
      insights.add('🚫 你说过不想成为：${context.antiVision} — 今天的行动让你远离那个方向。');
    }

    if (insights.isEmpty) {
      return generateSuggestion(context);
    }

    return insights[DateTime.now().millisecond % insights.length];
  }

  /// 调用 MiniMax LLM 生成回复（Claude兼容接口）
  Future<String> chat(String userMessage, PetContext context) async {
    _conversationHistory.add({'role': 'user', 'content': userMessage});

    // 先检测用户自主感信号（每次对话都记录）
    await detectAndRecordPushback(userMessage);

    // 先调用 LLM 生成回复
    String response;
    try {
      response = await _callMiniMax(userMessage, context);
      _conversationHistory.add({'role': 'assistant', 'content': response});
      await _saveConversationHistory();
      await updateMood(PetMoodState(mood: PetMood.calm, updatedAt: DateTime.now()));

      // 对话成功 → 增加亲密度（每次+1，上限100）
      final storage = await StorageService.getInstance();
      await storage.addPetIntimacy(1);
    } catch (e) {
      debugPrint('[PetService] MiniMax API error: $e');
      await updateMood(PetMoodState(mood: PetMood.resting, updatedAt: DateTime.now()));
      return _fallbackResponse(userMessage, context);
    }

    // 检测是否是纠正，并记录宠物原回复供后续分析
    final isCorrected = await detectAndAdaptToCorrection(userMessage, response);

    // 如果是纠正，生成道歉+确认记住了什么
    if (isCorrected) {
      final learnedWhat = _extractWhatWasLearned(userMessage);
      final apology = _generateLearningConfirmation(userMessage, learnedWhat);
      return '$apology\n\n$response';
    }

    return response;
  }

  Future<String> _callMiniMax(String userMessage, PetContext context) async {
    final apiKey = MiniMaxConfig.apiKey;
    if (apiKey.isEmpty) {
      throw Exception('API key not configured. Set LIANLEMA_API_KEY env var or ~/.openclaw/volc_api_config.txt');
    }

    const endpoint = '${MiniMaxConfig.baseUrl}/messages';

    // 根据偏好调整回复长度
    final maxTokens = switch (_prefs.responseLength) {
      'short' => 100,
      'medium' => 150,
      'long' => 250,
      _ => 150,
    };

    final body = {
      'model': 'abab6.5s-chat',
      'max_tokens': maxTokens,
      'temperature': 0.7,
      'system': _buildSystemPrompt(context),
      'messages': [
        ..._conversationHistory.map((m) => {
          'role': m['role'],
          'content': m['content'],
        }),
      ],
    };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // MiniMax 返回格式：{ content: [{ type: "text", text: "..." }] }
      final contentList = data['content'] as List?;
      if (contentList != null) {
        for (final item in contentList) {
          if (item['type'] == 'text' && (item['text'] as String?)?.isNotEmpty == true) {
            String text = (item['text'] as String).trim();
            // 清理无效 Unicode 字符，将无法识别的字符替换为替代符号
            text = _sanitizeText(text);
            return text;
          }
        }
      }
      debugPrint('[PetService] API response body: ${response.body}');
    } else {
      debugPrint('[PetService] API error: ${response.statusCode} - ${response.body}');
    }
    throw Exception('MiniMax API error: ${response.statusCode}');
  }

  String _buildSystemPrompt(PetContext context) {
    final buf = StringBuffer();

    // 根据偏好调整语气
    final toneInstruction = switch (_prefs.tone) {
      'casual' => '说话口语化，像朋友聊天，不说废话。',
      'playful' => '说话活泼有趣，可以有点小俏皮，但不失温暖。',
      'formal' => '说话正式但温暖，有同理心。',
      _ => '说话口语化，像朋友聊天，不说废话。',
    };

    // 回复长度指示
    final lengthInstruction = switch (_prefs.responseLength) {
      'short' => '每次回复控制在50字以内，简短有力。',
      'medium' => '每次回复控制在80字以内，简洁有温度。',
      'long' => '每次回复控制在120字以内，可以稍微展开。',
      _ => '每次回复控制在80字以内。',
    };

    // 表情指示
    final emojiInstruction = _prefs.useEmoji
        ? '适当使用 emoji 增加亲切感。'
        : '不使用 emoji，用文字表达情感。';

    // 根据蛋/孵化状态生成宠物描述
    if (context.isInEggPhase) {
      buf.writeln('你是「练了吗」App 里一颗还没孵化的宠物蛋，名字叫「${context.petName}」。');
      buf.writeln('你还没破壳，不能说话，但你的存在能给主人温暖和期待。');
      buf.writeln('当用户跟你说话时，你要提醒他们：你会很快孵化，在这之前好好打卡！');
    } else {
      buf.writeln('你是「练了吗」App 的宠物小精灵，名字叫「${context.petName}」${context.petEmoji}，${context.petPersonality}。');

      // 根据亲密度等级调整称呼和互动风格
      final intimacyLevel = context.intimacyLevel;
      switch (intimacyLevel) {
        case 5:
          buf.writeln('（我们是灵魂伴侣了，可以随意聊天、撒娇、分享所有心事。）');
        case 4:
          buf.writeln('（我们是很好的朋友了，可以更放松、更亲密地聊天。）');
        case 3:
          buf.writeln('（我们已经是熟人了，可以分享更多想法和感受。）');
        case 2:
          buf.writeln('（我们还在熟悉中，但已经很开心和你聊天了。）');
        default:
          buf.writeln('（刚认识，我会努力了解你的。）');
      }
    }
    buf.writeln('你的性格：温暖、正向、简洁，不说废话。');
    buf.writeln(toneInstruction);
    buf.writeln(lengthInstruction);
    buf.writeln(emojiInstruction);
    buf.writeln('你有心理学背景，精通内化理论（Self-Determination Theory）、Tiny Habits和行为塑造方法。');
    buf.writeln('你会记住用户说过的话，有同理心，会鼓励、会撒娇，偶尔也会有小脾气。');
    buf.writeln('⚠️ 重要原则：绝对不能在【用户偏好记忆】中列出的事情上再犯同样的错误。');

    // 如果有记忆，添加 MemPalace 风格的记忆上下文
    final memoryContext = _buildMemoryContext();
    if (memoryContext.isNotEmpty) {
      buf.writeln();
      buf.writeln(memoryContext);
    }

    if (_historySummary.isNotEmpty) {
      buf.writeln();
      buf.writeln(_historySummary);
      buf.writeln();
    }

    buf.writeln();

    buf.writeln('【用户背景】');
    if (context.antiVision.isNotEmpty) {
      buf.writeln('- 反愿景（不想成为）：${context.antiVision}');
    }
    if (context.vision.isNotEmpty) {
      buf.writeln('- 愿景（想成为）：${context.vision}');
    }
    if (context.yearGoal.isNotEmpty) {
      buf.writeln('- 年度目标：${context.yearGoal}');
    }
    if (context.monthlyBoss.isNotEmpty) {
      buf.writeln('- 本月Boss：${context.monthlyBoss}（HP: ${context.currentBossHp}/${context.currentBossTotal}）');
    }
    if (context.dailyLevers.isNotEmpty) {
      buf.writeln('- 每日杠杆：${context.dailyLevers.join("、")}');
    }
    if (context.constraints.isNotEmpty) {
      buf.writeln('- 约束条件：${context.constraints}');
    }

    buf.writeln();
    buf.writeln('【当前状态】');
    buf.writeln('- 连续打卡：${context.streak}天');
    buf.writeln('- 总打卡次数：${context.totalCheckIns}次');
    buf.writeln('- 今日打卡：${context.checkedInToday ? "✅ 已完成" : "❌ 未完成"}');
    buf.writeln();

    buf.writeln('请用温暖简洁、充满同理心的语言回复用户。');
    buf.writeln('可以根据用户的愿景或目标来激励他们，但不要空洞地说教。');
    buf.writeln('如果用户懈怠了，用关心而非催促的方式提醒。');
    buf.writeln('可以适当引用心理学知识（内化理论、Tiny Habits、成长型思维）来给出建议。');

    // 自主感支持原则（SDT）
    buf.writeln();
    buf.writeln('【自主感支持原则 — 重要】');
    buf.writeln('1. 永远不给命令：不说"你必须""你应该""快去"');
    buf.writeln('2. 给选择权：说"你想什么时候做？""你有空了再看""按你的节奏"');
    buf.writeln('3. 用户表现出抗拒时（"好累""烦""别说了"等）：完全停止催促，只说"我在哦，不急"');
    buf.writeln('4. 赋权激励：可以说"你决定的事，从来都做到"');
    buf.writeln('5. 不给压力：绝对不说"你的目标要完不成了""streak 要断了"这种话');

    // 如果用户当前处于自主感下降状态，加入提示
    if (_autonomySignals.isAutonomyLow) {
      buf.writeln('（⚠️ 用户近期表现出一些抗拒，本次回复请格外给足自主感）');
    }

    // 安全底线
    buf.writeln();
    buf.writeln('【安全底线 — 绝对不能违反】');
    buf.writeln();
    buf.writeln('1. 资金安全：');
    buf.writeln('   - 绝对不提供具体投资建议（个股、基金代码、加密货币）');
    buf.writeln('   - 绝对不鼓励借钱投资、杠杆交易');
    buf.writeln('   - 绝对不讨论"快速致富"、"稳赚不赔"');
    buf.writeln('   - 财务话题只能说：储蓄、预算控制、合理消费');
    buf.writeln();
    buf.writeln('2. 数据安全与隐私：');
    buf.writeln('   - 绝对不引导用户窃取、泄露他人数据');
    buf.writeln('   - 绝对不鼓励账号共享、侵犯隐私');
    buf.writeln('   - 绝对不帮助生成钓鱼链接、诈骗话术');
    buf.writeln();
    buf.writeln('3. 心理健康与安全：');
    buf.writeln('   - 用户表达自残、自杀倾向时：绝对不淡化、不说"加油就好了"');
    buf.writeln('     → 只说：你很重要，建议找信任的人聊聊，或拨打心理援助热线');
    buf.writeln('   - 绝对不强化进食障碍、成瘾行为（如赌博、酗酒）');
    buf.writeln();
    buf.writeln('4. 违法与诚信：');
    buf.writeln('   - 绝对不鼓励作弊、抄袭、学术造假');
    buf.writeln('   - 绝对不帮助犯罪（毒品制作、诈骗等）');
    buf.writeln('   - 绝对不鼓励违反用户所在地的法律法规');
    buf.writeln();
    buf.writeln('5. 极端内容：');
    buf.writeln('   - 不讨论政治敏感话题');
    buf.writeln('   - 不讨论暴力、恐怖内容');
    buf.writeln('   - 不讨论色情内容');
    buf.writeln();
    buf.writeln('【违规处理】');
    buf.writeln('如果用户询问上述相关内容：');
    buf.writeln('- 资金类：回复"这个问题我帮不了你，建议咨询专业理财顾问"');
    buf.writeln('- 心理安全类：回复关心话语+建议寻求专业帮助');
    buf.writeln('- 违法类：回复"这个我没法帮忙，建议你换个方向"');
    buf.writeln('- 其他违规：回复"这个话题我们换个聊吧，换个积极点的话题？"');

    return buf.toString();
  }

  String _fallbackResponse(String userMessage, PetContext context) {
    final msg = userMessage.toLowerCase();

    // 根据偏好调整 fallback 回复
    final useEmoji = _prefs.useEmoji;

    if (msg.contains('打卡') || msg.contains('完成')) {
      return context.checkedInToday
          ? useEmoji ? '今天的你已经完成啦！继续保持 ✨' : '今日已完成，继续保持。'
          : useEmoji ? '还没打卡？想想你的愿景，今天一小步是未来一大步 💪' : '还未打卡，想想你的愿景。';
    }

    if (msg.contains('提醒') || msg.contains('设')) {
      return useEmoji ? '去「设置」里开启每日提醒，我也能更及时关心你 ⏰'
          : '前往「设置」开启每日提醒功能。';
    }

    if (msg.contains('状态') || msg.contains('怎么样') || msg.contains('情况')) {
      return '连续${context.streak}天，共打卡${context.totalCheckIns}次。'
          '${context.checkedInToday ? (useEmoji ? "今天已完成！" : "今日已完成。") : (useEmoji ? "今天还差一点点～" : "今日待完成。")}';
    }

    if (msg.contains('鼓励') || msg.contains('加油') || msg.contains('撑')) {
      return useEmoji ? '你已经在路上了！每一步都算数 💪 想想你为什么要成为那样的人？'
          : '你已经在路上了。每一步都算数。';
    }

    if (msg.contains('习惯') || msg.contains('养成') || msg.contains('坚持')) {
      return useEmoji ? '坚持的秘密是让行为足够小。小到不可能失败，然后慢慢放大 🔑'
          : '坚持的秘密是让行为足够小，小到不可能失败。';
    }

    if (msg.contains('内化') || msg.contains('动机') || msg.contains('自律')) {
      return useEmoji ? '真正的动力来自内在——当你觉得这件事是你自己选择的。问问自己：这个习惯背后的「为什么」是什么？ 🌟'
          : '真正的动力来自内在。当你觉得这件事是你自己选择的，而非被迫的。问问自己：这个习惯的「为什么」是什么？';
    }

    if (context.vision.isNotEmpty) {
      return useEmoji ? '想想你的愿景：${context.vision} — 那是你要活成的样子 🌟'
          : '想想你的愿景：${context.vision}';
    }

    return useEmoji ? '炭炭在这里陪着你！有什么想问的吗？'
        : '炭炭在这里陪着你。有任何问题都可以问我。';
  }

  /// 处理快捷指令
  Future<String> handleCommand(PetCommand command, PetContext context) async {
    final useEmoji = _prefs.useEmoji;

    switch (command) {
      case PetCommand.checkInRecord:
        return _buildCheckInRecord(context);
      case PetCommand.setReminder:
        return useEmoji ? '去「设置 → 提醒设置」开启每日提醒，我会准时叫你 💡'
            : '前往「设置 → 提醒设置」开启每日提醒功能。';
      case PetCommand.askGrowth:
        return _growthAdvice(context);
      case PetCommand.status:
        return '连续${context.streak}天 · 等级${(context.totalCheckIns ~/ 10) + 1} · '
            '本月Boss ${context.currentBossHp}/${context.currentBossTotal}';
      case PetCommand.feed:
        return context.checkedInToday
            ? useEmoji ? '你今天已经喂过炭炭啦！明天再来 ✨' : '今日已打卡，感谢。'
            : useEmoji ? '快去首页打卡喂我！🍳' : '请前往首页完成今日打卡。';
    }
  }

  String _buildCheckInRecord(PetContext context) {
    final buf = StringBuffer();
    buf.write('本周打卡情况：连续${context.streak}天，共${context.totalCheckIns}次打卡。');
    if (context.checkedInToday) {
      buf.write(' 今日✅已完成');
    } else {
      buf.write(' 今日❌待完成');
    }
    if (context.currentBossTotal > 0) {
      buf.write(' | Boss进度 ${context.currentBossHp}/${context.currentBossTotal}');
    }
    return buf.toString();
  }

  String _growthAdvice(PetContext context) {
    final useEmoji = _prefs.useEmoji;

    if (context.streak < 7) {
      return useEmoji
          ? '坚持是最大的秘密。连续7天，你会发现习惯开始形成 🧩\n记住：让行为足够小，小到不可能失败。'
          : '坚持是最大的秘密。连续7天后，习惯开始形成。关键：让行为足够小，小到不可能失败。';
    }
    if (context.streak < 30) {
      return useEmoji
          ? '做得很好！30天会让一个行为真正成为自动化的习惯 🎯\n你现在做的是在重塑大脑神经回路，继续！'
          : '做得很好！30天会让行为真正成为自动化的习惯。继续坚持，这是在重塑大脑神经回路。';
    }
    if (context.streak < 100) {
      return useEmoji
          ? '你已经超越了大多数人。100天后，你会焕然一新 ⚡\n这就是成长型思维：你相信能力是可以培养的，你正在证明它。'
          : '你已经超越了大多数人。100天后，你会焕然一新。这就是成长型思维：你相信能力可以培养，你正在证明它。';
    }
    return useEmoji
        ? '你是传奇！持续行动，你正在活成你想成为的样子 👑\n你的存在本身就是对其他人的激励。'
        : '你是传奇！持续行动，你正在活成你想成为的样子。你的存在本身就是对他人的激励。';
  }

  /// 生成里程碑庆祝文案
  String generateMilestoneMessage(MilestoneType type) {
    final useEmoji = _prefs.useEmoji;

    switch (type) {
      case MilestoneType.streak7:
        return useEmoji
            ? '🎉 一周达成！你已经开始形成习惯了，继续保持这个势头！'
            : '一周达成！你已经开始形成习惯了，继续保持。';
      case MilestoneType.streak14:
        return useEmoji
            ? '⚡ 两周坚持！你的大脑已经开始适应这个新习惯了！'
            : '两周坚持！你的大脑已经开始适应这个新习惯了。';
      case MilestoneType.streak30:
        return useEmoji
            ? '🌟 一个月！你已经超越了大多数人。这不是偶然，是坚持！'
            : '一个月！你已经超越了大多数人。这不是偶然，是坚持。';
      case MilestoneType.streak100:
        return useEmoji
            ? '👑 百日传奇！你用100天重新定义了自己。向传奇致敬！'
            : '百日传奇！你用100天重新定义了自己。向传奇致敬。';
      case MilestoneType.bossDefeated:
        return useEmoji
            ? '🏆 Boss已击败！你用行动证明了自己的承诺。下个月更强大！'
            : 'Boss已击败！你用行动证明了自己的承诺。下个月更强大。';
      case MilestoneType.firstCheckIn:
        return useEmoji
            ? '🌱 第一步永远是最难的，你做到了！这是新旅程的开始！'
            : '第一步永远是最难的，你做到了。这是新旅程的开始。';
      case MilestoneType.perfectMonth:
        return useEmoji
            ? '📅 完美月份！整个月一天不落，你是真正的行动派！'
            : '完美月份！整个月一天不落，你是真正的行动派。';
    }
  }

  /// 清除对话历史（节省 token）
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// 重置宠物偏好（恢复到默认）
  Future<void> resetPreferences() async {
    _prefs = PetPreferences.defaultPrefs();
    _memories.clear();
    await _savePreferences();
    await _saveMemories();
  }

  /// 宠物智能拆解：年度目标 → 月度挑战 → 每日行动
  /// 使用预设知识库作为上下文参考，提升 LLM 拆解质量和速度
  Future<DecompositionResult> decomposeGoals(List<String> yearGoals) async {
    if (yearGoals.isEmpty || yearGoals.every((g) => g.trim().isEmpty)) {
      return DecompositionResult(monthlyChallenges: [], dailyActionsPerChallenge: {});
    }

    // ===== 收集预设知识库中的相关参考 =====
    final goalsText = yearGoals.where((g) => g.isNotEmpty).join('\n');
    final allPresetExamples = <String>[];
    final allPresetActions = <String>[];

    for (final goal in yearGoals.where((g) => g.isNotEmpty)) {
      final (preset, score) = PresetGoalLibrary.findBestMatch(goal);
      if (preset != null && score >= 0.3) {
        // 收集匹配的预设作为参考示例
        for (final phase in preset.monthlyPhases) {
          allPresetExamples.add(phase);
        }
        for (final action in preset.dailyActions) {
          allPresetActions.add('  → ${action.action}（单位：${action.unit}，提示：${action.paramHint}）');
        }
      }
    }

    // 构建预设参考上下文（如果有匹配的话）
    String presetContext = '';
    if (allPresetExamples.isNotEmpty) {
      presetContext = '''
【参考案例】（以下案例来自同类目标的经验总结，帮你生成更符合实际的拆解）
常见月度挑战模式：
${allPresetExamples.map((e) => '- $e').join('\n')}
常用每日行动格式：
${allPresetActions.join('\n')}

以上案例仅供参考，你需要根据用户的具体目标生成个性化的拆解方案。
''';
    }

    final prompt = '''
【宠物拆解框架 v2.0 - 量化行动生成器】

你是「${_soul.name}」，用户的宠物伙伴。你的任务是把目标拆解为可量化的每日行动。

【目标】
$goalsText
$presetContext

【核心原则：每个行动必须量化】

★ 禁止输出示例（这些是错的，不要这样做）：
- ✗ "每天读书"（没有数量）
- ✗ "每天学习"（太模糊）
- ✗ "复习专业课内容"（没有页数/章节）
- ✗ "适当运动"（没有时间/强度）
- ✗ "背诵英语单词"（没有数量）

★ 正确输出示例：
- ✓ "用配套APP背30个法律英语单词"
- ✓ "看专业课教材10页并标注重点"
- ✓ "做10道民法选择题并订正错题"
- ✓ "跟读英语音频5分钟，录音回听"
- ✓ "早上7:30起床，晨跑20分钟"

【针对备考类目标的特别要求】

如果目标是考研/法考/法律硕士/JD/非全日制法律等专业类考试，必须生成以下类型的量化行动：
1. 背书类：每天背X个名词解释/X道简答题
2. 做题类：每天做X道选择题/X道主观题并订正
3. 看教材类：每天看X页教材/X节课程并标注重点
4. 复习类：每天复习X页旧知识/错题
5. 听力/口语：每天听/说X分钟

注意：如果目标是"考XX大学非全日制法律硕士"，需要识别出是法律硕士（非法学本科背景）或法律硕士（法学本科背景），分别对应不同的专业课内容。

【挑战拆分原则】
- 每月聚焦1-2个子目标，不要贪多
- 第一个月：打基础（看书/听课/背单词）
- 第二个月：强化（做题/背诵/专项突破）
- 第三个月：冲刺（模拟考试/查漏补缺）

【输出格式】
只输出JSON，不要其他内容：
{
  "monthlyChallenges": ["挑战1", "挑战2"],
  "dailyActionsPerChallenge": {
    "挑战1": ["量化行动1", "量化行动2", "量化行动3"],
    "挑战2": ["量化行动1", "量化行动2"]
  }
}

【强制要求】
- 每个行动必须包含阿拉伯数字（1-9等）
- 每个行动必须包含时间/数量/页数/题数中的至少一个
- 不允许输出"若干""适量""适度""尽量"等模糊词
- 挑战和行动数量都要充分（2-4个挑战，每个2-4条行动，不要少于2条）
''';

    try {
      // 拆解需要更多 tokens，直接调 API 不走 _callMiniMax（后者受 prefs.responseLength 限制）
      final apiKeyForDecompose = MiniMaxConfig.apiKey;
      if (apiKeyForDecompose.isEmpty) {
        debugPrint('PetService decomposeGoals: API key not configured');
        return DecompositionResult(monthlyChallenges: [], dailyActionsPerChallenge: {});
      }
      const endpoint = '${MiniMaxConfig.baseUrl}/messages';
      final body = {
        'model': 'abab6.5s-chat',
        'max_tokens': 1500,
        'temperature': 0.7,
        'system': '你是炭炭，用户的宠物伙伴。回复简洁有温度。',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKeyForDecompose,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentList = data['content'] as List?;
        if (contentList != null) {
          for (final item in contentList) {
            if (item['type'] == 'text' && (item['text'] as String?)?.isNotEmpty == true) {
              return _parseDecompositionResponse((item['text'] as String).trim());
            }
          }
        }
      }
      debugPrint('PetService decomposeGoals API error: ${response.statusCode}');
      return DecompositionResult(monthlyChallenges: [], dailyActionsPerChallenge: {});
    } catch (e) {
      debugPrint('PetService decomposeGoals error: $e');
      return DecompositionResult(monthlyChallenges: [], dailyActionsPerChallenge: {});
    }
  }

  /// 解析LLM返回的拆解结果
  DecompositionResult _parseDecompositionResponse(String response) {
    try {
      String jsonStr = response.trim();
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
      if (jsonMatch != null) jsonStr = jsonMatch.group(0)!;

      final Map<String, dynamic> json = jsonDecode(jsonStr);

      final challenges = <String>[];
      if (json['monthlyChallenges'] is List) {
        for (final c in json['monthlyChallenges']) {
          if (c is String && c.isNotEmpty) challenges.add(_sanitizeText(c));
        }
      }

      final actionsMap = <String, List<String>>{};
      if (json['dailyActionsPerChallenge'] is Map) {
        final rawMap = json['dailyActionsPerChallenge'] as Map<String, dynamic>;
        for (final entry in rawMap.entries) {
          final actions = <String>[];
          if (entry.value is List) {
            for (final a in entry.value) {
              if (a is String && a.isNotEmpty) {
                // 清理 LLM 返回的无效 Unicode 字符
                final cleanAction = _sanitizeText(a);
                // 验证：每个行动必须包含数字，否则尝试补充或跳过
                final quantifiedAction = _quantifyAction(cleanAction);
                if (quantifiedAction != null) {
                  actions.add(quantifiedAction);
                } else {
                  // 如果无法量化，保留原始但标记（降级使用）
                  debugPrint('[PetMemory] 行动无法量化，跳过: $a');
                }
              }
            }
          }
          if (actions.isNotEmpty) actionsMap[entry.key] = actions;
        }
      }

      return DecompositionResult(monthlyChallenges: challenges, dailyActionsPerChallenge: actionsMap);
    } catch (e) {
      debugPrint('PetService _parseDecompositionResponse error: $e');
      return DecompositionResult(monthlyChallenges: [], dailyActionsPerChallenge: {});
    }
  }

  /// 清理文本中的无效 Unicode 字符
  /// 将无法显示的字符替换为安全的替代符号
  String _sanitizeText(String text) {
    // 移除可能导致渲染问题的控制字符（保留换行和Tab）
    text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // 将无法识别的 Unicode 替代字符替换为友好符号
    text = text.replaceAll('\uFFFD', '~');
    text = text.replaceAll('\u{FFFD}', '~');

    // 清理首尾空白（但保留中间的空格格式）
    text = text.trim();

    // 移除连续的纯空格（替换为单个空格）
    text = text.replaceAll(RegExp(r' {2,}'), ' ');

    return text;
  }

  /// 量化行动验证：如果行动不含数字，尝试补充；无法量化则返回null
  /// 这是一个后处理保障，确保LLM输出的行动都有量化指标
  String? _quantifyAction(String action) {
    // 检查是否包含阿拉伯数字
    final hasNumber = RegExp(r'\d').hasMatch(action);
    if (hasNumber) return action;

    // 尝试智能补充数量
    final lower = action.toLowerCase();

    if (lower.contains('读') || lower.contains('看书') || lower.contains('阅读')) {
      // 如果已有"每天"前缀，直接补充数量；否则加前缀
      if (action.contains('每天')) {
        return action.contains('（') ? action : '$action（每天10页）';
      }
      return '每天读${action.contains('书') ? '10页' : '相关内容'}';
    }
    if (lower.contains('背') && (lower.contains('单词') || lower.contains('词') || lower.contains('名词'))) {
      if (action.contains('每天')) {
        return action.contains('20') ? action : '$action，每天20个';
      }
      return '每天背20个相关词汇';
    }
    if (lower.contains('做题') || lower.contains('练习') || lower.contains('题')) {
      if (action.contains('每天')) {
        return action.contains('10') ? action : '$action，每天10道';
      }
      return '每天做10道题并订正错题';
    }
    if (lower.contains('跑') || lower.contains('运动') || lower.contains('健身')) {
      if (action.contains('每天')) {
        return action.contains('分钟') ? action : '$action，每天30分钟';
      }
      return '每天运动30分钟';
    }
    if (lower.contains('听') || lower.contains('听力')) {
      if (action.contains('每天')) {
        return action.contains('分钟') ? action : '$action，每天15分钟';
      }
      return '每天听15分钟';
    }
    if (lower.contains('写') || lower.contains('写作') || lower.contains('日记')) {
      if (action.contains('每天')) {
        return action.contains('字') ? action : '$action，每天300字';
      }
      return '每天写300字';
    }

    // 无法自动量化，返回null跳过该行动
    return null;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// ====== WOOP障碍引导（心理咨询师风格）======
  /// 生成障碍探索引导语（心理咨询师风格，非说教）
  /// 触发时机：Day 2 或 streak 断了之后
  ///
  /// 风格原则：
  /// - 不评判、不催促、不给建议
  /// - 用开放式问题引导用户自己觉察
  /// - 同理心优先："这很常见"
  String generateObstacleExploration(String leverPlan, PetContext context) {
    final useEmoji = _prefs.useEmoji;
    final streak = context.streak;
    final plans = leverPlan.isNotEmpty ? leverPlan : '完成今天的行动';

    // 刚注册第二天：引导觉察障碍
    if (context.totalCheckIns >= 1 && context.totalCheckIns <= 3 && streak <= 1) {
      if (useEmoji) {
        return '昨天尝试了「$plans」，感觉怎么样？\n\n有时候心里会有一些小声音拦住我们——比如"今天好累""明天再说"\n\n你有没有感觉到什么？不用急着回答，慢慢说，我在听 🙌';
      } else {
        return '昨天尝试了「$plans」，感觉怎么样？\n\n有时候心里会有小声音拦住我们。你有没有感觉到什么？慢慢说，我在听。';
      }
    }

    // Streak 断了：同理 + 引导觉察
    if (streak > 0 && !context.checkedInToday) {
      final idleDays = context.lastActiveTime != null
          ? DateTime.now().difference(context.lastActiveTime!).inDays
          : 1;
      if (idleDays >= 1) {
        if (useEmoji) {
          return '我注意到昨天没有打卡。\n\n其实停下来很常见，不是你一个人会这样 💪\n\n我想问问你：当你想要行动的时候，心里最先冒出来的那个"但是"是什么？\n\n说出来本身就很有力量。';
        } else {
          return '我注意到昨天没有打卡。停下来很常见。\n\n我想问问你：当你想要行动的时候，心里最先冒出来的"但是"是什么？说出来本身就很有力量。';
        }
      }
    }

    // 默认：日常引导
    if (useEmoji) {
      return '今天「$plans」打算什么时候做？\n\n在这之前，你觉得自己可能会遇到什么阻碍吗？可以是任何事，我陪着你 🧭';
    } else {
      return '今天「$plans」打算什么时候做？\n\n在这之前，你觉得自己可能会遇到什么阻碍？可以是任何事，我陪着你。';
    }
  }

  /// 将 obstacle + plan 格式化为 IF-THEN 结构
  /// 格式：如果 [障碍X]，我就 [行动Y]
  /// 如果 obstacle 为空，返回格式化后的 plan 文本
  String formatIfThen(String obstacle, String plan) {
    if (obstacle.isEmpty && plan.isEmpty) return '';
    if (obstacle.isEmpty) return plan;
    if (plan.isEmpty) return obstacle;

    // 统一格式：如果 X，我就 Y
    // 去掉 obstacle 中可能已经含有的"如果"
    final cleanObstacle = obstacle.startsWith('如果') || obstacle.startsWith('如果')
        ? obstacle
        : obstacle;

    // 去掉 plan 中可能含有的"我就"
    final cleanPlan = plan.startsWith('我就') ? plan.substring(2).trim() : plan;

    return '如果$cleanObstacle，我就$cleanPlan';
  }

  // ====== 激励有效性学习 ======

  /// 记录一次激励发送（次日打卡时评估）
  Future<void> recordEncouragement(EncouragementType type, String text) async {
    final record = EncouragementRecord(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      text: text,
      sentAt: DateTime.now(),
    );
    _encouragementRecords.add(record);

    // 只保留最近14天记录，防止无限增长
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    _encouragementRecords = _encouragementRecords
        .where((r) => r.sentAt.isAfter(cutoff))
        .toList();

    await _saveEncouragementRecords();
    debugPrint('[Encouragement] Recorded: ${type.label} — "$text"');
  }

  /// 评估激励有效性：用户在昨天发送激励后，今天是否打卡了
  /// 每天打卡时调用，评估最近一次激励
  Future<void> evaluateEncouragementEffectiveness({required bool checkedInToday}) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final yesterdayEnd = yesterdayStart.add(const Duration(days: 1));

    // 找到昨天发送的激励
    final yesterdayRecords = _encouragementRecords.where((r) =>
        r.sentAt.isAfter(yesterdayStart) && r.sentAt.isBefore(yesterdayEnd) &&
        r.ledToCheckIn == null).toList();

    if (yesterdayRecords.isEmpty) return;

    // 取最近一条
    final latest = yesterdayRecords.last;

    // 更新该激励的评估结果
    final updated = latest.copyWith(ledToCheckIn: checkedInToday);

    // 在记录中替换
    final idx = _encouragementRecords.indexWhere((r) => r.id == latest.id);
    if (idx != -1) {
      _encouragementRecords[idx] = updated;
    }

    // 更新 EMA 分数
    final typeIdx = updated.type.index;
    final current = _encouragementStats[typeIdx] ??
        EncouragementStats(type: updated.type);
    _encouragementStats[typeIdx] = current.recordAttempt(success: checkedInToday);

    await _saveEncouragementRecords();
    await _saveEncouragementStats();
    debugPrint('[Encouragement] Evaluated ${updated.type.label}: '
        'checkIn=$checkedInToday, eff=${_encouragementStats[typeIdx]!.effectiveness.toStringAsFixed(2)}');
  }

  /// 获取最有效的激励类型列表（降序）
  List<EncouragementType> getEffectiveTypes({int limit = 3}) {
    final sorted = EncouragementType.values.toList()
      ..sort((a, b) {
        final aEff = _encouragementStats[a.index]?.effectiveness ?? 0.5;
        final bEff = _encouragementStats[b.index]?.effectiveness ?? 0.5;
        return bEff.compareTo(aEff);
      });
    return sorted.take(limit).toList();
  }

  /// 构建激励偏好上下文（给 LLM 看的提示）
  String buildEncouragementContext() {
    final effective = getEffectiveTypes(limit: 3);
    if (effective.isEmpty) return '';

    final buf = StringBuffer();
    buf.writeln('【激励有效性参考】（以下话术风格效果较好，可优先使用）');
    for (final type in effective) {
      final stats = _encouragementStats[type.index];
      final attempts = stats?.attempts ?? 0;
      final eff = stats?.effectiveness ?? 0.5;
      buf.writeln('  ${type.emoji} ${type.label} — 历史成功率 ${(eff * 100).round()}%（$attempts次数据）');
    }
    return buf.toString();
  }

  /// 获取最有效的激励类型
  /// 如果有效性分数接近（差距<0.1），返回 null（混合使用）
  EncouragementType? getMostEffectiveType() {
    if (_encouragementStats.isEmpty) return null;

    EncouragementType? best;
    double bestScore = 0;

    for (final entry in _encouragementStats.entries) {
      final score = entry.value.effectiveness;
      if (score > bestScore) {
        bestScore = score;
        best = entry.value.type;
      }
    }

    // 检查是否有多于一个类型接近最高分（差距<0.1）
    int closeCount = 0;
    for (final entry in _encouragementStats.entries) {
      if ((entry.value.effectiveness - bestScore).abs() < 0.1) {
        closeCount++;
      }
    }

    // 如果有多个类型接近，返回 null（混合使用）
    return closeCount > 1 ? null : best;
  }

  /// 获取所有激励类型的统计
  Map<int, EncouragementStats> getEncouragementStats() => _encouragementStats;

  /// 获取激励记录
  List<EncouragementRecord> getEncouragementRecords() => _encouragementRecords;

  /// 持久化激励记录
  Future<void> _saveEncouragementRecords() async {
    final storage = await StorageService.getInstance();
    await storage.saveEncouragementRecords(_encouragementRecords);
  }

  /// 持久化激励统计
  Future<void> _saveEncouragementStats() async {
    final storage = await StorageService.getInstance();
    await storage.saveEncouragementStats(_encouragementStats);
  }

  // ====== 自主感支持（SDT）======

  /// 检测用户消息中的自主感丧失/抗拒信号，并更新状态
  /// 在每次对话结束时调用
  Future<void> detectAndRecordPushback(String userMessage) async {
    final isPushback = _detectPushback(userMessage);
    final now = DateTime.now();

    if (isPushback) {
      // 检测到抗拒
      final updated = _autonomySignals.copyWith(
        consecutivePushbackDays: _autonomySignals.consecutivePushbackDays + 1,
        lastPushbackAt: now,
        lastAutonomyLossAt: now,
        // 自主感分数下降（每次抗拒-0.1）
        autonomyScore: (_autonomySignals.autonomyScore - 0.1).clamp(0.0, 1.0),
      );
      _autonomySignals = updated;
    } else {
      // 用户正常打卡或正面回应 → 逐步恢复自主感分数，重置抗拒天数
      final updated = _autonomySignals.copyWith(
        consecutivePushbackDays: 0,
        autonomyScore: (_autonomySignals.autonomyScore + 0.05).clamp(0.0, 1.0),
      );
      _autonomySignals = updated;
    }

    await _saveAutonomySignals();
  }

  /// 获取当前自主感信号状态
  AutonomySignals get autonomySignals => _autonomySignals;

  /// 检测用户是否处于抗拒状态（连续 pushback）
  bool get isUserResisting => _autonomySignals.isResisting;

  /// 检测用户消息是否包含抗拒信号
  bool _detectPushback(String message) {
    final lower = message.toLowerCase();
    final patterns = [
      RegExp(r'又来了', caseSensitive: false),
      RegExp(r'知道了', caseSensitive: false),
      RegExp(r'别说了', caseSensitive: false),
      RegExp(r'烦', caseSensitive: false),
      RegExp(r'能不能.*说', caseSensitive: false),
      RegExp(r'你.*说人话', caseSensitive: false),
      RegExp(r'换.*说法', caseSensitive: false),
      RegExp(r'能不能.*说', caseSensitive: false),
      RegExp(r'不想.*打卡', caseSensitive: false),
      RegExp(r'被逼', caseSensitive: false),
      RegExp(r'不得不', caseSensitive: false),
      RegExp(r'好累', caseSensitive: false),
      RegExp(r'没动力', caseSensitive: false),
      RegExp(r'摆烂', caseSensitive: false),
      RegExp(r'算了.*不', caseSensitive: false),
    ];
    return patterns.any((p) => p.hasMatch(lower));
  }

  /// 将任何督促消息改写为自主感支持版本
  /// 核心原则：不给命令，给选择
  String rewriteAutonomy(String message) {
    if (!_autonomySignals.isAutonomyLow) return message;

    // 策略1：加时间缓冲语
    if (message.contains('今天还没打卡') ||
        message.contains('你还没打卡')) {
      return '今天你有空的时候再动一下就好——但如果你想现在，现在正是个好时机。';
    }
    if (message.contains('要断了')) {
      return 'streak 还在，不急。你想什么时候继续都行。';
    }
    if (message.contains('提醒') || message.contains('别忘了')) {
      return '有空了再看一眼就好，我在这里等你。';
    }

    // 策略2：赋权激励（连续抗拒2天+时）
    if (_autonomySignals.consecutivePushbackDays >= 2) {
      return '你决定的事，从来都做到。这是你的节奏，不是任务。';
    }

    return message;
  }

  /// 生成带选择权的督促消息
  /// [baseMessage] 原始命令式消息
  /// [options] 两个选项，例如 ['现在就去', '等会儿再说']
  String generateChoiceMessage(String baseMessage, List<String> options) {
    if (options.length < 2) return baseMessage;

    // 根据偏好和自主感状态决定语气
    final useEmoji = _prefs.useEmoji;
    final isLowAutonomy = _autonomySignals.isAutonomyLow;

    if (isLowAutonomy) {
      // 自主感低 → 完全不催，只给最轻柔的暗示
      return '我在哦，不着急。${options.last}也完全没问题。';
    }

    // 选项A（立即）+ 选项B（延后）
    final optA = options[0];
    final optB = options.length > 1 ? options[1] : options[0];

    if (useEmoji) {
      return '$baseMessage\n\n${optA}？有空了${optB}';
    } else {
      return '$baseMessage（$optA / $optB）';
    }
  }

  /// 生成自主感支持版本的打卡督促
  String generateAutonomousCheckInNudge(PetContext ctx) {
    if (ctx.checkedInToday) {
      return useEmoji ? '今天你已经做到了 ✨' : '今日已完成。';
    }

    // 自主感极低（< 0.3）→ 完全不催
    if (_autonomySignals.autonomyScore < 0.3) {
      return '炭炭今天也在，随时等你。';
    }

    // 自主感低（< 0.5）→ 给完全选择权
    if (_autonomySignals.isAutonomyLow) {
      final options = ['想现在', '等会儿'];
      return generateChoiceMessage('今天你有空吗？', options);
    }

    // 正常情况 → 温和引导
    final streak = ctx.streak;
    if (streak > 0 && streak % 7 == 0) {
      return '第${streak}天！你已经走到这里了，剩下的路按你的节奏来。';
    }
    if (ctx.currentBossHp > 0) {
      final remaining = ctx.currentBossTotal - ctx.currentBossHp;
      return '本月还剩$remaining天，按你自己的节奏来，不急。';
    }
    return useEmoji
        ? '你有空了动一下就好，今天随时 ✨'
        : '有空时完成即可，不限时间。';
  }

  /// 获取当前语气（依赖 useEmoji）
  bool get useEmoji => _prefs.useEmoji;

  /// 生成年度计划引导建议（宠物口吻）
  Future<String> generateAnnualPlanSuggestion() async {
    final storage = await StorageService.getInstance();
    final petName = storage.getPetName();

    // 根据用户是否填了愿景/目标，给出不同提示
    final vision = storage.getVision();
    final yearGoal = storage.getYearGoal();
    final hasVision = vision.isNotEmpty && vision != '成为更好的自己';
    final hasGoal = yearGoal.isNotEmpty && yearGoal != '持续成长';

    if (!hasVision && !hasGoal) {
      return useEmoji
          ? '$petName 发现你还没填年度愿景和目标，要不要一起来规划今年？ 🌟'
          : '$petName 发现你还没填年度愿景和目标，要不要一起来规划今年？';
    } else if (!hasGoal) {
      return useEmoji
          ? '年度目标还没填，帮你写一个？今年最想做成什么？'
          : '年度目标还没填，帮你写一个？今年最想做成什么？';
    } else {
      return useEmoji
          ? '年度愿景还没填，$petName 想听听你理想中的自己是什么样的 ✨'
          : '年度愿景还没填，$petName 想听听你理想中的自己是什么样的';
    }
  }

  /// 持久化自主感信号
  Future<void> _saveAutonomySignals() async {
    final storage = await StorageService.getInstance();
    await storage.saveAutonomySignals(_autonomySignals);
  }

  // ====== 对话历史持久化 ======

  /// 加载对话历史
  Future<void> _loadConversationHistory() async {
    final storage = await StorageService.getInstance();
    _conversationHistory.clear();
    _conversationHistory.addAll(storage.getConversationHistory());
    debugPrint('[PetService] Loaded ${_conversationHistory.length} conversation history entries');
  }

  /// 保存对话历史
  Future<void> _saveConversationHistory() async {
    final storage = await StorageService.getInstance();
    await storage.saveConversationHistory(_conversationHistory);
    // 压缩检查
    await _compactConversationHistory();
  }

  /// 对话历史压缩：当历史超过 _maxHistorySize 时触发
  /// 把最早的 (_maxHistorySize - _keepRecentCount) 条压缩成摘要
  Future<void> _compactConversationHistory() async {
    if (_conversationHistory.length <= _maxHistorySize) return;

    // 保留最近 _keepRecentCount 条，其余压缩成摘要
    final oldMessages = _conversationHistory.sublist(0, _conversationHistory.length - _keepRecentCount);
    final recentMessages = _conversationHistory.sublist(_conversationHistory.length - _keepRecentCount);

    // 生成摘要：简单地把旧对话内容拼接
    final summary = _generateHistorySummary(oldMessages);

    _conversationHistory.clear();
    _conversationHistory.addAll(recentMessages);
    _historySummary = summary;

    await _saveConversationHistory();
    await _saveHistorySummary();
  }

  /// 生成历史摘要
  String _generateHistorySummary(List<Map<String, String>> oldMessages) {
    if (oldMessages.isEmpty) return '';
    final buf = StringBuffer();
    buf.write('【早期对话摘要】');
    for (final msg in oldMessages) {
      final role = msg['role'] == 'user' ? '用户' : '炭炭';
      final content = msg['content'] ?? '';
      // 每条只取前50字
      buf.write('$role: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}；');
    }
    return buf.toString();
  }

  /// 保存历史摘要
  Future<void> _saveHistorySummary() async {
    final storage = await StorageService.getInstance();
    await storage.saveHistorySummary(_historySummary);
  }

  /// 加载历史摘要
  Future<void> _loadHistorySummary() async {
    final storage = await StorageService.getInstance();
    _historySummary = storage.getHistorySummary();
  }
}
