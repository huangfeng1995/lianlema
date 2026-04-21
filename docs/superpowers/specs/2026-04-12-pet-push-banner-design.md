# 宠物推送通知栏 + 首页卡片优化

## 背景

用户反馈：二级标题不一致，且宠物推送不应以 PetBubble 展开形式展示，应改为顶部通知栏。

## 设计原则

**简约大方有游戏感** — 无多余装饰，每张卡片像一张"任务卡"，通过颜色和动效传递游戏氛围。

---

## Part 1：宠物推送通知栏（PetPushBanner）

### 行为
- 首页顶部 SafeArea 之下弹出
- 只显示优先级最高的 1 条推送
- 8 秒后自动淡出消失（AnimatedOpacity fade 300ms）
- 同一推送消失后标记为已读，本次 App 会话不再出现

### 视觉

```
┌────────────────────────────────────────────────┐
│ 🐾  今日提醒：还没打卡哦，炭炭在等你～     ✕  │
└────────────────────────────────────────────────┘
```

- 左：宠物头像 24px + 空格 + 消息文字（14px, textPrimary）
- 背景气泡：AppColors.primary 10% 透明度，圆角 20px，全宽
- 右侧关闭按钮：消失前 2 秒淡入，点击立即消失
- 内边距：水平 16px，垂直 12px

### 状态
- **显示中**：透明度 1.0，Timer 运行中
- **淡出中**：300ms fade 到 0.0，Timer 归零
- **已消失**：从 widget tree 移除

---

## Part 2：卡片标题统一

三个卡片全部使用统一标题样式：

| 标题 | 字号 | 字重 | 颜色 |
|------|------|------|------|
| 长期计划 | 16px | w600 | textPrimary |
| 本月挑战 | 16px | w600 | textPrimary |
| 今日行动 | 16px | w600 | textPrimary |

标题与内容间距 6px。

### 各卡片内容

**长期计划（_buildVisionCard）**
- 新增标题"长期计划"，16px w600 textPrimary
- 年度计划条目（primary 色圆点 + 14px w500 primary色文字）
- 愿景（textSecondary 灰圆点 + 13px textSecondary 文字）
- 反愿景（13px textSecondary）

**本月挑战（BossHpBar）**
- 已有"本月挑战"标题，符合规范，无需改动
- bossName 分号分隔的挑战条目
- 打卡进度文字（12px textSecondary）

**今日行动（_buildDailyCheckIn）**
- 已有"今日行动"标题，符合规范，无需改动
- todayLevers 行动列表

---

## Part 3：游戏感设计

### 左边框
- 长期计划：炭火橙（AppColors.primary）
- 本月挑战：琥珀色（Color(0xFFFFA500)）
- 今日行动：薄荷绿（Color(0xFF6DBF8B)）
- 宽度 3px，圆角 16px

### 打卡按钮
- 背景：AppColors.primary 实心，无阴影
- 文字：白色 14px w600
- 圆角：12px

### 圆点符号（年度计划条目）
- 颜色：AppColors.primary（炭火橙，非灰）
- 尺寸：6x6px 圆角方块

---

## 实现文件

- `lib/widgets/pet_bubble.dart` — 移除推送卡片加载/展示逻辑（推送改由通知栏）
- `lib/screens/home_screen.dart` — 添加 PetPushBanner，清理旧 PetBubble 集成
- `lib/widgets/pet_push_banner.dart` — 新建通知栏组件
- `lib/screens/home_screen.dart` — _buildVisionCard 添加"长期计划"标题
- `lib/widgets/boss_hp_bar.dart` — 无需改动

---

## 验证
1. `flutter analyze` 零 error
2. 打开首页，顶部出现气泡通知栏
3. 8 秒后自动消失
4. 三张卡片标题均为 16px w600 textPrimary，视觉一致
