import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'utils/notification_service.dart';

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

class LianlemaApp extends StatelessWidget {
  final String? initialPage;

  const LianlemaApp({super.key, this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '练了吗',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(initialPage: initialPage),
      routes: {
        '/main': (context) => MainScreen(initialPage: initialPage),
      },
    );
  }
}
