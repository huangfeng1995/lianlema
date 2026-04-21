# 宠物推送通知栏 + 卡片标题统一 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 首页顶部新增宠物推送气泡通知栏（8秒自动消失），同时统一三张卡片的二级标题样式。

**Architecture:** PetPushBanner 作为独立 StatelessWidget，接收 PetPush 对象并自行管理 Timer 状态。HomeScreen 在 initState 时加载推送，传递给 banner 显示。Bubble 专注对话功能，移除所有 push 相关代码。

**Tech Stack:** Flutter StatefulWidget + AnimatedOpacity + Timer

---

## 文件结构

```
lib/widgets/pet_push_banner.dart   ← 新建：通知栏组件
lib/screens/home_screen.dart       ← 修改：集成 banner + 添加长期计划标题
lib/widgets/pet_bubble.dart        ← 修改：移除 _pushes 等 push 相关代码
```

---

## Task 1: 创建 PetPushBanner widget

**Files:**
- Create: `lib/widgets/pet_push_banner.dart`

---

- [ ] **Step 1: 创建文件，写入 PetPushBanner**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pet_models.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';

class PetPushBanner extends StatefulWidget {
  final PetPush push;

  const PetPushBanner({super.key, required this.push});

  @override
  State<PetPushBanner> createState() => _PetPushBannerState();
}

class _PetPushBannerState extends State<PetPushBanner> {
  double _opacity = 1.0;
  bool _showClose = false;
  Timer? _closeTimer;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    // 6秒后显示关闭按钮
    _closeTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showClose = true);
    });
    // 8秒后淡出
    _fadeTimer = Timer(const Duration(seconds: 8), _fadeOut);
  }

  void _fadeOut() {
    _fadeTimer?.cancel();
    setState(() => _opacity = 0.0);
    // 300ms 后从 tree 移除
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_opacity == 0.0) return const SizedBox.shrink();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _opacity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // 宠物头像
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getPetEmoji(widget.push.type),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 消息内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.push.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.push.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 关闭按钮
            if (_showClose)
              GestureDetector(
                onTap: _fadeOut,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getPetEmoji(PushType type) {
    switch (type) {
      case PushType.streakReminder:  return '☀️';
      case PushType.milestoneApproaching: return '🎯';
      case PushType.idleWarning:     return '💪';
      case PushType.weeklySummary:   return '📋';
      case PushType.challengeProgress: return '🏃';
      case PushType.obstacleGuidance: return '🧭';
      case PushType.annualPlanGuide: return '🌟';
    }
  }
}
```

- [ ] **Step 2: 运行 analyze 确认无 error**

```bash
/Users/openclaw/flutter/bin/flutter analyze lib/widgets/pet_push_banner.dart
```
Expected: 0 errors

- [ ] **Step 3: 提交**

```bash
git add lib/widgets/pet_push_banner.dart
git commit -m "feat: add PetPushBanner widget - auto-dismiss notification bar"
```

---

## Task 2: 长期计划卡片添加标题

**Files:**
- Modify: `lib/screens/home_screen.dart:2546-2665` (_buildVisionCard)

---

- [ ] **Step 1: 在 _buildVisionCard 的 Column children 开头添加标题行**

在 `child: Padding(padding: const EdgeInsets.all(16))` 之后、Column children 第一行插入：

```dart
// 标题行：长期计划
Text(
  '长期计划',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ),
),
const SizedBox(height: 6),
```

在 `_buildVisionCard` 的 Row > Expanded > Column > children 数组中，在 `if (hasYearGoal)` 之前插入以上标题行。

- [ ] **Step 2: 运行 analyze 确认无 error**

```bash
/Users/openclaw/flutter/bin/flutter analyze lib/screens/home_screen.dart
```
Expected: 0 errors（只有 pre-existing unused_element warnings）

- [ ] **Step 3: 提交**

```bash
git add lib/screens/home_screen.dart
git commit -m "feat(home_screen): add '长期计划' title to VisionCard - 16px w600"
```

---

## Task 3: HomeScreen 集成 PetPushBanner

**Files:**
- Modify: `lib/screens/home_screen.dart` — initState 添加 push 加载，build() 添加 banner

---

- [ ] **Step 1: 添加 state 字段**

在 HomeScreenState 类顶部（字段区）添加：

```dart
PetPush? _currentPush;
```

- [ ] **Step 2: 在 initState 中加载推送**

在 `_loadData()` 调用之后追加：

```dart
// 加载宠物推送（取最高优先级一条）
try {
  final pushes = await PetPushService.instance.generateDailyPushes(_ctx);
  if (pushes.isNotEmpty && mounted) {
    setState(() => _currentPush = pushes.first);
  }
} catch (_) {}
```

注意：`_ctx` 是 StorageService 单例，需要确认 `_ctx` 在 `_loadData()` 之前已经初始化。

- [ ] **Step 3: 在 build() 中添加 PetPushBanner**

在 `SafeArea` 内部、Column children 第一行添加：

```dart
// 宠物推送通知栏
if (_currentPush != null) ...[
  PetPushBanner(push: _currentPush!),
  const SizedBox(height: 12),
],
```

在 `_buildGreetingHeader()` 之前，替换原来的 `const SizedBox(height: 24),`。

- [ ] **Step 4: 移除 PetBubble 相关代码**

删除以下三处：
1. import 行：`import '../widgets/pet_bubble.dart';`
2. 字段：`final GlobalKey<PetBubbleState> _petBubbleKey = GlobalKey<PetBubbleState>();`
3. Stack children 中的：`PetBubble(key: _petBubbleKey),`

- [ ] **Step 5: 确认 import 完整性**

确保仍有 `import '../services/pet_push_service.dart';`（因为要调用 generateDailyPushes）。

- [ ] **Step 6: 运行 analyze**

```bash
/Users/openclaw/flutter/bin/flutter analyze lib/screens/home_screen.dart
```
Expected: 0 errors

- [ ] **Step 7: 提交**

```bash
git add lib/screens/home_screen.dart
git commit -m "feat(home_screen): integrate PetPushBanner - top notification bar, remove PetBubble"
```

---

## Task 4: PetBubble 清理 push 相关代码

**Files:**
- Modify: `lib/widgets/pet_bubble.dart`

---

- [ ] **Step 1: 移除 import**

删除：`import '../services/pet_push_service.dart';`

- [ ] **Step 2: 移除 _pushes 字段**

删除：`List<PetPush> _pushes = [];`（约第25行）

- [ ] **Step 3: 移除 _loadContext 中的 push 加载**

在 `_loadContext()` 方法中，删除 `pushes = await ...generateDailyPushes(ctx);` 和 `_pushes = pushes;` 两行（约第71、79行）。

保留 `await _loadProactiveInsight(ctx);` 和 `await _loadPersonality(ctx);`。

- [ ] **Step 4: 移除 _buildMessageList 中的 push 卡片渲染**

在 `_buildMessageList()` 中（约第274-276行），删除：

```dart
if (_pushes.isNotEmpty) ...[
  ..._pushes.map((push) => Padding(
```

整段删除，包括对应的闭合括号。

- [ ] **Step 5: 移除 PetPushService.instance 调用**

Grep 确认文件中不再有 `PetPushService` 或 `generateDailyPushes` 引用。

- [ ] **Step 6: 运行 analyze**

```bash
/Users/openclaw/flutter/bin/flutter analyze lib/widgets/pet_bubble.dart
```
Expected: 0 errors

- [ ] **Step 7: 提交**

```bash
git add lib/widgets/pet_bubble.dart
git commit -m "refactor(pet_bubble): remove push display logic - moved to PetPushBanner"
```

---

## Task 5: 验证完整构建

- [ ] **Step 1: flutter analyze 全量**

```bash
/Users/openclaw/flutter/bin/flutter analyze lib/
```
Expected: 0 errors

- [ ] **Step 2: flutter build ios --simulator**

```bash
cd /Users/openclaw/Documents/trae_projects/change/lianlema
/Users/openclaw/flutter/bin/flutter build ios --simulator
```
Expected: Build success

- [ ] **Step 3: 提交所有修改**

```bash
git add -A
git commit -m "feat: PetPushBanner + card title unification + game-feel polish"
```
