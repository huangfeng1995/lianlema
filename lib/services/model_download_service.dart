import 'dart:io';
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
      name: "Qwen2-0.5B（内置默认）",
      description: "体积小，速度快，适合绝大多数用户使用",
      sizeMB: 250,
      downloadUrl: "https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF",
      md5: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    ),
    ModelInfo(
      type: ModelType.miniCPM_2b,
      name: "MiniCPM-2B（效果更好）",
      description: "对话更自然，效果更接近大模型",
      sizeMB: 600,
      downloadUrl: "https://huggingface.co/openbmbai/MiniCPM-2B-sft-bf16",
      md5: "b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7",
    ),
    ModelInfo(
      type: ModelType.llama3_8b,
      name: "Llama3-8B（高端机型专属）",
      description: "效果接近GPT-3.5，适合高端机型用户",
      sizeMB: 4500,
      downloadUrl: "https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct",
      md5: "c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8",
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

    // 检查assets目录是否有模型（不推荐，因为文件太大）
    if (model.type == ModelType.qwen2_05b) {
      // 尝试从应用文档目录加载，而不是从assets
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

    model.status = ModelStatus.notDownloaded;
    model.localPath = null;
  }

  /// 获取模型下载说明
  String getModelDownloadInstructions(ModelType type) {
    switch (type) {
      case ModelType.qwen2_05b:
        return """
Qwen2-0.5B-Instruct-GGUF 下载说明：

1. 访问 HuggingFace: https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF

2. 下载一个合适的量化版本，推荐：
   - qwen2-0_5b-instruct-q4_0.gguf (约300MB，速度快)
   - qwen2-0_5b-instruct-q8_0.gguf (约600MB，质量更好)

3. 将下载的文件重命名为: qwen2_05b_int4.gguf

4. 通过iTunes/文件共享放入应用文档目录，或在开发时放入手机的Documents/models目录

5. 重启应用即可
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
