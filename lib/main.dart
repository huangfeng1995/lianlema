import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'utils/notification_service.dart';
import 'utils/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 初始化通知服务
  final notificationService = await NotificationService.getInstance();

  // 获取启动时是否从通知进入
  final launchPayload = await notificationService.getNotificationLaunchPayload();

  // 调度所有报告通知
  await notificationService.scheduleAllReports();

  runApp(LianlemaApp(initialPage: launchPayload));
}

// GlobalKey 供 SettingsScreen 触发主题重建
final GlobalKey<State<MaterialApp>> appKey = GlobalKey<State<MaterialApp>>();

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: appKey,
      title: '练了吗',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: SplashScreen(initialPage: widget.initialPage),
      routes: {
        '/main': (context) => MainScreen(initialPage: widget.initialPage),
      },
    );
  }
}
