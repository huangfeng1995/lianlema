# 练了吗

> 从今天开始发生改变

一个帮助职场人「发生真实改变」的App。通过每日打卡、游戏化等级系统、月度Boss战和复盘流程，帮助用户养成持续行动的习惯。

## 核心功能

### 🎯 六组件系统
- **反愿景** - 你不想成为什么样的人（锁定1年）
- **愿景** - 你想成为什么样的人（锁定1年）
- **一年目标** - 年度核心目标（每年可改1次）
- **月度Boss战** - 月度挑战目标（每月可改1次）
- **每日杠杆** - 2-3件关键行动（每天可调）
- **约束条件** - 坚定遵守的底线（锁定1年）

### 🎮 游戏化系统
- XP 等级体系（Lv.1 初出茅庐 → Lv.100+ 登峰造极）
- 10个徽章（初醒 → 连续100天 → 年度冠军）
- Streak 连续打卡天数
- 月度Boss HP系统
- 彩纸庆祝动画

### 📊 报告与复盘
- **日报** - 今日行动 + 今日一刻（可选睡前记录）
- **周报** - 本周回顾 + 周复盘（感激 + 下周计划）
- **月报** - 月度战报 + 月度复盘（4步骤）
- **年报** - 年度战报 + 年度复盘（4步骤）

### 🔧 功能特性
- 深色模式
- 极简模式
- 每日提醒通知
- 数据导出
- Streak补救机制（每月1次）

## 技术栈

- **Flutter** - 跨平台UI框架
- **SharedPreferences** - 本地数据存储
- **flutter_local_notifications** - 本地通知

## 项目结构

```
lib/
├── main.dart                 # App入口
├── models/                   # 数据模型
│   └── models.dart
├── screens/                  # 页面
│   ├── home_screen.dart      # 首页
│   ├── goals_screen.dart     # 目标编辑
│   ├── profile_screen.dart    # 我的页面
│   ├── onboarding_screen.dart # 引导流程
│   └── ...
├── services/                 # 服务
├── theme/                    # 主题
│   └── app_theme.dart
├── utils/                    # 工具
│   ├── storage_service.dart  # 存储
│   ├── notification_service.dart # 通知
│   ├── xp_service.dart       # XP计算
│   └── date_utils.dart       # 日期工具
└── widgets/                  # 组件
    ├── bottom_nav_bar.dart
    └── pressed_button.dart
```

## 开发

```bash
# 安装依赖
flutter pub get

# 运行
flutter run

# 构建iOS
flutter build ios --simulator --no-codesign
```

## 版本

- v0.1 - HTML原型
- v0.2 - 产品规格文档
- v0.3 - Flutter开发中

## License

Private
