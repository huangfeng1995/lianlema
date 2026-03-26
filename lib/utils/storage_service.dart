import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 存储键
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyUserStats = 'user_stats';
  static const String _keyAntiVision = 'anti_vision';
  static const String _keyVision = 'vision';
  static const String _keyYearGoal = 'year_goal';
  static const String _keyMonthlyBoss = 'monthly_boss';
  static const String _keyDailyLevers = 'daily_levers';
  static const String _keyConstraints = 'constraints';
  static const String _keyCheckIns = 'check_ins';
  static const String _keyBadges = 'badges';
  static const String _keyMinimalMode = 'minimal_mode';
  static const String _keyTemptingBundling = 'tempting_bundling';
  static const String _keyLastReviewMonth = 'last_review_month';
  static const String _keyAnnualIdentity = 'annual_identity';
  static const String _keyDarkMode = 'dark_mode';

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
  Future<void> saveDailyLevers(List<String> levers) async {
    await _prefs.setString(_keyDailyLevers, jsonEncode(levers));
  }

  List<String> getDailyLevers() {
    final str = _prefs.getString(_keyDailyLevers);
    if (str == null) return [];
    return List<String>.from(jsonDecode(str));
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
      name: '初次行动',
      description: '完成第一次打卡',
      icon: '🎯',
      isUnlocked: false,
    ),
    AppBadge(
      id: '2',
      name: '连续7天',
      description: '连续打卡7天',
      icon: '🔥',
      isUnlocked: false,
    ),
    AppBadge(
      id: '3',
      name: '连续30天',
      description: '连续打卡30天',
      icon: '💎',
      isUnlocked: false,
    ),
    AppBadge(
      id: '4',
      name: '完成100次',
      description: '累计打卡100次',
      icon: '🏆',
      isUnlocked: false,
    ),
    AppBadge(
      id: '5',
      name: '年度目标达成',
      description: '完成年度目标',
      icon: '🌟',
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

  // ====== 保存所有 onboarding 数据 ======
  Future<void> saveOnboardingData({
    required String antiVision,
    required String vision,
    required String yearGoal,
    required String monthlyBoss,
    required List<String> dailyLevers,
    required String constraints,
    String temptingBundling = '',
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

    await Future.wait<void>([
      saveAntiVision(antiVision),
      saveVision(vision),
      saveYearGoal(yearGoal),
      saveMonthlyBoss(boss),
      saveDailyLevers(dailyLevers),
      saveConstraints(constraints),
      saveTemptingBundling(temptingBundling),
      setOnboardingComplete(true),
      saveBadges(_defaultBadges),
      saveLastReviewMonth('${now.year}-${now.month.toString().padLeft(2, '0')}'),
    ]);
  }

  // ====== 重置应用 ======
  Future<void> resetAll() async {
    await _prefs.clear();
    _instance = null;
  }
}
