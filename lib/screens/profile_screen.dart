import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/xp_service.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/badge_icon.dart';
import 'settings_screen.dart';

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
    _storage = await StorageService.getInstance();

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
                  const SizedBox(height: 24),
                  _buildLongTermPlanningSection(),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primaryLight.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
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
                  color: AppColors.primary.withValues(alpha: 0.5),
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
                    ? AppColors.primary.withValues(alpha: 0.1)
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
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.textLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: badge.isUnlocked
                              ? AppColors.primary
                              : AppColors.textLight.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          getBadgeIcon(badge.icon),
                          size: 36,
                          color: badge.isUnlocked
                              ? Color(0xFFFF6B00)
                              : AppColors.textLight.withValues(alpha: 0.35),
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

  Widget _buildLongTermPlanningSection() {
    final hasAntiVision = _antiVision.isNotEmpty;
    final hasVision = _vision.isNotEmpty;
    final hasYearGoal = _annualIdentity.isNotEmpty;
    final constraints = _storage.getConstraints();
    // 只有当约束不是默认的「每天进步一点点」时才计数
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
                  color: AppColors.primary.withValues(alpha: 0.1),
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
            color: isSet ? iconColor.withValues(alpha: 0.1) : AppColors.textLight.withValues(alpha: 0.1),
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
            color: isSet ? AppColors.success.withValues(alpha: 0.1) : AppColors.textLight.withValues(alpha: 0.1),
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

  /// 导出数据到剪贴板
  Future<void> _exportData() async {
    final now = DateTime.now();
    final unlockedBadges = _badges.where((b) => b.isUnlocked).toList();

    // 计算每月出勤
    final monthlyStats = <String>[];
    for (int m = 1; m <= 12; m++) {
      final monthCheckIns = _checkIns.where((c) => c.date.year == now.year && c.date.month == m).length;
      final totalDays = DateTime(now.year, m + 1, 0).day;
      final actualDays = (m == now.month) ? now.day : totalDays;
      if (monthCheckIns > 0 || m <= now.month) {
        monthlyStats.add('${m}月：$monthCheckIns/$actualDays天');
      }
    }

    final report = StringBuffer();
    report.writeln('=== 练了吗 数据导出 ===');
    report.writeln('导出时间：${DateFormat('yyyy-MM-dd HH:mm').format(now)}');
    report.writeln('');
    report.writeln('【基本信息】');
    report.writeln('连续打卡：${_stats.streak}天');
    report.writeln('总打卡次数：${_stats.totalCheckIns}天');
    report.writeln('等级：Lv${_stats.level}');
    report.writeln('总经验值：${_stats.totalXP} XP');
    if (unlockedBadges.isNotEmpty) {
      report.writeln('徽章：${unlockedBadges.map((b) => b.name).join(' / ')}');
    }
    report.writeln('');
    report.writeln('【愿景】');
    report.writeln('反愿景：${_antiVision.isNotEmpty ? _antiVision : '未设置'}');
    report.writeln('愿景：${_vision.isNotEmpty ? _vision : '未设置'}');
    if (_annualIdentity.isNotEmpty) {
      report.writeln('年度身份：我是${_annualIdentity}的行动派');
    }
    report.writeln('');
    report.writeln('【${now.year}年打卡日历】');
    for (final stat in monthlyStats) {
      report.writeln(stat);
    }
    report.writeln('');
    report.writeln('【约束条件】');
    final constraints = _storage.getConstraints();
    report.writeln(constraints.isNotEmpty ? constraints : '未设置');

    final text = report.toString();

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('数据已复制到剪贴板'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
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
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
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
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  getBadgeIcon(badge.icon),
                  size: 56,
                  color: badge.isUnlocked
                      ? Color(0xFFFF6B00)
                      : AppColors.textLight.withValues(alpha: 0.35),
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
                  color: AppColors.textLight.withValues(alpha: 0.1),
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
      ..color = const Color(0xFFE85A1C).withValues(alpha: 0.5)
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
