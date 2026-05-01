import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../utils/xp_service.dart';

/// 年度复盘流程（4步骤）
/// 触发条件：每年12月31日 / 周年推送
class YearlyReviewScreen extends StatefulWidget {
  final int? reviewYear;

  const YearlyReviewScreen({
    super.key,
    this.reviewYear,
  });

  @override
  State<YearlyReviewScreen> createState() => _YearlyReviewScreenState();
}

class _YearlyReviewScreenState extends State<YearlyReviewScreen> {
  late PageController _pageController;
  int _currentStep = 0;
  final int _totalSteps = 4;

  late StorageService _storage;
  bool _isLoading = true;

  // 年度数据
  int _totalCheckIns = 0;
  int _totalBossesDefeated = 0;
  int _longestStreak = 0;
  int _level = 1;

  // 最感激自己的时刻
  String _gratitudeText = '';

  // 年度总结
  String _yearSummary = '';

  // 下一年的身份升级
  String _nextYearIdentity = '';

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

    final reviewYear = widget.reviewYear ?? DateTime.now().year;

    // 获取年度数据
    final stats = _storage.getUserStats();
    final checkIns = _storage.getCheckIns();

    final yearCheckIns = checkIns.where((c) => c.date.year == reviewYear).toList();
    _totalCheckIns = yearCheckIns.length;

    // 计算最长连续
    _longestStreak = _calculateLongestStreak(yearCheckIns.map((c) => c.date).toList());

    // 计算击败的boss数量（需要从历史记录中获取，简化处理）
    _totalBossesDefeated = stats.totalCheckIns ~/ 30; // 估算

    _level = stats.level;

    setState(() => _isLoading = false);
  }

  int _calculateLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    dates.sort();
    int maxStreak = 1;
    int currentStreak = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }
    return maxStreak;
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

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true; // 年度回顾不需要输入
      case 1:
        return _gratitudeText.trim().isNotEmpty;
      case 2:
        return _yearSummary.trim().isNotEmpty;
      case 3:
        return _nextYearIdentity.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _completeReview() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 保存年度身份
      await _storage.saveAnnualIdentity(_nextYearIdentity);

      // 保存到storage（如果有专门的年度总结字段可以保存）

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [const Icon(Icons.check_circle, color: Colors.white, size: 18), const SizedBox(width: 8), const Text('年度复盘已完成')]),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentStep = index),
                      children: [
                        _buildStep1_YearReview(),
                        _buildStep2_Gratitude(),
                        _buildStep3_YearSummary(),
                        _buildStep4_NextYear(),
                      ],
                    ),
                  ),
                  _buildBottom(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity( 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
              Text(
                '${_currentStep + 1} / $_totalSteps',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? AppColors.primary
                        : AppColors.primary.withOpacity( 0.3),
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

  Widget _buildBottom() {
    final canProceed = _canProceed();

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

  // ====== Step 1: 年度回顾 =====
  Widget _buildStep1_YearReview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这一年，你做到了什么？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '回顾这一年的行动成果',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildStatCard(Icons.calendar_today, AppColors.primary, '打卡天数', '$_totalCheckIns 天'),
          const SizedBox(height: 16),
          _buildStatCard(Icons.local_fire_department, AppColors.streak, '最长连续', '$_longestStreak 天'),
          const SizedBox(height: 16),
          _buildStatCard(Icons.shield, AppColors.primary, '完成挑战', '$_totalBossesDefeated 个'),
          const SizedBox(height: 16),
          _buildStatCard(Icons.star, const Color(0xFFFFD700), '当前等级', 'Lv.$_level · ${XpService.levelTitle(_level)}'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity( 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '这些数字背后，是你每一个小小的行动',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withOpacity( 0.8),
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

  Widget _buildStatCard(IconData icon, Color iconColor, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textLight.withOpacity( 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====== Step 2: 感激时刻 =====
  Widget _buildStep2_Gratitude() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这一年，你最感激自己的哪一刻？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '不是结果，是过程中的某个瞬间',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity( 0.3)),
            ),
            child: TextField(
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: '例如：那天晚上坚持写完日记，虽然很累...\n\n完成连续7天打卡的那一刻...\n\n第一次完成月度挑战时的激动...',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _gratitudeText = v),
            ),
          ),
        ],
      ),
    );
  }

  // ====== Step 3: 年度总结 =====
  Widget _buildStep3_YearSummary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这一年，你活成了什么样的人？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '用一句话总结你的这一年',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity( 0.3)),
            ),
            child: TextField(
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '例如：坚持了100天打卡的行动派\n从拖延症患者变成了执行者\n每天早起读书的终身学习者',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _yearSummary = v),
            ),
          ),
        ],
      ),
    );
  }

  // ====== Step 4: 下一年身份 =====
  Widget _buildStep4_NextYear() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '新的一年，你想成为什么样的人？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '这是你下一年的身份宣言',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity( 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '用「我是_____的人」来描述',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withOpacity( 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity( 0.3)),
            ),
            child: TextField(
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '我是每天早起写作的人\n我是能够影响他人一起成长的人\n我是真正的终身学习者',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _nextYearIdentity = v),
            ),
          ),
        ],
      ),
    );
  }
}
