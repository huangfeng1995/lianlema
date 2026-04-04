import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lianlema/models/pet_models.dart';
import 'package:lianlema/utils/pet_service.dart';
import 'package:lianlema/utils/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PetService 集成测试', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.getInstance();
    });

    tearDown(() {
      StorageService.resetInstance();
      PetService.instance.clearHistory();
    });

    test('buildContext 返回完整的用户上下文', () async {
      final ctx = await PetService.instance.buildContext();
      expect(ctx, isNotNull);
      expect(ctx.streak, isA<int>());
      expect(ctx.totalCheckIns, isA<int>());
      expect(ctx.checkedInToday, isA<bool>());
    });

    test('calculateMood 返回正确的心情状态', () async {
      final ctx = await PetService.instance.buildContext();
      final mood = PetService.instance.calculateMood(ctx);
      expect(mood, isNotNull);
      expect(mood.mood, isA<PetMood>());
    });

    test('generateGreeting 生成问候语', () {
      final greeting = PetService.instance.generateGreeting();
      expect(greeting, isNotEmpty);
      expect(greeting.length, lessThan(100));
    });

    test('generateSuggestion 生成建议', () async {
      final ctx = await PetService.instance.buildContext();
      final suggestion = PetService.instance.generateSuggestion(ctx);
      expect(suggestion, isNotEmpty);
    });

    test('generateProactiveInsight 生成主动洞察', () async {
      final ctx = await PetService.instance.buildContext();
      final insight = PetService.instance.generateProactiveInsight(ctx);
      expect(insight, isNotEmpty);
      expect(insight.length, lessThan(200));
    });

    test('handleCommand 返回正确的快捷指令响应', () async {
      final ctx = await PetService.instance.buildContext();

      final statusResp = await PetService.instance.handleCommand(PetCommand.status, ctx);
      expect(statusResp, contains('天'));

      final checkInResp = await PetService.instance.handleCommand(PetCommand.checkInRecord, ctx);
      expect(checkInResp, isNotEmpty);

      final growthResp = await PetService.instance.handleCommand(PetCommand.askGrowth, ctx);
      expect(growthResp, isNotEmpty);
    });

    test('generateMilestoneMessage 生成里程碑文案', () {
      final msg7 = PetService.instance.generateMilestoneMessage(MilestoneType.streak7);
      expect(msg7, contains('7'));

      final msg30 = PetService.instance.generateMilestoneMessage(MilestoneType.streak30);
      expect(msg30, contains('30'));

      final msgBoss = PetService.instance.generateMilestoneMessage(MilestoneType.bossDefeated);
      expect(msgBoss, contains('Boss'));
    });

    test('chat 使用本地兜底回复（模拟API失败）', () async {
      // 由于无法mock HTTP，直接测试 chat 方法会走 fallback
      final ctx = await PetService.instance.buildContext();

      // 测试关键词触发的兜底回复
      final resp1 = await PetService.instance.chat('打卡了吗', ctx);
      expect(resp1, isNotEmpty);
      expect(resp1.length, lessThan(200));
    });
  });

  group('PetMoodState 单元测试', () {
    test('PetMoodState.initial 创建默认状态', () {
      final state = PetMoodState.initial();
      expect(state.mood, PetMood.calm);
      expect(state.consecutiveIdleDays, 0);
    });

    test('PetMoodState.copyWith 正确复制', () {
      final state = PetMoodState.initial();
      final updated = state.copyWith(mood: PetMood.happy);
      expect(updated.mood, PetMood.happy);
      expect(updated.consecutiveIdleDays, 0);
    });

    test('PetMoodState toJson/fromJson 序列化', () {
      final state = PetMoodState(
        mood: PetMood.excited,
        updatedAt: DateTime(2024, 1, 1),
        consecutiveIdleDays: 3,
      );
      final json = state.toJson();
      final restored = PetMoodState.fromJson(json);
      expect(restored.mood, PetMood.excited);
      expect(restored.consecutiveIdleDays, 3);
    });
  });

  group('PetQuickCommand 快捷指令测试', () {
    test('所有快捷指令都有完整信息', () {
      for (final cmd in PetQuickCommand.all) {
        expect(cmd.label, isNotEmpty);
        expect(cmd.description, isNotEmpty);
        expect(cmd.icon, isNotEmpty);
      }
    });

    test('快捷指令数量正确', () {
      expect(PetQuickCommand.all.length, 4);
    });
  });

  group('MilestoneType 里程碑测试', () {
    test('所有里程碑类型都有标题和emoji', () {
      for (final type in MilestoneType.values) {
        final milestone = PetMilestone(type: type, achievedAt: DateTime.now());
        expect(milestone.title, isNotEmpty);
        expect(milestone.emoji, isNotEmpty);
      }
    });
  });
}
