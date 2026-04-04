import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'pet_screen.dart';
import 'daily_report_screen.dart';
import 'weekly_report_screen.dart';
import 'monthly_report_screen.dart';
import 'yearly_report_screen.dart';

class MainScreen extends StatefulWidget {
  final String? initialPage;

  const MainScreen({super.key, this.initialPage});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const PetScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 根据通知类型跳转到对应页面
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationNavigation();
    });
  }

  void _handleNotificationNavigation() {
    if (widget.initialPage == null) return;

    switch (widget.initialPage) {
      case 'daily_report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyReportScreen()),
        );
        break;
      case 'weekly_report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
        );
        break;
      case 'monthly_report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
        );
        break;
      case 'yearly_report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const YearlyReportScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
