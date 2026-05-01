import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/notification_service.dart';
import '../utils/pet_service.dart';
import '../models/goal_templates.dart';

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

  // AI 拆解状态
  bool _isDecomposing = false;

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

    // 自动触发 AI 拆解：有月度挑战但行动为空或只有占位符
    if (_monthlyBoss != null && _monthlyBoss!.content.isNotEmpty) {
      final hasUserAction = _dailyLevers.any((l) => (l['plan'] ?? '').trim().isNotEmpty);
      if (!hasUserAction) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _decomposeBossWithAI());
      }
    }
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
                  if (!_isEditing && _antiVision.isEmpty && _vision.isEmpty) ...[
                    const SizedBox(height: 4),
                    _buildTemplateSelector(),
                  ],
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
      borderColor: AppColors.textLight.withOpacity( 0.3),
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
      borderColor: AppColors.primary.withOpacity( 0.3),
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
      borderColor: AppColors.primary.withOpacity( 0.3),
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
      borderColor: AppColors.primary.withOpacity( 0.3),
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
          color: AppColors.primary.withOpacity( 0.3),
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
                  color: AppColors.primary.withOpacity( 0.1),
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
              color: AppColors.primary.withOpacity( 0.05),
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
                    backgroundColor: AppColors.textLight.withOpacity( 0.2),
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
                  color: AppColors.primary.withOpacity( 0.1),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '例如：每天运动30分钟',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '保存后可点击「AI智能拆解」生成每日行动',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity( 0.7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final now = DateTime.now();
              final newContent = controller.text.trim();
              _monthlyBoss = MonthlyBoss(
                content: newContent,
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

  /// 调用 AI 智能拆解：根据月度挑战生成每日行动
  Future<void> _decomposeBossWithAI() async {
    if (_monthlyBoss == null || _monthlyBoss!.content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先设置本月挑战目标'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isDecomposing = true);

    try {
      final result = await PetService.instance
          .decomposeGoals([_monthlyBoss!.content])
          .timeout(const Duration(seconds: 15));

      if (result.monthlyChallenges.isNotEmpty || result.dailyActionsPerChallenge.isNotEmpty) {
        // 合并所有挑战的每日行动
        final allActions = <String>[];
        for (final actions in result.dailyActionsPerChallenge.values) {
          allActions.addAll(actions);
        }

        if (allActions.isNotEmpty) {
          setState(() {
            // 更新每日杠杆
            _dailyLevers = allActions.take(5).map((a) => {
              'obstacle': '',
              'plan': a,
            }).toList();
            // 确保至少有3个槽位
            while (_dailyLevers.length < 3) {
              _dailyLevers.add({'obstacle': '', 'plan': ''});
            }
          });

          // 自动保存
          await _saveDailyLevers();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已生成 ${allActions.take(5).length} 条每日行动 ✨'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('拆解结果为空，请手动设置每日行动'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('拆解超时，请手动设置每日行动'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拆解失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDecomposing = false);
    }
  }

  Future<void> _saveDailyLevers() async {
    // 过滤掉空的杠杆
    final validLevers = _dailyLevers.where((l) => (l['plan'] ?? '').trim().isNotEmpty).toList();
    if (validLevers.isEmpty) return;

    await _storage.saveDailyLevers(validLevers);

    // 同时更新 dailyActions
    final dailyActions = validLevers.map((l) => l['plan'] ?? '').toList();
    await _storage.saveDailyActions(dailyActions);
  }

  Widget _buildDailyLeversCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity( 0.3),
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
                  color: AppColors.primary.withOpacity( 0.1),
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
                            ? AppColors.primary.withOpacity( 0.1)
                            : AppColors.textLight.withOpacity( 0.1),
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
                      GestureDetector(
                        onTap: () => _showObstacleDialog(index),
                        child: Icon(
                          (_dailyLevers[index]['obstacle'] ?? '').isNotEmpty
                              ? Icons.psychology
                              : Icons.psychology_outlined,
                          size: 20,
                          color: (_dailyLevers[index]['obstacle'] ?? '').isNotEmpty
                              ? AppColors.primary
                              : AppColors.textLight,
                        ),
                      ),
                    ],
                    // 显示障碍内容（如果有）
                    if ((_dailyLevers[index]['obstacle'] ?? '').isNotEmpty && !_isEditing) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, size: 12, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '障碍：${_dailyLevers[index]['obstacle']}',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
          // AI 智能拆解按钮
          if (!_isEditing && _monthlyBoss != null && _monthlyBoss!.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isDecomposing ? null : _decomposeBossWithAI,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity( 0.1),
                      const Color(0xFFFF6B35).withOpacity( 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity( 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isDecomposing)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B35)),
                      )
                    else
                      const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFFF6B35)),
                    const SizedBox(width: 6),
                    Text(
                      _isDecomposing ? 'AI 拆解中...' : 'AI 智能拆解',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      borderColor: AppColors.textLight.withOpacity( 0.3),
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
          color: borderColor ?? AppColors.primary.withOpacity( 0.3),
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
                  color: iconColor.withOpacity( 0.1),
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
                    color: AppColors.textLight.withOpacity( 0.1),
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

  Widget _buildTemplateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 不知道定什么目标？试试模板',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: GoalTemplates.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, index) {
              final template = GoalTemplates.all[index];
              return _buildTemplateCard(template);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(GoalTemplate template) {
    return GestureDetector(
      onTap: () => _applyTemplate(template),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity( 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              template.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              template.description,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _applyTemplate(GoalTemplate template) {
    setState(() {
      _antiVision = template.antiVision;
      _vision = template.vision;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(template.emoji),
            const SizedBox(width: 8),
            Text('已选择「${template.name}」模板，可点击编辑完善'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
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

  /// 显示障碍设置对话框
  Future<void> _showObstacleDialog(int index) async {
    if (index >= _dailyLevers.length || (_dailyLevers[index]['plan'] ?? '').isEmpty) {
      return;
    }

    final controller = TextEditingController(text: _dailyLevers[index]['obstacle'] ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.psychology, color: AppColors.primary),
            SizedBox(width: 8),
            Text('设置障碍', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '计划：${_dailyLevers[index]['plan']}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text('阻碍你行动的内心障碍是什么？', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: '例如：太累了、没时间、觉得没意义...',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '说不清楚也可以不填～',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('保存'),
          ),
        ],
      ),
    );

    if (result != null) {
      _dailyLevers[index]['obstacle'] = result;
      await _storage.saveDailyLevers(_dailyLevers);
      setState(() {});
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
