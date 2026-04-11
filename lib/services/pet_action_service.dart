import '../utils/storage_service.dart';
import '../models/models.dart';
import '../models/pet_models.dart';

/// 宠物可执行的动作类型
enum PetActionType {
  /// 记录打卡
  recordCheckIn,
  /// 创建每日杠杆
  createDailyLever,
  /// 修改每日杠杆
  updateDailyLever,
  /// 保存里程碑记忆
  saveMilestone,
  /// 保存教训记忆
  saveLesson,
  /// 更新挑战内容
  updateBossContent,
}

/// 宠物动作服务 — 把「说」变成「做」
class PetActionService {
  /// 根据用户消息判断是否需要执行动作
  /// 返回 null 表示不需要动作，返回结果表示执行了动作
  Future<PetActionResult?> handleUserRequest(
    String message,
    Map<String, dynamic> ctx,
  ) async {
    final m = message.toLowerCase();
    final storage = await StorageService.getInstance();

    // 记录打卡
    if (_match(m, ['记录打卡', '帮我打卡', '打卡', '补打卡', '今天完成了'])) {
      return await _recordCheckIn(storage, ctx);
    }

    // 创建每日杠杆
    if (_match(m, ['创建每日杠杆', '帮我创建', '添加每日', '新增杠杆', '帮我加一个'])) {
      return await _createDailyLever(storage, message, ctx);
    }

    // 修改每日杠杆
    if (_match(m, ['修改杠杆', '改一下', '更新杠杆', '调整杠杆'])) {
      return await _updateDailyLever(storage, message, ctx);
    }

    // 保存里程碑
    if (_match(m, ['完成了', '做到了', '终于', '突破', '达成了'])) {
      return await _saveMilestone(storage, message, ctx);
    }

    // 保存教训
    if (_match(m, ['失败了', '放弃了', '没做到', '搞砸了', '没坚持'])) {
      return await _saveLesson(storage, message, ctx);
    }

    return null;
  }

  /// 判断今日是否需要提醒打卡（快结束了还没打卡）
  bool shouldRemindCheckIn(Map<String, dynamic> ctx) {
    if (ctx['checkedInToday'] == true) return false;
    return true; // 只要今天没打卡就提醒
  }

  /// 判断是否很久没做任务
  bool shouldRemindLongIdle(Map<String, dynamic> ctx) {
    // 超过3天没打卡
    final streak = (ctx['streak'] as int?) ?? 0;
    final totalCheckIns = (ctx['totalCheckIns'] as int?) ?? 0;
    final checkedInToday = ctx['checkedInToday'] == true;
    return streak > 0 && totalCheckIns > 3 && !checkedInToday;
  }

  /// 判断是否快到里程碑
  bool shouldRemindMilestone(Map<String, dynamic> ctx) {
    const milestones = [7, 30, 100];
    final streak = (ctx['streak'] as int?) ?? 0;
    for (final m in milestones) {
      if (streak != m && (streak - m).abs() <= 2) return true;
    }
    return false;
  }

  // ===== 具体动作实现 =====

  Future<PetActionResult> _recordCheckIn(
    StorageService storage,
    Map<String, dynamic> ctx,
  ) async {
    try {
      final checkIns = storage.getCheckIns();
      final streak = (ctx['streak'] as int?) ?? 0;
      checkIns.add(CheckIn(
        date: DateTime.now(),
        leverIds: const [],
      ));
      await storage.saveCheckIns(checkIns);
      // 打卡奖励宠物币
      await storage.addPetCoins(5, PetCoinReason.dailyCheckIn);
      return PetActionResult(
        success: true,
        message: '好的，今天打卡记录好了！✨ 你已经坚持了 ${streak + 1} 天！获得 +5🪙',
        summary: '已记录今日打卡',
      );
    } catch (e) {
      return PetActionResult(
        success: false,
        message: '记录失败了，${e.toString()}',
      );
    }
  }

  Future<PetActionResult> _createDailyLever(
    StorageService storage,
    String message,
    Map<String, dynamic> ctx,
  ) async {
    try {
      // 从消息中提取杠杆内容（去掉上面的关键词）
      final content = message
          .replaceAll(RegExp('创建每日杠杆|帮我创建|添加每日|新增杠杆|帮我加一个'), '')
          .trim();

      if (content.isEmpty) {
        return PetActionResult(
          success: false,
          message: '你想创建什么每日杠杆？告诉我具体内容～',
        );
      }

      final levers = storage.getDailyLevers();
      levers.add({'plan': content, 'obstacle': ''});
      await storage.saveDailyLevers(levers);

      return PetActionResult(
        success: true,
        message: '好，每日杠杆已添加：$content',
        summary: '已添加：$content',
      );
    } catch (e) {
      return PetActionResult(
        success: false,
        message: '添加失败了，${e.toString()}',
      );
    }
  }

  Future<PetActionResult> _updateDailyLever(
    StorageService storage,
    String message,
    Map<String, dynamic> ctx,
  ) async {
    return PetActionResult(
      success: false,
      message: '想调整哪个每日杠杆？告诉我是哪个，我来帮你改～',
    );
  }

  Future<PetActionResult> _saveMilestone(
    StorageService storage,
    String message,
    Map<String, dynamic> ctx,
  ) async {
    try {
      final memory = PetMemory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        type: 'milestone',
        content: message,
        petResponse: '',
      );
      await storage.addPetMemory(memory);

      return PetActionResult(
        success: true,
        message: '太棒了！这个我记住了 💎 炭炭为你骄傲！',
        summary: '已记录里程碑',
      );
    } catch (e) {
      return PetActionResult(
        success: false,
        message: '记录失败了，${e.toString()}',
      );
    }
  }

  Future<PetActionResult> _saveLesson(
    StorageService storage,
    String message,
    Map<String, dynamic> ctx,
  ) async {
    try {
      final memory = PetMemory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        type: 'lesson',
        content: message,
        petResponse: '',
      );
      await storage.addPetMemory(memory);

      return PetActionResult(
        success: true,
        message: '收到了，我们一起记下来。失败也是进步的一部分 🤝',
        summary: '已记录教训',
      );
    } catch (e) {
      return PetActionResult(
        success: false,
        message: '记录失败了，${e.toString()}',
      );
    }
  }

  bool _match(String m, List<String> keywords) {
    return keywords.any((k) => m.contains(k.toLowerCase()));
  }
}

/// 宠物执行动作的结果
class PetActionResult {
  final bool success;
  final String message;
  final String? summary; // 用于显示给用户

  PetActionResult({required this.success, required this.message, this.summary});
}
