import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/report_models.dart';
import '../utils/storage_service.dart';
import '../utils/report_service.dart';
import '../utils/xp_service.dart';
import 'home_screen.dart';

/// 每月复盘流程（4步骤）
/// 触发条件：月度Boss击败 或 每月25日-5日打开App
class MonthlyReviewScreen extends StatefulWidget {
  /// 要复盘的月份，默认为上个月（月初复盘时）
  final int? reviewYear;
  final int? reviewMonth;

  const MonthlyReviewScreen({
    super.key,
    this.reviewYear,
    this.reviewMonth,
  });

  @override
  State<MonthlyReviewScreen> createState() => _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends State<MonthlyReviewScreen> {
  late PageController _pageController;
  int _currentStep = 0;
  final int _totalSteps = 4;

  late StorageService _storage;
  late ReportService _reportService;
  bool _isLoading = true;

  // 上月数据
  MonthlyReport? _lastMonthReport;
  MonthlyBoss? _lastMonthBoss;

  // 感激时刻
  String _gratitudeText = '';

  // 下月身份
  String _currentIdentity = '';
  String _nextIdentity = '';

  // 新Boss
  String _newBossContent = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    _reportService = ReportService(_storage);

    final stats = _storage.getUserStats();
    _currentIdentity = XpService.levelTitle(stats.level);
    _nextIdentity = XpService.levelTitle(stats.level + 1);

    // 获取上月Boss
    _lastMonthBoss = _storage.getMonthlyBoss();
    // 上月Boss可能跨月，所以直接从storage取
    // 如果上上月boss被保留在storage，则需要特殊处理
    // 这里直接用 generateMonthlyReport
    _lastMonthReport = _reportService.generateMonthlyReport(
      widget.reviewYear ?? DateTime.now().year,
      widget.reviewMonth ?? DateTime.now().month,
    );

    setState(() => _isLoading = false);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeReview();
    }
  }

  Future<void> _completeReview() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 1. 计算下个月
      int nextYear = widget.reviewYear ?? DateTime.now().year;
      int nextMonth = (widget.reviewMonth ?? DateTime.now().month) + 1;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear += 1;
      }

      // 2. 保存新Boss
      if (_newBossContent.trim().isNotEmpty) {
        final newBoss = MonthlyBoss(
          content: _newBossContent.trim(),
          month: nextMonth,
          year: nextYear,
          totalDays: DateTime(nextYear, nextMonth + 1, 0).day,
          hp: 0,
        );
        await _storage.saveMonthlyBoss(newBoss);
      }

      // 3. 标记复盘完成
      final currentMonth = '${widget.reviewYear ?? DateTime.now().year}-${(widget.reviewMonth ?? DateTime.now().month).toString().padLeft(2, '0')}';
      await _storage.saveLastReviewMonth(currentMonth);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: const Icon(Icons.check_circle, size: 36, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '复盘完成！',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '下个月，一起继续前行',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('回到首页'),
                ),
              ),
            ],
          ),
        ),
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
        child: Column(
          children: [
            _buildHeader(),
            _buildReportSummary(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildStep1_BossReview(),
                  _buildStep2_Gratitude(),
                  _buildStep3_IdentityUpgrade(),
                  _buildStep4_NewBoss(),
                ],
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ====== 月度数据总览（原月报内容） ======
  Widget _buildReportSummary() {
    final report = _lastMonthReport;
    if (report == null) return const SizedBox.shrink();

    final boss = _lastMonthBoss;
    final reviewYear = widget.reviewYear ?? DateTime.now().year;
    final reviewMonth = widget.reviewMonth ?? DateTime.now().month;
    final isBossForReviewMonth = boss != null &&
        boss.year == reviewYear &&
        boss.month == reviewMonth;
    final bossHp = isBossForReviewMonth ? boss.hp : 0;
    final bossTotal = isBossForReviewMonth ? boss.totalDays : 0;
    final isDefeated = bossHp >= bossTotal && bossTotal > 0;
    final attendance = report.totalDays > 0 ? report.checkInDays / report.totalDays : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('本月战报', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDefeated
                      ? AppColors.success.withValues(alpha: 0.15)
                      : const Color(0xFFFF9500).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDefeated ? '🏆 Boss击败' : '🔥 Boss进行中',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isDefeated ? AppColors.success : const Color(0xFFFF9500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip('📅 出勤', '${report.checkInDays}天'),
              const SizedBox(width: 8),
              _buildStatChip('⚡ 出勤率', '${(attendance * 100).toInt()}%'),
              const SizedBox(width: 8),
              _buildStatChip('⭐ XP', '+${report.xpEarned}'),
              const SizedBox(width: 8),
              _buildStatChip('🔥 连续', '${report.longestStreak}天'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
              color: AppColors.primary,
            )),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(
              fontSize: 10, color: AppColors.textSecondary,
            ), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
              const Spacer(),
              Text(
                '${_currentStep + 1}/$_totalSteps',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final canProceed = _currentStep < 2 || _newBossContent.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (canProceed && !_isSaving) ? _nextStep : null,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_currentStep == _totalSteps - 1 ? '完成复盘 ✨' : '下一步'),
        ),
      ),
    );
  }

  // ====== Step 1: 上个月Boss回顾 ======
  Widget _buildStep1_BossReview() {
    final report = _lastMonthReport;
    final boss = _lastMonthBoss;
    final reviewYear = widget.reviewYear ?? DateTime.now().year;
    final reviewMonth = widget.reviewMonth ?? DateTime.now().month;

    // 判断是否是当月boss还是上月boss
    final isBossForReviewMonth = boss != null &&
        boss.year == reviewYear &&
        boss.month == reviewMonth;

    final bossContent = isBossForReviewMonth ? boss.content : (report?.bossDefeated == false ? '本月Boss' : '—');
    final bossHp = isBossForReviewMonth ? boss.hp : (report?.checkInDays ?? 0);
    final bossTotal = isBossForReviewMonth ? boss.totalDays : (report?.bossTotalHp ?? 0);
    final isDefeated = bossHp >= bossTotal && bossTotal > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${reviewYear}年${reviewMonth}月',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '上个月Boss\n完成了吗？',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),

          // Boss状态卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDefeated
                    ? AppColors.success.withValues(alpha: 0.4)
                    : const Color(0xFFFF9500).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDefeated
                            ? AppColors.success.withValues(alpha: 0.1)
                            : const Color(0xFFFF9500).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          isDefeated ? '🏆' : '🔥',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '月度Boss',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bossContent,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // HP条
                if (bossTotal > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDefeated ? '已击败！' : '进行中',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDefeated ? AppColors.success : const Color(0xFFFF9500),
                        ),
                      ),
                      Text(
                        'HP $bossHp/$bossTotal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (bossHp / bossTotal).clamp(0.0, 1.0),
                      backgroundColor: AppColors.textLight.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDefeated ? AppColors.success : const Color(0xFFFF9500),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 结果展示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDefeated
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  isDefeated ? '✨' : '💪',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDefeated ? '恭喜！你击败了上个月的Boss' : '这个月还差一点，继续加油',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDefeated ? AppColors.success : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDefeated
                            ? '连续打卡$bossHp天，你做到了！'
                            : '打卡$bossHp天，完成${bossTotal > 0 ? ((bossHp / bossTotal) * 100).toInt() : 0}%，下个月继续！',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 月度打卡数据
          if (report != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '本月战果',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildStatItem('打卡天数', '${report.checkInDays}天'),
                      const SizedBox(width: 24),
                      _buildStatItem('出勤率', '${report.totalDays > 0 ? ((report.checkInDays / report.totalDays) * 100).toInt() : 0}%'),
                      const SizedBox(width: 24),
                      _buildStatItem('获得XP', '+${report.xpEarned}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ====== Step 2: 感激自己的时刻 ======
  Widget _buildStep2_Gratitude() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            '感激自己的时刻 🎀',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.reviewYear ?? DateTime.now().year}年${widget.reviewMonth ?? DateTime.now().month}月，哪些时刻让你骄傲？',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              maxLines: 7,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: '例如：\n虽然没完全击败Boss，但坚持了20天\n第一次完成了全部杠杆\n在很累的时候还是选择行动',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(18),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _gratitudeText = v),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '记录这些时刻，让它们成为你持续行动的能量 💖',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ====== Step 3: 下月身份升级 ======
  Widget _buildStep3_IdentityUpgrade() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            '下月身份升级预告 ⬆️',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '你已经走在持续成长的路上\n下个月，你将以什么身份继续前行？',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          // 当前身份
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textLight.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前身份',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentIdentity,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('→', style: TextStyle(color: AppColors.primary, fontSize: 16)),
                  SizedBox(width: 4),
                  Text(
                    '下月升级',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 下月身份
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primaryLight.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '下月身份',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _nextIdentity,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '每月持续行动，身份自然升级',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====== Step 4: 新Boss选择 ======
  Widget _buildStep4_NewBoss() {
    int nextYear = widget.reviewYear ?? DateTime.now().year;
    int nextMonth = (widget.reviewMonth ?? DateTime.now().month) + 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$nextYear 年 $nextMonth 月',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '新月度Boss\n你想击败什么？',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '用「我是已经击败了这个Boss的人」来描述\n打败它，你将更接近理想中的自己',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _newBossContent.trim().isNotEmpty
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '例如：我是已经击败了「早起30天」这个Boss的人\n我是已经读完《原子习惯》的人\n我是已经连续打卡21天的人',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(18),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _newBossContent = v),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.whatshot, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '每月打卡满天数 = 击败Boss\n没击败会累积到下个月，持续追击！',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
