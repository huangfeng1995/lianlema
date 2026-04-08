import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../widgets/boss_hp_bar.dart';

class MonthlyBossEditScreen extends StatefulWidget {
  const MonthlyBossEditScreen({super.key});

  @override
  State<MonthlyBossEditScreen> createState() => _MonthlyBossEditScreenState();
}

class _MonthlyBossEditScreenState extends State<MonthlyBossEditScreen> {
  late StorageService _storage;
  bool _isLoading = true;
  bool _isSaving = false;

  // 所有 Boss keys（template name 或 custom_0, custom_1...）
  late List<String> _bossKeys = [];

  // 每个 Boss 的行动控制器 Map
  late Map<String, List<TextEditingController>> _actionControllers;

  // Boss 内容（用于显示）
  late Map<String, String> _bossContents = {};

  // Boss hp 信息
  MonthlyBoss? _boss;

  // 模板定义（用于获取 desc 和 hints）
  final List<Map<String, String>> _bossTemplates = [
    {'name': '读完一本书', 'desc': '本月读完一本书'},
    {'name': '培养早起习惯', 'desc': '连续早起21天'},
    {'name': '学会Python', 'desc': 'Python基础入门'},
    {'name': '养成运动习惯', 'desc': '每周运动3次'},
  ];

  @override
  void initState() {
    super.initState();
    _actionControllers = {};
    _bossContents = {};
    _loadData();
  }

  String _getBossDesc(String key) {
    // 如果是默认key，直接用boss内容里的对应项
    if (key == 'default') {
      return _bossContents[key] ?? '月度挑战';
    }
    if (key.startsWith('custom_')) {
      final idx = int.tryParse(key.substring(7)) ?? 0;
      // 如果内容已经加载过，优先用已加载的内容
      if (_bossContents.containsKey(key) && _bossContents[key]!.isNotEmpty) {
        return _bossContents[key]!;
      }
      final customs = _storage.getCustomBosses();
      if (idx < customs.length) return customs[idx];
      return '自定义挑战';
    }
    // 如果内容已经加载过，优先用已加载的内容
    if (_bossContents.containsKey(key) && _bossContents[key]!.isNotEmpty) {
      return _bossContents[key]!;
    }
    final t = _bossTemplates.firstWhere(
      (t) => t['name'] == key,
      orElse: () => {'desc': key},
    );
    return t['desc']!;
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();

    // 加载 Boss HP 信息
    final now = DateTime.now();
    final boss = _storage.getMonthlyBoss();
    if (boss != null && boss.month == now.month && boss.year == now.year) {
      _boss = boss;
    }

    // 加载 bossTasks（per-boss 每日行动）
    final bossTasks = _storage.getBossTasks();

    // 加载已选的 Boss 类型
    final selectedTypes = _storage.getSelectedBossTypes();
    final customBosses = _storage.getCustomBosses();

    _bossKeys = [];
    _bossKeys.addAll(selectedTypes);
    for (var i = 0; i < customBosses.length; i++) {
      if (customBosses[i].trim().isNotEmpty) {
        _bossKeys.add('custom_$i');
      }
    }

    // 如果没有任何 boss（兼容旧数据）
    if (_bossKeys.isEmpty && boss != null) {
      _bossKeys = ['default'];
    }

    // 初始化每个 boss 的控制器
    _actionControllers = {};
    for (final key in _bossKeys) {
      final actions = bossTasks[key] ?? [];
      if (actions.isEmpty) {
        _actionControllers[key] = [TextEditingController()];
      } else {
        _actionControllers[key] = actions.map((a) => TextEditingController(text: a)).toList();
      }
    }

    // 加载 boss 内容（从 monthlyBoss.content 解析，或从 customBosses）
    _bossContents = {};
    if (_boss != null) {
      final parts = _boss!.content.split('；');
      for (var i = 0; i < _bossKeys.length && i < parts.length; i++) {
        _bossContents[_bossKeys[i]] = parts[i].trim();
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addAction(String bossKey) {
    if (_actionControllers[bossKey]!.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('每个挑战最多5个行动'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() {
      _actionControllers[bossKey]!.add(TextEditingController());
    });
  }

  void _removeAction(String bossKey, int index) {
    if (_actionControllers[bossKey]!.length <= 1) return;
    setState(() {
      _actionControllers[bossKey]![index].dispose();
      _actionControllers[bossKey]!.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 收集每个 boss 的非空行动
      final bossTasks = <String, List<String>>{};
      final contentParts = <String>[];

      for (final key in _bossKeys) {
        final actions = _actionControllers[key]!
            .map((c) => c.text.trim())
            .where((a) => a.isNotEmpty)
            .toList();
        if (actions.isNotEmpty) {
          bossTasks[key] = actions;
          // 第一个行动作为 boss 的描述
          contentParts.add(actions.first);
        }
      }

      final now = DateTime.now();

      // 保存 monthlyBoss
      if (bossTasks.isNotEmpty) {
        final updatedBoss = MonthlyBoss(
          content: contentParts.join('；'),
          month: now.month,
          year: now.year,
          totalDays: DateTime(now.year, now.month + 1, 0).day,
          hp: _boss?.hp ?? 0,
        );
        await _storage.saveMonthlyBoss(updatedBoss);
      }

      // 保存 per-boss 行动
      await _storage.saveBossTasks(bossTasks);

      // 展平保存到 dailyActions 和 dailyLevers（兼容其他读取）
      final allActions = bossTasks.values.expand((a) => a).toList();
      await _storage.saveDailyActions(allActions);
      await _storage.saveDailyLevers(
        allActions.map((a) => {'obstacle': '', 'plan': a}).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功 ✨'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controllers in _actionControllers.values) {
      for (final c in controllers) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '编辑月度挑战',
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
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
          ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HP 状态
                  if (_boss != null) ...[
                    BossHpBar(
                      currentHp: _boss!.hp,
                      maxHp: _boss!.totalDays,
                      bossName: _boss!.content,
                      currentMonth: _boss!.month,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 每个 Boss 的编辑区块
                  if (_bossKeys.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          '暂无挑战数据，请在设置中添加',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._bossKeys.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final key = entry.value;
                      final desc = _getBossDesc(key);
                      final controllers = _actionControllers[key] ?? [];
                      final circledNumbers = ['①', '②', '③', '④', '⑤'];

                      return Container(
                        margin: EdgeInsets.only(bottom: idx < _bossKeys.length - 1 ? 20 : 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.textLight.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Boss 标签
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.15),
                                    AppColors.primaryLight.withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      desc,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 每日行动提示
                            Row(
                              children: [
                                const Text(
                                  '每日行动',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _addAction(key),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF8E53).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 12, color: Color(0xFFFF8E53)),
                                        SizedBox(width: 2),
                                        Text(
                                          '添加',
                                          style: TextStyle(fontSize: 11, color: Color(0xFFFF8E53), fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 行动输入框
                            ...List.generate(controllers.length, (actionIdx) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: actionIdx < controllers.length - 1 ? 10 : 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      margin: const EdgeInsets.only(top: 7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF8E53).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          circledNumbers[actionIdx],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFFF8E53),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: controllers[actionIdx],
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                        decoration: InputDecoration(
                                          hintText: '这个行动要做什么？',
                                          hintStyle: TextStyle(fontSize: 12, color: AppColors.textLight.withValues(alpha: 0.6)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2), width: 1.5),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2), width: 1.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFFFF8E53), width: 2),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    if (controllers.length > 1)
                                      GestureDetector(
                                        onTap: () => _removeAction(key, actionIdx),
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 6, top: 9),
                                          child: Icon(
                                            Icons.close,
                                            size: 18,
                                            color: AppColors.textLight.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
