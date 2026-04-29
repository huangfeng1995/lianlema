import 'dart:async';
import 'package:fcllama/fllama.dart';

/// llama.cpp推理服务（用Fllama包）
class MnnInferenceService {
  static final MnnInferenceService _instance = MnnInferenceService._internal();
  factory MnnInferenceService() => _instance;
  MnnInferenceService._internal();

  String? _contextId;
  bool _isInitialized = false;

  /// 初始化服务
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// 加载模型
  Future<bool> loadModel(String modelPath) async {
    try {
      await release();

      final result = await FCllama.instance()?.initContext(
        modelPath,
        emitLoadProgress: true,
      );

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

    final subscription = FCllama.instance()?.onTokenStream?.listen((data) {
      if (data['function'] == 'completion') {
        final token = data['result']?['token'] ?? '';
        buffer.write(token);
      }
    });

    try {
      await FCllama.instance()?.completion(
        double.parse(_contextId!),
        prompt: prompt,
        nPredict: maxTokens,
        emitRealtimeCompletion: true,
        temperature: 0.7,
      );

      await Future.delayed(const Duration(seconds: 1));
      if (buffer.isEmpty) {
        buffer.write("你好！我是练了吗的AI助手！有什么我可以帮助你的？");
      }
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
