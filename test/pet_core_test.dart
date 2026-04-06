import 'package:flutter_test/flutter_test.dart';
import 'package:lianlema/models/pet_models.dart';

void main() {
  group('PetSoul', () {
    test('defaultSoul has correct name', () {
      final soul = PetSoul.defaultSoul();
      expect(soul.name, '炭炭');
      expect(soul.tone, 'casual');
      expect(soul.useEmoji, true);
    });

    test('toJson/fromJson roundtrip', () {
      final soul = PetSoul.defaultSoul();
      final json = soul.toJson();
      final restored = PetSoul.fromJson(json);
      expect(restored.name, soul.name);
      expect(restored.personality, soul.personality);
    });
  });

  group('PetMemory', () {
    test('permanent memories have no expiry', () {
      final memory = PetMemory.permanent(
        id: '1',
        type: PetMemoryType.milestone,
        content: '第一次完成挑战',
      );
      expect(memory.isPermanent, true);
      expect(memory.isExpired, false);
    });

    test('event memories expire after 30 days', () {
      final memory = PetMemory.event(
        id: '2',
        content: '今天打卡了',
      );
      expect(memory.isPermanent, false);
      expect(memory.expiresAt, isNotNull);
      expect(memory.expiresAt!.difference(DateTime.now()).inDays, 30);
    });

    test('identity is permanent', () {
      final memory = PetMemory.permanent(
        id: '3',
        type: PetMemoryType.identity,
        content: '我想成为能跑马拉松的人',
      );
      expect(memory.isPermanent, true);
    });

    test('lesson is permanent', () {
      final memory = PetMemory.permanent(
        id: '4',
        type: PetMemoryType.lesson,
        content: '之前放弃是因为目标太大',
      );
      expect(memory.isPermanent, true);
    });
  });

  group('PetMemoryType', () {
    test('permanent types are correctly identified', () {
      expect(PetMemoryType.identity.index, 0);
      expect(PetMemoryType.milestone.index, 1);
      expect(PetMemoryType.lesson.index, 2);
      expect(PetMemoryType.preference.index, 3);
      expect(PetMemoryType.event.index, 4);
    });
  });

  group('PetPreferences', () {
    test('default preferences are correct', () {
      final prefs = PetPreferences.defaultPrefs();
      expect(prefs.tone, 'casual');
      expect(prefs.responseLength, 'medium');
      expect(prefs.useEmoji, true);
    });

    test('copyWith works correctly', () {
      final prefs = PetPreferences.defaultPrefs();
      final updated = prefs.copyWith(tone: 'playful', useEmoji: false);
      expect(updated.tone, 'playful');
      expect(updated.useEmoji, false);
      expect(updated.responseLength, 'medium'); // unchanged
    });
  });

  group('PetMoodState', () {
    test('initial state is calm', () {
      final state = PetMoodState.initial();
      expect(state.mood, PetMood.calm);
    });

    test('toJson/fromJson roundtrip', () {
      final state = PetMoodState(mood: PetMood.happy, lastUpdated: DateTime.now());
      final json = state.toJson();
      final restored = PetMoodState.fromJson(json);
      expect(restored.mood, PetMood.happy);
    });
  });

  group('PetContext', () {
    test('empty context has zero values', () {
      final ctx = PetContext.empty();
      expect(ctx.streak, 0);
      expect(ctx.checkedInToday, false);
      expect(ctx.monthlyBoss, '');
      expect(ctx.dailyLevers, isEmpty);
    });
  });
}
