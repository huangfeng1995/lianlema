import 'package:get/get.dart';
import '../models/pet_models.dart';
import '../services/pet_push_service.dart';
import '../utils/pet_service.dart';
import '../utils/storage_service.dart';

/// 全局推送横幅控制器
/// 管理 PetPushBanner 的显示状态，让所有页面都能触发推送显示
class PushBannerController extends GetxController {
  static PushBannerController get to => Get.find();

  // ===== 响应式状态 =====
  final _currentPush = Rxn<PetPush>();
  final _shouldShowPush = false.obs;
  final _forceShowPush = false.obs;
  final _isInitialized = false.obs;

  // ===== Getters =====
  PetPush? get currentPush => _currentPush.value;
  bool get shouldShowPush => _shouldShowPush.value;
  bool get forceShowPush => _forceShowPush.value;
  bool get isVisible => _currentPush.value != null && (_shouldShowPush.value || _forceShowPush.value);
  bool get isInitialized => _isInitialized.value;

  @override
  void onInit() {
    super.onInit();
    _initializePush();
  }

  Future<void> _initializePush() async {
    try {
      final storage = await StorageService.getInstance();

      // 检查是否应该显示推送
      if (!storage.shouldShowPush()) {
        _isInitialized.value = true;
        return;
      }

      // 加载宠物上下文
      await PetService.instance.loadState();
      final ctx = await PetService.instance.buildContext();

      // 生成推送
      final pushes = await PetPushService.instance.generateDailyPushes(ctx);
      if (pushes.isNotEmpty) {
        _currentPush.value = pushes.first;
        _shouldShowPush.value = true;
      }
    } catch (_) {
      // 静默失败
    } finally {
      _isInitialized.value = true;
    }
  }

  /// 显示推送
  void showPush(PetPush push) {
    _currentPush.value = push;
    _shouldShowPush.value = true;
    _forceShowPush.value = true;
  }

  /// 隐藏推送
  void hidePush() {
    _shouldShowPush.value = false;
    _forceShowPush.value = false;
    // 延迟清除推送对象，让动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_shouldShowPush.value && !_forceShowPush.value) {
        _currentPush.value = null;
      }
    });
  }

  /// 强制生成并显示推送（用于测试）
  Future<void> forceShowTestPush() async {
    try {
      final ctx = await PetService.instance.buildContext();
      final pushes = await PetPushService.instance.generateDailyPushes(ctx);
      if (pushes.isNotEmpty) {
        showPush(pushes.first);
      }
    } catch (_) {}
  }
}
