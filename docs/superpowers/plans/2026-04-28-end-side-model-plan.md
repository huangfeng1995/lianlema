# 练了吗端侧模型实现 - 详细分阶段实施计划

**日期：2026-04-28**
**对应设计文档：** [2026-04-28-end-side-model-design.md](../specs/2026-04-28-end-side-model-design.md)

---

## 项目当前状态分析

现有代码已包含基础框架（`mnn_inference_service.dart` 和 `model_download_service.dart`），但相关依赖被注释掉，实际业务逻辑（`pet_service.dart`）使用 Mock 数据。架构需要改为 **Platform Channel 桥接** 方案。

---

## 阶段 0：技术验证（最重要）

**目标**：验证 MNN + Qwen2-0.5B 在端侧运行的可行性

### 具体任务清单
1. **下载和准备测试模型**
   - 获取 Qwen2-0.5B-Instruct 模型
   - 转换为 4bit 量化 MNN 格式
   - 准备小型测试样本

2. **Android 平台技术验证**
   - 创建独立 Android 测试项目
   - 集成 MNN 推理库
   - 实现最小化推理 Demo
   - 测试推理速度和内存占用

3. **iOS 平台技术验证**
   - 创建独立 iOS 测试项目
   - 集成 MNN 推理库
   - 实现最小化推理 Demo
   - 测试推理速度和内存占用

4. **Tokenizer 验证**
   - 验证 Qwen2 Tokenizer 在移动端可用
   - 测试 Encoding/Decoding 性能

### 需要修改的文件
- 新建测试项目（不在主项目内）
- `docs/tech-validation-report.md`（验证报告）

### 验收标准
- [ ] Android 端能成功加载模型并执行推理
- [ ] iOS 端能成功加载模型并执行推理
- [ ] 单次推理时间 < 3秒（在中端机型上）
- [ ] 内存占用 < 500MB
- [ ] Tokenizer 能正确处理中英文

### 预估工作量
**2-3 人周**

---

## 阶段 1：基础环境

**目标**：搭建 Platform Channel 基础设施

### 具体任务清单

#### 1.1 Flutter 端 Platform Channel 定义
- 定义 MethodChannel 名称和通信协议
- 定义数据模型（推理请求、推理结果、模型状态等）

#### 1.2 Android 端 Platform Channel 实现
- 在 `MainActivity.kt` 中创建 MethodChannel Handler
- 集成 MNN SDK 依赖
- 创建 Android 侧推理服务类
- 实现基础的通道通信（ping/pong 测试）

#### 1.3 iOS 端 Platform Channel 实现
- 在 `AppDelegate.swift` 中创建 MethodChannel Handler
- 集成 MNN SDK 依赖
- 创建 iOS 侧推理服务类
- 实现基础的通道通信（ping/pong 测试）

#### 1.4 项目依赖配置
- 取消 `pubspec.yaml` 中相关注释或调整依赖
- 配置 Android `build.gradle.kts`
- 配置 iOS `Podfile`

### 需要修改的文件
- `pubspec.yaml`
- `android/app/build.gradle.kts`
- `android/app/src/main/kotlin/com/lianlema/lianlema/MainActivity.kt`
- `android/app/src/main/kotlin/com/lianlema/lianlema/MnnInferencePlugin.kt`（新建）
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/MnnInferencePlugin.swift`（新建）
- `ios/Podfile`
- `lib/services/mnn_inference_service.dart`（重构）

### 验收标准
- [ ] Flutter 能与 Android 端成功通信
- [ ] Flutter 能与 iOS 端成功通信
- [ ] 基础 ping/pong 测试通过
- [ ] 项目能在两个平台正常编译运行

### 预估工作量
**1.5-2 人周**

---

## 阶段 2：Tokenizer + 最小推理

**目标**：实现端到端的 Tokenization 和最小推理功能

### 具体任务清单

#### 2.1 Tokenizer 实现
- 集成 Qwen2 Tokenizer（Android/iOS）
- 实现 Tokenize 方法（文本 → token IDs）
- 实现 Detokenize 方法（token IDs → 文本）
- 通过 Platform Channel 暴露给 Flutter

#### 2.2 模型加载功能
- 实现模型加载 API
- 实现模型释放 API
- 支持从本地文件路径加载
- 错误处理和状态反馈

#### 2.3 最小推理实现
- 实现单次推理接口
- 支持配置 maxTokens
- 返回推理结果文本
- 错误处理和异常捕获

#### 2.4 Flutter 端桥接
- 重构 `mnn_inference_service.dart` 为 Platform Channel 桥接
- 实现 init()、loadModel()、infer()、release() 方法
- 保持现有接口签名不变（兼容性）

### 需要修改的文件
- `lib/services/mnn_inference_service.dart`（主要重构）
- `android/app/src/main/kotlin/com/lianlema/lianlema/MnnInferencePlugin.kt`
- `ios/Runner/MnnInferencePlugin.swift`
- Android/iOS 新增 Tokenizer 相关类

### 验收标准
- [ ] 能通过 Flutter 调用 tokenize 方法
- [ ] 能通过 Flutter 调用 detokenize 方法
- [ ] 能成功加载模型文件
- [ ] 能执行简单推理（如 "Hello" → 得到回复）
- [ ] 推理结果正确且可读
- [ ] 错误情况下有合理异常处理

### 预估工作量
**2-2.5 人周**

---

## 阶段 3：模型分发层

**目标**：实现模型下载、验证、管理功能

### 具体任务清单

#### 3.1 模型下载功能（Native 端）
- 实现断点续传下载
- 下载进度回调
- 下载暂停/取消
- Android 使用 DownloadManager 或自定义实现
- iOS 使用 URLSession

#### 3.2 模型验证
- 实现 MD5/SHA256 文件校验
- 下载后自动校验
- 校验失败自动重下

#### 3.3 模型存储管理
- 模型文件存储目录管理
- 已下载模型列表查询
- 模型删除功能

#### 3.4 Flutter 端桥接
- 重构 `model_download_service.dart`
- 保持现有 ModelInfo、ModelType、ModelStatus 结构
- 通过 Platform Channel 调用 Native 下载功能
- 实现下载进度流（Stream）

### 需要修改的文件
- `lib/services/model_download_service.dart`（重构）
- `android/app/src/main/kotlin/com/lianlema/lianlema/ModelDownloadService.kt`（新建）
- `ios/Runner/ModelDownloadService.swift`（新建）
- 可能需要更新 AndroidManifest.xml 和 Info.plist 权限

### 验收标准
- [ ] 能触发模型下载
- [ ] 下载进度能实时回调到 Flutter
- [ ] 下载完成后自动校验文件完整性
- [ ] 支持暂停和取消下载
- [ ] 能查询已下载模型列表
- [ ] 能删除已下载模型
- [ ] 首次启动能检测并触发默认模型下载

### 预估工作量
**1.5-2 人周**

---

## 阶段 4：业务逻辑改造

**目标**：接入真实推理，替换 Mock 数据

### 具体任务清单

#### 4.1 恢复 PetService 推理调用
- 取消 `pet_service.dart` 中的注释
- 恢复 `MnnInferenceService` 和 `ModelDownloadService` 的实例化
- 恢复 `init()` 中的初始化逻辑

#### 4.2 Chat 功能接入
- 恢复 `chat()` 方法中的推理调用
- 完善 prompt 构建逻辑
- 添加上下文管理
- 错误处理（推理失败时的降级方案）

#### 4.3 Emotion 功能接入
- 恢复 `getEmotion()` 方法
- 实现情绪分类 prompt
- 结果解析和验证

#### 4.4 Push 功能接入
- 恢复 `generatePush()` 方法
- 实现推送生成 prompt
- 完善结果解析逻辑

#### 4.5 降级策略设计
- 推理失败时的默认回复
- 模型未下载时的引导流程
- 异常情况的用户友好提示

### 需要修改的文件
- `lib/services/pet_service.dart`（主要修改）
- `lib/services/mnn_inference_service.dart`（可能需要微调接口）

### 验收标准
- [ ] PetService 初始化成功
- [ ] 能与宠物进行真实对话（非 Mock）
- [ ] 情绪判断功能正常工作
- [ ] 能生成个性化推送内容
- [ ] 推理失败时有友好的降级方案
- [ ] 对话历史能正确保存

### 预估工作量
**1 人周**

---

## 阶段 5：UI 对接与测试

**目标**：完整用户流程测试和 UI 优化

### 具体任务清单

#### 5.1 首次启动流程
- 首次启动检测模型状态
- 模型下载引导 UI
- 下载进度展示
- 下载完成提示

#### 5.2 设置界面
- 模型管理页面（如果还没有）
- 已下载模型列表
- 模型切换功能
- 删除模型功能

#### 5.3 完整流程测试
- 新用户首次启动体验
- 对话功能完整测试
- 推送生成测试
- 各种异常场景测试

#### 5.4 多机型测试
- 低端机型兼容性
- 中端机型性能
- 高端机型优化

#### 5.5 Bug 修复
- 根据测试结果修复问题
- 优化用户体验

### 需要修改的文件
- `lib/screens/settings_screen.dart`（可能）
- `lib/screens/splash_screen.dart`（可能）
- 可能需要新建模型管理页面
- 其他根据测试发现需要修改的文件

### 验收标准
- [ ] 首次启动流程顺畅
- [ ] 模型下载 UI 友好清晰
- [ ] 完整对话流程无 Crash
- [ ] 推送功能正常工作
- [ ] 在低中高端机型上都能运行
- [ ] 无严重 Bug

### 预估工作量
**1.5-2 人周**

---

## 阶段 6：性能优化

**目标**：优化推理速度、内存占用和用户体验

### 具体任务清单

#### 6.1 推理性能优化
- 调查推理速度瓶颈
- 尝试不同的推理参数配置
- KV Cache 优化（如果支持）
- 批量处理优化

#### 6.2 内存优化
- 内存占用监控
- 及时释放未使用资源
- 低内存配置方案

#### 6.3 启动优化
- 延迟初始化
- 后台预加载
- 减少首屏等待时间

#### 6.4 用户体验优化
- 推理中 loading 状态
- 流式输出（如果可能）
- 更快的首字响应

### 需要修改的文件
- `lib/services/mnn_inference_service.dart`
- Native 端推理服务类
- 相关 UI 页面（loading 状态）

### 验收标准
- [ ] 推理速度较阶段 2 提升 > 30%
- [ ] 内存占用降低 > 20%
- [ ] 首字响应时间 < 1秒
- [ ] 用户体验流畅无明显卡顿

### 预估工作量
**1-1.5 人周**

---

## 总体时间规划

| 阶段 | 工作量 | 关键输出 |
|------|--------|----------|
| 0. 技术验证 | 2-3 人周 | 技术验证报告 |
| 1. 基础环境 | 1.5-2 人周 | Platform Channel 基础设施 |
| 2. Tokenizer + 最小推理 | 2-2.5 人周 | 端到端推理能力 |
| 3. 模型分发层 | 1.5-2 人周 | 模型下载管理功能 |
| 4. 业务逻辑改造 | 1 人周 | 真实推理接入业务 |
| 5. UI 对接与测试 | 1.5-2 人周 | 完整可发布版本 |
| 6. 性能优化 | 1-1.5 人周 | 优化后的最终版本 |
| **总计** | **10.5-14.5 人周** | |

---

## 关键依赖与风险

### 依赖项
1. **MNN 库**：需要稳定的 Flutter/Android/iOS 绑定
2. **Qwen2 模型**：需要可在端侧运行的量化版本
3. **Tokenizer**：需要与 Qwen2 兼容的端侧实现

### 主要风险
1. **技术可行性风险**：阶段 0 需验证，如不可行需备选方案
2. **性能风险**：端侧推理可能过慢或内存过大
3. **包体积风险**：MNN + 模型可能导致 App 体积过大
4. **兼容性风险**：不同机型/OS 版本的兼容性问题

### 缓解措施
- 阶段 0 充分验证，不轻易进入后续阶段
- 准备备选推理引擎方案（如 ONNX Runtime）
- 模型可下载，不打包进 App 主包
- 充分的多机型测试

---

## 关键文件总结

| 路径 | 说明 |
|------|------|
| `lib/services/mnn_inference_service.dart` | 核心推理服务（主要重构） |
| `lib/services/model_download_service.dart` | 模型下载服务（主要重构） |
| `lib/services/pet_service.dart` | 业务逻辑（恢复注释代码） |
| `android/app/src/main/kotlin/com/lianlema/lianlema/MainActivity.kt` | Android Platform Channel 入口 |
| `android/app/src/main/kotlin/com/lianlema/lianlema/MnnInferencePlugin.kt` | Android 推理插件（新建） |
| `android/app/src/main/kotlin/com/lianlema/lianlema/ModelDownloadService.kt` | Android 下载服务（新建） |
| `ios/Runner/AppDelegate.swift` | iOS Platform Channel 入口 |
| `ios/Runner/MnnInferencePlugin.swift` | iOS 推理插件（新建） |
| `ios/Runner/ModelDownloadService.swift` | iOS 下载服务（新建） |
| `pubspec.yaml` | 依赖配置 |
| `android/app/build.gradle.kts` | Android 依赖配置 |
| `ios/Podfile` | iOS 依赖配置 |

---

**计划状态：已创建，等待开始阶段 0**
