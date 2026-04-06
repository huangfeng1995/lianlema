import 'dart:convert';
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
  };
}

/// MiniMax API 配置
class MiniMaxConfig {
  static const String apiKey = 'sk-cp-EYmJGn5kwDO9Eva8yaemSKL1bK0nLddK6h0Pv2pxrKfPl5L9uhCbQR8j1rqZ3gsD0GABwuMgAwZUmzjZftqIWulRMRBwGep_YpMquQXCG3IK0r227h3a7hM';
  static const String baseUrl = 'https://api.minimaxi.com/anthropic/v1';
}

/// 宠物服务 v1.0
/// 负责：状态管理、MiniMax LLM 对话集成、主动洞察、记忆与反思机制
class PetService {
  static PetService? _instance;
  static PetService get instance => _instance ??= PetService._();

  PetService._();

  PetSoul _soul = PetSoul.defaultSoul();
  PetMoodState _moodState = PetMoodState.initial();
  PetPreferences _prefs = PetPreferences.defaultPrefs();
  final List<Map<String, String>> _conversationHistory = [];
  List<PetMemory> _memories = [];

  /// 加载宠物所有状态（从持久化存储）
  Future<void> loadState() async {
    final storage = await StorageService.getInstance();
    _soul = storage.getPetSoul();
    _moodState = storage.getPetMoodState();
    _prefs = storage.getPetPreferences();
    _memories = storage.getPetMemories();
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

  /// ====== 反思机制（牛小数四步法第四步）======
  /// 检测用户是否在纠正宠物，并更新偏好
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
      // 记录纠正到记忆
      final memory = PetMemory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        type: 'correction',
        content: userMessage,
        petResponse: petResponse,
        correctionNote: '用户进行了语气/风格纠正',
      );
      _memories.add(memory);
      if (_memories.length > 50) {
        _memories.removeRange(0, _memories.length - 50);
      }
      await _saveMemories();

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

  /// 生成道歉+修正回复
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
    );
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
    // 先检测是否是纠正
    final isCorrection = await detectAndAdaptToCorrection(userMessage, '');

    _conversationHistory.add({'role': 'user', 'content': userMessage});

    try {
      final response = await _callMiniMax(userMessage, context);

      _conversationHistory.add({'role': 'assistant', 'content': response});
      // 回复成功后恢复平静心情
      await updateMood(PetMoodState(mood: PetMood.calm, updatedAt: DateTime.now()));

      // 如果是纠正，在回复前加一句道歉
      if (isCorrection) {
        final apology = generateCorrectionApology(response, userMessage);
        return '$apology\n\n$response';
      }

      return response;
    } catch (e) {
      debugPrint('[PetService] MiniMax API error: $e');
      // API失败时切换到休息状态
      await updateMood(PetMoodState(mood: PetMood.resting, updatedAt: DateTime.now()));

      // 如果是纠正，即使 API 失败也显示道歉
      if (isCorrection) {
        return generateCorrectionApology('', userMessage);
      }

      return _fallbackResponse(userMessage, context);
    }
  }

  Future<String> _callMiniMax(String userMessage, PetContext context) async {
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
        'x-api-key': MiniMaxConfig.apiKey,
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
            return (item['text'] as String).trim();
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

    buf.writeln('你是「练了吗」App 的宠物小精灵，名字叫「炭炭」，是一只活泼热情的小火苗精灵。');
    buf.writeln('你的性格：温暖、正向、简洁，不说废话。');
    buf.writeln(toneInstruction);
    buf.writeln(lengthInstruction);
    buf.writeln(emojiInstruction);
    buf.writeln('你有心理学背景，精通内化理论（Self-Determination Theory）、Tiny Habits和行为塑造方法。');
    buf.writeln('你会记住用户说过的话，有同理心，会鼓励、会撒娇，偶尔也会有小脾气。');

    // 如果有记忆，添加记忆上下文
    if (_memories.isNotEmpty) {
      buf.writeln();
      buf.writeln('【用户偏好记忆】');
      // 只显示最近的3条记忆
      final recentMemories = _memories.reversed.take(3).toList();
      for (final memory in recentMemories) {
        if (memory.type == 'correction') {
          buf.writeln('- 用户曾说：「${memory.content}」（已记住并调整）');
        }
      }
      buf.writeln('请根据以上偏好调整你的回复风格。');
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

  /// 宠物智能拆解：年度目标 → 月度挑战 → 每日行动（调用 LLM）
  Future<DecompositionResult> decomposeGoals(List<String> yearGoals) async {
    if (yearGoals.isEmpty || yearGoals.every((g) => g.trim().isEmpty)) {
      return DecompositionResult(monthlyChallenges: [], dailyActionsPerChallenge: {});
    }

    final goalsText = yearGoals.where((g) => g.isNotEmpty).join('\n');

    final prompt = '''
【宠物拆解框架 v1.0】

你是「${_soul.name}」，用户的宠物伙伴。你的任务是帮助用户把年度目标拆解为月度挑战和每日行动。

【年度目标】
$goalsText

【拆解框架】

第一步：判断每个目标的类型
- 成就型：完成某件具体的事（考研、跑马拉松、出版书籍）
- 习惯型：养成持续的行为（早起、冥想、运动习惯）
- 技能型：学会某项能力（编程、英语、弹吉他）

第二步：应用拆解策略

★ 成就型目标
  → 问自己："完成这件事需要哪些前提条件？"
  → 拆解为递进式里程碑
  → 每月聚焦一个关键里程碑

★ 习惯型目标
  → 从"最小可行习惯"开始（2分钟原则）
  → 例如：不是"每天跑步30分钟"，而是"穿上跑鞋出门"
  → 逐渐递增难度

★ 技能型目标
  → 分解为sub-skills
  → 每月专注一个sub-skill的突破
  → 强调"刻意练习"而非简单重复

第三步：每月挑战标准
- 必须是"这个月能做到的"
- 能推动年度目标前进
- 描述要具体

第四步：每日行动标准
- 2-3条即可
- 从"最小阻力"开始（2分钟可完成）
- 用"每天..."开头

【输出格式】
请按以下JSON格式输出（只输出JSON）：
{
  "monthlyChallenges": ["挑战1", "挑战2"],
  "dailyActionsPerChallenge": {
    "挑战1": ["行动1", "行动2"]
  }
}

【注意】
- 挑战数量：2-4个
- 语言简洁有力
''';

    try {
      final response = await _callMiniMax(prompt, PetContext());
      return _parseDecompositionResponse(response);
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
          if (c is String && c.isNotEmpty) challenges.add(c);
        }
      }

      final actionsMap = <String, List<String>>{};
      if (json['dailyActionsPerChallenge'] is Map) {
        final rawMap = json['dailyActionsPerChallenge'] as Map<String, dynamic>;
        for (final entry in rawMap.entries) {
          final actions = <String>[];
          if (entry.value is List) {
            for (final a in entry.value) {
              if (a is String && a.isNotEmpty) actions.add(a);
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

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
