import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'storage_service.dart';

/// 模型类型枚举
enum ModelType {
  qwen2_05b, // 内置默认模型，Qwen2-0.5B 4bit量化版(GGUF)
  miniCPM_2b, // 可选模型，MiniCPM-2B 4bit量化版
  llama3_8b, // 可选模型，Llama3-8B 4bit量化版
}

/// 模型状态枚举
enum ModelStatus {
  notDownloaded, // 未下载
  downloading, // 下载中
  downloaded, // 已下载
  corrupted, // 已损坏
}

/// 模型信息
class ModelInfo {
  final ModelType type;
  final String name;
  final String description;
  final int sizeMB;
  final String downloadUrl;
  final String md5; // 文件校验值
  ModelStatus status;
  int downloadProgress;
  String? localPath;

  ModelInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.sizeMB,
    required this.downloadUrl,
    required this.md5,
    this.status = ModelStatus.notDownloaded,
    this.downloadProgress = 0,
    this.localPath,
  });
}

/// 模型下载管理服务
class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._internal();

  final StorageService _storage = StorageService();

  /// 所有支持的模型列表
  final List<ModelInfo> _models = [
    ModelInfo(
      type: ModelType.qwen2_05b,
      name: "Qwen2-0.5B",
      description: "体积小，速度快，适合绝大多数用户使用",
      sizeMB: 350,
      downloadUrl: "https://github.com/huangfeng1995/lianlema/releases/download/models/qwen2_05b_int4.gguf",
      md5: "",
    ),
  ];

  /// 初始化服务
  Future<void> init() async {
    await _checkAllModelsStatus();
  }

  /// 获取所有模型列表
  List<ModelInfo> getModels() => List.unmodifiable(_models);

  /// 获取当前使用的模型
  Future<ModelInfo?> getCurrentModel() async {
    final typeIndex = await _storage.getCurrentModelType();
    if (typeIndex == null) return getDefaultModel();
    final type = ModelType.values[typeIndex];
    for (final m in _models) {
      if (m.type == type) return m;
    }
    return getDefaultModel();
  }

  /// 获取默认内置模型
  ModelInfo getDefaultModel() {
    for (final m in _models) {
      if (m.type == ModelType.qwen2_05b) return m;
    }
    return _models.first;
  }

  /// 删除已下载的模型
  Future<void> deleteModel(ModelType type) async {
    ModelInfo? model;
    for (final m in _models) {
      if (m.type == type) {
        model = m;
        break;
      }
    }
    if (model == null) return;

    if (model.localPath != null) {
      final file = File(model.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    model.status = ModelStatus.notDownloaded;
    model.localPath = null;
    await _storage.deleteModelStatus(type.index);
  }

  /// 切换使用的模型
  Future<void> switchModel(ModelType type) async {
    ModelInfo? model;
    for (final m in _models) {
      if (m.type == type) {
        model = m;
        break;
      }
    }
    if (model == null || model.status != ModelStatus.downloaded) return;
    await _storage.setCurrentModelType(type.index);
  }

  /// 下载模型
  Future<void> downloadModel(
    ModelType type, {
    Function(int, int)? onProgress,
    Function()? onComplete,
    Function(String)? onError,
  }) async {
    ModelInfo? model;
    for (final m in _models) {
      if (m.type == type) {
        model = m;
        break;
      }
    }
    if (model == null) {
      onError?.call("模型不存在");
      return;
    }

    model.status = ModelStatus.downloading;
    model.downloadProgress = 0;

    try {
      final modelDir = await _getModelSaveDir();
      final savePath = path.join(modelDir.path, _getModelFileName(type));
      final tempPath = '$savePath.tmp';

      final request = http.Request('GET', Uri.parse(model.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('下载失败: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      final file = File(tempPath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);

        model.downloadProgress = totalBytes > 0
            ? (receivedBytes / totalBytes * 100).round()
            : 0;

        onProgress?.call(receivedBytes, totalBytes);
      }

      await sink.flush();
      await sink.close();

      // 重命名临时文件
      await file.rename(savePath);

      model.status = ModelStatus.downloaded;
      model.localPath = savePath;
      await _saveModelStatus(model);

      // 设为当前模型
      await _storage.setCurrentModelType(type.index);

      onComplete?.call();
    } catch (e) {
      model.status = ModelStatus.notDownloaded;
      model.downloadProgress = 0;
      onError?.call(e.toString());
    }
  }

  /// 取消下载
  void cancelDownload(ModelType type) {
    ModelInfo? model;
    for (final m in _models) {
      if (m.type == type) {
        model = m;
        break;
      }
    }
    if (model == null) return;
    model.status = ModelStatus.notDownloaded;
    model.downloadProgress = 0;
  }

  /// 校验所有模型状态
  Future<void> _checkAllModelsStatus() async {
    for (final model in _models) {
      await _checkModelStatus(model);
    }
  }

  /// 校验单个模型状态
  Future<void> _checkModelStatus(ModelInfo model) async {
    // 先从存储读取状态
    final savedStatus = await _storage.getModelStatus(model.type.index);
    final savedPath = await _storage.getModelLocalPath(model.type.index);

    if (savedStatus != null && savedPath != null) {
      final file = File(savedPath);
      if (await file.exists()) {
        model.status = ModelStatus.downloaded;
        model.localPath = savedPath;
        return;
      }
    }

    // 检查应用文档目录是否有模型
    if (model.type == ModelType.qwen2_05b) {
      final modelDir = await _getModelSaveDir();
      final modelPath = path.join(modelDir.path, _getModelFileName(model.type));
      final file = File(modelPath);
      if (await file.exists()) {
        model.status = ModelStatus.downloaded;
        model.localPath = modelPath;
        await _saveModelStatus(model);
        return;
      }
    }

    // 【临时】检查Downloads目录（开发测试用）
    if (model.type == ModelType.qwen2_05b) {
      const downloadsPath = "/Users/openclaw/Downloads/qwen2_05b_int4.gguf";
      final file = File(downloadsPath);
      if (await file.exists()) {
        model.status = ModelStatus.downloaded;
        model.localPath = downloadsPath;
        await _saveModelStatus(model);
        return;
      }
    }

    model.status = ModelStatus.notDownloaded;
    model.localPath = null;
  }

  /// 获取模型下载说明
  String getModelDownloadInstructions(ModelType type) {
    switch (type) {
      case ModelType.qwen2_05b:
        return """
Qwen2-0.5B 模型下载说明：

模型已托管在 GitHub Releases，点击下载按钮即可自动下载。

文件大小：约 350MB
预计时间：Wi-Fi 下 1-3 分钟
""";
      case ModelType.miniCPM_2b:
        return "MiniCPM-2B模型下载说明待添加";
      case ModelType.llama3_8b:
        return "Llama3-8B模型下载说明待添加";
    }
  }

  /// 保存模型状态到存储
  Future<void> _saveModelStatus(ModelInfo model) async {
    await _storage.setModelStatus(model.type.index, model.status.index);
    if (model.localPath != null) {
      await _storage.setModelLocalPath(model.type.index, model.localPath!);
    }
  }

  /// 获取模型保存目录
  Future<Directory> _getModelSaveDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(path.join(appDir.path, "models"));
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// 获取模型文件名
  String _getModelFileName(ModelType type) {
    switch (type) {
      case ModelType.qwen2_05b:
        return "qwen2_05b_int4.gguf";
      case ModelType.miniCPM_2b:
        return "minicpm_2b_int4.gguf";
      case ModelType.llama3_8b:
        return "llama3_8b_int4.gguf";
    }
  }
}
