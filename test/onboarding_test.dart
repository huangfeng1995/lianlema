import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lianlema/screens/onboarding_screen.dart';
import 'package:lianlema/theme/app_theme.dart';

void main() {
  testWidgets('OnboardingScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const OnboardingScreen(),
      ),
    );

    // 验证欢迎页标题
    expect(find.text('欢迎来到练了吗'), findsOneWidget);

    // 验证功能卡片显示
    expect(find.text('每日打卡'), findsOneWidget);
    expect(find.text('月度Boss战'), findsOneWidget);
    expect(find.text('每日杠杆'), findsOneWidget);

    // 验证下一步按钮存在
    expect(find.text('下一步'), findsOneWidget);
  });

  testWidgets('OnboardingScreen navigation works', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const OnboardingScreen(),
      ),
    );

    // 点击下一步
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    // 验证进入反愿景页面
    expect(find.text('「反愿景」\n锁定1年不可更改'), findsOneWidget);
  });
}
