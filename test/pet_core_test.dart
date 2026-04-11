import 'package:flutter_test/flutter_test.dart';
import 'package:lianlema/models/pet_models.dart';
import 'package:lianlema/utils/pet_service.dart';

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
    test('milestone memories are permanent', () {
      final memory = PetMemory(
        id: '1',
        createdAt: DateTime.now(),
        type: 'milestone',
        wing: MemoryWing.milestone,
        content: '第一次完成挑战',
        petResponse: '',
      );
      expect(memory.isPermanent, true);
      expect(memory.isExpired, false);
    });

    test('low importance memories expire after 30 days', () {
      final memory = PetMemory(
        id: '2',
        createdAt: DateTime.now(),
        type: 'event',
        importance: MemoryImportance.low,
        content: '今天打卡了',
        petResponse: '',
      );
      expect(memory.isPermanent, false);
      expect(memory.isExpired, false); // just created, not yet expired
    });

    test('identity wing is permanent', () {
      final memory = PetMemory(
        id: '3',
        createdAt: DateTime.now(),
        type: 'identity',
        wing: MemoryWing.identity,
        content: '我想成为能跑马拉松的人',
        petResponse: '',
      );
      expect(memory.isPermanent, true);
    });

    test('lesson wing is permanent', () {
      final memory = PetMemory(
        id: '4',
        createdAt: DateTime.now(),
        type: 'lesson',
        wing: MemoryWing.lesson,
        content: '之前放弃是因为目标太大',
        petResponse: '',
      );
      expect(memory.isPermanent, true);
    });
  });

  group('MemoryWing', () {
    test('wing enum has correct values', () {
      expect(MemoryWing.identity.index, 0);
      expect(MemoryWing.aspiration.index, 1);
      expect(MemoryWing.preference.index, 2);
      expect(MemoryWing.milestone.index, 3);
      expect(MemoryWing.lesson.index, 4);
    });
  });

  group('PetPreferences', () {
    test('default preferences are correct', () {
      final prefs = PetPreferences.defaultPrefs();
      expect(prefs.tone, 'casual');
      expect(prefs.responseLength, 'short');
      expect(prefs.useEmoji, true);
    });

    test('copyWith works correctly', () {
      final prefs = PetPreferences.defaultPrefs();
      final updated = prefs.copyWith(tone: 'playful', useEmoji: false);
      expect(updated.tone, 'playful');
      expect(updated.useEmoji, false);
      expect(updated.responseLength, 'short'); // unchanged
    });
  });

  group('PetMoodState', () {
    test('initial state is calm', () {
      final state = PetMoodState.initial();
      expect(state.mood, PetMood.calm);
    });

    test('toJson/fromJson roundtrip', () {
      final state = PetMoodState(mood: PetMood.happy, updatedAt: DateTime.now());
      final json = state.toJson();
      final restored = PetMoodState.fromJson(json);
      expect(restored.mood, PetMood.happy);
    });
  });

  group('PetContext', () {
    test('empty context has zero values', () {
      final ctx = PetContext();
      expect(ctx.streak, 0);
      expect(ctx.checkedInToday, false);
      expect(ctx.monthlyBoss, '');
      expect(ctx.dailyLevers, isEmpty);
    });
  });
}
