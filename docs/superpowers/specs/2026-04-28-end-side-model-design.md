# 练了吗端侧模型实现设计文档

**日期：2026-04-28**
**状态：已批准，待实施**

---

## 一、技术选型

| 组件 | 选型 | 说明 |
|------|------|------|
| 推理引擎 | **llama.cpp**（先验证） | 备选：MLC LLM |
| 内置模型 | Qwen2-0.5B-Instruct GGUF 4bit量化版 | ~250MB，**首次启动下载** |
| 可选模型 | MiniCPM-2B、Llama3-8B | 用户按需下载 |
| 桥接方案 | Platform Channel | Flutter <-> 原生双端 |

---

## 二、架构设计

```
┌─────────────────────────────────────────┐
│         Flutter UI层 (现有不变)          │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│      业务逻辑层 (PetService - 现有不变)  │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│    推理服务层 (MnnInferenceService)     │
│  改为 Platform Channel 桥接 (简化版)    │
└────────────────┬────────────────────────┘
                 │
         ┌───────┴────────┐
         │ Platform Channel │
         └───────┬────────┘
    ┌────────────┴────────────┐
    │                         │
┌───▼──────────┐      ┌──────▼───────┐
│  iOS原生层   │      │ Android原生层 │
│  llama.cpp + Swift │  llama.cpp + Kotlin │
│  + Tokenizer │      │  + Tokenizer │
└──────────────┘      └──────────────┘
```

### 修改范围说明

**只需修改一个文件：**
- `lib/services/mnn_inference_service.dart` - 改为 Platform Channel 桥接

**保持不变的文件：**
- `lib/services/pet_service.dart` - 接口不变
- `lib/services/model_download_service.dart` - 仅调整内置模型逻辑
- `lib/services/storage_service.dart` - 不变
- 所有 UI 层 - 不变

---

## 三、分阶段实现（调整版）

### 阶段0：技术验证（最重要！先做这个）
- 最小 Demo 验证：**llama.cpp + Qwen2-0.5B** 能否在 iOS/Android 端跑通？
- 测量推理速度、内存占用、电量消耗
- 如果 llama.cpp 不行，及时切换备选方案（MLC LLM）

**验收标准：**
- [ ] iOS 端能加载 Qwen2-0.5B 并推理
- [ ] Android 端能加载 Qwen2-0.5B 并推理
- [ ] 推理速度可接受（中端机 < 5s/轮）
- [ ] 内存占用可接受（< 800MB）

### 阶段1：基础环境搭建
- pubspec.yaml 清理（删除不存在的依赖）
- 创建 iOS/Android 原生目录占位
- 验证项目能正常编译

**验收标准：**
- [ ] `flutter build ios` 成功
- [ ] `flutter build apk` 成功

### 阶段2：Tokenizer + 最小推理
- 原生端实现 Qwen2 Tokenizer
- 实现最简单的推理接口
- Platform Channel 桥接
- 简化 `MnnInferenceService`，去掉 Isolate

**验收标准：**
- [ ] Tokenizer 能正确编码/解码
- [ ] Flutter 能通过 Platform Channel 调用原生推理
- [ ] 能返回推理结果（即使很慢）

### 阶段3：模型分发层
- 模型改为首次启动时下载
- 下载模型保存到应用文档目录
- 完整性校验

**验收标准：**
- [ ] 首次启动提示下载模型
- [ ] 下载进度显示正常
- [ ] 下载失败能重试
- [ ] 模型完整性校验通过

### 阶段4：业务逻辑层改造
- 取消 PetService 中注释的代码
- 连接推理服务，替换 Mock 回复
- 验证对话、情绪判断、推送生成

**验收标准：**
- [ ] 对话功能正常（非 Mock）
- [ ] 情绪判断正常返回 happy/sad/encourage/tease
- [ ] 推送内容由模型生成

### 阶段5：UI层对接与测试
- 现有 UI 不需要大改
- 完善加载状态、错误处理
- 端到端测试

**验收标准：**
- [ ] 推理时显示 loading 状态
- [ ] 推理失败有友好提示
- [ ] 连续对话 10 轮无异常
- [ ] 应用退到后台能释放资源

### 阶段6：性能优化与包体积控制
- iOS：On-Demand Resources
- Android：Dynamic Feature Modules
- 推理性能调优

**验收标准：**
- [ ] 推理速度优化 30%+
- [ ] 内存占用降低 20%+
- [ ] 初始包体积 < 100MB

---

## 四、关键接口设计

### Platform Channel 方法

```dart
static const MethodChannel _channel = MethodChannel('mnn_inference');
```

**方法列表：**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `init` | - | `Future<void>` | 初始化推理引擎 |
| `loadModel` | `{path: String}` | `Future<bool>` | 加载模型 |
| `infer` | `{prompt: String, maxTokens: int}` | `Future<String>` | 执行推理 |
| `release` | - | `Future<void>` | 释放资源 |

### 简化后的 MnnInferenceService

```dart
import 'package:flutter/services.dart';

class MnnInferenceService {
  static final MnnInferenceService _instance = MnnInferenceService._internal();
  factory MnnInferenceService() => _instance;
  MnnInferenceService._internal();

  static const MethodChannel _channel = MethodChannel('mnn_inference');

  Future<void> init() async {
    await _channel.invokeMethod('init');
  }

  Future<bool> loadModel(String modelPath) async {
    final result = await _channel.invokeMethod<bool>('loadModel', {'path': modelPath});
    return result ?? false;
  }

  Future<String> infer(String prompt, {int maxTokens = 512}) async {
    final result = await _channel.invokeMethod<String>('infer', {
      'prompt': prompt,
      'maxTokens': maxTokens,
    });
    return result ?? "";
  }

  Future<void> release() async {
    await _channel.invokeMethod('release');
  }
}
```

### 原生端接口（iOS Swift）

```swift
class MnnInferencePlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mnn_inference", binaryMessenger: registrar.messenger())
    let instance = MnnInferencePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "init":
      initEngine(result: result)
    case "loadModel":
      loadModel(call: call, result: result)
    case "infer":
      infer(call: call, result: result)
    case "release":
      release(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
```

### 原生端接口（Android Kotlin）

```kotlin
class MnnInferencePlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mnn_inference")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "init" -> initEngine(result)
      "loadModel" -> loadModel(call, result)
      "infer" -> infer(call, result)
      "release" -> release(result)
      else -> result.notImplemented()
    }
  }
}
```

---

## 五、关键问题说明

### 1. 为什么不用 flutter_mnn？
因为 `flutter_mnn` 包在 pub.dev 上不存在，是虚构的依赖，必须自己实现桥接。

### 2. 为什么从 MNN 改为 llama.cpp？
- MNN 主要用于计算机视觉，对 LLM 支持有限
- llama.cpp 是目前最成熟的端侧 LLM 推理方案
- 生态好，支持多种模型（包括 Qwen2）
- 用户选择方案A（llama.cpp）

### 3. 为什么模型不内置？
- 250MB 内置会导致 App 体积暴增
- App Store 初始下载限制 150MB
- 改为首次启动时下载，用户可以选择 WiFi 环境下载

### 4. 为什么保留 Isolate？
不保留，改为 Platform Channel 后，推理在原生线程执行，Dart 层不需要 Isolate。

### 5. 降级策略？
- llama.cpp 验证失败 → 切换备选方案（MLC LLM）
- 推理失败 → 提示用户重试
- 终极降级 → 保留 Mock 回复机制

---

## 六、风险与缓解措施

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| llama.cpp 移动端集成复杂 | 中 | 高 | 先做阶段 0 验证，准备备选方案 |
| 推理速度太慢 | 中 | 高 | 实测性能，必要时换更小的模型 |
| 内存占用过高 | 中 | 高 | 优化模型量化，必要时降级 |
| 用户拒绝下载模型 | 低 | 中 | 友好提示，提供跳过选项 |
| App Store 审核不通过 | 低 | 高 | 遵守苹果审核指南 |

---

## 七、已知代码问题（需要修复）

1. `model_download_service.dart` 中 `_calculateFileMd5` 直接返回 `model.md5`，需要实现真实的 MD5 校验
2. `mnn_inference_service.dart` 需要移除 Isolate 相关代码，改为 Platform Channel
3. 需要把 `MnnInferenceService` 重命名为更通用的名称（如 `LlmInferenceService`）

---

## 八、决策记录

| 决策项 | 决策 | 日期 | 备注 |
|--------|------|------|------|
| 端侧 vs 云端 | 端侧 | 2026-04-28 | 用户明确拒绝云端 |
| 推理引擎 | MNN → **llama.cpp** | 2026-04-28 | 用户选择方案A，MNN对LLM支持有限 |
| 模型 | Qwen2-0.5B-Instruct GGUF | 2026-04-28 | 4bit 量化，~250MB |
| 模型分发 | 首次启动下载 | 2026-04-28 | 不内置 |
| 桥接方案 | Platform Channel | 2026-04-28 | 仅修改推理服务 |

---

**文档状态：已批准，等待实施**
