import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import 'onboarding_screen.dart';
import 'main_screen.dart';

/// Splash Screen - 简洁品牌展示 + 直接跳转
class SplashScreen extends StatefulWidget {
  final String? initialPage;
  const SplashScreen({super.key, this.initialPage});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => storage.isOnboardingComplete
            ? const MainScreen()
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEE6),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // 猫掌图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFE85D2D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity( 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image(
                    image: const AssetImage('assets/images/icon/splash_icon.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(flex: 2),
                // 文字放底部
                Text(
                  '相信行动的力量',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary.withOpacity( 0.75),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                // 装饰线
                Container(
                  width: 40,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity( 0.35),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
