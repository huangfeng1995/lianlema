import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/pet_models.dart';

class StorageService {
  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  /// 重置单例（用于数据清除后重新初始化）
  static void resetInstance() {
    _instance = null;
  }

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    const maxRetries = 3;
    Object? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _prefs = await SharedPreferences.getInstance();
        return;
      } catch (e) {
        lastError = e;
        debugPrint('SharedPreferences init attempt $attempt failed: $e');
        if (attempt < maxRetries) {
          // 重试前等待一小段时间
          await Future.delayed(Duration(milliseconds: 100 * attempt));
        }
      }
    }

    // 所有重试都失败了，尝试使用 mock values 作为最后的手段
    debugPrint('SharedPreferences all retries failed, using mock values: $lastError');
    SharedPreferences.setMockInitialValues({});
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences mock also failed: $e');
      rethrow;
    }
  }

  void debugPrint(String msg) {
    // ignore: avoid_print
    print('[StorageService] $msg');
  }

  // 存储键
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyUserStats = 'user_stats';
  static const String _keyAntiVision = 'anti_vision';
  static const String _keyVision = 'vision';
  static const String _keyYearGoal = 'year_goal';
  static const String _keyMonthlyBoss = 'monthly_boss';
  static const String _keyDailyLevers = 'daily_levers';
  static const String _keyDailyActions = 'daily_actions';
  static const String _keyConstraints = 'constraints';
  static const String _keyCheckIns = 'check_ins';
  static const String _keyBadges = 'badges';
  static const String _keyMinimalMode = 'minimal_mode';
  static const String _keyTemptingBundling = 'tempting_bundling';
  static const String _keyLastReviewMonth = 'last_review_month';
  static const String _keyAnnualIdentity = 'annual_identity';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyStreakRemedyUsedMonths = 'streak_remedy_used_months'; // 用过的补救月份
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyFocusReminders = 'focus_reminders'; // 专注时段提醒
  static const String _keyPetMoodState = 'pet_mood_state'; // 宠物心情状态
  static const String _keyPetMemories = 'pet_memories'; // 宠物记忆
  static const String _keyPetSoul = 'pet_soul'; // 宠物人格
  static const String _keyPetPreferences = 'pet_preferences'; // 宠物偏好
  static const String _keyPetName = 'pet_name'; // 宠物名字
  static const String _keyPushWeights = 'push_weights'; // 推送类型权重
  static const String _keyPetAdoptDate = 'pet_adopt_date'; // 宠物领养日期
  static const String _keyPetCoins = 'pet_coins'; // 宠物币余额
  static const String _keyPetCoinTransactions = 'pet_coin_transactions'; // 宠物币交易记录
  static const String _keyPetOwnedItems = 'pet_owned_items'; // 已拥有物品
  static const String _keyEquippedCostume = 'equipped_costume'; // 当前穿戴外观
  static const String _keyEquippedDecorations = 'equipped_decorations'; // 当前家居装饰
  static const String _keyPetType = 'pet_type'; // 宠物类型 id
  static const String _keyPetAppearanceLevel = 'pet_appearance_level'; // 外观等级 1-5
  static const String _keyPetMoodValue = 'pet_mood_value'; // 心情数值 0-100
  static const String _keyPetPersonality = 'pet_personality'; // 大五人格

  // ====== 宠物名字 ======
  static const String defaultPetName = '炭炭';

  Future<void> savePetName(String name) async {
    // 限制最大10个字符
    final trimmed = name.length > 10 ? name.substring(0, 10) : name;
    await _prefs.setString(_keyPetName, trimmed);
  }

  String getPetName() {
    return _prefs.getString(_keyPetName) ?? defaultPetName;
  }

  // ====== 宠物领养日期 ======
  Future<void> savePetAdoptDate(DateTime date) async {
    await _prefs.setString(_keyPetAdoptDate, date.toIso8601String());
  }

  DateTime? getPetAdoptDate() {
    final str = _prefs.getString(_keyPetAdoptDate);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  // ====== 宠物币余额 ======
  int getPetCoins() {
    return _prefs.getInt(_keyPetCoins) ?? 50; // 默认50
  }

  Future<void> savePetCoins(int amount) async {
    await _prefs.setInt(_keyPetCoins, amount);
  }

  // ====== 宠物币交易记录 ======
  List<PetCoinTransaction> getPetCoinTransactions() {
    final str = _prefs.getString(_keyPetCoinTransactions);
    if (str == null) return [];
    final list = jsonDecode(str) as List;
    return list.map((e) => PetCoinTransaction.fromJson(e)).toList();
  }

  Future<void> addPetCoinTransaction(PetCoinTransaction tx) async {
    final txs = getPetCoinTransactions();
    txs.add(tx);
    // 最多保留200条记录
    if (txs.length > 200) {
      txs.removeRange(0, txs.length - 200);
    }
    final list = txs.map((t) => t.toJson()).toList();
    await _prefs.setString(_keyPetCoinTransactions, jsonEncode(list));
  }

  /// 增减宠物币并记录交易
  Future<void> addPetCoins(int amount, PetCoinReason reason) async {
    final current = getPetCoins();
    final newAmount = current + amount;
    await savePetCoins(newAmount);
    final tx = PetCoinTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      reason: reason,
      createdAt: DateTime.now(),
    );
    await addPetCoinTransaction(tx);
  }

  // ====== 宠物背包物品 ======
  List<PetOwnedItem> getPetOwnedItems() {
    final str = _prefs.getString(_keyPetOwnedItems);
    if (str == null) return [];
    final list = jsonDecode(str) as List;
    return list.map((e) => PetOwnedItem.fromJson(e)).toList();
  }

  Future<void> savePetOwnedItems(List<PetOwnedItem> items) async {
    final list = items.map((i) => i.toJson()).toList();
    await _prefs.setString(_keyPetOwnedItems, jsonEncode(list));
  }

  Future<void> addPetOwnedItem(PetOwnedItem item) async {
    final items = getPetOwnedItems();
    // 防止重复添加
    if (!items.any((i) => i.itemId == item.itemId)) {
      items.add(item);
      await savePetOwnedItems(items);
    }
  }

  Future<void> removePetOwnedItem(String itemId) async {
    final items = getPetOwnedItems();
    items.removeWhere((i) => i.itemId == itemId);
    await savePetOwnedItems(items);
  }

  // ====== 穿戴外观 ======
  String? getEquippedCostume() {
    return _prefs.getString(_keyEquippedCostume);
  }

  Future<void> saveEquippedCostume(String? costumeId) async {
    if (costumeId == null) {
      await _prefs.remove(_keyEquippedCostume);
    } else {
      await _prefs.setString(_keyEquippedCostume, costumeId);
    }
  }

  // ====== 家居装饰 ======
  List<String> getEquippedDecorations() {
    final str = _prefs.getString(_keyEquippedDecorations);
    if (str == null) return [];
    final List decoded = jsonDecode(str);
    return decoded.cast<String>();
  }

  Future<void> saveEquippedDecorations(List<String> decorationIds) async {
    await _prefs.setString(_keyEquippedDecorations, jsonEncode(decorationIds));
  }

  // ====== 宠物类型 ======
  Future<void> savePetType(String type) async {
    await _prefs.setString(_keyPetType, type);
  }

  String getPetType() {
    return _prefs.getString(_keyPetType) ?? 'fox';
  }

  // ====== 外观等级 ======
  Future<void> savePetAppearanceLevel(int level) async {
    await _prefs.setInt(_keyPetAppearanceLevel, level);
  }

  int getPetAppearanceLevel() {
    return _prefs.getInt(_keyPetAppearanceLevel) ?? 1;
  }

  // ====== 心情数值 ======
  int getPetMoodValue() {
    return _prefs.getInt(_keyPetMoodValue) ?? 50; // 默认50
  }

  Future<void> savePetMoodValue(int value) async {
    await _prefs.setInt(_keyPetMoodValue, value.clamp(0, 100));
  }

  // ====== 大五人格 ======
  Future<void> savePetPersonality(PetPersonality personality) async {
    await _prefs.setString(_keyPetPersonality, jsonEncode(personality.toJson()));
  }

  PetPersonality getPetPersonality() {
    final str = _prefs.getString(_keyPetPersonality);
    if (str == null) return PetPersonality.random();
    return PetPersonality.fromJson(jsonDecode(str));
  }

  /// 消耗宠物币（余额不足时抛出异常）
  Future<void> spendPetCoins(int amount, PetCoinReason reason) async {
    if (amount <= 0) return;
    final current = getPetCoins();
    if (current < amount) {
      throw Exception('宠物币余额不足：需要 $amount，当前 $current');
    }
    await addPetCoins(-amount, reason);
  }

  /// 判断宠物是否处于蛋阶段（领养后7天内）
  bool isInEggPhase() {
    final adoptDate = getPetAdoptDate();
    if (adoptDate == null) return false;
    final daysSinceAdopt = DateTime.now().difference(adoptDate).inDays;
    return daysSinceAdopt < 7;
  }

  // ====== 宠物记忆（反思机制） ======
  Future<void> savePetMemories(List<PetMemory> memories) async {
    // 过滤掉已过期的记忆
    final valid = memories.where((m) => !m.isExpired).toList();
    final list = valid.map((m) => m.toJson()).toList();
    await _prefs.setString(_keyPetMemories, jsonEncode(list));
  }

  List<PetMemory> getPetMemories() {
    final str = _prefs.getString(_keyPetMemories);
    if (str == null) return [];
    final list = jsonDecode(str) as List;
    return list.map((e) => PetMemory.fromJson(e)).toList();
  }

  Future<void> addPetMemory(PetMemory memory) async {
    final memories = getPetMemories();
    memories.add(memory);
    // 非永久记忆最多保留100条（防止无限增长）
    final nonPermanent = memories.where((m) => !m.isPermanent).toList();
    if (nonPermanent.length > 100) {
      // 移除最旧的非永久记忆
      final toRemove = nonPermanent.length - 100;
      final toRemoveIds = nonPermanent.take(toRemove).map((m) => m.id).toSet();
      memories.removeWhere((m) => !m.isPermanent && toRemoveIds.contains(m.id));
    }
    await savePetMemories(memories);
  }

  // ====== 宠物人格 ======
  Future<void> savePetSoul(PetSoul soul) async {
    await _prefs.setString(_keyPetSoul, jsonEncode(soul.toJson()));
  }

  PetSoul getPetSoul() {
    final str = _prefs.getString(_keyPetSoul);
    if (str == null) return PetSoul.defaultSoul();
    return PetSoul.fromJson(jsonDecode(str));
  }

  // ===== 推送权重 ======
  /// 获取各推送类型的当前权重
  Map<int, double> getPushWeights() {
    final str = _prefs.getString(_keyPushWeights);
    if (str == null) return {};
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toDouble()));
  }

  Future<void> savePushWeights(Map<int, double> weights) async {
    final str = jsonEncode(weights.map((k, v) => MapEntry(k.toString(), v)));
    await _prefs.setString(_keyPushWeights, str);
  }

  // ====== 宠物偏好 ======
  Future<void> savePetPreferences(PetPreferences prefs) async {
    await _prefs.setString(_keyPetPreferences, jsonEncode(prefs.toJson()));
  }

  PetPreferences getPetPreferences() {
    final str = _prefs.getString(_keyPetPreferences);
    if (str == null) return PetPreferences.defaultPrefs();
    return PetPreferences.fromJson(jsonDecode(str));
  }

  // ====== 宠物心情 ======
  Future<void> savePetMoodState(PetMoodState state) async {
    await _prefs.setString(_keyPetMoodState, jsonEncode(state.toJson()));
  }

  PetMoodState getPetMoodState() {
    final str = _prefs.getString(_keyPetMoodState);
    if (str == null) return PetMoodState.initial();
    return PetMoodState.fromJson(jsonDecode(str));
  }

  // ====== Onboarding ======
  bool get isOnboardingComplete => _prefs.getBool(_keyOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_keyOnboardingComplete, value);
  }

  // ====== 用户数据 ======
  Future<void> saveUserStats(UserStats stats) async {
    await _prefs.setString(_keyUserStats, jsonEncode(stats.toJson()));
  }

  UserStats getUserStats() {
    final str = _prefs.getString(_keyUserStats);
    if (str == null) {
      return UserStats(
        level: 1,
        currentXP: 0,
        totalXP: 0,
        streak: 0,
        totalCheckIns: 0,
      );
    }
    return UserStats.fromJson(jsonDecode(str));
  }

  // ====== 反愿景 ======
  Future<void> saveAntiVision(String content) async {
    await _prefs.setString(_keyAntiVision, content);
  }

  String getAntiVision() {
    return _prefs.getString(_keyAntiVision) ?? '';
  }

  // ====== 愿景 ======
  Future<void> saveVision(String content) async {
    await _prefs.setString(_keyVision, content);
  }

  String getVision() {
    return _prefs.getString(_keyVision) ?? '';
  }

  // ====== 年度目标 ======
  Future<void> saveYearGoal(String content) async {
    await _prefs.setString(_keyYearGoal, content);
  }

  String getYearGoal() {
    return _prefs.getString(_keyYearGoal) ?? '';
  }

  // ====== 月度Boss ======
  Future<void> saveMonthlyBossFromOnboarding(String content) async {
    final now = DateTime.now();
    final boss = MonthlyBoss(
      content: content,
      month: now.month,
      year: now.year,
      totalDays: DateTime(now.year, now.month + 1, 0).day,
      hp: 0,
    );
    await saveMonthlyBoss(boss);
  }

  // ====== 每日杠杆 ======
  // 存储格式：List<Map<String, String>> 每个元素包含 obstacle（内心障碍）和 plan（IF-THEN 计划）
  Future<void> saveDailyLevers(List<Map<String, String>> levers) async {
    await _prefs.setString(_keyDailyLevers, jsonEncode(levers));
  }

  List<Map<String, String>> getDailyLevers() {
    final str = _prefs.getString(_keyDailyLevers);
    if (str == null) return [];
    final List decoded = jsonDecode(str);
    return decoded.map((e) {
      if (e is String) {
        // 兼容旧数据：只有计划文本，没有障碍字段
        return {'obstacle': '', 'plan': e};
      }
      return Map<String, String>.from(e as Map);
    }).toList();
  }

  // ====== 每日行动 ======
  Future<void> saveDailyActions(List<String> actions) async {
    await _prefs.setString(_keyDailyActions, jsonEncode(actions));
  }

  List<String> getDailyActions() {
    final str = _prefs.getString(_keyDailyActions);
    if (str == null) return [];
    final List decoded = jsonDecode(str);
    return decoded.cast<String>();
  }

  // ====== 约束条件 ======
  Future<void> saveConstraints(String content) async {
    await _prefs.setString(_keyConstraints, content);
  }

  String getConstraints() {
    return _prefs.getString(_keyConstraints) ?? '';
  }

  // ====== 极简模式 ======
  Future<void> saveMinimalMode(bool value) async {
    await _prefs.setBool(_keyMinimalMode, value);
  }

  bool getMinimalMode() {
    return _prefs.getBool(_keyMinimalMode) ?? false;
  }

  // ====== 诱惑捆绑 ======
  Future<void> saveTemptingBundling(String content) async {
    await _prefs.setString(_keyTemptingBundling, content);
  }

  String getTemptingBundling() {
    return _prefs.getString(_keyTemptingBundling) ?? '';
  }

  // ====== 最后复盘月份 ======
  /// 记录用户已完成复盘的月份，格式 "YYYY-MM"
  Future<void> saveLastReviewMonth(String yearMonth) async {
    await _prefs.setString(_keyLastReviewMonth, yearMonth);
  }

  String? getLastReviewMonth() {
    return _prefs.getString(_keyLastReviewMonth);
  }

  /// 检查是否需要显示月度复盘（月初或月底）
  bool shouldShowMonthlyReview() {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final lastReview = getLastReviewMonth();
    // 需要复盘的条件：本月还没做过复盘，且是月末(25-31)或月初(1-5)
    if (lastReview == currentMonth) return false;
    final day = now.day;
    return day >= 25 || day <= 5;
  }

  /// 获取待复盘的月份信息，返回 [year, month]
  List<int> getReviewMonth() {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    // 月初(1-5号)复盘上个月
    if (now.day <= 5) {
      month -= 1;
      if (month < 1) {
        month = 12;
        year -= 1;
      }
    }
    return [year, month];
  }

  // ====== 年度身份 ======
  Future<void> saveAnnualIdentity(String content) async {
    await _prefs.setString(_keyAnnualIdentity, content);
  }

  String getAnnualIdentity() {
    return _prefs.getString(_keyAnnualIdentity) ?? '';
  }

  // ====== 暗色模式 ======
  Future<void> saveDarkMode(bool isDark) async {
    await _prefs.setBool(_keyDarkMode, isDark);
  }

  bool getDarkMode() {
    return _prefs.getBool(_keyDarkMode) ?? false;
  }

  // ====== 提醒设置 ======
  int getReminderHour() {
    return _prefs.getInt(_keyReminderHour) ?? 21;
  }

  int getReminderMinute() {
    return _prefs.getInt(_keyReminderMinute) ?? 0;
  }

  Future<void> saveReminderTime(int hour, int minute) async {
    await _prefs.setInt(_keyReminderHour, hour);
    await _prefs.setInt(_keyReminderMinute, minute);
  }

  bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  // ====== Streak补救 ======
  /// 检查本月是否已使用过补救
  bool isStreakRemedyUsedThisMonth() {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final usedMonths = _prefs.getStringList(_keyStreakRemedyUsedMonths) ?? [];
    return usedMonths.contains(monthKey);
  }

  /// 使用补救（标记本月已使用）
  Future<void> useStreakRemedy() async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final usedMonths = _prefs.getStringList(_keyStreakRemedyUsedMonths) ?? [];
    if (!usedMonths.contains(monthKey)) {
      usedMonths.add(monthKey);
      await _prefs.setStringList(_keyStreakRemedyUsedMonths, usedMonths);
    }
  }

  /// 获取本月是否可补救
  bool canUseStreakRemedy() {
    return !isStreakRemedyUsedThisMonth();
  }

  // ====== 专注时段提醒 ======
  /// 专注提醒数据结构
  static const List<int> focusDurations = [15, 25, 30, 45, 60];

  Future<void> saveFocusReminders(List<Map<String, dynamic>> reminders) async {
    await _prefs.setString(_keyFocusReminders, jsonEncode(reminders));
  }

  List<Map<String, dynamic>> getFocusReminders() {
    final str = _prefs.getString(_keyFocusReminders);
    if (str == null) return [];
    final list = jsonDecode(str) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> addFocusReminder(String leverId, String leverContent, int hour, int minute, int duration) async {
    final reminders = getFocusReminders();
    // 检查是否已存在
    reminders.removeWhere((r) => r['leverId'] == leverId);
    reminders.add({
      'leverId': leverId,
      'leverContent': leverContent,
      'hour': hour,
      'minute': minute,
      'duration': duration,
    });
    await saveFocusReminders(reminders);
  }

  Future<void> removeFocusReminder(String leverId) async {
    final reminders = getFocusReminders();
    reminders.removeWhere((r) => r['leverId'] == leverId);
    await saveFocusReminders(reminders);
  }

  // ====== 打卡记录 ======
  Future<void> saveCheckIns(List<CheckIn> checkIns) async {
    final list = checkIns.map((c) => c.toJson()).toList();
    await _prefs.setString(_keyCheckIns, jsonEncode(list));
  }

  List<CheckIn> getCheckIns() {
    final str = _prefs.getString(_keyCheckIns);
    if (str == null) return [];
    final list = jsonDecode(str) as List;
    return list.map((e) => CheckIn.fromJson(e)).toList();
  }

  // ====== 徽章 ======
  Future<void> saveBadges(List<AppBadge> badges) async {
    final list = badges.map((b) => b.toJson()).toList();
    await _prefs.setString(_keyBadges, jsonEncode(list));
  }

  List<AppBadge> getBadges() {
    final str = _prefs.getString(_keyBadges);
    if (str == null) {
      return _defaultBadges;
    }
    final list = jsonDecode(str) as List;
    return list.map((e) => AppBadge.fromJson(e)).toList();
  }

  List<AppBadge> get _defaultBadges => [
    AppBadge(
      id: '1',
      name: '初醒',
      description: '开始了，就是最好的时刻',
      icon: 'assets/images/badge/badge_01_hatch.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '2',
      name: '连续7天',
      description: '7天，你开始形成习惯',
      icon: 'assets/images/badge/badge_02_fire7.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '3',
      name: '连续14天',
      description: '两周，行动成了本能',
      icon: 'assets/images/badge/badge_03_lightning.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '4',
      name: '连续30天',
      description: '一个月，你已经不一样了',
      icon: 'assets/images/badge/badge_04_gem.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '5',
      name: '连续100天',
      description: '百日蜕变，你活成了想成为的人',
      icon: 'assets/images/badge/badge_05_crown.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '6',
      name: '完成第1个挑战',
      description: '击败本月挑战，身份又近一步',
      icon: 'assets/images/badge/badge_06_target.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '7',
      name: '月度冠军',
      description: '半年同行，持续在行动',
      icon: 'assets/images/badge/badge_07_trophy.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '8',
      name: '反愿景坚守者',
      description: '一年坚守，你活成了反愿景的反面',
      icon: 'assets/images/badge/badge_08_skull.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '9',
      name: '完美月份',
      description: '整月无缺，这是你的证明',
      icon: 'assets/images/badge/badge_09_calendar.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '10',
      name: '重新出发',
      description: '跌倒了再站起来，比第一次更勇敢',
      icon: 'assets/images/badge/badge_10_sprout.png',
      isUnlocked: false,
    ),
    // v0.2.3 规划徽章
    AppBadge(
      id: '11',
      name: '规划者',
      description: '你已经想清楚要逃避什么',
      icon: 'assets/images/badge/badge_11_planner.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '12',
      name: '愿景家',
      description: '你有画面了，知道要活成谁',
      icon: 'assets/images/badge/badge_12_visionary.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '13',
      name: '年度目标',
      description: '主线任务已确认',
      icon: 'assets/images/badge/badge_13_target.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '14',
      name: '底线',
      description: '你的底线，你来定',
      icon: 'assets/images/badge/badge_14_baseline.png',
      isUnlocked: false,
    ),
    AppBadge(
      id: '15',
      name: '完整规划',
      description: '这是一个完整的自己',
      icon: 'assets/images/badge/badge_15_complete.png',
      isUnlocked: false,
    ),
  ];

  // ====== 月度Boss ======
  Future<void> saveMonthlyBoss(MonthlyBoss boss) async {
    await _prefs.setString(_keyMonthlyBoss, jsonEncode(boss.toJson()));
  }

  MonthlyBoss? getMonthlyBoss() {
    final str = _prefs.getString(_keyMonthlyBoss);
    if (str == null) return null;
    return MonthlyBoss.fromJson(jsonDecode(str));
  }

  // Per-boss 存储（v2 扩展）
  static const String _keySelectedBossTypes = 'selected_boss_types';
  static const String _keyCustomBosses = 'custom_bosses';
  static const String _keyBossTasks = 'boss_tasks';

  List<String> getSelectedBossTypes() {
    final str = _prefs.getString(_keySelectedBossTypes);
    if (str == null) return [];
    final List decoded = jsonDecode(str);
    return decoded.cast<String>();
  }

  Future<void> saveSelectedBossTypes(List<String> types) async {
    await _prefs.setString(_keySelectedBossTypes, jsonEncode(types));
  }

  List<String> getCustomBosses() {
    final str = _prefs.getString(_keyCustomBosses);
    if (str == null) return [];
    final List decoded = jsonDecode(str);
    return decoded.cast<String>();
  }

  Future<void> saveCustomBosses(List<String> bosses) async {
    await _prefs.setString(_keyCustomBosses, jsonEncode(bosses));
  }

  Map<String, List<String>> getBossTasks() {
    final str = _prefs.getString(_keyBossTasks);
    if (str == null) return {};
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as List).cast<String>()));
  }

  Future<void> saveBossTasks(Map<String, List<String>> tasks) async {
    await _prefs.setString(_keyBossTasks, jsonEncode(tasks));
  }

  // ====== 保存所有 onboarding 数据 ======
  
  /// 根据 Boss 内容自动生成每日行动
  List<String> _generateDailyActionsFromBoss(String bossContent) {
    final actions = <String>[];
    final lower = bossContent.toLowerCase();

    if (lower.contains('读书') || lower.contains('阅读') || lower.contains('书')) {
      actions.addAll(['每天阅读', '记录读书心得']);
    }
    if (lower.contains('运动') || lower.contains('跑步') || lower.contains('健身') || lower.contains('锻炼')) {
      actions.addAll(['每天运动30分钟', '运动后拉伸']);
    }
    if (lower.contains('早起') || lower.contains('早睡')) {
      actions.addAll(['按时起床', '保证睡眠时间']);
    }
    if (lower.contains('写作') || lower.contains('写') || lower.contains('日记')) {
      actions.addAll(['每天写作', '记录想法']);
    }
    if (lower.contains('英语') || lower.contains('外语') || lower.contains('语言')) {
      actions.addAll(['每天学习英语', '练习口语或听力']);
    }
    if (lower.contains('冥想') || lower.contains('正念')) {
      actions.addAll(['每天冥想10分钟', '保持专注']);
    }
    if (lower.contains('饮食') || lower.contains('减肥') || lower.contains('健康')) {
      actions.addAll(['健康饮食', '记录饮食情况']);
    }
    // 默认行动
    if (actions.isEmpty) {
      actions.addAll(['制定今日计划', '回顾完成情况']);
    }
    return actions.take(3).toList();
  }

Future<void> saveOnboardingData({
    required String antiVision,
    required String vision,
    required String yearGoal,
    required String monthlyBoss,
    required List<Map<String, String>> dailyLevers,
    required String constraints,
    String temptingBundling = '',
    List<String> dailyActions = const [],
  }) async {
    // 保存月度 Boss
    final now = DateTime.now();
    final boss = MonthlyBoss(
      content: monthlyBoss,
      month: now.month,
      year: now.year,
      totalDays: DateTime(now.year, now.month + 1, 0).day,
      hp: 0,
    );

    // 顺序写入，避免并发导致 SharedPreferences 失败
    await saveAntiVision(antiVision);
    await saveVision(vision);
    await saveYearGoal(yearGoal);
    await saveMonthlyBoss(boss);
    await saveDailyLevers(dailyLevers);
    // 自动生成每日行动（基于 Boss 类型）
    if (dailyActions.isEmpty && monthlyBoss.isNotEmpty) {
      dailyActions = _generateDailyActionsFromBoss(monthlyBoss);
    }
    await saveDailyActions(dailyActions);
    await saveConstraints(constraints);
    await saveTemptingBundling(temptingBundling);
    await setOnboardingComplete(true);
    await saveBadges(_defaultBadges);
    await saveLastReviewMonth('${now.year}-${now.month.toString().padLeft(2, '0')}');
    // 首次领养宠物，记录领养日期，随机分配宠物类型，生成性格
    if (getPetAdoptDate() == null) {
      await savePetAdoptDate(now);
      final assignedPet = assignRandomPet();
      await savePetType(assignedPet.type);
      // 生成大五人格并保存
      final personality = PetPersonality.random();
      await savePetPersonality(personality);
      final soul = getPetSoul();
      await savePetSoul(PetSoul(
        name: soul.name,
        personality: soul.personality,
        speakingStyle: soul.speakingStyle,
        tone: soul.tone,
        useEmoji: soul.useEmoji,
        defaultGreeting: assignedPet.greeting,
        type: assignedPet.type,
        petEmoji: assignedPet.emoji,
      ));
    }
  }

  // ====== 规划徽章检查 ======
  /// 检查并解锁规划徽章
  /// 当用户设置反愿景/愿景/年度目标/约束条件时调用
  Future<List<AppBadge>> checkPlanningBadges() async {
    final badges = getBadges();
    final antiVision = getAntiVision();
    final vision = getVision();
    final yearGoal = getYearGoal();
    final constraints = getConstraints();

    bool updated = false;
    final now = DateTime.now();

    // 检查各单项徽章
    final antiVisionBadge = badges.firstWhere((b) => b.id == '11', orElse: () => badges.first);
    if (antiVision.isNotEmpty && !antiVisionBadge.isUnlocked) {
      final idx = badges.indexWhere((b) => b.id == '11');
      if (idx >= 0) {
        badges[idx] = AppBadge(
          id: '11',
          name: antiVisionBadge.name,
          description: antiVisionBadge.description,
          icon: antiVisionBadge.icon,
          isUnlocked: true,
          unlockedAt: now,
        );
        updated = true;
      }
    }

    final visionBadge = badges.firstWhere((b) => b.id == '12', orElse: () => badges.first);
    if (vision.isNotEmpty && !visionBadge.isUnlocked) {
      final idx = badges.indexWhere((b) => b.id == '12');
      if (idx >= 0) {
        badges[idx] = AppBadge(
          id: '12',
          name: visionBadge.name,
          description: visionBadge.description,
          icon: visionBadge.icon,
          isUnlocked: true,
          unlockedAt: now,
        );
        updated = true;
      }
    }

    final yearGoalBadge = badges.firstWhere((b) => b.id == '13', orElse: () => badges.first);
    if (yearGoal.isNotEmpty && !yearGoalBadge.isUnlocked) {
      final idx = badges.indexWhere((b) => b.id == '13');
      if (idx >= 0) {
        badges[idx] = AppBadge(
          id: '13',
          name: yearGoalBadge.name,
          description: yearGoalBadge.description,
          icon: yearGoalBadge.icon,
          isUnlocked: true,
          unlockedAt: now,
        );
        updated = true;
      }
    }

    final constraintsBadge = badges.firstWhere((b) => b.id == '14', orElse: () => badges.first);
    if (constraints.isNotEmpty && !constraintsBadge.isUnlocked) {
      final idx = badges.indexWhere((b) => b.id == '14');
      if (idx >= 0) {
        badges[idx] = AppBadge(
          id: '14',
          name: constraintsBadge.name,
          description: constraintsBadge.description,
          icon: constraintsBadge.icon,
          isUnlocked: true,
          unlockedAt: now,
        );
        updated = true;
      }
    }

    // 检查完整规划徽章（全部4项都完成）
    final completeBadge = badges.firstWhere((b) => b.id == '15', orElse: () => badges.first);
    final allFourCompleted = antiVision.isNotEmpty && vision.isNotEmpty && yearGoal.isNotEmpty && constraints.isNotEmpty;
    if (allFourCompleted && !completeBadge.isUnlocked) {
      final idx = badges.indexWhere((b) => b.id == '15');
      if (idx >= 0) {
        badges[idx] = AppBadge(
          id: '15',
          name: completeBadge.name,
          description: completeBadge.description,
          icon: completeBadge.icon,
          isUnlocked: true,
          unlockedAt: now,
        );
        updated = true;
      }
    }

    if (updated) {
      await saveBadges(badges);
    }

    return badges;
  }

  // ====== 根据打卡天数更新外观等级 ======
  Future<void> updateAppearanceLevelFromStreak(int streakDays) async {
    int level = 1;
    if (streakDays >= 100) level = 5;
    else if (streakDays >= 60) level = 4;
    else if (streakDays >= 30) level = 3;
    else if (streakDays >= 14) level = 2;
    // 只有升级才更新，不降级
    if (level > getPetAppearanceLevel()) {
      await savePetAppearanceLevel(level);
    }
  }

  // ====== 重置应用 ======
  Future<void> resetAll() async {
    await _prefs.clear();
    _instance = null;
  }
}
