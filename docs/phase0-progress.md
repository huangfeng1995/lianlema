# 阶段0：技术验证 - 进度记录

**分支：** `feature/phase0-tech-validation`
**开始日期：** 2026-04-28
**状态：** 🔴 进行中

---

## 阶段0目标

验证 **llama.cpp + Qwen2-0.5B** 在 iOS/Android 端侧运行的可行性（从MNN调整为llama.cpp）

---

## 任务清单

### 任务0.1：调研 llama.cpp
- [x] 确认使用 llama.cpp 替代 MNN（用户选择方案A）
- [x] 网络问题解决！能访问GitHub
- [x] 查阅 llama.cpp 官方README
- [x] 发现：支持Qwen模型！
- [x] 发现：有Flutter绑定！
- [x] 发现：有Android示例！
- [x] 发现：有Swift绑定！
- [ ] 继续深入调研移动端集成方式

**记录：**
- llama.cpp：https://github.com/ggerganov/llama.cpp
- 用户选择方案A，从MNN调整为llama.cpp
- 支持模型：Qwen在支持列表中！
- Flutter绑定：https://github.com/netdur/llama_cpp_dart 和 https://github.com/xuegao-tzx/Fllama
- Android示例：/examples/llama.android
- Swift绑定：多个选项

**发现的关键信息：**
1. 支持Qwen模型 ✓
2. 有Flutter绑定 ✓
3. 有移动端集成示例 ✓

---

### 任务0.2：调研 Qwen2 模型资源
- [ ] 查找 Qwen2-0.5B-Instruct 的官方模型下载
- [ ] 确认是否有 GGUF 量化版本（llama.cpp格式）
- [ ] 了解模型转换工具和流程

**记录：**
- Qwen2：https://github.com/QwenLM/Qwen2

---

### 任务0.3：Flutter 集成方案调研
- [x] 查找是否有现成的 llama.cpp Flutter 插件
- [x] 发现：有两个Flutter绑定项目！
- [ ] 深入调研第一个项目：llama_cpp_dart
- [ ] 深入调研第二个项目：Fllama
- [ ] 对比两个方案的优缺点
- [ ] 调研 Platform Channel 桥接方案作为备选
- [ ] 了解 iOS/Android 原生集成 llama.cpp 的方式

**记录：**
- Flutter绑定1：https://github.com/netdur/llama_cpp_dart
- Flutter绑定2：https://github.com/xuegao-tzx/Fllama

---

### 任务0.4：Android 最小 Demo（如果需要）
- [ ] 创建独立 Android 测试项目
- [ ] 集成 MNN SDK
- [ ] 准备测试模型文件
- [ ] 实现最小推理测试
- [ ] 测试推理速度和内存占用

**记录：**
-

---

### 任务0.5：iOS 最小 Demo（如果需要）
- [ ] 创建独立 iOS 测试项目
- [ ] 集成 MNN SDK
- [ ] 准备测试模型文件
- [ ] 实现最小推理测试
- [ ] 测试推理速度和内存占用

**记录：**
-

---

### 任务0.6：技术验证报告
- [ ] 汇总测试结果
- [ ] 分析可行性
- [ ] 给出建议（继续 MNN / 切换方案）
- [ ] 更新主设计文档

**记录：**
-

---

## 当前进度

**已完成：**
- ✅ 调整技术选型：MNN → llama.cpp（用户选择方案A）
- ✅ 更新设计文档：所有MNN相关内容改为llama.cpp
- ✅ 提交变更到分支

**下一步：**
- 调研 llama.cpp 移动端集成方式
- 查找 Qwen2-0.5B 的 GGUF 量化版本

---

## 重要链接

- [设计文档](../superpowers/specs/2026-04-28-end-side-model-design.md)
- [实施计划](../superpowers/plans/2026-04-28-end-side-model-plan.md)
- [MNN 官网](https://github.com/alibaba/MNN)
- [Qwen2 官网](https://github.com/QwenLM/Qwen2)

---

## Session 重启指南

如果会话重启，按以下步骤继续：

1. **检查当前分支：** `git branch`，确保在 `feature/phase0-tech-validation`
2. **查看最新进度：** 阅读本文档
3. **继续当前任务：** 从"下一步"继续
4. **及时更新文档：** 每完成一步都更新本文档并 commit

---

## 🎉 重大发现：Fllama（fcllama）项目！（2026-04-29）

**Fllama关键发现：**
1. ✓ **在pub.dev上！** `flutter pub add fcllama`
2. ✓ **用Platform Channel！** 正是我们设计的架构
3. ✓ **支持iOS 14+和Android 23+**
4. ✓ **iOS支持Metal加速！**
5. ✓ **支持流式输出！**
6. ✓ **支持tokenize/detokenize！**
7. ✓ **支持GGUF模型！**
8. ✓ **有完整的示例代码！**

**项目链接：** https://github.com/xuegao-tzx/Fllama
**pub.dev：** https://pub.dev/packages/fcllama

**阶段0进展：**
- 任务0.1完成：调研llama.cpp
- 任务0.3正在进行：调研Flutter集成方案
- **发现了现成的Fllama包！可以直接用！**

**下一步建议：**
1. 直接集成Fllama包到项目中
2. 更新设计文档，将MnnInferenceService改为用Fllama
3. 保持现有PetService接口不变，最小化改动

---

**最后更新：** 2026-04-29 - 重大发现！Fllama完美符合我们的需求！
