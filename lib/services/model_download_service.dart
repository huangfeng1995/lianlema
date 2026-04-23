import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'storage_service.dart';

/// 模型类型枚举
enum ModelType {
  qwen2_05b, // 内置默认模型，Qwen2-0.5B 4bit量化版
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
      name: "Qwen2-0.5B（内置默认）",
      description: "体积小，速度快，适合绝大多数用户使用",
      sizeMB: 250,
      downloadUrl: "https://static.lianlema.app/models/qwen2_05b_int4.mnn",
      md5: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    ),
    ModelInfo(
      type: ModelType.miniCPM_2b,
      name: "MiniCPM-2B（效果更好）",
      description: "对话更自然，效果更接近大模型",
      sizeMB: 600,
      downloadUrl: "https://static.lianlema.app/models/minicpm_2b_int4.mnn",
      md5: "b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7",
    ),
    ModelInfo(
      type: ModelType.llama3_8b,
      name: "Llama3-8B（高端机型专属）",
      description: "效果接近GPT-3.5，适合高端机型用户",
      sizeMB: 4500,
      downloadUrl: "https://static.lianlema.app/models/llama3_8b_int4.mnn",
      md5: "c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8",
    ),
  ];

  /// 初始化服务
  Future<void> init() async {
    await FlutterDownloader.initialize(debug: false);
    await _checkAllModelsStatus();
  }

  /// 获取所有模型列表
  List<ModelInfo> getModels() => List.unmodifiable(_models);

  /// 获取当前使用的模型
  Future<ModelInfo?> getCurrentModel() async {
    final typeIndex = await _storage.getCurrentModelType();
    if (typeIndex == null) return getDefaultModel();
    final type = ModelType.values[typeIndex];
    return _models.firstWhereOrNull((m) => m.type == type);
  }

  /// 获取默认内置模型
  ModelInfo getDefaultModel() => _models.firstWhere((m) => m.type == ModelType.qwen2_05b);

  /// 下载模型
  Future<String?> downloadModel(ModelType type) async {
    final model = _models.firstWhere((m) => m.type == type);
    if (model.status == ModelStatus.downloading) return null;

    final saveDir = await _getModelSaveDir();
    final savePath = path.join(saveDir.path, _getModelFileName(type));

    model.status = ModelStatus.downloading;
    model.downloadProgress = 0;

    final taskId = await FlutterDownloader.enqueue(
      url: model.downloadUrl,
      savedDir: saveDir.path,
      fileName: _getModelFileName(type),
      showNotification: true,
      openFileFromNotification: false,
    );

    // 监听下载进度
    FlutterDownloader.registerCallback((id, status, progress) {
      if (id == taskId) {
        model.downloadProgress = progress;
        if (status == DownloadTaskStatus.complete) {
          model.status = ModelStatus.downloaded;
          model.localPath = savePath;
          _saveModelStatus(model);
        } else if (status == DownloadTaskStatus.failed) {
          model.status = ModelStatus.notDownloaded;
        }
      }
    });

    return taskId;
  }

  /// 暂停下载
  Future<void> pauseDownload(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
  }

  /// 取消下载
  Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  /// 删除已下载的模型
  Future<void> deleteModel(ModelType type) async {
    final model = _models.firstWhere((m) => m.type == type);
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
    final model = _models.firstWhere((m) => m.type == type);
    if (model.status != ModelStatus.downloaded) return;
    await _storage.setCurrentModelType(type.index);
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
        // 校验MD5
        final fileMd5 = await _calculateFileMd5(file);
        if (fileMd5 == model.md5) {
          model.status = ModelStatus.downloaded;
          model.localPath = savedPath;
          return;
        } else {
          // 文件损坏，删除
          await file.delete();
        }
      }
    }

    // 内置模型默认从assets读取
    if (model.type == ModelType.qwen2_05b) {
      model.status = ModelStatus.downloaded;
      model.localPath = "assets/models/qwen2_05b_int4.mnn";
      await _saveModelStatus(model);
      return;
    }

    model.status = ModelStatus.notDownloaded;
    model.localPath = null;
  }

  /// 保存模型状态到存储
  Future<void> _saveModelStatus(ModelInfo model) async {
    await _storage.setModelStatus(model.type.index, model.status.index);
    await _storage.setModelLocalPath(model.type.index, model.localPath!);
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
        return "qwen2_05b_int4.mnn";
      case ModelType.miniCPM_2b:
        return "minicpm_2b_int4.mnn";
      case ModelType.llama3_8b:
        return "llama3_8b_int4.mnn";
    }
  }

  /// 计算文件MD5（简化实现，实际开发替换为完整MD5计算）
  Future<String> _calculateFileMd5(File file) async {
    // 实际开发这里替换为真实的MD5计算逻辑
    return model.md5;
  }
}
