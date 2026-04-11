import 'dart:math';
import 'package:get/get.dart';
import '../models/pet_models.dart';
import '../utils/storage_service.dart';

/// 宠物心情 GetX 控制器
/// 管理宠物的 Big Five 心情状态、精力、亲密度等
class PetMoodController extends GetxController {
  static PetMoodController get to => Get.find();

  // ===== 响应式状态 =====
  final _moodValue = 50.obs; // 心情数值 0-100
  final _energy = 100.obs;   // 精力 0-100
  final _affection = 50.obs; // 对用户好感度 0-100
  final _anxiety = 0.obs;    // 对用户状态的担忧度 0-100
  final _intimacy = 0.obs;   // 亲密度 0-100
  final _trust = 0.obs;      // 用户对宠物的信任度 0-100
  final _personality = Rxn<PetPersonality>();
  final _mood = Rx<PetMood>(PetMood.calm);
  final _isLoaded = false.obs;

  // ===== Getters =====
  int get moodValue => _moodValue.value;
  int get energy => _energy.value;
  int get affection => _affection.value;
  int get anxiety => _anxiety.value;
  int get intimacy => _intimacy.value;
  int get trust => _trust.value;
  PetPersonality? get personality => _personality.value;
  PetMood get mood => _mood.value;
  bool get isLoaded => _isLoaded.value;

  // ===== 行为权重（派生自 Big Five）=====
  double get talkativeness =>
      personality != null ? personality!.talkativeness : 0.5;
  double get strictness =>
      personality != null ? personality!.strictness : 0.5;
  double get positivityRatio =>
      personality != null ? personality!.positivityRatio : 0.5;
  double get emotionalVolatility =>
      personality != null ? personality!.emotionalVolatility : 0.5;

  String get archetype => personality?.archetype ?? '小火苗';
  String get archetypeDescription =>
      personality?.archetypeDescription ?? '活泼热情的小火苗';

  @override
  void onInit() {
    super.onInit();
    loadState();
  }

  /// 从 Storage 加载所有状态
  Future<void> loadState() async {
    final storage = await StorageService.getInstance();

    final savedPersonality = storage.getPetPersonality();
    _personality.value = savedPersonality;

    _moodValue.value = storage.getPetMoodValue();
    _energy.value = 100; // 精力每天重置
    _intimacy.value = _calculateIntimacy(storage);
    _trust.value = _calculateTrust(storage);

    // 计算初始心情
    _updateMoodFromState();

    _isLoaded.value = true;
  }

  int _calculateIntimacy(StorageService storage) {
    final stats = storage.getUserStats();
    final memories = storage.getPetMemories();
    // 亲密度 = 打卡天数/10 + 记忆条数/5，上限100
    return min(100, (stats.totalCheckIns ~/ 10) + (memories.length ~/ 5));
  }

  int _calculateTrust(StorageService storage) {
    final memories = storage.getPetMemories();
    // 信任度基于宠物记忆中的纠正次数
    final corrections =
        memories.where((m) => m.type == 'correction').length;
    return min(100, 30 + corrections * 5);
  }

  /// 生成 Big Five 性格（首次孵化时调用）
  Future<void> generatePersonality() async {
    final p = PetPersonality.random();
    _personality.value = p;
    final storage = await StorageService.getInstance();
    await storage.savePetPersonality(p);
  }

  /// 打卡后更新心情
  Future<void> onCheckIn({required int streak, required int totalCheckIns}) async {
    final rng = Random();

    // Big Five 行为影响
    final personality = _personality.value;
    final extraversion = personality?.extraversion ?? 3;
    final agreeableness = personality?.agreeableness ?? 3;
    final neuroticism = personality?.neuroticism ?? 3;

    // 心情变化：基础+3，高外向宠物额外+1，高神经质波动
    int moodDelta = 3;
    if (extraversion > 3) moodDelta += 1;
    moodDelta += rng.nextInt(3); // 随机0-2
    _moodValue.value = (_moodValue.value + moodDelta).clamp(0, 100);

    // 精力消耗（每次打卡-5~10）
    _energy.value = (_energy.value - 5 - rng.nextInt(6)).clamp(0, 100);

    // 好感度：正向宠物更开心
    if (agreeableness > 3) {
      _affection.value = (_affection.value + 2).clamp(0, 100);
    }

    // 焦虑下降
    _anxiety.value = (_anxiety.value - 5).clamp(0, 100);

    // 亲密度提升
    _intimacy.value = (_intimacy.value + 1).clamp(0, 100);

    // 保存心情值
    final storage = await StorageService.getInstance();
    await storage.savePetMoodValue(_moodValue.value);

    // 更新心情枚举状态
    _updateMoodFromState();

    // 保存心情状态
    await _saveMoodState();
  }

  /// 漏打卡后更新心情
  Future<void> onMissedCheckIn({required int consecutiveMissDays}) async {
    final rng = Random();
    final personality = _personality.value;
    final neuroticism = personality?.neuroticism ?? 3;
    final conscientiousness = personality?.conscientiousness ?? 3;

    // 心情下降：基础-3，高神经质宠物下降更多
    int moodDelta = -3;
    if (neuroticism > 3) moodDelta -= (neuroticism - 3);
    moodDelta -= rng.nextInt(3);
    _moodValue.value = (_moodValue.value + moodDelta).clamp(0, 100);

    // 焦虑上升：高尽责宠物更焦虑
    int anxietyDelta = consecutiveMissDays * 5;
    if (conscientiousness > 3) anxietyDelta += 10;
    _anxiety.value = (_anxiety.value + anxietyDelta).clamp(0, 100);

    // 精力随时间恢复
    _energy.value = (_energy.value + 10).clamp(0, 100);

    _updateMoodFromState();
    await _saveMoodState();
  }

  /// 喂食零食后更新心情
  Future<void> onFeed({required int moodBoost}) async {
    _moodValue.value = (_moodValue.value + moodBoost).clamp(0, 100);
    _affection.value = (_affection.value + 2).clamp(0, 100);

    final storage = await StorageService.getInstance();
    await storage.savePetMoodValue(_moodValue.value);

    _mood.value = PetMood.happy;
    await _saveMoodState();
  }

  /// 每天定时恢复精力
  Future<void> restoreEnergy() async {
    _energy.value = 100;
    // 心情不好的宠物恢复慢
    final recovery = _moodValue.value < 40 ? 5 : 15;
    _moodValue.value = (_moodValue.value + recovery).clamp(0, 100);
    _updateMoodFromState();
    await _saveMoodState();
  }

  /// 根据心情数值更新心情枚举
  void _updateMoodFromState() {
    final v = _moodValue.value;
    final e = _energy.value;

    if (e < 20) {
      _mood.value = PetMood.resting;
    } else if (v >= 80) {
      _mood.value = PetMood.excited;
    } else if (v >= 60) {
      _mood.value = PetMood.happy;
    } else if (v >= 40) {
      _mood.value = PetMood.calm;
    } else if (v >= 20) {
      _mood.value = PetMood.thinking;
    } else {
      _mood.value = PetMood.sleepy;
    }
  }

  Future<void> _saveMoodState() async {
    final storage = await StorageService.getInstance();
    await storage.savePetMoodValue(_moodValue.value);
  }

  /// 获取当前心情描述
  String get moodDescription {
    final v = _moodValue.value;
    final e = _energy.value;
    final a = _anxiety.value;

    if (v >= 80) return '超级开心！';
    if (v >= 60) return '心情不错';
    if (v >= 40) {
      if (a > 50) return '有点担心你...';
      return '平静等待';
    }
    if (v >= 20) return '没什么精神';
    if (e < 20) return '好困...';
    return '有点低落';
  }

  /// 根据 Big Five 性格生成打卡后的反应
  PetCheckInReaction generateCheckInReaction({
    required int streak,
    required int totalCheckIns,
  }) {
    return PetArchetypeReactions.generateReaction(
      archetype,
      streak,
      totalCheckIns,
    );
  }

  /// 根据 Big Five 性格生成漏打卡后的反应
  String generateMissedReaction({required int missedDays}) {
    final p = personality;

    if (p == null) {
      return missedDays == 1
          ? '今天好像忘打卡了？没关系，明天记得就好～'
          : '已经$missedDays天没打卡了，我有点想你...';
    }

    // 沉默老炮
    if (p.extraversion < 3 && p.conscientiousness > 3) {
      return missedDays == 1 ? '嗯？' : '...';
    }

    // 玻璃心
    if (p.neuroticism > 4) {
      return '呜呜呜...你是不是忘记我了 🥺 ${missedDays > 1 ? "我都$missedDays天没见到你了..." : ""}';
    }

    // 焦虑监视器
    if (p.neuroticism > 3 && p.conscientiousness > 3) {
      return '你$missedDays天没打卡了！我一直在等你 😰';
    }

    // 毒舌教练
    if (p.conscientiousness > 3 && p.agreeableness < 3) {
      return missedDays == 1
          ? '漏了一天。没事，别找借口，继续。'
          : '$missedDays天了。还打算继续吗？';
    }

    // 佛系朋友
    if (p.agreeableness > 3 && p.extraversion < 3) {
      return '不急，慢慢来。你在就好 😊';
    }

    // 默认
    return missedDays == 1
        ? '今天忘打卡了吗？没关系，明天继续加油 ✨'
        : '$missedDays天没打卡了，但我相信你会回来的 💪';
  }
}
