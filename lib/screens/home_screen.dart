import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/xp_service.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/badge_icon.dart';
import 'profile_screen.dart';
import 'monthly_review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StorageService _storage;
  bool _isLoading = true;

  // 打卡成功反馈
  bool _showSuccessFeedback = false;
  int _xpEarnedPreview = 0;

  UserStats _stats = UserStats(
    level: 1,
    currentXP: 0,
    totalXP: 0,
    streak: 0,
    totalCheckIns: 0,
  );

  List<DailyLever> _todayLevers = [];
  bool _isCheckedInToday = false;
  String _antiVision = '';
  String _vision = '';
  MonthlyBoss? _monthlyBoss;
  List<CheckIn> _checkIns = [];
  bool _minimalMode = false;
  String _temptingBundling = '';
  bool _streakBroken = false; // 检测streak是否昨天断裂
  bool _canUseRemedy = false; // 本月是否可以使用补救

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();

    final stats = _storage.getUserStats();
    final levers = _storage.getDailyLevers();
    final antiVision = _storage.getAntiVision();
    final vision = _storage.getVision();
    final checkIns = _storage.getCheckIns();
    final monthlyBoss = _storage.getMonthlyBoss();
    final minimalMode = _storage.getMinimalMode();
    final temptingBundling = _storage.getTemptingBundling();

    // 检查今天是否已打卡
    final today = DateTime.now();
    final todayStr = app_date.AppDateUtils.formatDate(today);
    final checkedIn = checkIns.any((c) => app_date.AppDateUtils.formatDate(c.date) == todayStr);

    // 检查昨天是否漏打卡（streak断裂但今天还没打卡）
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = app_date.AppDateUtils.formatDate(yesterday);
    final yesterdayCheckedIn = checkIns.any((c) => app_date.AppDateUtils.formatDate(c.date) == yesterdayStr);
    final streakBroken = !checkedIn && !yesterdayCheckedIn && checkIns.isNotEmpty;

    // 计算连续打卡天数
    final checkInDates = checkIns.map((c) => c.date).toList();
    final streak = app_date.AppDateUtils.calculateStreak(checkInDates);

    setState(() {
      _stats = UserStats(
        level: stats.level,
        currentXP: stats.currentXP,
        totalXP: stats.totalXP,
        streak: streak,
        totalCheckIns: stats.totalCheckIns,
      );
      _todayLevers = levers.asMap().entries.map((e) {
        return DailyLever(id: '${e.key}', content: e.value, order: e.key);
      }).toList();
      _antiVision = antiVision;
      _vision = vision;
      _monthlyBoss = monthlyBoss;
      _checkIns = checkIns;
      _isCheckedInToday = checkedIn;
      _streakBroken = streakBroken;
      _canUseRemedy = _storage.canUseStreakRemedy();
      _minimalMode = minimalMode;
      _temptingBundling = temptingBundling;
      _isLoading = false;
    });

    // 月末/月初检查：显示月度复盘
    if (_storage.shouldShowMonthlyReview()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMonthlyReview());
    }
  }

  void _showMonthlyReview({int? forYear, int? forMonth}) {
    final reviewInfo = _storage.getReviewMonth();
    final year = forYear ?? reviewInfo[0];
    final month = forMonth ?? reviewInfo[1];
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MonthlyReviewScreen(
          reviewYear: year,
          reviewMonth: month,
        ),
      ),
    );
  }

  Future<void> _checkIn() async {
    final today = DateTime.now();
    final completedIds = _todayLevers.where((l) => l.isCompleted).map((l) => l.id).toList();

    // 保存打卡记录
    final checkIn = CheckIn(date: today, leverIds: completedIds);
    _checkIns.add(checkIn);
    await _storage.saveCheckIns(_checkIns);

    // 更新月度 Boss HP
    final boss = _storage.getMonthlyBoss();
    MonthlyBoss? updatedBoss;
    if (boss != null && boss.month == today.month && boss.year == today.year) {
      updatedBoss = MonthlyBoss(
        content: boss.content,
        month: boss.month,
        year: boss.year,
        totalDays: boss.totalDays,
        hp: boss.hp + 1,
      );
      await _storage.saveMonthlyBoss(updatedBoss);
    }

    // 计算 XP
    final xpEarned = XpService.calculateCheckInXP(
      completedLevers: completedIds.length,
      totalLevers: _todayLevers.length,
      currentStreak: _stats.streak,
    );

    // 计算新连续天数
    final newStreak = _stats.streak + 1;

    // 检查 Boss 是否被击败（在徽章检查之前）
    final bool bossWasAlreadyDefeated = _monthlyBoss != null && _monthlyBoss!.hp >= _monthlyBoss!.totalDays;
    final bool bossDefeatedNow = updatedBoss != null && updatedBoss.hp >= updatedBoss.totalDays;
    final bool bossJustDefeated = bossDefeatedNow && !bossWasAlreadyDefeated;

    // 累计 XP（含 boss 击败奖励，只有刚击败才加）
    int totalXP = xpEarned;
    if (bossJustDefeated) totalXP += XpService.bossDefeatXP;

    // 更新 UserStats
    final oldStats = _stats;
    final newStats = XpService.addXP(_stats, totalXP);

    // 检查徽章
    final badges = _storage.getBadges();
    final updatedBadges = XpService.checkBadgeUnlocks(
      currentBadges: badges,
      totalCheckIns: oldStats.totalCheckIns + 1,
      currentStreak: newStreak,
      yearGoalAchieved: false,
      bossDefeated: bossDefeatedNow,
    );
    final newUnlockedBadges = XpService.getNewlyUnlockedBadges(badges, updatedBadges);

    final finalStats = UserStats(
      level: newStats.level,
      currentXP: newStats.currentXP,
      totalXP: newStats.totalXP,
      streak: newStreak,
      totalCheckIns: oldStats.totalCheckIns + 1,
    );

    await _storage.saveUserStats(finalStats);
    await _storage.saveBadges(updatedBadges);

    // 微妙成功反馈（非极简模式）
    if (!_minimalMode) {
      _playSuccessFeedback(xpEarned);
    }

    setState(() {
      _stats = finalStats;
      _isCheckedInToday = true;
      if (updatedBoss != null) _monthlyBoss = updatedBoss;
    });

    if (bossJustDefeated) {
      _showVictoryDialog(
        updatedBoss!,
        onDismiss: () => _showMonthlyReview(
          forYear: updatedBoss!.year,
          forMonth: updatedBoss!.month,
        ),
      );
    }

    // 显示奖励提示
    _showRewardDialog(
      xpEarned: xpEarned,
      didLevelUp: XpService.didLevelUp(oldStats, newStats),
      newBadges: newUnlockedBadges,
    );
  }

  void _showVictoryDialog(MonthlyBoss boss, {VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.whatshot, size: 32, color: AppColors.primary),
                  const Text(
                    ' VICTORY ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.whatshot, size: 32, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                boss.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, size: 16, color: Color(0xFFFFD700)),
                    const SizedBox(width: 6),
                    const Text(
                      '月度Boss已击败！',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (onDismiss != null) onDismiss();
                  },
                  child: const Text('太棒了！'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewardDialog({
    required int xpEarned,
    required bool didLevelUp,
    required List<AppBadge> newBadges,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 28, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '打卡成功！',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (_temptingBundling.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.military_tech, size: 22, color: Color(0xFFFFD700)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '你赢得：$_temptingBundling',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$xpEarned XP',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (didLevelUp) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '升级到 Lv${_stats.level}！',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              if (newBadges.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '新解锁徽章：',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: newBadges.map((b) => Icon(getBadgeIcon(b.icon), size: 36, color: AppColors.primary)).toList(),
                ),
                const SizedBox(height: 4),
                Text(
                  newBadges.map((b) => b.name).join('、'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('太棒了！'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleLever(DailyLever lever) {
    if (_isCheckedInToday) return;
    setState(() {
      lever.isCompleted = !lever.isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildStreakCard(),
                  _buildMonthlyBossCard(),
                  _buildDailyCheckIn(),
                  _buildVisionCard(),
                  _buildAntiVisionCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_showSuccessFeedback) _buildSuccessFeedback(),
        ],
      ),
    );
  }

  void _playSuccessFeedback(int xp) {
    setState(() {
      _showSuccessFeedback = true;
      _xpEarnedPreview = xp;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSuccessFeedback = false);
      }
    });
  }

  Widget _buildSuccessFeedback() {
    return AnimatedOpacity(
      opacity: _showSuccessFeedback ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: AppColors.primary.withValues(alpha: 0.15),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '+$_xpEarnedPreview XP',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MM月dd日 EEEE', 'zh_CN').format(now),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.apps,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLevelProgress(),
        ],
      ),
    );
  }

  Widget _buildLevelProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Lv${_stats.level}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_stats.currentXP} / ${XpService.xpForLevel(_stats.level)} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '再获 ${XpService.xpForLevel(_stats.level) - _stats.currentXP} XP 升级',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: XpService.levelProgress(_stats.totalXP),
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBossCard() {
    final boss = _monthlyBoss;
    final now = DateTime.now();
    if (boss == null || boss.month != now.month || boss.year != now.year) {
      return const SizedBox.shrink();
    }
    final hp = boss.hp;
    final total = boss.totalDays;
    final progress = total > 0 ? (hp / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, -24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Icon(Icons.whatshot, size: 28, color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '本月Boss战',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'HP $hp/$total',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    boss.content,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, -24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.local_fire_department, size: 36, color: AppColors.streak),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_stats.streak}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '天',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _streakBroken ? '重新开始' : '连续打卡',
                  style: TextStyle(
                    fontSize: 12,
                    color: _streakBroken ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (_streakBroken && _canUseRemedy && !_isCheckedInToday)
              GestureDetector(
                onTap: _showRemedyDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.settings, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      const Text(
                        '补救',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isCheckedInToday
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isCheckedInToday ? '✓ 今日已完成' : '去打卡',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isCheckedInToday ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCheckIn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日行动',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_todayLevers.isNotEmpty)
                Text(
                  '${_todayLevers.where((l) => l.isCompleted).length}/${_todayLevers.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_todayLevers.isEmpty) _buildEmptyLeversCard(),
          ...List.generate(_todayLevers.length, (index) {
            final lever = _todayLevers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _toggleLever(lever),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lever.isCompleted
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: lever.isCompleted ? AppColors.primary : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: lever.isCompleted ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: lever.isCompleted ? AppColors.primary : AppColors.textLight,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: lever.isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildLeverText(lever),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (_todayLevers.every((l) => l.isCompleted) && !_isCheckedInToday)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkIn,
                child: const Text('完成打卡 ✨'),
              ),
            ),
          if (_isCheckedInToday)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  '✓ 今日已打卡，明天继续加油！',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyLeversCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            '还没有设置今日行动',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方「目标」标签\n设置你的每日杠杆',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'IF-THEN格式效果更好',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRemedyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.settings, size: 24),
            const SizedBox(width: 8),
            const Text('补救机会'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '你已经漏掉了昨天的打卡，但这个月还有一次补救机会！',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '回答一个问题即可补救：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '「今天你愿意为昨天的缺席做点什么？」',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _applyStreakRemedy();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text('确认补救 ✨'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyStreakRemedy() async {
    // 使用补救
    await _storage.useStreakRemedy();

    // 更新状态
    setState(() {
      _canUseRemedy = false;
    });

    // 显示成功
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('补救成功！本月还有0次补救机会 ✨'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildAntiVisionCard() {
    if (_antiVision.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '反愿景提醒',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.textLight.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '我不想成为的人',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _antiVision,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisionCard() {
    if (_vision.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的愿景',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.textLight.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '我是_____的人',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _vision,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '早上好，今天也要加油';
    if (hour < 18) return '下午好，继续保持';
    return '晚上好，完成今天的行动了吗';
  }

  /// 渲染 IF-THEN 格式的杠杆文本
  /// 格式：「如果[情境]，那么[行为]」或「如果...我就...」
  Widget _buildLeverText(DailyLever lever) {
    final content = lever.content;
    final isCompleted = lever.isCompleted;
    final textColor = isCompleted ? AppColors.primary : AppColors.textPrimary;

    // 尝试匹配 IF-THEN 格式
    final ifThenPattern = RegExp(r'^(如果[，,].*?[，,]|如果[^\n]{2,30}[,，]\s*)(.*)$', caseSensitive: false);
    final match = ifThenPattern.firstMatch(content);

    if (match != null) {
      final ifPart = match.group(1) ?? '';
      final thenPart = match.group(2) ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ifPart,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '→ $thenPart',
            style: TextStyle(
              fontSize: 15,
              color: textColor,
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      );
    }

    // 备选：匹配「如果...我就...」格式
    final aiyoPattern = RegExp(r'^(如果[^\n]{2,40}?)\s*([,，]?我就|[,，]?那么)(.*)$', caseSensitive: false);
    final aiyoMatch = aiyoPattern.firstMatch(content);
    if (aiyoMatch != null) {
      final ifPart = aiyoMatch.group(1) ?? '';
      final thenPart = aiyoMatch.group(3) ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ifPart,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '→ $thenPart',
            style: TextStyle(
              fontSize: 15,
              color: textColor,
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      );
    }

    // 默认：普通文本
    return Text(
      content,
      style: TextStyle(
        fontSize: 15,
        color: textColor,
        decoration: isCompleted ? TextDecoration.lineThrough : null,
      ),
    );
  }
}
