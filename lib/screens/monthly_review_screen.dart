import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/report_models.dart';
import '../utils/storage_service.dart';
import '../utils/report_service.dart';

/// 月度回顾页面 - 单页滚动设计
class MonthlyReviewScreen extends StatefulWidget {
  final int? reviewYear;
  final int? reviewMonth;

  const MonthlyReviewScreen({super.key, this.reviewYear, this.reviewMonth});

  @override
  State<MonthlyReviewScreen> createState() => _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends State<MonthlyReviewScreen> {
  late StorageService _storage;
  late ReportService _reportService;
  bool _isLoading = true;

  MonthlyReport? _lastMonthReport;
  MonthlyBoss? _lastMonthBoss;
  final List<String> _newBossItems = [''];
  List<TextEditingController> _bossControllers = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bossControllers = [TextEditingController()];
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _bossControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    _reportService = ReportService(_storage);
    _lastMonthBoss = _storage.getMonthlyBoss();
    _lastMonthReport = _reportService.generateMonthlyReport(
      widget.reviewYear ?? DateTime.now().year,
      widget.reviewMonth ?? DateTime.now().month,
    );
    setState(() => _isLoading = false);
  }

  Future<void> _completeReview() async {
    debugPrint('月度回顾：_completeReview 被调用, _isSaving=$_isSaving');
    if (_isSaving) {
      debugPrint('月度回顾：_isSaving=true，直接返回');
      return;
    }

    final goals = _bossControllers
        .map((c) => c.text.trim())
        .where((g) => g.isNotEmpty)
        .toList();

    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少填写一个月度挑战'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      int nextYear = widget.reviewYear ?? DateTime.now().year;
      int nextMonth = (widget.reviewMonth ?? DateTime.now().month) + 1;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear += 1;
      }

      final newBoss = MonthlyBoss(
        content: goals.join('；'),
        month: nextMonth,
        year: nextYear,
        totalDays: DateTime(nextYear, nextMonth + 1, 0).day,
        hp: 0,
      );
      await _storage.saveMonthlyBoss(newBoss);

      final currentMonth = '${widget.reviewYear ?? DateTime.now().year}-${(widget.reviewMonth ?? DateTime.now().month).toString().padLeft(2, '0')}';
      await _storage.saveLastReviewMonth(currentMonth);

      if (mounted) {
        debugPrint('月度回顾：mounted=true，执行pop');
        Navigator.of(context).pop(true);
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

  void _addBossItem() {
    if (_newBossItems.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目标不宜过多，聚焦最重要的事效果更好')),
      );
      return;
    }
    setState(() {
      _newBossItems.add('');
      _bossControllers.add(TextEditingController());
    });
  }

  void _removeBossItem(int index) {
    if (_newBossItems.length <= 1) return;
    setState(() {
      _bossControllers[index].dispose();
      _bossControllers.removeAt(index);
      _newBossItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final reviewYear = widget.reviewYear ?? DateTime.now().year;
    final reviewMonth = widget.reviewMonth ?? DateTime.now().month;
    final report = _lastMonthReport;
    final boss = _lastMonthBoss;

    final isBossForReviewMonth = boss != null && boss.year == reviewYear && boss.month == reviewMonth;
    final bossHp = isBossForReviewMonth ? boss.hp : 0;
    final bossTotal = isBossForReviewMonth ? boss.totalDays : 0;
    final isDefeated = bossHp >= bossTotal && bossTotal > 0;
    final attendance = (report?.totalDays ?? 0) > 0 ? report!.checkInDays / report.totalDays : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 24, color: AppColors.textSecondary),
        ),
        title: Text(
          '$reviewYear年$reviewMonth月复盘',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====== 挑战结果 ======
              _buildSectionCard(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDefeated
                              ? AppColors.success.withValues(alpha: 0.12)
                              : const Color(0xFFFF9500).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isDefeated ? Icons.emoji_events : Icons.local_fire_department,
                          size: 28,
                          color: isDefeated ? AppColors.success : const Color(0xFFFF9500),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDefeated ? '挑战完成！' : '挑战进行中',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDefeated ? AppColors.success : AppColors.textPrimary,
                              ),
                            ),
                            if (isBossForReviewMonth) ...[
                              const SizedBox(height: 4),
                              Text(
                                boss.content,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isDefeated && bossTotal > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (bossHp / bossTotal).clamp(0.0, 1.0),
                              backgroundColor: AppColors.textLight.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9500)),
                              minHeight: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$bossHp/$bossTotal天',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // ====== 本月数据 ======
              _buildSectionCard(
                children: [
                  Row(
                    children: [
                      _buildStatCard('${report?.checkInDays ?? 0}', '打卡天数', Icons.calendar_today_outlined),
                      const SizedBox(width: 12),
                      _buildStatCard('${report?.longestStreak ?? 0}', '最长连续', Icons.local_fire_department_outlined),
                      const SizedBox(width: 12),
                      _buildStatCard('${(attendance * 100).toInt()}%', '出勤率', Icons.trending_up_outlined),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ====== 新月度挑战 ======
              _buildSectionCard(
                children: [
                  _buildSectionHeader('新月度挑战', Icons.flag_outlined, '用「我已经击败了...」来描述你的挑战'),
                  const SizedBox(height: 10),
                  ...List.generate(_newBossItems.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < _newBossItems.length - 1 ? 10 : 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: index < _bossControllers.length ? _bossControllers[index] : null,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: '例如：我是已经击败了「早起30天」这个Boss的人',
                                hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6), fontSize: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                          if (_newBossItems.length > 1)
                            GestureDetector(
                              onTap: () => _removeBossItem(index),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6, top: 10),
                                child: Icon(Icons.close, size: 18, color: AppColors.textLight.withValues(alpha: 0.4)),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _addBossItem,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            '添加挑战',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ====== 完成按钮 ======
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _completeReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('完成复盘', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  }
