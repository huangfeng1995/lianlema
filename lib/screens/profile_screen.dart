import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_celebration.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/xp_service.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/badge_icon.dart';
import '../utils/pet_service.dart';
import '../widgets/encouragement_stats_card.dart';
import '../services/share_service.dart';
import 'settings_screen.dart';
import 'report_center_screen.dart';
import 'weekly_review_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late StorageService _storage;
  bool _isLoading = true;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  UserStats _stats = UserStats(
    level: 1,
    currentXP: 0,
    totalXP: 0,
    streak: 0,
    totalCheckIns: 0,
  );

  List<AppBadge> _badges = [];
  String _antiVision = '';
  String _vision = '';
  String _annualIdentity = '';
  List<CheckIn> _checkIns = [];
  String _petName = StorageService.defaultPetName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _storage = await StorageService.getInstance();
      await PetService.instance.loadState();

      final stats = _storage.getUserStats();
      final badges = _storage.getBadges();
      final antiVision = _storage.getAntiVision();
      final vision = _storage.getVision();
      final annualIdentity = _storage.getAnnualIdentity();
      final checkIns = _storage.getCheckIns();
      final petName = _storage.getPetName();

      setState(() {
        _stats = stats;
        _badges = badges;
        _antiVision = antiVision;
        _vision = vision;
        _annualIdentity = annualIdentity;
        _checkIns = checkIns;
        _petName = petName;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('ProfileScreen _loadData error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Set<String> get _checkInDates {
    return _checkIns
        .map((c) => app_date.AppDateUtils.formatDate(c.date))
        .toSet();
  }

  int get _monthlyCheckIns {
    return _checkIns.where((c) {
      return c.date.year == _selectedYear && c.date.month == _selectedMonth;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('我的'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportData,
            tooltip: '导出数据',
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportCenterScreen()),
              );
            },
            tooltip: '报告中心',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildPetNameCard(),
                  const SizedBox(height: 24),
                  if (_annualIdentity.isNotEmpty) ...[
                    _buildAnnualIdentitySection(),
                    const SizedBox(height: 24),
                  ],
                  _buildCalendarSection(),
                  const SizedBox(height: 24),
                  _buildBadgesSection(),
                  const SizedBox(height: 12),
                  _buildEncouragementStatsSection(),
                  const SizedBox(height: 24),
                  _buildLongTermPlanningSection(),
                  const SizedBox(height: 12),
                  _buildReviewSection(),
                  const SizedBox(height: 12),
                  _buildShareSection(),
                  const SizedBox(height: 12),
                  _buildDataExportSection(),
                  const SizedBox(height: 24),
                  _buildAntiVisionSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Lv${_stats.level}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      XpService.levelTitle(_stats.level),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lv ${_stats.level}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_stats.totalXP} XP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity( 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, size: 14, color: AppColors.streak),
                        const SizedBox(width: 4),
                        Text(
                          '${_stats.streak}天',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总打卡', '${_stats.totalCheckIns}'),
              Container(width: 1, height: 30, color: Colors.white30),
              _buildStatItem('本月', '$_monthlyCheckIns'),
              Container(width: 1, height: 30, color: Colors.white30),
              _buildStatItem('徽章', '${_badges.where((b) => b.isUnlocked).length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnualIdentitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity( 0.12),
            AppColors.primaryLight.withOpacity( 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity( 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity( 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.star, size: 24, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '我是',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _annualIdentity,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '的行动派',
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

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '打卡日历',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth == 1) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      } else {
                        _selectedMonth--;
                      }
                    });
                  },
                ),
                Text(
                  '$_selectedYear年$_selectedMonth月',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth == 12) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      } else {
                        _selectedMonth++;
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: ['一', '二', '三', '四', '五', '六', '日']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 12,
                                color: (d == '六' || d == '日')
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              _buildCalendarGrid(),
              const SizedBox(height: 12),
              _buildAttendanceRate(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceRate() {
    final now = DateTime.now();
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final today = DateTime(now.year, now.month, now.day);
    final selectedToday = DateTime(_selectedYear, _selectedMonth, daysInMonth);

    // 计算当月总天数（如果看当月则只算到今天）
    final daysToCount = (_selectedYear == now.year && _selectedMonth == now.month)
        ? now.day
        : daysInMonth;

    final checkedInDays = _checkIns.where((c) {
      return c.date.year == _selectedYear &&
          c.date.month == _selectedMonth &&
          !c.date.isAfter(today);
    }).length;

    final attendanceRate = daysToCount > 0 ? (checkedInDays / daysToCount * 100).round() : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '本月出勤率',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            if (attendanceRate < 100 && daysToCount > checkedInDays)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity( 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              '$attendanceRate%（$checkedInDays/$daysToCount天）',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: attendanceRate == 100 ? AppColors.success : AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final startWeekday = firstDay.weekday;
    final now = DateTime.now();
    final isCurrentMonth = (_selectedYear == now.year && _selectedMonth == now.month);

    List<Widget> dayWidgets = [];

    for (int i = 1; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(
        DateTime(_selectedYear, _selectedMonth, day),
      );
      final isCheckedIn = _checkInDates.contains(dateStr);
      final isToday = (day == now.day && _selectedMonth == now.month && _selectedYear == now.year);

      // 战损判断：当天还没到，或者已到但未打卡
      final date = DateTime(_selectedYear, _selectedMonth, day);
      final isMissedDay = !isCheckedIn && date.isBefore(DateTime(now.year, now.month, now.day));

      dayWidgets.add(
        Container(
          decoration: BoxDecoration(
            color: isCheckedIn
                ? AppColors.primary
                : isToday
                    ? AppColors.primary.withOpacity( 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday && !isCheckedIn
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    color: isCheckedIn
                        ? Colors.white
                        : isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
                    fontWeight: (isToday || isCheckedIn) ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              // 未打卡的历史日期：灰色虚线圆圈（去除污名化）
              if (isMissedDay)
                CustomPaint(
                  size: const Size(28, 28),
                  painter: _DamageSlashPainter(),
                ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: dayWidgets,
    );
  }

  Widget _buildBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '徽章墙',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = _badges[index];
              return GestureDetector(
                onTap: () => _showBadgeDetail(badge),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: badge.isUnlocked
                            ? AppColors.primary.withOpacity( 0.1)
                            : AppColors.textLight.withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: badge.isUnlocked
                              ? AppColors.primary
                              : AppColors.textLight.withOpacity( 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          getBadgeIcon(badge.icon),
                          size: 36,
                          color: getBadgeColor(badge.icon, isUnlocked: badge.isUnlocked),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      badge.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: badge.isUnlocked
                            ? AppColors.textPrimary
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEncouragementStatsSection() {
    return const EncouragementStatsCard();
  }

  Widget _buildLongTermPlanningSection() {
    final hasAntiVision = _antiVision.isNotEmpty;
    final hasVision = _vision.isNotEmpty;
    final hasYearGoal = _annualIdentity.isNotEmpty;
    final constraints = _storage.getConstraints();
    // 排除默认值「每天进步一点点」，只有用户真实填写才算已完成
    final hasConstraints = constraints.isNotEmpty && constraints != '每天进步一点点';

    final completedCount = [hasAntiVision, hasVision, hasYearGoal, hasConstraints].where((b) => b).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '长期规划',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (completedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '已完成 $completedCount/4',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (hasAntiVision) ...[
                _buildPlanningItem(
                  icon: Icons.map_outlined,
                  iconColor: const Color(0xFF888888),
                  title: '反愿景',
                  desc: _antiVision,
                  isSet: true,
                ),
                const SizedBox(height: 12),
              ],
              if (hasVision) ...[
                _buildPlanningItem(
                  icon: Icons.visibility_outlined,
                  iconColor: AppColors.primary,
                  title: '愿景',
                  desc: _vision,
                  isSet: true,
                ),
                const SizedBox(height: 12),
              ],
              if (hasYearGoal) ...[
                _buildPlanningItem(
                  icon: Icons.flag_outlined,
                  iconColor: AppColors.primary,
                  title: '年度目标',
                  desc: _annualIdentity,
                  isSet: true,
                ),
                const SizedBox(height: 12),
              ],
              if (hasConstraints) ...[
                _buildPlanningItem(
                  icon: Icons.balance_outlined,
                  iconColor: const Color(0xFF888888),
                  title: '约束条件',
                  desc: constraints,
                  isSet: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanningItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required bool isSet,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSet ? iconColor.withOpacity( 0.1) : AppColors.textLight.withOpacity( 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isSet ? iconColor : AppColors.textLight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSet ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: isSet ? AppColors.textSecondary : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSet ? AppColors.success.withOpacity( 0.1) : AppColors.textLight.withOpacity( 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isSet ? '✓' : '未设置',
            style: TextStyle(
              fontSize: 12,
              color: isSet ? AppColors.success : AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAntiVisionSection() {
    // 已合并到长期规划模块，隐藏重复内容
    return const SizedBox.shrink();
  }

  /// 导出数据到剪贴板（JSON 格式）
  Future<void> _exportData() async {
    final data = _storage.exportAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('数据已复制到剪贴板'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
    }
  }

  Widget _buildReviewSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WeeklyReviewScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity( 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '定期回顾',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    '查看周/月复盘',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildShareSection() {
    return GestureDetector(
      onTap: () => ShareService.shareStreak(_stats.streak),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity( 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.share, size: 18, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '分享坚持',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '已连续打卡 ${_stats.streak} 天',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildDataExportSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _showExportDialog,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity( 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.download, size: 18, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '导出数据',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      '备份你的所有打卡记录和宠物数据',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download, color: AppColors.primary),
            SizedBox(width: 8),
            Text('导出数据'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '将导出以下数据：',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildExportItem(Icons.check_circle, '打卡记录'),
            _buildExportItem(Icons.check_circle, '宠物状态'),
            _buildExportItem(Icons.check_circle, '徽章与成就'),
            _buildExportItem(Icons.check_circle, '激励统计'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '数据格式为 JSON，可用于备份或在网页端查看详细统计',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _exportData();
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('复制数据'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// 分享给朋友（复制到剪贴板）
  Future<void> _shareWithFriends() async {
    final text = '''我最近在用『练了吗』养成每日习惯，一起加油！

反愿景：${_antiVision.isNotEmpty ? _antiVision : '成为每天虚度光阴的人'}
✨ 我的愿景：${_vision.isNotEmpty ? _vision : '活成自己想要的样子'}

从今天开始发生改变 📍
#练了吗''';

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分享文案已复制，去粘贴告诉朋友吧'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildPetNameCard() {
    return GestureDetector(
      onTap: _showEditPetNameDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity( 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.pets, size: 22, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '宠物名字',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _petName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPetNameDialog() {
    final controller = TextEditingController(text: _petName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.pets, size: 24, color: AppColors.primary),
            SizedBox(width: 8),
            Text('修改宠物名字'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: '输入新名字（最多10字）',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
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
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _storage.savePetName(newName);
                setState(() {
                  _petName = newName.length > 10 ? newName.substring(0, 10) : newName;
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(AppBadge badge) {
    // 已解锁徽章查看时触发彩纸庆祝
    if (badge.isUnlocked) {
      ConfettiOverlay.show(context);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? AppColors.primary.withOpacity( 0.1)
                    : AppColors.textLight.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  getBadgeIcon(badge.icon),
                  size: 56,
                  color: getBadgeColor(badge.icon, isUnlocked: badge.isUnlocked),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (badge.isUnlocked && badge.unlockedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                '解锁于 ${DateFormat('yyyy-MM-dd').format(badge.unlockedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
            if (!badge.isUnlocked) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '尚未解锁',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// 战损斜线Painter - 未打卡日期显示红色删除线
class _DamageSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE85A1C).withOpacity( 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.85);
    path.lineTo(size.width * 0.85, size.height * 0.15);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
