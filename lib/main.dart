import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/pet_screen.dart';
import 'screens/annual_plan_screen.dart';
import 'utils/notification_service.dart';
import 'utils/storage_service.dart';
import 'controllers/pet_mood_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 全局异常捕获，防止乱码显示
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 打印错误到控制台，不在 UI 显示乱码
    print('Flutter Error: ${details.exception}');
  };
  // 异步异常捕获
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Async Error: $error');
    return true;
  };
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 初始化存储服务
  final storage = await StorageService.getInstance();

  // 如果通知开启，则初始化通知服务并调度
  if (storage.getNotificationsEnabled()) {
    final notificationService = await NotificationService.getInstance();
    await notificationService.scheduleAllReports();
  }

  runApp(const LianlemaApp());
}

// GlobalKey 供 SettingsScreen 触发主题重建
final GlobalKey<_LianlemaAppState> appKey = GlobalKey<_LianlemaAppState>();

/// GetX 全局依赖绑定
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(PetMoodController(), permanent: true);
  }
}

class LianlemaApp extends StatefulWidget {
  final String? initialPage;

  const LianlemaApp({super.key, this.initialPage});

  @override
  State<LianlemaApp> createState() => _LianlemaAppState();
}

class _LianlemaAppState extends State<LianlemaApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final storage = await StorageService.getInstance();
    final isDark = storage.getDarkMode();
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // 供 SettingsScreen 调用以切换主题
  Future<void> toggleDarkMode(bool isDark) async {
    final storage = await StorageService.getInstance();
    await storage.saveDarkMode(isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      key: appKey,
      title: '练了吗',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialBinding: AppBindings(),
      home: SplashScreen(initialPage: widget.initialPage),
      routes: {
        '/main': (context) => MainScreen(initialPage: widget.initialPage),
        '/pet': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return PetScreen(initialMessage: args?['initialMessage'] as String?);
        },
        '/annual-plan': (context) => const AnnualPlanScreen(),
      },
    );
  }
}
