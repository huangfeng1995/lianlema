import 'package:flutter_test/flutter_test.dart';

/// 模拟 _getSuggestedChallenges 的核心逻辑
/// （复制 onboarding_screen.dart 里的算法，不依赖 Flutter）
List<String> getSuggestedChallenges(String yearGoals) {
  final suggestions = <String, String>{};

  for (final goal in yearGoals.split('；')) {
    if (goal.trim().isEmpty) continue;
    final g = goal.toLowerCase();
    final bucket = goal.trim();

    if (g.contains('马拉松') || g.contains('跑')) {
      suggestions['$bucket-跑1'] = '每月跑步累计80-100公里';
      suggestions['$bucket-跑2'] = '每月完成1次LSD（20km+）';
    }
    if (g.contains('研究生') || g.contains('考研') || g.contains('考博') || g.contains('上岸')) {
      suggestions['$bucket-学1'] = '制定备考计划并执行';
      suggestions['$bucket-学2'] = '每月完成1次模拟测试';
    }
    if (g.contains('运动') || g.contains('健身')) {
      suggestions['$bucket-动1'] = '每周运动3次';
      suggestions['$bucket-动2'] = '养成运动习惯';
    }
    if (g.contains('早起') || g.contains('早睡')) {
      suggestions['$bucket-早1'] = '养成早起习惯';
    }
    if (g.contains('书') || g.contains('阅读') || g.contains('读')) {
      suggestions['$bucket-读1'] = '每月读1-2本书';
    }
    if (g.contains('写作') || g.contains('写文章')) {
      suggestions['$bucket-写1'] = '每周写作3篇';
    }
    if (g.contains('英语') || g.contains('外语') || g.contains('语言')) {
      suggestions['$bucket-英1'] = '每天学英语30分钟';
    }
  }

  return suggestions.values.take(6).toList();
}

void main() {
  group('年度目标 → 月度挑战拆解', () {
    test('跑马拉松 → 训练计划', () {
      final result = getSuggestedChallenges('跑一次马拉松');
      expect(result, contains('每月跑步累计80-100公里'));
      expect(result, contains('每月完成1次LSD（20km+）'));
    });

    test('考上研究生 → 备考计划', () {
      final result = getSuggestedChallenges('考上研究生');
      expect(result, contains('制定备考计划并执行'));
      expect(result, contains('每月完成1次模拟测试'));
    });

    test('每天运动 → 习惯养成', () {
      final result = getSuggestedChallenges('每天运动');
      expect(result, contains('每周运动3次'));
      expect(result, contains('养成运动习惯'));
    });

    test('三项目标混合 → 各取不同，不重复', () {
      final result = getSuggestedChallenges('跑一次马拉松；考上研究生；每天运动');
      // 应该从三个不同目标各取建议
      expect(result.length, greaterThanOrEqualTo(3));
      expect(result.toSet().length, result.length); // 无重复
    });

    test('只有考研 → 不产生运动建议', () {
      final result = getSuggestedChallenges('考上研究生');
      expect(result.any((r) => r.contains('运动')), false);
    });

    test('同时匹配考研和运动 → 两个目标都贡献建议', () {
      final result = getSuggestedChallenges('考上研究生；每天运动');
      expect(result.any((r) => r.contains('备考') || r.contains('模拟')), true);
      expect(result.any((r) => r.contains('运动3次') || r.contains('习惯')), true);
    });
  });
}
