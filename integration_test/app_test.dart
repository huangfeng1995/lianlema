import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lianlema/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('Onboarding flow', (WidgetTester tester) async {
      // 启动App
      app.main();
      await tester.pumpAndSettle();

      // 验证Splash页面显示
      expect(find.text('练了吗'), findsOneWidget);
      expect(find.text('从今天开始发生改变'), findsOneWidget);

      // 等待2秒Splash后跳转到Onboarding
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // 验证Onboarding欢迎页
      expect(find.text('欢迎来到练了吗'), findsOneWidget);

      // 点击下一步按钮
      final nextButton = find.text('下一步');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }

      // 继续填写反愿景页面
      await tester.pump(const Duration(seconds: 1));

      // 截图保存测试结果
      await tester.takeScreenshot('test_result');
    });
  });
}
