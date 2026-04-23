import 'dart:isolate';
import 'package:flutter_mnn/flutter_mnn.dart';
import 'model_download_service.dart';

/// MNN推理引擎服务
class MnnInferenceService {
  static final MnnInferenceService _instance = MnnInferenceService._internal();
  factory MnnInferenceService() => _instance;
  MnnInferenceService._internal();

  final ModelDownloadService _modelService = ModelDownloadService();
  MNN? _mnnEngine;
  Isolate? _inferIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  bool _isInitialized = false;
  bool _isModelLoaded = false;

  /// MNN实例
  MNN? get engine => _mnnEngine;

  /// 初始化引擎
  Future<void> init() async {
    if (_isInitialized) return;
    // 初始化MNN
    await MNN.init();
    // 初始化后台Isolate
    await _initIsolate();

    _isInitialized = true;
    // 加载默认模型
    final defaultModel = _modelService.getDefaultModel();
    await loadModel(defaultModel.localPath!);
  }

  /// 后台Isolate初始化
  Future<void> _initIsolate() async {
    _receivePort = ReceivePort();
    _inferIsolate = await Isolate.spawn(_inferIsolateEntry, _receivePort!.sendPort);
    _sendPort = await _receivePort!.first;
  }

  /// Isolate入口函数（静态）
  static void _inferIsolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    MNN? isolateEngine;

    receivePort.listen((message) async {
      if (message is Map) {
        final type = message['type'] as String;
        if (type == 'load_model') {
          final modelPath = message['modelPath'] as String;
          isolateEngine = await MNN.loadModelFromFile(modelPath);
          sendPort.send({'success': isolateEngine != null});
        } else if (type == 'infer') {
          final prompt = message['prompt'] as String;
          final maxTokens = message['maxTokens'] as int;
          if (isolateEngine == null) {
            sendPort.send({'error': 'Model not loaded'});
            return;
          }
          // 执行推理
          final result = await isolateEngine!.inferText(prompt, maxTokens: maxTokens);
          sendPort.send({'result': result});
        } else if (type == 'release') {
          await isolateEngine?.release();
          isolateEngine = null;
          sendPort.send({'success': true});
        }
      }
    });
  }

  /// 加载模型
  Future<bool> loadModel(String modelPath) async {
    if (!_isInitialized) await init();
    if (_sendPort == null) return false;

    final responsePort = ReceivePort();
    _sendPort!.send({
      'type': 'load_model',
      'modelPath': modelPath,
      'responsePort': responsePort.sendPort,
    });

    final result = await responsePort.first;
    _isModelLoaded = result['success'] == true;
    return _isModelLoaded;
  }

  /// 执行文本推理
  Future<String> infer(String prompt, {int maxTokens = 512}) async {
    if (!_isModelLoaded) return "";
    if (_sendPort == null) return "";

    final responsePort = ReceivePort();
    _sendPort!.send({
      'type': 'infer',
      'prompt': prompt,
      'maxTokens': maxTokens,
      'responsePort': responsePort.sendPort,
    });

    final result = await responsePort.first;
    return result['result'] ?? "";
  }

  /// 释放资源
  Future<void> release() async {
    if (_sendPort != null) {
      final responsePort = ReceivePort();
      _sendPort!.send({
        'type': 'release',
        'responsePort': responsePort.sendPort,
      });
      await responsePort.first;
    }
    _inferIsolate?.kill();
    _receivePort?.close();
    _mnnEngine?.release();
    _mnnEngine = null;
    _isInitialized = false;
    _isModelLoaded = false;
  }

  /// 后台空闲时自动释放资源
  void autoRelease() {
    Future.delayed(const Duration(minutes: 5), () {
      release();
    });
  }
}
