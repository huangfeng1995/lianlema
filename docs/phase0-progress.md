# 阶段0：技术验证 - 进度记录

**分支：** `feature/phase0-tech-validation`
**开始日期：** 2026-04-28
**状态：** 🔴 进行中

---

## 阶段0目标

验证 MNN + Qwen2-0.5B 在 iOS/Android 端侧运行的可行性

---

## 任务清单

### 任务0.1：调研 MNN 对 LLM 的支持
- [ ] 查阅 MNN 官方文档，确认对 Transformer/LLM 的支持
- [ ] 查找 MNN 的移动端集成示例
- [ ] 确认 MNN 的 iOS/Android SDK 获取方式
- [ ] 查找 MNN 推理 LLM 的示例代码

**记录：**
-

---

### 任务0.2：调研 Qwen2 模型资源
- [ ] 查找 Qwen2-0.5B-Instruct 的官方模型下载
- [ ] 确认是否有量化版本
- [ ] 查找是否有转换好的 MNN 格式模型
- [ ] 了解模型转换工具和流程

**记录：**
-

---

### 任务0.3：备选方案调研
- [ ] 调研 MLC LLM 方案
- [ ] 调研 llama.cpp + Flutter 方案
- [ ] 调研 ONNX Runtime 方案
- [ ] 对比各方案的优缺点

**记录：**
-

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

**下一步：**
-

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

**最后更新：** 2026-04-28
