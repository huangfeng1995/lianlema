import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../utils/date_utils.dart' as app_date;

/// 周复盘流程（3步骤）
/// 触发条件：每周日晚 / 手动进入
class WeeklyReviewScreen extends StatefulWidget {
  final int? reviewYear;
  final int? reviewWeek;

  const WeeklyReviewScreen({
    super.key,
    this.reviewYear,
    this.reviewWeek,
  });

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  late PageController _pageController;
  int _currentStep = 0;
  final int _totalSteps = 3;

  late StorageService _storage;
  bool _isLoading = true;

  // 周数据
  int _checkInDays = 0;
  int _completedLevers = 0;
  int _totalLevers = 0;
  String _startDate = '';
  String _endDate = '';

  // 本周感激
  String _gratitudeText = '';

  // 下周计划
  String _nextWeekPlan = '';

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

    final now = DateTime.now();
    final year = widget.reviewYear ?? now.year;
    final week = widget.reviewWeek ?? _getWeekOfYear(now);

    // 计算本周日期范围
    final weekDates = _getWeekDates(year, week);
    _startDate = app_date.AppDateUtils.formatDate(weekDates.start);
    _endDate = app_date.AppDateUtils.formatDate(weekDates.end);

    // 获取打卡数据
    final checkIns = _storage.getCheckIns();
    final levers = _storage.getDailyLevers();

    int checkInCount = 0;
    int leverCount = 0;

    for (int i = 0; i < 7; i++) {
      final date = weekDates.start.add(Duration(days: i));
      final dateStr = app_date.AppDateUtils.formatDate(date);
      final checkedIn = checkIns.any((c) => 
        app_date.AppDateUtils.formatDate(c.date) == dateStr);
      if (checkedIn) checkInCount++;
    }

    leverCount = levers.length;

    setState(() {
      _checkInDays = checkInCount;
      _totalLevers = leverCount;
      _isLoading = false;
    });
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  ({DateTime start, DateTime end}) _getWeekDates(int year, int week) {
    final firstDayOfYear = DateTime(year, 1, 1);
    final firstMonday = firstDayOfYear.add(Duration(days: (8 - firstDayOfYear.weekday) % 7));
    final weekStart = firstMonday.add(Duration(days: (week - 1) * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return (start: weekStart, end: weekEnd);
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
        return true; // 数据展示不需要输入
      case 1:
        return _gratitudeText.trim().isNotEmpty;
      case 2:
        return _nextWeekPlan.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _completeReview() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 保存周复盘数据（如果storage支持）
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('周复盘已完成 🎉'),
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
                        _buildStep1_WeekReview(),
                        _buildStep2_Gratitude(),
                        _buildStep3_NextWeek(),
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
                    color: Colors.black.withValues(alpha: 0.06),
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
                        : AppColors.primary.withValues(alpha: 0.3),
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
              : Text(_currentStep == _totalSteps - 1 ? '完成复盘 🎉' : '下一步'),
        ),
      ),
    );
  }

  // ====== Step 1: 本周回顾 =====
  Widget _buildStep1_WeekReview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这一周，你做到了什么？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_startDate - $_endDate',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildStatRow('📅', '打卡天数', '$_checkInDays / 7 天'),
          const SizedBox(height: 16),
          _buildStatRow('🎯', '每日杠杆', '$_completedLevers / $_totalLevers 项'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '每一个小行动，都在塑造更大的自己',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withValues(alpha: 0.8),
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

  Widget _buildStatRow(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textLight.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
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
                  fontSize: 18,
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

  // ====== Step 2: 本周感激 =====
  Widget _buildStep2_Gratitude() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这一周，你最感激自己的哪一刻？',
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
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: TextField(
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '例如：那天加班到很晚还是坚持写完了日记...\n\n周末早起运动的感觉特别棒...\n\n帮同事解决了一个问题...',
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

  // ====== Step 3: 下周计划 =====
  Widget _buildStep3_NextWeek() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '下周，你想有什么不同？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '写下下周最重要的一件事',
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
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: TextField(
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '例如：下周要早起3次...\n\n每天读书30分钟...\n\n减少刷短视频到每天最多30分钟...',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _nextWeekPlan = v),
            ),
          ),
        ],
      ),
    );
  }
}
