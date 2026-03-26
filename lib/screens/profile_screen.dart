import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/xp_service.dart';
import '../utils/date_utils.dart' as app_date;
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
  List<CheckIn> _checkIns = [];

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
    final checkIns = _storage.getCheckIns();

    setState(() {
      _stats = stats;
      _badges = badges;
      _antiVision = antiVision;
      _vision = vision;
      _checkIns = checkIns;
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
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
                ),
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
                  const SizedBox(height: 24),
                  _buildCalendarSection(),
                  const SizedBox(height: 24),
                  _buildBadgesSection(),
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
                    child: Text(
                      '🔥 ${_stats.streak}天',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
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
              // 战损红色斜线标记（未打卡的历史日期）
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
                        child: Text(
                          badge.icon,
                          style: TextStyle(
                            fontSize: 28,
                            color: badge.isUnlocked ? null : Colors.grey,
                          ),
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

  Widget _buildAntiVisionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '反愿景提醒',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '锁定中 · 1年不可更改',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '我最不想成为的人',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _antiVision.isNotEmpty ? _antiVision : '暂无内容',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
              if (_vision.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  '我的愿景',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _vision,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
                child: Text(
                  badge.icon,
                  style: const TextStyle(fontSize: 40),
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
