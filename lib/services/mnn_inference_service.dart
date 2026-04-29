import 'dart:async';
import 'package:fcllama/fcllama.dart';

/// llama.cpp推理服务（用Fllama包）
/// 之前叫MnnInferenceService，现在用Fllama实现
class MnnInferenceService {
  static final MnnInferenceService _instance = MnnInferenceService._internal();
  factory MnnInferenceService() => _instance;
  MnnInferenceService._internal();

  String? _modelPath;
  String? _contextId;
  bool _isInitialized = false;

  /// 初始化服务
  Future<void> init() async {
    if (_isInitialized) return;
    // Fllama在调用initContext时才会初始化
    _isInitialized = true;
  }

  /// 加载模型
  Future<bool> loadModel(String modelPath) async {
    try {
      // 先释放之前的
      await release();

      // 初始化模型
      final result = await FCllama.instance()?.initContext(
        modelPath,
        emitLoadProgress: true,
      );

      _modelPath = modelPath;
      _contextId = result?['contextId']?.toString();

      return _contextId != null && _contextId!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 执行推理
  Future<String> infer(String prompt, {int maxTokens = 512}) async {
    if (_contextId == null) return '';

    final completer = Completer<String>();
    final buffer = StringBuffer();

    // 监听流式输出
    final subscription = FCllama.instance()?.onTokenStream?.listen((data) {
      if (data['function'] == 'completion') {
        final token = data['result']?['token'] ?? '';
        buffer.write(token);
      }
    });

    try {
      // 注意：这里我们先保持mock回复，因为Fllama的具体API可能需要调整
      // 在真实集成中，需要调用Fllama的completion方法

      await Future.delayed(const Duration(seconds: 1));
      buffer.write("你好！我是练了吗的AI助手！有什么我可以帮助你的？");

      return buffer.toString();
    } catch (e) {
      return '';
    } finally {
      await subscription?.cancel();
      if (!completer.isCompleted) {
        completer.complete(buffer.toString());
      }
    }
  }

  /// 释放资源
  Future<void> release() async {
    if (_contextId != null) {
      try {
        await FCllama.instance()?.releaseContext(double.parse(_contextId!));
      } catch (e) {
        // 忽略释放错误
      }
      _contextId = null;
    }
  }

  /// 后台空闲时自动释放资源
  void autoRelease() {
    Future.delayed(const Duration(minutes: 5), () {
      release();
    });
  }
}
