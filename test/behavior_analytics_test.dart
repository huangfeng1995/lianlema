import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lianlema/models/behavior_models.dart';
import 'package:lianlema/utils/storage_service.dart';

void main() {
  group('BehaviorReport - Week Key', () {
    test('currentWeekKey returns YYYY-WW format', () {
      final key = BehaviorReport.currentWeekKey();
      expect(key, matches(RegExp(r'^\d{4}-\d{2}$')));
    });

    test('weekKey can be parsed into year and week', () {
      final report = BehaviorReport(
        id: '1',
        weekKey: '2024-15',
        generatedAt: DateTime.now(),
        checkInDays: 5,
        totalDays: 7,
        completionRate: 0.71,
        currentStreak: 5,
        totalCheckIns: 30,
        chatCount: 3,
        encouragementSent: 2,
        encouragementConversionRate: 0.5,
        metrics: [],
        focusAreas: [],
      );
      final (year, week) = report.parseWeekKey();
      expect(year, 2024);
      expect(week, 15);
    });

    test('isThisWeek is true for current week', () {
      final key = BehaviorReport.currentWeekKey();
      final report = BehaviorReport(
        id: '1',
        weekKey: key,
        generatedAt: DateTime.now(),
        checkInDays: 0,
        totalDays: 7,
        completionRate: 0,
        currentStreak: 0,
        totalCheckIns: 0,
        chatCount: 0,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: [],
        focusAreas: [],
      );
      expect(report.isThisWeek, true);
    });

    test('isThisWeek is false for past week', () {
      final report = BehaviorReport(
        id: '1',
        weekKey: '2020-01',
        generatedAt: DateTime.now(),
        checkInDays: 0,
        totalDays: 7,
        completionRate: 0,
        currentStreak: 0,
        totalCheckIns: 0,
        chatCount: 0,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: [],
        focusAreas: [],
      );
      expect(report.isThisWeek, false);
    });
  });

  group('BehaviorReport - JSON roundtrip', () {
    test('toJson/fromJson roundtrip preserves all fields', () {
      final report = BehaviorReport(
        id: 'test-id',
        weekKey: '2024-15',
        generatedAt: DateTime(2024, 4, 10),
        checkInDays: 5,
        totalDays: 7,
        completionRate: 0.71,
        completionRateDelta: 0.14,
        currentStreak: 5,
        totalCheckIns: 30,
        chatCount: 3,
        chatCountDelta: 1,
        encouragementSent: 2,
        encouragementConversionRate: 0.5,
        metrics: const [
          BehaviorMetric(
            type: 'checkin_rate',
            label: '打卡率',
            value: 71.0,
            delta: 14.0,
            description: '本周表现不错',
          ),
        ],
        focusAreas: const ['坚持早起', '减少拖延'],
        highlight: '连续5天打卡',
        improvement: '周末漏打较多',
      );

      final json = report.toJson();
      final restored = BehaviorReport.fromJson(json);

      expect(restored.id, report.id);
      expect(restored.weekKey, report.weekKey);
      expect(restored.checkInDays, report.checkInDays);
      expect(restored.totalDays, report.totalDays);
      expect(restored.completionRate, report.completionRate);
      expect(restored.completionRateDelta, report.completionRateDelta);
      expect(restored.currentStreak, report.currentStreak);
      expect(restored.totalCheckIns, report.totalCheckIns);
      expect(restored.chatCount, report.chatCount);
      expect(restored.chatCountDelta, report.chatCountDelta);
      expect(restored.encouragementSent, report.encouragementSent);
      expect(restored.encouragementConversionRate, report.encouragementConversionRate);
      expect(restored.metrics.length, 1);
      expect(restored.metrics[0].type, 'checkin_rate');
      expect(restored.focusAreas, ['坚持早起', '减少拖延']);
      expect(restored.highlight, '连续5天打卡');
      expect(restored.improvement, '周末漏打较多');
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = {
        'id': 'minimal',
        'weekKey': '2024-10',
        'generatedAt': '2024-03-10T00:00:00.000',
        'checkInDays': 3,
        'totalDays': 7,
        'completionRate': 0.42,
        'currentStreak': 0,
        'totalCheckIns': 5,
        'chatCount': 0,
        'encouragementSent': 0,
        'encouragementConversionRate': 0.0,
        'metrics': [],
        'focusAreas': [],
      };

      final report = BehaviorReport.fromJson(json);
      expect(report.id, 'minimal');
      expect(report.completionRateDelta, null);
      expect(report.chatCountDelta, null);
      expect(report.highlight, null);
    });
  });

  group('BehaviorMetric', () {
    test('fromJson handles numeric delta correctly', () {
      final json = {
        'type': 'test',
        'label': '测试',
        'value': 80,
        'delta': 5, // int instead of double
        'description': null,
      };
      final metric = BehaviorMetric.fromJson(json);
      expect(metric.value, 80.0);
      expect(metric.delta, 5.0);
    });
  });

  group('BehaviorReport - completion rate helpers', () {
    test('completionRatePercent returns clamped 0-100', () {
      final report = BehaviorReport(
        id: '1',
        weekKey: '2024-01',
        generatedAt: DateTime.now(),
        checkInDays: 7,
        totalDays: 7,
        completionRate: 1.5, // 超过1.0
        currentStreak: 7,
        totalCheckIns: 100,
        chatCount: 0,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: [],
        focusAreas: [],
      );
      expect(report.completionRatePercent, 100); // clamped
    });

    test('conversionRatePercent returns correct percentage', () {
      final report = BehaviorReport(
        id: '1',
        weekKey: '2024-01',
        generatedAt: DateTime.now(),
        checkInDays: 0,
        totalDays: 7,
        completionRate: 0,
        currentStreak: 0,
        totalCheckIns: 0,
        chatCount: 0,
        encouragementSent: 2,
        encouragementConversionRate: 0.5,
        metrics: [],
        focusAreas: [],
      );
      expect(report.conversionRatePercent, 50);
    });
  });

  group('BehaviorReport - toShortSummary', () {
    test('generates correct summary without delta', () {
      final report = BehaviorReport(
        id: '1',
        weekKey: '2024-15',
        generatedAt: DateTime.now(),
        checkInDays: 5,
        totalDays: 7,
        completionRate: 0.71,
        currentStreak: 5,
        totalCheckIns: 30,
        chatCount: 3,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: [],
        focusAreas: [],
      );
      final summary = report.toShortSummary();
      expect(summary, contains('2024-15'));
      expect(summary, contains('5/7'));
      expect(summary, contains('71'));
      expect(summary, contains('3次'));
      expect(summary, contains('连续5天'));
    });

    test('generates correct summary with positive delta', () {
      final report = BehaviorReport(
        id: '1',
        weekKey: '2024-15',
        generatedAt: DateTime.now(),
        checkInDays: 5,
        totalDays: 7,
        completionRate: 0.71,
        completionRateDelta: 14.0, // percentage points: +14%
        currentStreak: 5,
        totalCheckIns: 30,
        chatCount: 3,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: [],
        focusAreas: [],
      );
      final summary = report.toShortSummary();
      expect(summary, contains('+14%'));
    });

    test('generates correct summary with negative delta', () {
      final report = BehaviorReport(
        id: '1',
        weekKey: '2024-15',
        generatedAt: DateTime.now(),
        checkInDays: 3,
        totalDays: 7,
        completionRate: 0.42,
        completionRateDelta: -14.0, // percentage points: -14%
        currentStreak: 0,
        totalCheckIns: 30,
        chatCount: 1,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: [],
        focusAreas: [],
      );
      final summary = report.toShortSummary();
      expect(summary, contains('-14%'));
    });
  });

  group('StorageService - Behavior Analytics', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      StorageService.resetInstance();
      storage = await StorageService.getInstance();
    });

    test('getCurrentWeekKey returns correct format', () {
      final key = storage.getCurrentWeekKey();
      expect(key, matches(RegExp(r'^\d{4}-\d{2}$')));
    });

    test('shouldGenerateBehaviorReport is true on first call', () {
      // No last analytics week set
      expect(storage.shouldGenerateBehaviorReport(), true);
    });

    test('shouldGenerateBehaviorReport is false after saving report this week', () async {
      final currentWeek = storage.getCurrentWeekKey();
      final report = BehaviorReport(
        id: '1',
        weekKey: currentWeek,
        generatedAt: DateTime.now(),
        checkInDays: 1,
        totalDays: 7,
        completionRate: 0.14,
        currentStreak: 1,
        totalCheckIns: 1,
        chatCount: 0,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: const [],
        focusAreas: const [],
      );
      await storage.saveBehaviorReport(report);
      expect(storage.shouldGenerateBehaviorReport(), false);
    });

    test('saveBehaviorReport replaces same-week report', () async {
      final currentWeek = storage.getCurrentWeekKey();
      final report1 = BehaviorReport(
        id: '1',
        weekKey: currentWeek,
        generatedAt: DateTime(2024, 4, 10),
        checkInDays: 1,
        totalDays: 7,
        completionRate: 0.14,
        currentStreak: 1,
        totalCheckIns: 1,
        chatCount: 0,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: const [],
        focusAreas: const [],
      );
      await storage.saveBehaviorReport(report1);

      final report2 = BehaviorReport(
        id: '2',
        weekKey: currentWeek,
        generatedAt: DateTime(2024, 4, 12),
        checkInDays: 5,
        totalDays: 7,
        completionRate: 0.71,
        currentStreak: 5,
        totalCheckIns: 5,
        chatCount: 0,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: const [],
        focusAreas: const [],
      );
      await storage.saveBehaviorReport(report2);

      final reports = storage.getBehaviorReports();
      expect(reports.length, 1);
      expect(reports[0].checkInDays, 5);
      expect(reports[0].id, '2'); // updated
    });

    test('getBehaviorReportForWeek returns correct report', () async {
      final report = BehaviorReport(
        id: 'test-week-15',
        weekKey: '2024-15',
        generatedAt: DateTime(2024, 4, 10),
        checkInDays: 5,
        totalDays: 7,
        completionRate: 0.71,
        currentStreak: 5,
        totalCheckIns: 30,
        chatCount: 3,
        encouragementSent: 2,
        encouragementConversionRate: 0.5,
        metrics: const [],
        focusAreas: const ['早起'],
      );
      await storage.saveBehaviorReport(report);

      final found = storage.getBehaviorReportForWeek('2024-15');
      expect(found, isNotNull);
      expect(found!.checkInDays, 5);
      expect(found.focusAreas, ['早起']);
    });

    test('getBehaviorReportForWeek returns null for non-existent week', () {
      final found = storage.getBehaviorReportForWeek('2024-99');
      expect(found, isNull);
    });

    test('getThisWeekReport returns null when no report exists', () {
      expect(storage.getThisWeekReport(), isNull);
    });

    test('getLastWeekReport returns null with only one report', () async {
      final report = BehaviorReport(
        id: '1',
        weekKey: '2024-15',
        generatedAt: DateTime.now(),
        checkInDays: 5,
        totalDays: 7,
        completionRate: 0.71,
        currentStreak: 5,
        totalCheckIns: 30,
        chatCount: 3,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: const [],
        focusAreas: const [],
      );
      await storage.saveBehaviorReport(report);
      expect(storage.getLastWeekReport(), isNull);
    });

    test('saves multiple weeks and getLastWeekReport returns previous', () async {
      final report1 = BehaviorReport(
        id: 'r1',
        weekKey: '2024-14',
        generatedAt: DateTime(2024, 4, 3),
        checkInDays: 3,
        totalDays: 7,
        completionRate: 0.42,
        currentStreak: 3,
        totalCheckIns: 28,
        chatCount: 1,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: const [],
        focusAreas: const [],
      );
      await storage.saveBehaviorReport(report1);

      final report2 = BehaviorReport(
        id: 'r2',
        weekKey: '2024-15',
        generatedAt: DateTime(2024, 4, 10),
        checkInDays: 5,
        totalDays: 7,
        completionRate: 0.71,
        currentStreak: 5,
        totalCheckIns: 30,
        chatCount: 3,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: const [],
        focusAreas: const [],
      );
      await storage.saveBehaviorReport(report2);

      final lastWeek = storage.getLastWeekReport();
      expect(lastWeek, isNotNull);
      expect(lastWeek!.weekKey, '2024-14');
      expect(lastWeek.checkInDays, 3);
    });

    test('keeps at most 12 weekly reports', () async {
      // Save 15 reports across different weeks
      for (int i = 1; i <= 15; i++) {
        final report = BehaviorReport(
          id: 'r$i',
          weekKey: '2024-${i.toString().padLeft(2, '0')}',
          generatedAt: DateTime.now(),
          checkInDays: i,
          totalDays: 7,
          completionRate: 0.5,
          currentStreak: i,
          totalCheckIns: i * 2,
          chatCount: i,
          encouragementSent: 0,
          encouragementConversionRate: 0,
          metrics: const [],
          focusAreas: const [],
        );
        await storage.saveBehaviorReport(report);
      }

      final reports = storage.getBehaviorReports();
      expect(reports.length, 12);
      // Should keep the most recent weeks (highest week numbers)
      final weekKeys = reports.map((r) => r.weekKey).toList();
      expect(weekKeys.contains('2024-04'), true);
      expect(weekKeys.contains('2024-01'), false); // oldest should be dropped
    });

    test('getLastAnalyticsWeek returns correct value after save', () async {
      expect(storage.getLastAnalyticsWeek(), null);

      final currentWeek = storage.getCurrentWeekKey();
      final report = BehaviorReport(
        id: '1',
        weekKey: currentWeek,
        generatedAt: DateTime.now(),
        checkInDays: 5,
        totalDays: 7,
        completionRate: 0.71,
        currentStreak: 5,
        totalCheckIns: 30,
        chatCount: 3,
        encouragementSent: 0,
        encouragementConversionRate: 0,
        metrics: const [],
        focusAreas: const [],
      );
      await storage.saveBehaviorReport(report);

      expect(storage.getLastAnalyticsWeek(), currentWeek);
    });
  });
}
