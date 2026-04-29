# 端侧模型下载指南

## 概述

练了吗App使用 **llama.cpp** 进行端侧AI推理，支持多种开源模型。

**注意**: 模型文件较大（几百MB到几GB），请确保设备有足够存储空间。

---

## Qwen2-0.5B-Instruct-GGUF（推荐）

### 模型介绍
- **开发者：阿里巴巴通义实验室
- **参数量**：0.5B
- **模型格式**：GGUF (llama.cpp格式)
- **推荐量化版本**：Q4_0 或 Q8_0

### 下载步骤

1. **访问 HuggingFace**
   - 网址：https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF

2. **选择并下载模型文件**
   推荐以下任一版本：
   - `qwen2-0_5b-instruct-q4_0.gguf (约300MB，速度/质量均衡)
   - `qwen2-0_5b-instruct-q8_0.gguf (约600MB，质量更好)

3. **重命名文件**
   下载后将文件重命名为：`qwen2_05b_int4.gguf`

4. **放入设备文件放置位置**
   - **iOS**: 通过iTunes文件共享，放入应用的Documents目录
   - **Android**: 放入应用的私有存储空间
   - **开发测试**: 通过Xcode/Android Studio直接放入模拟器的Documents/models目录

---

## 其他可选模型

### MiniCPM-2B
- 效果更好，体积约600MB（Q4量化）
- 下载地址：https://huggingface.co/openbmbai/MiniCPM-2B-sft-bf16

### Llama3-8B
- 效果接近GPT-3.5
- 体积约4.5GB（Q4量化）
- 下载地址：https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct

---

## 在应用中使用

### 首次加载模型后，应用会自动：
1. 通过宠物对话会使用端侧模型生成回复
2. 推送通知会由模型个性化生成
3. 所有推理完全离线进行，保护用户隐私

### 如果没有模型，应用会自动使用预设的mock回复，功能正常使用。

---

## 技术细节

### llama.cpp
- 官网：https://github.com/ggerganov/llama.cpp
- 优点：高性能、低内存占用、跨平台

### Fllama
- GitHub：https://github.com/xuegao-tzx/Fllama
- pub.dev：https://pub.dev/packages/fcllama
- Flutter与llama.cpp的Flutter绑定，使用Platform Channel实现

---

## 注意事项

⚠️ **不要将模型文件提交到Git仓库！
- 模型文件太大，会严重影响仓库体积和克隆速度
- .gitignore已配置忽略 *.gguf 文件
