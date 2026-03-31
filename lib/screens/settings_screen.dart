import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../utils/notification_service.dart';
import '../main.dart';
import 'splash_screen.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 提醒时间（小时，分钟）
  int _reminderHour = 21;
  int _reminderMinute = 0;

  // 极简模式
  bool _minimalMode = false;

  // 暗色模式
  bool _darkMode = false;

  // 通知开关
  bool _notificationsEnabled = true;

  // App版本号
  final String _appVersion = '1.0.0';

  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _storage = storage;
      _minimalMode = storage.getMinimalMode();
      _darkMode = storage.getDarkMode();
      _reminderHour = storage.getReminderHour();
      _reminderMinute = storage.getReminderMinute();
      _notificationsEnabled = storage.getNotificationsEnabled();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildSectionHeader('提醒'),
            _buildReminderTimeItem(),
            const SizedBox(height: 24),
            _buildSectionHeader('显示'),
            _buildSwitchItem(
              icon: '☀️',
              title: '极简模式',
              subtitle: '隐藏打卡动画和特效',
              value: _minimalMode,
              onChanged: (value) async {
                setState(() => _minimalMode = value);
                if (_storage != null) {
                  await _storage!.saveMinimalMode(value);
                }
              },
            ),
            _buildSwitchItem(
              icon: '🌙',
              title: '暗色模式',
              subtitle: '深色主题',
              value: _darkMode,
              onChanged: (value) async {
                setState(() => _darkMode = value);
                await appKey.currentState?.toggleDarkMode(value);
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('通知'),
            _buildSwitchItem(
              icon: '🔔',
              title: '通知开关',
              subtitle: '接收打卡提醒和成就通知',
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await _storage?.saveNotificationsEnabled(value);

                // 根据开关状态启用或取消通知
                final notificationService = await NotificationService.getInstance();
                if (value) {
                  await notificationService.scheduleAllReports();
                } else {
                  await notificationService.cancelAllReportNotifications();
                }
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('数据'),
            _buildDangerItem(
              icon: '🗑️',
              title: '清空所有数据',
              subtitle: '重新开始',
              onTap: _showResetDataDialog,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('关于'),
            _buildInfoItem(
              icon: '📋',
              title: '版本号',
              trailing: Text(
                _appVersion,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: '📖',
              title: '使用条款',
              onTap: () => _showComingSoon('使用条款'),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: '🔒',
              title: '隐私政策',
              onTap: () => _showComingSoon('隐私政策'),
            ),
            const SizedBox(height: 40),
            _buildFooter(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildReminderTimeItem() {
    return _buildSettingsCard([
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text('⏰', style: TextStyle(fontSize: 18)),
          ),
        ),
        title: const Text(
          '提醒时间',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _formatTime(_reminderHour, _reminderMinute),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textLight,
        ),
        onTap: () => _showTimePicker(),
      ),
    ]);
  }

  Widget _buildSwitchItem({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingsCard([
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ),
    ]);
  }

  Widget _buildInfoItem({
    required String icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return _buildSettingsCard([
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
            ),
        onTap: onTap,
      ),
    ]);
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '练',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '练了吗',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '每天行动，成为想成为的人',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.textLight.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Text(
                    '选择提醒时间',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '确定',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  2024,
                  1,
                  1,
                  _reminderHour,
                  _reminderMinute,
                ),
                onDateTimeChanged: (DateTime newDateTime) async {
                  setState(() {
                    _reminderHour = newDateTime.hour;
                    _reminderMinute = newDateTime.minute;
                  });
                  await _storage?.saveReminderTime(_reminderHour, _reminderMinute);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 开发中'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDangerItem({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🗑️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('清空所有数据'),
          ],
        ),
        content: const Text(
          '这将删除所有你的打卡记录、目标和设置，此操作不可恢复。\n\n确定要重新开始吗？',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('确定清空'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    // 取消所有通知
    final notificationService = await NotificationService.getInstance();
    await notificationService.cancelAllReportNotifications();

    // 清空SharedPreferences（保留极简模式和暗色模式设置）
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('dark_mode') ?? false;
    final minimalMode = prefs.getBool('minimal_mode') ?? false;

    await prefs.clear();

    // 恢复部分设置
    await prefs.setBool('dark_mode', darkMode);
    await prefs.setBool('minimal_mode', minimalMode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('数据已清空，正在重启...'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      // 重置 StorageService 单例，让它重新初始化
      StorageService.resetInstance();
      
      // 跳转到 SplashScreen 并清除所有导航栈
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,  // 清除所有历史导航栈
        );
      }
    }
  }
}
