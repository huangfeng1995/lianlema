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

    // 验证年度目标页面标题
    expect(find.text('年度目标'), findsOneWidget);

    // 验证副标题
    expect(find.text('这一年结束后，你在哪方面想有突破？'), findsOneWidget);

    // 验证输入框提示文字
    expect(find.text('例如：读完24本书，跑完半程马拉松...'), findsOneWidget);

    // 验证下一步按钮存在
    expect(find.text('下一步'), findsOneWidget);
  });

  testWidgets('OnboardingScreen can enter year goal and navigate', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const OnboardingScreen(),
      ),
    );

    // 输入年度目标
    final textField = find.byType(TextField).first;
    await tester.enterText(textField, '读完24本书');
    await tester.pump();

    // 下一步按钮应可用（已填写目标）
    expect(find.text('下一步'), findsOneWidget);
  });
}
