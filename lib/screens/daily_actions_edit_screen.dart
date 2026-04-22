import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../utils/pet_service.dart';

class DailyActionsEditScreen extends StatefulWidget {
  const DailyActionsEditScreen({super.key});

  @override
  State<DailyActionsEditScreen> createState() => _DailyActionsEditScreenState();
}

class _DailyActionsEditScreenState extends State<DailyActionsEditScreen> {
  StorageService? _storage;
  bool _isSaving = false;
  bool _dataLoaded = false;

  // 今日行动列表 - 每个行动包含 plan 和 obstacle
  List<Map<String, String>> _dailyActions = [{'plan': '', 'obstacle': ''}];
  List<TextEditingController> _planControllers = [];
  List<TextEditingController> _obstacleControllers = [];
  List<TextEditingController> _ifThenControllers = [];
  List<bool> _expanded = []; // 跟踪每个行动项是否展开

  @override
  void initState() {
    super.initState();
    _planControllers = [TextEditingController()];
    _obstacleControllers = [TextEditingController()];
    _ifThenControllers = [TextEditingController()];
    _expanded = [false];
    // 先显示表单，再异步加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final storage = await StorageService.getInstance();
      if (!mounted) return;

      // 加载今日行动
      final levers = storage.getDailyLevers();
      if (levers.isNotEmpty) {
        _dailyActions = levers.map((l) => {
          'plan': l['plan'] ?? '',
          'obstacle': l['obstacle'] ?? '',
        }).toList();
        // 添加一个额外的空输入框
        _dailyActions.add({'plan': '', 'obstacle': ''});
      } else {
        _dailyActions = [{'plan': '', 'obstacle': ''}];
      }

      // 重建 controllers
      for (final c in _planControllers) c.dispose();
      for (final c in _obstacleControllers) c.dispose();
      for (final c in _ifThenControllers) c.dispose();

      _planControllers = _dailyActions.map((a) => TextEditingController(text: a['plan'])).toList();
      _obstacleControllers = _dailyActions.map((a) {
        final obstacle = a['obstacle'] ?? '';
        // 解析"如果X，我就Y"格式
        if (obstacle.startsWith('如果')) {
          final commaIndex = obstacle.indexOf('，我就');
          if (commaIndex != -1) {
            return TextEditingController(text: obstacle.substring(2, commaIndex));
          }
        }
        return TextEditingController(text: obstacle);
      }).toList();
      _ifThenControllers = _dailyActions.map((a) {
        final obstacle = a['obstacle'] ?? '';
        // 解析"如果X，我就Y"格式
        if (obstacle.startsWith('如果')) {
          final commaIndex = obstacle.indexOf('，我就');
          if (commaIndex != -1) {
            return TextEditingController(text: obstacle.substring(commaIndex + 3));
          }
        }
        return TextEditingController(text: '');
      }).toList();

      // 初始化展开状态：如果有 obstacle 内容则展开
      _expanded = _dailyActions.map((a) {
        final obstacle = a['obstacle'] ?? '';
        return obstacle.isNotEmpty;
      }).toList();

      _storage = storage;
      if (mounted) setState(() => _dataLoaded = true);
    } catch (e) {
      debugPrint('[DailyActionsEditScreen] loadData error: $e');
      if (mounted) setState(() => _dataLoaded = true);
    }
  }

  @override
  void dispose() {
    for (final c in _planControllers) c.dispose();
    for (final c in _obstacleControllers) c.dispose();
    for (final c in _ifThenControllers) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final storage = _storage ?? await StorageService.getInstance();
    setState(() => _isSaving = true);

    try {
      final actions = <Map<String, String>>[];
      for (int i = 0; i < _planControllers.length; i++) {
        final plan = _planControllers[i].text.trim();
        if (plan.isNotEmpty) {
          final obstacle = _obstacleControllers[i].text.trim();
          final ifThen = _ifThenControllers[i].text.trim();
          actions.add({
            'plan': plan,
            'obstacle': obstacle.isNotEmpty && ifThen.isNotEmpty
                ? PetService.instance.formatIfThen(obstacle, ifThen)
                : obstacle,
          });
        }
      }

      await storage.saveDailyLevers(actions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '今日行动',
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8533A)),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE8533A)),
                  ),
          ),
        ],
        elevation: 0,
      ),
      body: !_dataLoaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== 今日行动 =====
                  _buildSectionHeader('今日行动', Icons.checklist_outlined, '每天2-3件高优先级事'),
                  const SizedBox(height: 12),
                  ...List.generate(_dailyActions.length, (index) {
                    final hasObstacleContent = _obstacleControllers.length > index && _obstacleControllers[index].text.isNotEmpty;
                    final hasIfThenContent = _ifThenControllers.length > index && _ifThenControllers[index].text.isNotEmpty;
                    final shouldExpand = _expanded.length > index && (_expanded[index] || hasObstacleContent || hasIfThenContent);

                    return Padding(
                      padding: EdgeInsets.only(bottom: index < _dailyActions.length - 1 ? 16 : 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 主任务输入
                                TextField(
                                  controller: index < _planControllers.length ? _planControllers[index] : null,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: '例如：写500字，联系3个客户...',
                                    hintStyle: TextStyle(
                                      color: AppColors.textLight.withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: AppColors.textLight.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: AppColors.textLight.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                // 展开/收起按钮
                                if (!shouldExpand)
                                  GestureDetector(
                                    onTap: () {
                                      if (_expanded.length <= index) {
                                        _expanded.add(true);
                                      } else {
                                        _expanded[index] = true;
                                      }
                                      setState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '添加应对方案',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // 如果...我就... 输入（展开时显示）
                                if (shouldExpand) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '如果...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            TextField(
                                              controller: index < _obstacleControllers.length ? _obstacleControllers[index] : null,
                                              maxLines: 1,
                                              decoration: InputDecoration(
                                                hintText: '什么情况下容易放弃？',
                                                hintStyle: TextStyle(
                                                  color: AppColors.textLight.withValues(alpha: 0.6),
                                                  fontSize: 12,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: AppColors.textLight.withValues(alpha: 0.2),
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: AppColors.textLight.withValues(alpha: 0.2),
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                    color: AppColors.primary,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                isDense: true,
                                              ),
                                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '我就...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            TextField(
                                              controller: index < _ifThenControllers.length ? _ifThenControllers[index] : null,
                                              maxLines: 1,
                                              decoration: InputDecoration(
                                                hintText: '你会怎么做？',
                                                hintStyle: TextStyle(
                                                  color: AppColors.textLight.withValues(alpha: 0.6),
                                                  fontSize: 12,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: AppColors.textLight.withValues(alpha: 0.2),
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: AppColors.textLight.withValues(alpha: 0.2),
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                    color: AppColors.primary,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                isDense: true,
                                              ),
                                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_dailyActions.length > 1)
                            GestureDetector(
                              onTap: () {
                                _planControllers[index].dispose();
                                _obstacleControllers[index].dispose();
                                _ifThenControllers[index].dispose();
                                _planControllers.removeAt(index);
                                _obstacleControllers.removeAt(index);
                                _ifThenControllers.removeAt(index);
                                if (_expanded.length > index) {
                                  _expanded.removeAt(index);
                                }
                                setState(() => _dailyActions.removeAt(index));
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6, top: 10),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.textLight.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      if (_dailyActions.length >= 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('行动不宜过多，聚焦最重要的事效果更好'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _dailyActions.add({'plan': '', 'obstacle': ''});
                        _planControllers.add(TextEditingController());
                        _obstacleControllers.add(TextEditingController());
                        _ifThenControllers.add(TextEditingController());
                        _expanded.add(false);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Text(
                            '添加行动',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
