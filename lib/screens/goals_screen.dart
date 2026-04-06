import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/notification_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late StorageService _storage;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String _antiVision = '';
  String _vision = '';

  // 专注提醒数据
  List<Map<String, dynamic>> _focusReminders = [];
  String _yearGoal = '';
  String _annualIdentity = '';
  List<Map<String, String>> _dailyLevers = [];
  String _constraints = '';
  MonthlyBoss? _monthlyBoss;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    _antiVision = _storage.getAntiVision();
    _vision = _storage.getVision();
    _yearGoal = _storage.getYearGoal();
    _annualIdentity = _storage.getAnnualIdentity();
    _dailyLevers = _storage.getDailyLevers();
    // 确保至少有3个槽位（不在 build 中修改状态）
    while (_dailyLevers.length < 3) {
      _dailyLevers.add({'obstacle': '', 'plan': ''});
    }
    _constraints = _storage.getConstraints();
    _monthlyBoss = _storage.getMonthlyBoss();
    _focusReminders = _storage.getFocusReminders();

    setState(() => _isLoading = false);
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      // 保存长期规划（触发徽章检查）
      await _storage.saveAntiVision(_antiVision);
      await _storage.saveVision(_vision);
      await _storage.saveYearGoal(_yearGoal);
      await _storage.saveAnnualIdentity(_annualIdentity);
      await _storage.saveConstraints(_constraints);
      await _storage.saveDailyLevers(_dailyLevers);
      if (_monthlyBoss != null) {
        await _storage.saveMonthlyBoss(_monthlyBoss!);
      }

      // 检查规划徽章
      await _storage.checkPlanningBadges();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('目标设定'),
        centerTitle: true,
        leading: const SizedBox(width: 48), // GoalsScreen 是底部 Tab 页面，无需返回按钮
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text(
                      '保存',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )
          else
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text(
                '编辑',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAntiVisionCard(),
                  const SizedBox(height: 16),
                  _buildVisionCard(),
                  const SizedBox(height: 16),
                  _buildYearGoalCard(),
                  const SizedBox(height: 16),
                  _buildAnnualIdentityCard(),
                  const SizedBox(height: 16),
                  _buildMonthlyBossCard(),
                  const SizedBox(height: 16),
                  _buildDailyLeversCard(),
                  const SizedBox(height: 16),
                  _buildConstraintsCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildAntiVisionCard() {
    return _buildCard(
      icon: Icons.warning,
      iconColor: const Color(0xFF888888),
      title: '反愿景',
      subtitle: '可随时修改',
      subtitleColor: AppColors.textSecondary,
      content: _antiVision,
      isLocked: false,
      canEdit: _isEditing,
      onEditChanged: (v) => _antiVision = v,
      borderColor: AppColors.textLight.withValues(alpha: 0.3),
      hintText: '描述你最不想成为的人、最不想过的生活',
    );
  }

  Widget _buildVisionCard() {
    return _buildCard(
      icon: Icons.auto_awesome,
      iconColor: AppColors.primary,
      title: '愿景',
      subtitle: '可随时修改',
      subtitleColor: AppColors.textSecondary,
      content: _vision,
      isLocked: false,
      canEdit: _isEditing,
      onEditChanged: (v) => _vision = v,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      hintText: '描述你理想中的一年后的生活',
    );
  }

  Widget _buildYearGoalCard() {
    return _buildCard(
      icon: Icons.flag,
      iconColor: AppColors.primary,
      title: '一年目标',
      subtitle: '每年可改1次',
      subtitleColor: AppColors.primary,
      content: _yearGoal,
      isLocked: false,
      canEdit: _isEditing,
      onEditChanged: (v) => _yearGoal = v,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
    );
  }

  Widget _buildAnnualIdentityCard() {
    return _buildCard(
      icon: Icons.star,
      iconColor: AppColors.primary,
      title: '年度身份',
      subtitle: '我是_____的行动派',
      subtitleColor: AppColors.primary,
      content: _annualIdentity,
      isLocked: false,
      canEdit: _isEditing,
      onEditChanged: (v) => _annualIdentity = v,
      hintText: '例如：早起读书、持续运动、写作',
      borderColor: AppColors.primary.withValues(alpha: 0.3),
    );
  }

  Widget _buildMonthlyBossCard() {
    final boss = _monthlyBoss;
    final now = DateTime.now();
    final hp = boss != null && boss.month == now.month && boss.year == now.year
        ? boss.hp
        : 0;
    final total = boss != null && boss.month == now.month && boss.year == now.year
        ? boss.totalDays
        : appDateDaysInMonth(now);
    final bossContent = boss != null && boss.month == now.month && boss.year == now.year
        ? boss.content
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: const Icon(Icons.whatshot, size: 18, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本月挑战',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'HP: $hp/$total',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bossContent.isNotEmpty ? bossContent : '设置你的本月挑战目标',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? hp / total : 0,
                    backgroundColor: AppColors.textLight.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showEditBossDialog(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '设置/更换Boss目标',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int appDateDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  void _showEditBossDialog() {
    final controller = TextEditingController(
      text: _monthlyBoss != null ? _monthlyBoss!.content : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('设置本月挑战'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '例如：每天运动30分钟',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final now = DateTime.now();
              _monthlyBoss = MonthlyBoss(
                content: controller.text,
                month: now.month,
                year: now.year,
                totalDays: appDateDaysInMonth(now),
                hp: 0,
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLeversCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(Icons.build, size: 18, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '每日杠杆',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      '每天可调整',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_dailyLevers.length, (index) {
            final hasContent = (_dailyLevers[index]['plan'] ?? '').isNotEmpty;
            final leverId = 'lever_$index';
            final hasReminder = _focusReminders.any((r) => r['leverId'] == leverId);
            final reminder = hasReminder ? _focusReminders.firstWhere((r) => r['leverId'] == leverId) : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: hasContent ? () => _showFocusReminderSheet(index) : null,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: hasContent
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.textLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasContent ? AppColors.primary : AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _isEditing
                          ? TextField(
                              decoration: const InputDecoration(
                                hintText: '添加杠杆...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              controller: TextEditingController(text: _dailyLevers[index]['plan'] ?? ''),
                              onChanged: (v) => _dailyLevers[index]['plan'] = v,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasContent ? _dailyLevers[index]['plan']! : '未设置',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: hasContent ? AppColors.textPrimary : AppColors.textLight,
                                  ),
                                ),
                                if (hasReminder && reminder != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.notifications_active, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(reminder['hour'] as int).toString().padLeft(2, '0')}:${(reminder['minute'] as int).toString().padLeft(2, '0')} · ${reminder['duration']}分钟',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                    ),
                    if (hasContent && !_isEditing) ...[
                      const SizedBox(width: 8),
                      Icon(
                        hasReminder ? Icons.notifications_active : Icons.notifications_none,
                        size: 20,
                        color: hasReminder ? AppColors.primary : AppColors.textLight,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConstraintsCard() {
    return _buildCard(
      icon: Icons.block,
      iconColor: const Color(0xFF888888),
      title: '约束条件',
      subtitle: '可随时修改',
      subtitleColor: AppColors.textSecondary,
      content: _constraints,
      isLocked: false,
      canEdit: _isEditing,
      onEditChanged: (v) => _constraints = v,
      borderColor: AppColors.textLight.withValues(alpha: 0.3),
      hintText: '哪些原则是你绝对不能打破的？',
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required String content,
    bool isLocked = false,
    bool canEdit = false,
    Function(String)? onEditChanged,
    Color? borderColor,
    String? hintText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, size: 18, color: iconColor),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: AppColors.textLight),
                      SizedBox(width: 4),
                      Text(
                        '锁定',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: canEdit
                ? TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: hintText ?? '请输入...',
                      border: InputBorder.none,
                    ),
                    controller: TextEditingController(text: content),
                    onChanged: onEditChanged,
                  )
                : Text(
                    content.isNotEmpty ? content : '暂无内容',
                    style: TextStyle(
                      fontSize: 14,
                      color: content.isNotEmpty ? AppColors.textPrimary : AppColors.textLight,
                      height: 1.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 显示专注提醒设置
  void _showFocusReminderSheet(int index) {
    if (index >= _dailyLevers.length || (_dailyLevers[index]['plan'] ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先填写杠杆内容'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 检查是否已有提醒
    final existingReminder = _focusReminders.where((r) => r['leverId'] == 'lever_$index').toList();
    final hasReminder = existingReminder.isNotEmpty;
    int selectedHour = hasReminder ? existingReminder.first['hour'] : 9;
    int selectedMinute = hasReminder ? existingReminder.first['minute'] : 0;
    int selectedDuration = hasReminder ? existingReminder.first['duration'] : 25;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasReminder ? '修改专注提醒' : '设置专注提醒',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _dailyLevers[index]['plan'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              // 时间选择
              const Text(
                '开始时间',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: selectedHour, minute: selectedMinute),
                  );
                  if (time != null) {
                    setSheetState(() {
                      selectedHour = time.hour;
                      selectedMinute = time.minute;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Icon(Icons.access_time, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 时长选择
              const Text(
                '持续时间',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: StorageService.focusDurations.map((duration) {
                  final isSelected = selectedDuration == duration;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() => selectedDuration = duration);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$duration分钟',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // 操作按钮
              Row(
                children: [
                  if (hasReminder)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _removeFocusReminder(index);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('删除提醒'),
                      ),
                    ),
                  if (hasReminder) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _saveFocusReminder(index, selectedHour, selectedMinute, selectedDuration);
                      },
                      child: Text(hasReminder ? '修改' : '保存'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFocusReminder(int index, int hour, int minute, int duration) async {
    final leverContent = _dailyLevers[index]['plan'] ?? '';
    final leverId = 'lever_$index';

    // 保存到storage
    await _storage.addFocusReminder(leverId, leverContent, hour, minute, duration);

    // 调度通知
    final notificationService = await NotificationService.getInstance();
    await notificationService.scheduleFocusReminder(
      leverIndex: index,
      content: leverContent,
      hour: hour,
      minute: minute,
      durationMinutes: duration,
    );

    // 更新本地状态
    _focusReminders = _storage.getFocusReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已设置 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} 开始，$duration分钟后提醒'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _removeFocusReminder(int index) async {
    final leverId = 'lever_$index';

    // 从storage删除
    await _storage.removeFocusReminder(leverId);

    // 取消通知
    final notificationService = await NotificationService.getInstance();
    await notificationService.cancelFocusReminder(index);

    // 更新本地状态
    _focusReminders = _storage.getFocusReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已删除专注提醒'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
