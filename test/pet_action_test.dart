import 'package:flutter_test/flutter_test.dart';
import 'package:lianlema/services/pet_action_service.dart';
import 'package:lianlema/models/pet_models.dart';

void main() {
  group('PetActionService - 主动触发判断（无需storage）', () {
    late PetActionService svc;

    setUp(() {
      svc = PetActionService();
    });

    test('streak=5 → 快到7天里程碑', () {
      final ctx = _makeCtx(streak: 5);
      expect(svc.shouldRemindMilestone(ctx), true);
    });

    test('streak=8 → 刚过7天里程碑', () {
      final ctx = _makeCtx(streak: 8);
      expect(svc.shouldRemindMilestone(ctx), true); // within ±2
    });

    test('streak=28 → 快到30天里程碑', () {
      final ctx = _makeCtx(streak: 28);
      expect(svc.shouldRemindMilestone(ctx), true);
    });

    test('streak=50 → 不是关键里程碑', () {
      final ctx = _makeCtx(streak: 50);
      expect(svc.shouldRemindMilestone(ctx), false);
    });

    test('已打卡 → 不提醒懈怠', () {
      final ctx = _makeCtx(streak: 5, checkedInToday: true);
      expect(svc.shouldRemindLongIdle(ctx), false);
    });

    test('未打卡 + streak>0 + totalCheckIns>3 → 提醒懈怠', () {
      final ctx = _makeCtx(streak: 5, checkedInToday: false, totalCheckIns: 10);
      expect(svc.shouldRemindLongIdle(ctx), true);
    });

    test('未打卡 + streak=0 → 新用户不触发懈怠', () {
      final ctx = _makeCtx(streak: 0, checkedInToday: false, totalCheckIns: 0);
      expect(svc.shouldRemindLongIdle(ctx), false);
    });

    test('未打卡 → 提醒打卡', () {
      final ctx = _makeCtx(streak: 3, checkedInToday: false);
      expect(svc.shouldRemindCheckIn(ctx), true);
    });

    test('已打卡 → 不提醒打卡', () {
      final ctx = _makeCtx(streak: 3, checkedInToday: true);
      expect(svc.shouldRemindCheckIn(ctx), false);
    });
  });
}

PetContext _makeCtx({
  int streak = 0,
  int totalCheckIns = 0,
  bool checkedInToday = false,
}) => PetContext(
  streak: streak,
  totalCheckIns: totalCheckIns,
  checkedInToday: checkedInToday,
  antiVision: '',
  vision: '',
  yearGoal: '',
  monthlyBoss: '',
  dailyLevers: [],
  constraints: [],
  currentBossHp: 0,
  currentBossTotal: 0,
);
