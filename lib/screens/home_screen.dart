import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/pet_service.dart';
import '../models/pet_models.dart';
import '../utils/xp_service.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/badge_icon.dart';
import '../services/pet_push_service.dart';
import '../widgets/confetti_celebration.dart';
import '../widgets/level_up_celebration.dart';
import '../widgets/boss_hp_bar.dart';
import '../widgets/boss_victory_celebration.dart';
import '../widgets/streak_broken_overlay.dart';
import '../widgets/evolution_celebration.dart';
import '../widgets/pet_push_banner.dart';
import '../controllers/pet_mood_controller.dart';
import '../services/share_service.dart';
import 'package:get/get.dart';

import 'profile_screen.dart';
import 'monthly_review_screen.dart';
import 'pet_screen.dart';
import 'monthly_boss_edit_screen.dart';
import 'annual_plan_screen.dart';

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
  static const Map<String, IconData> _archetypeIconMap = {
    'local_fire_department': Icons.local_fire_department,
    'flash_on': Icons.flash_on,
    'favorite': Icons.favorite,
    'emoji_emotions': Icons.emoji_emotions,
    'psychology': Icons.psychology,
    'celebration': Icons.celebration,
    'thumb_up': Icons.thumb_up,
    'sentiment_relieved': Icons.sentiment_satisfied,
    'auto_awesome': Icons.auto_awesome,
    'pets': Icons.pets,
    'whatshot': Icons.whatshot,
  };

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
  PetPush? _currentPush;

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
    // 加载宠物推送（取最高优先级一条）
    try {
      final pushes = await PetPushService.instance.generateDailyPushes(_context!);
      if (pushes.isNotEmpty) {
        _currentPush = pushes.first;
      }
    } catch (_) {}

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
    final checkedIn = checkIns
        .any((c) => app_date.AppDateUtils.formatDate(c.date) == todayStr);

    // 检查昨天是否漏打卡（streak断裂但今天还没打卡）
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = app_date.AppDateUtils.formatDate(yesterday);
    final yesterdayCheckedIn = checkIns
        .any((c) => app_date.AppDateUtils.formatDate(c.date) == yesterdayStr);
    final streakBroken =
        !checkedIn && !yesterdayCheckedIn && checkIns.isNotEmpty;

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
      _hasLongTermPlanning = antiVision.isNotEmpty ||
          vision.isNotEmpty ||
          yearGoal.isNotEmpty ||
          constraints.isNotEmpty;
      _minimalMode = minimalMode;
      _temptingBundling = temptingBundling;
      _isLoading = false;
    });

    // 月末/月初检查：显示月度复盘
    if (_storage.shouldShowMonthlyReview()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMonthlyReview());
    }

    // Streak 断裂提示
    if (_streakBroken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        StreakBrokenOverlay.show(
          context,
          brokenAtStreak: _stats.streak + 1, // 断裂前的连续天数
          onDismiss: () {
            // 动画结束后什么也不做，回到主界面
          },
        );
      });
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
    final completedIds =
        _todayLevers.where((l) => l.isCompleted).map((l) => l.id).toList();

    // 保存打卡记录
    final checkIn = CheckIn(date: today, leverIds: completedIds);
    _checkIns.add(checkIn);
    await _storage.saveCheckIns(_checkIns);

    // 计算新连续天数（提前定义，供多处使用）
    final newStreak = _stats.streak + 1;

    // 打卡奖励宠物币
    await _storage.addPetCoins(5, PetCoinReason.dailyCheckIn);

    // 打卡后心情+3
    final currentMood = _storage.getPetMoodValue();
    await _storage.savePetMoodValue(currentMood + 3);

    // 打卡后亲密度+3
    await _storage.addPetIntimacy(3);

    // 更新 GetX 心情控制器
    if (Get.isRegistered<PetMoodController>()) {
      PetMoodController.to.onCheckIn(
        streak: newStreak,
        totalCheckIns: _stats.totalCheckIns + 1,
      );
    }

    // 激励有效性学习：用户打卡了
    PetPushService.instance.onCheckIn(checkedInToday: true);

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

    // 连续打卡7天奖励
    if (newStreak == 7) {
      await _storage.addPetCoins(10, PetCoinReason.streak7);
    }
    // 连续打卡30天奖励
    if (newStreak == 30) {
      await _storage.addPetCoins(50, PetCoinReason.streak30);
    }

    // 检查 Boss 是否被击败（在徽章检查之前）
    final bool bossWasAlreadyDefeated =
        _monthlyBoss != null && _monthlyBoss!.hp >= _monthlyBoss!.totalDays;
    final bool bossDefeatedNow =
        updatedBoss != null && updatedBoss.hp >= updatedBoss.totalDays;
    final bool bossJustDefeated = bossDefeatedNow && !bossWasAlreadyDefeated;

    // Boss 击败奖励宠物币
    if (bossJustDefeated) {
      await _storage.addPetCoins(20, PetCoinReason.bossComplete);
    }

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
    final newUnlockedBadges =
        XpService.getNewlyUnlockedBadges(badges, updatedBadges);

    final finalStats = UserStats(
      level: newStats.level,
      currentXP: newStats.currentXP,
      totalXP: newStats.totalXP,
      streak: newStreak,
      totalCheckIns: oldStats.totalCheckIns + 1,
    );

    await _storage.saveUserStats(finalStats);
    await _storage.saveBadges(updatedBadges);

    // 检查外观等级是否升级，播放进化动画
    final oldAppearanceLevel = _storage.getPetAppearanceLevel();
    await _storage.updateAppearanceLevelFromStreak(newStreak);
    final newAppearanceLevel = _storage.getPetAppearanceLevel();
    if (newAppearanceLevel > oldAppearanceLevel) {
      final petType = _storage.getPetType();
      final petEmoji = getPetTypeConfig(petType)?.emoji ?? '🦊';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        EvolutionOverlay.show(context, newAppearanceLevel, petEmoji);
      });
      // 记录外观升级记忆
      await _storage.checkAndAddLevelUpMemory(newAppearanceLevel);
    }

    // 检查并添加记忆亮点
    await _storage.checkAndAddFirstCheckInMemory(_stats.totalCheckIns + 1);
    await _storage.checkAndAddStreakMemory(newStreak);

    // 检查成就解锁
    final newBadges = await _storage.checkAndUnlockAchievements();
    if (newBadges.isNotEmpty && mounted) {
      for (final badge in newBadges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(badge.emoji, style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('成就解锁！', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(badge.name, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                if (badge.reward > 0)
                  Text('+${badge.reward}币', style: TextStyle(color: Colors.yellow)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => ShareService.shareAchievement(badge.name, badge.emoji),
                  child: Icon(Icons.share, size: 18, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }

    // 微妙成功反馈（非极简模式）
    if (!_minimalMode) {
      _playSuccessFeedback(xpEarned);
    }
    // 彩纸庆祝动画
    ConfettiOverlay.show(context);

    // 显示打卡成功后分享按钮（非极简模式）
    if (!_minimalMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showShareButton();
      });
    }

    setState(() {
      _stats = finalStats;
      _isCheckedInToday = true;
      if (updatedBoss != null) _monthlyBoss = updatedBoss;
    });

    // 刷新宠物心情（让UI更新）
    setState(() {});

    if (bossJustDefeated) {
      BossVictoryOverlay.show(
        context,
        bossName: updatedBoss!.content,
        month: updatedBoss!.month,
        totalDays: updatedBoss!.totalDays,
        onDismiss: () => _showVictoryDialog(
          updatedBoss!,
          onDismiss: () => _showMonthlyReview(
            forYear: updatedBoss!.year,
            forMonth: updatedBoss!.month,
          ),
        ),
      );
    }

    // 显示奖励提示
    final didLevelUp = XpService.didLevelUp(oldStats, newStats);
    if (didLevelUp) {
      LevelUpOverlay.show(context, finalStats.level);
    }

    // ====== 宠物打卡反应（大五人格驱动）======
    final personality = _storage.getPetPersonality();
    final reaction = PetArchetypeReactions.generateReaction(
      personality.archetype,
      newStreak,
      finalStats.totalCheckIns,
    );
    _showRewardDialog(
      xpEarned: xpEarned,
      didLevelUp: didLevelUp,
      newBadges: newUnlockedBadges,
      petReaction: reaction,
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
                  const Icon(Icons.whatshot,
                      size: 32, color: AppColors.primary),
                  const Text(
                    ' VICTORY ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.whatshot,
                      size: 32, color: AppColors.primary),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events,
                        size: 16, color: Color(0xFFFFD700)),
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
    PetCheckInReaction? petReaction,
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
              // 宠物打卡反应（大五人格驱动）
              if (petReaction != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _archetypeIconMap[petReaction.iconName] ??
                              Icons.whatshot,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              petReaction.mainText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              petReaction.moodText,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_temptingBundling.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      const Icon(Icons.military_tech,
                          size: 22, color: Color(0xFFFFD700)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  children: newBadges
                      .map((b) => Icon(getBadgeIcon(b.icon),
                          size: 36,
                          color:
                              getBadgeColor(b.icon, isUnlocked: b.isUnlocked)))
                      .toList(),
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
    final obstacleController = TextEditingController();
    final ifThenController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('今日行动'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '每天2-3件高优先级事（如"写500字""联系3个客户"），确保有效推进项目',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('如果...（可选）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: obstacleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '什么情况下容易放弃？',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('我就...（可选）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: ifThenController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '你会怎么做？',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final obstacle = obstacleController.text.trim();
                final ifThen = ifThenController.text.trim();

                final newLever = DailyLever(
                  id: '${DateTime.now().millisecondsSinceEpoch}',
                  obstacle: obstacle,
                  plan: obstacle.isNotEmpty && ifThen.isNotEmpty
                      ? PetService.instance.formatIfThen(obstacle, ifThen)
                      : text,
                  isCompleted: false,
                  order: _todayLevers.length,
                );
                setState(() {
                  _todayLevers.add(newLever);
                });
                final storage = await StorageService.getInstance();
                final leverMaps = _todayLevers
                    .map((l) => {'obstacle': l.obstacle, 'plan': l.plan})
                    .toList();
                await storage.saveDailyLevers(leverMaps);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 导航到宠物页面，带上障碍引导初始消息
  void _navigateToPetWithObstacleGuidance(DailyLever lever) async {
    final ctx = _context ?? await PetService.instance.buildContext();
    final guidance =
        PetService.instance.generateObstacleExploration(lever.plan, ctx);
    if (mounted) {
      Navigator.of(context).pushNamed(
        '/pet',
        arguments: {'initialMessage': guidance},
      );
    }
  }

  /// 打开填写障碍的对话框（WOOP 格式：IF-THEN）
  void _showObstacleDialog(DailyLever lever, int leverIndex) {
    // 解析已有的IF-THEN格式
    String initialObstacle = lever.obstacle;
    String initialPlan = '';

    if (lever.obstacle.isNotEmpty && lever.plan.startsWith('如果')) {
      // 尝试解析IF-THEN格式
      final planText = lever.plan;
      final commaIndex = planText.indexOf('，我就');
      if (commaIndex != -1) {
        initialObstacle = planText.substring(2, commaIndex);
        initialPlan = planText.substring(commaIndex + 3);
      }
    } else if (lever.obstacle.isEmpty) {
      initialPlan = lever.plan;
    }

    final obstacleController = TextEditingController(text: initialObstacle);
    final planController = TextEditingController(text: initialPlan);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(lever.obstacle.isEmpty ? '添加应对方案' : '编辑应对方案'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('如果...'),
              const SizedBox(height: 8),
              TextField(
                controller: obstacleController,
                decoration: const InputDecoration(
                  hintText: '什么情况下容易放弃？',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text('我就...'),
              const SizedBox(height: 8),
              TextField(
                controller: planController,
                decoration: const InputDecoration(
                  hintText: '你会怎么做？',
                  border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: () async {
              final obstacle = obstacleController.text.trim();
              final plan = planController.text.trim();

              final old = _todayLevers[leverIndex];
              final updated = DailyLever(
                id: old.id,
                obstacle: obstacle,
                plan: obstacle.isNotEmpty && plan.isNotEmpty
                    ? PetService.instance.formatIfThen(obstacle, plan)
                    : (plan.isNotEmpty ? plan : old.plan),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // 宠物推送通知栏（初始化完成且有推送时才显示）
              if (!_isLoading && _currentPush != null) ...[
                PetPushBanner(push: _currentPush!),
                const SizedBox(height: 12),
              ],
              // ===== 大字问候语 =====
              _buildGreetingHeader(),
              const SizedBox(height: 28),
              // 长期计划
              _buildWarmCard(
                accent: const Color(0xFFE8533A),
                child: _buildVisionCard(),
              ),
              const SizedBox(height: 16),
              // 本月挑战
              if (_monthlyBoss != null &&
                  _monthlyBoss!.month == DateTime.now().month &&
                  _monthlyBoss!.year == DateTime.now().year)
                _buildWarmCard(
                  accent: const Color(0xFFF5A623),
                  child: BossHpBar(
                    currentHp: _monthlyBoss!.hp,
                    maxHp: _monthlyBoss!.totalDays,
                    bossName: _monthlyBoss!.content,
                    currentMonth: _monthlyBoss!.month,
                    onTap: () {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const MonthlyBossEditScreen()),
                        );
                      }
                    },
                  ),
                ),
              if (_monthlyBoss != null) const SizedBox(height: 16),
              // 今日行动
              _buildWarmCard(
                accent: const Color(0xFFFFCC00),
                child: _buildDailyCheckIn(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareButton() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '分享你的坚持',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '第 ${_stats.streak} 天连续打卡，继续加油！',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ShareService.shareCheckIn();
                },
                icon: const Icon(Icons.share),
                label: const Text('分享到社交媒体'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后再说'),
            ),
          ],
        ),
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
              // 等级徽章
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
            ],
          ),
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
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
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
                    child: const Center(
                        child: Icon(Icons.shield,
                            size: 26, color: AppColors.primary)),
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
              // 所有任务列表，不跳过第一个
              const SizedBox(height: 8),
              ...boss.content
                  .split('；')
                  .where((task) => task.trim().isNotEmpty)
                  .map((task) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.primary)),
                            Expanded(
                              child: Text(
                                task.trim(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                                maxLines: 2,
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
                  child: Icon(Icons.auto_awesome,
                      size: 20, color: AppColors.primary),
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
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.primary),
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
            Icon(Icons.bolt, size: 36, color: Color(0xFFFFA500)),
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
                    color: _streakBroken
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (_streakBroken && _canUseRemedy && !_isCheckedInToday)
              GestureDetector(
                onTap: _showRemedyDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    color: _isCheckedInToday
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionBar() {
    final totalDays = _stats.totalCheckIns;
    final currentLevel = PetAppearanceLevel.calculateStage(totalDays);
    final maxLevel = PetAppearanceLevel.stages.length;
    final progress = currentLevel / maxLevel;
    // 找当前阶段和下一阶段
    final currentStage = PetAppearanceLevel.getStage(currentLevel);
    final nextStage = PetAppearanceLevel.stages
        .where((s) => s.level == currentLevel + 1)
        .firstOrNull;

    return Row(
      children: [
        // 当前阶段 emoji
        if (currentStage != null)
          Text(currentStage.evolutionEmoji, style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        // 进度条
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标签行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentStage?.name ?? '',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                  if (nextStage != null)
                    Text(
                      '$totalDays/${nextStage.requiredDays}天 → ${nextStage.evolutionEmoji}${nextStage.name}',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    )
                  else
                    Text('已到终极阶段 ${currentStage?.evolutionEmoji ?? ''}',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 4),
              // 进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.textLight.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteLever(int index) async {
    final removed = _todayLevers.removeAt(index);
    setState(() {});
    await _storage.saveDailyLevers(_todayLevers
        .map((l) => {
              'plan': l.plan,
              'obstacle': l.obstacle,
              'isCompleted': l.isCompleted.toString()
            })
        .toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '已删除：${removed.plan.length > 20 ? '${removed.plan.substring(0, 20)}...' : removed.plan}'),
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPetCard() {
    final mood = PetService.instance.moodState.mood;
    final greeting = PetService.instance.generateGreeting();
    final suggestion =
        PetService.instance.generateSuggestion(_context ?? PetContext());
    // 检查蛋阶段：领养后7天内显示🥚
    // 未领养或领养7天内都显示蛋
    final bool isEggPhase =
        _storage.getPetAdoptDate() == null || _storage.isInEggPhase();

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
                      isEggPhase
                          ? '再等${7 - DateTime.now().difference(_storage.getPetAdoptDate() ?? DateTime.now()).inDays}天就孵化了 🥚'
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
                  _buildPetCmdBtn(
                      '查打卡', Icons.checklist_rounded, PetCommand.checkInRecord),
                  const SizedBox(width: 6),
                  _buildPetCmdBtn('提醒', Icons.notifications_outlined,
                      PetCommand.setReminder),
                  const SizedBox(width: 6),
                  _buildPetCmdBtn(
                      '成长', Icons.lightbulb_outline, PetCommand.askGrowth),
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
      case PetMood.happy:
        return Icon(Icons.emoji_emotions, color: Colors.white, size: size);
      case PetMood.sleepy:
        return Icon(Icons.nightlight, color: Colors.white70, size: size);
      case PetMood.excited:
        return Icon(Icons.bolt, color: Colors.yellow, size: size);
      case PetMood.thinking:
        return Icon(Icons.psychology, color: Colors.white, size: size);
      case PetMood.calm:
        return Icon(Icons.local_fire_department,
            color: Colors.white, size: size);
      case PetMood.resting:
        return Icon(Icons.bedtime, color: Colors.white70, size: size);
    }
  }

  String _getMoodText(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return '开心';
      case PetMood.sleepy:
        return '困了';
      case PetMood.excited:
        return '兴奋';
      case PetMood.thinking:
        return '思考中';
      case PetMood.calm:
        return '平静';
      case PetMood.resting:
        return '休息中';
    }
  }

  String _getMoodEmoji(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return '😊';
      case PetMood.sleepy:
        return '😴';
      case PetMood.excited:
        return '🤩';
      case PetMood.thinking:
        return '🤔';
      case PetMood.calm:
        return '😌';
      case PetMood.resting:
        return '💤';
    }
  }

  Widget _buildPetCmdBtn(String label, IconData icon, PetCommand cmd) {
    return GestureDetector(
      onTap: () {
        // 点击按钮跳转到宠物页面并发送对应命令
        Navigator.of(context).pushNamed(
          '/pet',
          arguments: {'initialMessage': label},
        );
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
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCheckIn() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 今日行动标题
          Row(
            children: [
              const Text(
                '今日行动',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              // 连续 + 累计
              Text(
                '连续 ',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '${_stats.streak} 天',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 10, color: AppColors.textLight.withValues(alpha: 0.2)),
              const SizedBox(width: 10),
              Text(
                '累积 ',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '${_stats.totalCheckIns}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (_todayLevers.isNotEmpty)
                Text(
                  '${_todayLevers.where((l) => l.isCompleted).length}/${_todayLevers.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              GestureDetector(
                onTap: _showAddLeverDialog,
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_todayLevers.isEmpty) _buildEmptyLeversCard(),
          ...List.generate(_todayLevers.length, (index) {
            final lever = _todayLevers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _toggleLever(lever),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: lever.isCompleted
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: lever.isCompleted
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: lever.isCompleted
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: lever.isCompleted
                                    ? AppColors.primary
                                    : AppColors.textLight
                                        .withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: lever.isCompleted
                                  ? [
                                      BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          spreadRadius: 1)
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: lever.isCompleted
                                  ? Colors.white
                                  : AppColors.textLight.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildLeverText(lever)),
                          GestureDetector(
                            onTap: () => _deleteLever(index),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(Icons.close,
                                  size: 16,
                                  color: AppColors.textLight
                                      .withValues(alpha: 0.35)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_todayLevers.every((l) => l.isCompleted) && !_isCheckedInToday)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkIn,
                  child: const Text('完成打卡'),
                ),
              ),
            ),
          if (_isCheckedInToday)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '今日已打卡，明天继续加油！',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyLeversCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '添加你的今日行动',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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

  /// 显示用户愿景的卡片（原 _buildVisionCard，尚未集成到 build()）
  Widget _buildVisionDisplay() {
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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

  /// 统一卡片包装
  /// Warm Editorial 风格：无白卡，左侧彩色强调边
  Widget _buildWarmCard({required Color accent, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// 大字问候 Header — Warm Editorial Typography
  Widget _buildGreetingHeader() {
    final now = DateTime.now();
    final weekday = _weekdayZh(now.weekday);
    final dateStr = '${now.month}月${now.day}日 $weekday';
    final greeting = _getGreeting();
    final subtitle = _context != null
        ? PetService.instance.generateGreetingSubtitle(_context!)
        : '';
    // 宠物专属logo：蛋阶段显示🥚，否则用SF Symbols图标
    final petLogo = (_context != null && !_context!.isInEggPhase)
        ? _context!.petEmoji
        : '🥚';

    IconData _petIcon(String emoji) {
      switch (emoji) {
        case '🥚': return Icons.egg_outlined;
        case '🦊': return CupertinoIcons.hare;
        case '🐺': return CupertinoIcons.flame;
        case '🐰': return CupertinoIcons.hare;
        case '🦌': return CupertinoIcons.leaf_arrow_circlepath;
        case '🦔': return CupertinoIcons.leaf_arrow_circlepath;
        case '🐦': return CupertinoIcons.paperplane;
        case '🐿️': return CupertinoIcons.bolt;
        case '🦝': return CupertinoIcons.eye;
        case '🐻': return CupertinoIcons.house;
        case '🐧': return CupertinoIcons.snow;
        case '🦉': return CupertinoIcons.moon;
        case '🐨': return CupertinoIcons.cloud;
        case '🐼': return CupertinoIcons.circle_grid_hex;
        case '🦋': return CupertinoIcons.sparkles;
        case '🖤': return CupertinoIcons.moon_fill;
        default: return CupertinoIcons.hare;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dateStr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 主问候语 + 宠物 Logo
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                greeting,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Icon(
              _petIcon(petLogo),
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// 长期计划卡片
  Widget _buildVisionCard() {
    final vision = _vision;
    final antiVision = _antiVision;
    final yearGoal = _storage.getYearGoal();
    final hasVision = vision.isNotEmpty && vision != '成为更好的自己';
    final hasAntiVision = antiVision.isNotEmpty;
    final hasYearGoal = yearGoal.isNotEmpty && yearGoal != '持续成长';
    if (!hasVision && !hasAntiVision && !hasYearGoal) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnnualPlanScreen()),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 长期计划 标题（只在有实际内容时显示）
                  if (hasYearGoal || hasVision) ...[
                    const Text(
                      '长期计划',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (hasYearGoal)
                    ...yearGoal
                        .split('；')
                        .where((s) => s.trim().isNotEmpty)
                        .map((goal) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin:
                                        const EdgeInsets.only(top: 6, right: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      goal.trim(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  if (hasVision) ...[
                    const SizedBox(height: 6),
                    ...vision
                        .split('；')
                        .where((s) => s.trim().isNotEmpty)
                        .map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin:
                                        const EdgeInsets.only(top: 6, right: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.textSecondary,
                                      borderRadius: BorderRadius.circular(2.5),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      v.trim(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],
                  if (hasAntiVision) ...[
                    const SizedBox(height: 4),
                    Text(
                      '不想成为：$antiVision',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
          ],
        ),
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

    // 主任务和备注
    String mainTask = plan;
    String? note;

    // 格式1：用句号/分号分隔 "主任务。如果..." 或 "主任务；如果..."
    // 先找句号，再找分号
    int splitIndex = plan.indexOf(RegExp(r'[.。]'));
    if (splitIndex < 0) {
      splitIndex = plan.indexOf(RegExp(r'[;；]'));
    }
    if (splitIndex > 0 && splitIndex < plan.length - 1) {
      final beforeSplit = plan.substring(0, splitIndex).trim();
      final afterSplit = plan.substring(splitIndex + 1).trim();
      if (beforeSplit.isNotEmpty && afterSplit.isNotEmpty) {
        mainTask = beforeSplit;
        note = afterSplit;
      }
    }

    // 如果没找到分隔符，但有 obstacle，用 obstacle 做备注
    if (note == null && obstacle.isNotEmpty) {
      note = obstacle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主要任务
        Text(
          mainTask,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            fontWeight: FontWeight.w500,
            decoration: decoration,
            height: 1.4,
          ),
        ),
        // 备注（次要展示，淡色小字）
        if (note != null && note!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            note!,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.5),
              decoration: decoration,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
