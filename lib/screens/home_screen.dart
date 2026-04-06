import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/pet_service.dart';
import '../models/pet_models.dart';
import '../utils/xp_service.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/badge_icon.dart';

import 'profile_screen.dart';
import 'monthly_review_screen.dart';
import 'monthly_boss_edit_screen.dart';

/// 蛋形Painter（绘制椭圆形的蛋轮廓）
class _EggPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    // 蛋形是椭圆形，略高
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.75,
      height: size.height * 0.85,
    );
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  bool _hasLongTermPlanning = false; // 是否有长期规划
  PetContext? _context; // 宠物上下文
  String _petName = StorageService.defaultPetName; // 宠物名字

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    // 初始化宠物服务，加载心情状态
    await PetService.instance.loadState();
    _context = await PetService.instance.buildContext();
    _petName = _storage.getPetName();

    final stats = _storage.getUserStats();
    final leverMaps = _storage.getDailyLevers();
    // 优先用 onboarding 保存的每日杠杆，不足的再由 auto-generated 补充
    final dailyActions = _storage.getDailyActions();
    // 合并：用户真实填的优先，auto-generated 的作为补充
    final merged = <Map<String, String>>[];
    merged.addAll(leverMaps);
    if (dailyActions.isNotEmpty) {
      for (final a in dailyActions) {
        if (!merged.any((m) => m['plan'] == a)) {
          merged.add({'obstacle': '', 'plan': a});
        }
      }
    }
    final effectiveLevers = merged;
    final antiVision = _storage.getAntiVision();
    final vision = _storage.getVision();
    final yearGoal = _storage.getYearGoal();
    final constraints = _storage.getConstraints();
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
      _todayLevers = effectiveLevers.asMap().entries.map((e) {
        return DailyLever(
          id: '${e.key}',
          obstacle: e.value['obstacle'] ?? '',
          plan: e.value['plan'] ?? '',
          order: e.key,
        );
      }).toList();
      _antiVision = antiVision;
      _vision = vision;
      _monthlyBoss = monthlyBoss;
      _checkIns = checkIns;
      _isCheckedInToday = checkedIn;
      _streakBroken = streakBroken;
      _canUseRemedy = _storage.canUseStreakRemedy();
      _hasLongTermPlanning = antiVision.isNotEmpty || vision.isNotEmpty || yearGoal.isNotEmpty || constraints.isNotEmpty;
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

    // 刷新宠物心情（让UI更新）
    setState(() {});

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
                      '月度挑战已完成！',
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
                  const Icon(Icons.pets, size: 28, color: AppColors.primary),
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
                  children: newBadges.map((b) => Icon(getBadgeIcon(b.icon), size: 36, color: Color(0xFFFF6B00))).toList(),
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

  void _showAddLeverDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('添加今日行动', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: _monthlyBoss != null
                ? '例如：从Boss「${_monthlyBoss!.content.split('；').first}」分解出一个行动'
                : '写下今天要做的关键行动',
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final newLever = DailyLever(
                  id: '${DateTime.now().millisecondsSinceEpoch}',
                  obstacle: '',
                  plan: text,
                  isCompleted: false,
                  order: _todayLevers.length,
                );
                setState(() {
                  _todayLevers.add(newLever);
                });
                final storage = await StorageService.getInstance();
                // 保存到 storage
                final leverMaps = _todayLevers.map((l) => {'obstacle': l.obstacle, 'plan': l.plan}).toList();
                await storage.saveDailyLevers(leverMaps);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('添加', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 导航到宠物页面，带上障碍引导初始消息
  void _navigateToPetWithObstacleGuidance(DailyLever lever) async {
    final ctx = _context ?? await PetService.instance.buildContext();
    final guidance = PetService.instance.generateObstacleExploration(lever.plan, ctx);
    if (mounted) {
      Navigator.of(context).pushNamed(
        '/pet',
        arguments: {'initialMessage': guidance},
      );
    }
  }

  /// 打开填写障碍的对话框（WOOP 格式：IF-THEN）
  void _showObstacleDialog(DailyLever lever, int leverIndex) {
    final obstacleController = TextEditingController();
    final planController = TextEditingController(text: lever.plan);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('添加障碍预案'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '帮「${lever.plan}」找一个触发条件：',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const Text('如果...（什么情况下容易放弃？）',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: obstacleController,
                decoration: const InputDecoration(
                  hintText: '例如：下班太累了',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              const Text('我就...（你会怎么做？）',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: planController,
                decoration: const InputDecoration(
                  hintText: '例如：先做5分钟再说',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final obstacle = obstacleController.text.trim();
              final plan = planController.text.trim();
              if (obstacle.isNotEmpty) {
                final ifThen = PetService.instance.formatIfThen(obstacle, plan);
                final old = _todayLevers[leverIndex];
                final updated = DailyLever(
                  id: old.id,
                  obstacle: obstacle,
                  plan: ifThen,
                  order: old.order,
                  isCompleted: old.isCompleted,
                );
                setState(() {
                  _todayLevers[leverIndex] = updated;
                });
                final storage = await StorageService.getInstance();
                final leverMaps = _todayLevers
                    .map((l) => {'obstacle': l.obstacle, 'plan': l.plan})
                    .toList();
                await storage.saveDailyLevers(leverMaps);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
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
                  if (!_hasLongTermPlanning) _buildPlanningPrompt(),
                  _buildStreakCard(),
                  _buildPetCard(),
                  _buildMonthlyBossCard(),
                  if (_todayLevers.isNotEmpty) _buildDailyCheckIn(),
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
                    '${now.month}月${now.day}日 ${_weekdayZh(now.weekday)}',
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
              const SizedBox(width: 44),
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

    // 计算本月有多少天
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // 获取本月所有打卡日期的 day 值
    final checkedDays = _checkIns
        .where((c) => c.date.year == now.year && c.date.month == now.month)
        .map((c) => c.date.day)
        .toSet();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MonthlyBossEditScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(child: Icon(Icons.shield, size: 26, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '本月挑战',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          boss.content.split('；').first,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '已打卡 ${checkedDays.length}/$daysInMonth 天',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // 任务列表
              ...boss.content.split('；').skip(1).map((task) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    Expanded(
                      child: Text(
                        task.trim(),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建日历方格打卡图
  Widget _buildCalendarGrid(int daysInMonth, Set<int> checkedDays, int today) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List.generate(daysInMonth, (index) {
        final day = index + 1;
        final isChecked = checkedDays.contains(day);
        final isToday = day == today;

        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isChecked
                ? AppColors.primary
                : (isToday
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(3),
            border: isToday && !isChecked
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: isChecked
              ? const Icon(Icons.check, size: 9, color: Colors.white)
              : null,
        );
      }),
    );
  }

  Widget _buildPlanningPrompt() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primaryLight.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '你的长期规划还空着',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '设置反愿景、愿景、年度目标，获得专属徽章',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
            Icon(Icons.local_fire_department, size: 36, color: Color(0xFFFF4500)),
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

  Widget _buildPetCard() {
    final mood = PetService.instance.moodState.mood;
    final greeting = PetService.instance.generateGreeting();
    final suggestion = PetService.instance.generateSuggestion(_context ?? PetContext());
    // 检查蛋阶段：领养后7天内显示🥚
    // 未领养或领养7天内都显示蛋
    final bool isEggPhase = _storage.getPetAdoptDate() == null || _storage.isInEggPhase();

    return GestureDetector(
      onTap: () {
        if (mounted) {
          Navigator.of(context).pushNamed('/pet');
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
              // ===== 宠物完整视觉形象（左侧）=====
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isEggPhase
                    // 蛋阶段：显示🥚图标（用Container画一个蛋形）
                    ? CustomPaint(
                        painter: _EggPainter(),
                        child: const Center(
                          child: Icon(Icons.egg, color: Colors.white, size: 28),
                        ),
                      )
                    // 成年宠物：显示心情图标
                    : Center(child: _buildMoodIcon(mood, size: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEggPhase
                          ? '$_petName · 还在蛋里...'
                          : '$_petName · ${_getMoodText(mood)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEggPhase ? '再等${7 - DateTime.now().difference(_storage.getPetAdoptDate() ?? DateTime.now()).inDays}天就孵化了 🥚'
                          : '$greeting $suggestion',
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
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPetCmdBtn('查打卡', Icons.checklist_rounded, PetCommand.checkInRecord),
                  const SizedBox(width: 6),
                  _buildPetCmdBtn('提醒', Icons.notifications_outlined, PetCommand.setReminder),
                  const SizedBox(width: 6),
                  _buildPetCmdBtn('成长', Icons.lightbulb_outline, PetCommand.askGrowth),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodIcon(PetMood mood, {double size = 26}) {
    switch (mood) {
      case PetMood.happy: return Icon(Icons.emoji_emotions, color: Colors.white, size: size);
      case PetMood.sleepy: return Icon(Icons.nightlight, color: Colors.white70, size: size);
      case PetMood.excited: return Icon(Icons.bolt, color: Colors.yellow, size: size);
      case PetMood.thinking: return Icon(Icons.psychology, color: Colors.white, size: size);
      case PetMood.calm: return Icon(Icons.local_fire_department, color: Colors.white, size: size);
      case PetMood.resting: return Icon(Icons.bedtime, color: Colors.white70, size: size);
    }
  }

  String _getMoodText(PetMood mood) {
    switch (mood) {
      case PetMood.happy: return '开心';
      case PetMood.sleepy: return '困了';
      case PetMood.excited: return '兴奋';
      case PetMood.thinking: return '思考中';
      case PetMood.calm: return '平静';
      case PetMood.resting: return '休息中';
    }
  }

  String _getMoodEmoji(PetMood mood) {
    switch (mood) {
      case PetMood.happy: return '😊';
      case PetMood.sleepy: return '😴';
      case PetMood.excited: return '🤩';
      case PetMood.thinking: return '🤔';
      case PetMood.calm: return '😌';
      case PetMood.resting: return '💤';
    }
  }

  Widget _buildPetCmdBtn(String label, IconData icon, PetCommand cmd) {
    return GestureDetector(
      onTap: () async {
        final ctx = _context ?? await PetService.instance.buildContext();
        final resp = await PetService.instance.handleCommand(cmd, ctx);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp), duration: const Duration(seconds: 2)));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500),
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
              Row(
                children: [
                  if (_todayLevers.isNotEmpty)
                    Text(
                      '${_todayLevers.where((l) => l.isCompleted).length}/${_todayLevers.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  GestureDetector(
                    onTap: _showAddLeverDialog,
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: AppColors.primary),
                          SizedBox(width: 2),
                          Text(
                            '添加',
                            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // IF-THEN 解释（obstacle 非空时隐藏，用卡片本身说明）
          if (_todayLevers.isEmpty || _todayLevers.every((l) => l.obstacle.isEmpty))
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 14,
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '💡 点击下方「添加障碍预案」，设置「如果...我就...」的触发计划，让行动在障碍出现时自动执行。',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: lever.isCompleted ? AppColors.primary : Colors.transparent,
                              border: Border.all(
                                color: lever.isCompleted ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: lever.isCompleted
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: lever.isCompleted
                                ? const Icon(Icons.check, size: 17, color: Colors.white)
                                : Icon(Icons.check, size: 17, color: AppColors.textLight.withValues(alpha: 0.3)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildLeverText(lever),
                          ),
                        ],
                      ),
                      // 障碍引导入口（obstacle 为空时显示）
                      if (lever.obstacle.isEmpty) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showObstacleDialog(lever, index),
                          child: Row(
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 12,
                                color: const Color(0xFFFF6B35).withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '添加障碍预案',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFFFF6B35).withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  static const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  String _weekdayZh(int weekday) => _weekdayNames[weekday - 1];

  /// 渲染 WOOP 格式的杠杆文本
  /// 先显示障碍（灰色小字），再显示 IF-THEN 计划（主要样式）
  Widget _buildLeverText(DailyLever lever) {
    final obstacle = lever.obstacle;
    final plan = lever.plan;
    final isCompleted = lever.isCompleted;
    final textColor = isCompleted ? AppColors.primary : AppColors.textPrimary;
    final decoration = isCompleted ? TextDecoration.lineThrough : null;

    // 如果有障碍，先显示障碍
    if (obstacle.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 内心障碍（灰色小字）
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 12,
                color: textColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  obstacle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                    decoration: decoration,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (plan.isNotEmpty) const SizedBox(height: 6),
          // IF-THEN 计划（主要样式）
          if (plan.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: textColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    plan,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      decoration: decoration,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    }

    // 没有障碍时，显示 IF-THEN 计划（兼容旧格式或无障碍的情况）
    if (plan.isNotEmpty) {
      // 尝试解析 IF-THEN 格式
      final ifThenPattern = RegExp(r'^(如果[，,].*?[，,]|如果[^\n]{2,30}[,，]\s*)(.*)$', caseSensitive: false);
      final match = ifThenPattern.firstMatch(plan);
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
                decoration: decoration,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '→ $thenPart',
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.w500,
                decoration: decoration,
              ),
            ),
          ],
        );
      }
      // 直接显示计划
      return Text(
        plan,
        style: TextStyle(
          fontSize: 15,
          color: textColor,
          fontWeight: FontWeight.w500,
          decoration: decoration,
        ),
      );
    }

    // 完全无内容时显示空
    return const SizedBox.shrink();
  }
}
