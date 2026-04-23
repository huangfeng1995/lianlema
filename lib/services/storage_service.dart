import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 本地存储服务
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ============== 原有打卡相关存储接口 ==============

  /// 获取连续打卡天数
  Future<int> getStreakDays() async {
    await init();
    return _prefs?.getInt('streak_days') ?? 0;
  }

  /// 保存连续打卡天数
  Future<void> setStreakDays(int days) async {
    await init();
    await _prefs?.setInt('streak_days', days);
  }

  /// 获取本月目标进度百分比
  Future<int> getMonthlyBossProgress() async {
    await init();
    return _prefs?.getInt('monthly_progress') ?? 0;
  }

  /// 保存本月目标进度
  Future<void> setMonthlyBossProgress(int progress) async {
    await init();
    await _prefs?.setInt('monthly_progress', progress);
  }

  /// 今天是否已打卡
  Future<bool> isTodayChecked() async {
    await init();
    final lastCheckDate = _prefs?.getString('last_check_date');
    final today = DateTime.now().toIso8601String().split("T")[0];
    return lastCheckDate == today;
  }

  /// 保存今天打卡状态
  Future<void> setTodayChecked() async {
    await init();
    final today = DateTime.now().toIso8601String().split("T")[0];
    await _prefs?.setString('last_check_date', today);
  }

  // ============== 新增宠物相关存储接口 ==============

  /// 获取宠物对话历史
  Future<List<Map<String, String>>> getPetChatHistory({int limit = 10}) async {
    await init();
    final historyStr = _prefs?.getStringList('pet_chat_history') ?? [];
    final history = historyStr.map((str) {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return Map<String, String>.from(map);
    }).toList();
    // 返回最新的limit条
    if (history.length > limit) {
      return history.sublist(history.length - limit);
    }
    return history;
  }

  /// 保存宠物对话消息
  Future<void> savePetChatMessage(String userInput, String assistantReply) async {
    await init();
    final historyStr = _prefs?.getStringList('pet_chat_history') ?? [];
    final msg = jsonEncode({
      'user': userInput,
      'assistant': assistantReply,
      'time': DateTime.now().toIso8601String(),
    });
    historyStr.add(msg);
    // 最多保留100条历史
    if (historyStr.length > 100) {
      historyStr.removeAt(0);
    }
    await _prefs?.setStringList('pet_chat_history', historyStr);
  }

  /// 获取模型状态
  Future<int?> getModelStatus(int modelTypeIndex) async {
    await init();
    return _prefs?.getInt('model_status_$modelTypeIndex');
  }

  /// 保存模型状态
  Future<void> setModelStatus(int modelTypeIndex, int statusIndex) async {
    await init();
    await _prefs?.setInt('model_status_$modelTypeIndex', statusIndex);
  }

  /// 删除模型状态
  Future<void> deleteModelStatus(int modelTypeIndex) async {
    await init();
    await _prefs?.remove('model_status_$modelTypeIndex');
  }

  /// 获取模型本地路径
  Future<String?> getModelLocalPath(int modelTypeIndex) async {
    await init();
    return _prefs?.getString('model_path_$modelTypeIndex');
  }

  /// 保存模型本地路径
  Future<void> setModelLocalPath(int modelTypeIndex, String path) async {
    await init();
    await _prefs?.setString('model_path_$modelTypeIndex', path);
  }

  /// 获取当前使用的模型类型
  Future<int?> getCurrentModelType() async {
    await init();
    return _prefs?.getInt('current_model_type');
  }

  /// 保存当前使用的模型类型
  Future<void> setCurrentModelType(int typeIndex) async {
    await init();
    await _prefs?.setInt('current_model_type', typeIndex);
  }
}
