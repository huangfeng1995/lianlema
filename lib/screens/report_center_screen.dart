import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../utils/report_service.dart';
import '../utils/date_utils.dart' as app_date;
import 'daily_report_screen.dart';
import 'weekly_report_screen.dart';
import 'monthly_review_screen.dart';
import 'yearly_report_screen.dart';

class ReportCenterScreen extends StatefulWidget {
  const ReportCenterScreen({super.key});

  @override
  State<ReportCenterScreen> createState() => _ReportCenterScreenState();
}

class _ReportCenterScreenState extends State<ReportCenterScreen> {
  late ReportService _reportService;
  bool _isLoading = true;

  String _dailySummary = '';
  String _weeklySummary = '';
  int _todayCompleted = 0;
  int _todayTotal = 0;
  int _weekDays = 0;
  int _monthDays = 0;
  int _yearDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await StorageService.getInstance();
    _reportService = ReportService(storage);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today;

    final dailyReport = _reportService.generateDailyReport(today);
    final weeklyReport = _reportService.generateWeeklyReport(weekEnd);
    final monthlyReport = _reportService.generateMonthlyReport(now.year, now.month);
    final yearlyReport = _reportService.generateYearlyReport(now.year);

    setState(() {
      _dailySummary = _reportService.getDailySummary();
      _weeklySummary = _reportService.getWeeklySummary();
      _todayCompleted = dailyReport.completedLevers;
      _todayTotal = dailyReport.totalLevers;
      _weekDays = weeklyReport.checkInDays;
      _monthDays = monthlyReport.checkInDays;
      _yearDays = yearlyReport.totalCheckInDays;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('报告中心'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportCard(
                    icon: Icons.today_rounded,
                    title: '日报',
                    subtitle: app_date.AppDateUtils.formatMonthDay(DateTime.now()),
                    summary: _dailySummary,
                    progress: _todayTotal > 0 ? _todayCompleted / _todayTotal : 0.0,
                    progressText: '$_todayCompleted/$_todayTotal',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DailyReportScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    icon: Icons.date_range_rounded,
                    title: '周报',
                    subtitle: '本周${_weekDays > 0 ? "已打卡" : "暂无数据"}',
                    summary: _weeklySummary,
                    progress: _weekDays / 7,
                    progressText: '$_weekDays/7天',
                    color: const Color(0xFF6C63FF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    icon: Icons.calendar_today,
                    title: '月报',
                    subtitle: '本月出勤',
                    summary: '本月已打卡$_monthDays天',
                    progress: 0,
                    progressText: '$_monthDays天',
                    color: const Color(0xFFFF9500),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MonthlyReviewScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    icon: Icons.analytics_rounded,
                    title: '年报',
                    subtitle: '${DateTime.now().year}年度',
                    summary: '今年累计打卡$_yearDays天',
                    progress: 0,
                    progressText: '$_yearDays天',
                    color: const Color(0xFF34C759),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const YearlyReportScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String summary,
    required double progress,
    required String progressText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textLight,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (progress > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        progressText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (progress > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.textLight.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
