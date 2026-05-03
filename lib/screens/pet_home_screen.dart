import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/pet_models.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../utils/icon_utils.dart';
import 'pet_evolution_screen.dart';

/// 宠物主页 — 淘宝AI助手卡片风格
/// 顶部标题 + 宠物大卡片（站立平台光效） + 底部横向滑动互动按钮
class PetHomeScreen extends StatefulWidget {
  const PetHomeScreen({super.key});

  @override
  State<PetHomeScreen> createState() => _PetHomeScreenState();
}

class _PetHomeScreenState extends State<PetHomeScreen> {
  late StorageService _storage;
  bool _initialized = false;
  String _petName = '炭炭';
  int _coins = 50;
  String? _equippedCostume;
  List<String> _equippedDecorations = [];
  List<PetOwnedItem> _ownedItems = [];
  String _petEmoji = '🦊';
  int _appearanceLevel = 1;
  int _intimacy = 0;
  int _intimacyLevel = 1;
  String _intimacyName = '初次见面';
  int _streakDays = 0;
  PetPersonality? _personality;
  List<PetMemoryHighlight> _memoryHighlights = [];
  int _unallocatedPoints = 0;
  bool _showAllocatePanel = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 页面每次显示时都重新加载数据
    if (_initialized) {
      _loadData();
    }
  }

  /// 显示宠物领养对话框
  void _showAdoptionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PetAdoptionDialog(
        onAdopted: _onPetAdopted,
      ),
    );
  }

  Future<void> _onPetAdopted(String petType, String petName) async {
    final petConfig = getPetTypeConfig(petType);
    if (petConfig == null) return;
    final currentSoul = _storage.getPetSoul();
    await _storage.savePetAdoptDate(DateTime.now());
    await _storage.savePetType(petType);
    await _storage.savePetName(petName);
    final personality = PetPersonality.random();
    await _storage.savePetPersonality(personality);
    await _storage.savePetPersonalityLevel(1);
    await _storage.savePetUnallocatedPoints(0);
    await _storage.savePetSoul(PetSoul(
      name: petName,
      personality: personality.archetype, // PetPersonality.archetype is a String
      speakingStyle: currentSoul.speakingStyle,
      tone: currentSoul.tone,
      useEmoji: currentSoul.useEmoji,
      defaultGreeting: petConfig.greeting,
      type: petConfig.type,
      petEmoji: petConfig.emoji,
    ));
    await _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    final adoptDate = _storage.getPetAdoptDate();
    final petType = _storage.getPetType();
    final petConfig = getPetTypeConfig(petType);
    final soul = _storage.getPetSoul();

    final needsAdoption = adoptDate == null;
    setState(() {
      _petName = _storage.getPetName();
      _coins = _storage.getPetCoins();
      _equippedCostume = _storage.getEquippedCostume();
      _equippedDecorations = _storage.getEquippedDecorations();
      _ownedItems = _storage.getPetOwnedItems();
      if (adoptDate == null) {
        _petEmoji = '🦊';
        _appearanceLevel = 1;
      } else {
        _petEmoji = petConfig?.emoji ?? soul.petEmoji;
        _appearanceLevel = _storage.getPetAppearanceLevel();
      }
      _personality = _storage.getPetPersonality();
      _intimacy = _storage.getPetIntimacy();
      _intimacyLevel = _storage.getPetIntimacyLevel();
      _intimacyName = _storage.getPetIntimacyLevelName();
      _streakDays = _storage.getUserStats().streak;
      _memoryHighlights = _storage.getPetMemoryHighlights();
      _unallocatedPoints = _storage.getPetUnallocatedPoints();
      print('🔍 _loadData() 调试: _unallocatedPoints = $_unallocatedPoints');
      _initialized = true;
    });

    // 首次进入且未领养 → 弹出领养对话框
    if (needsAdoption) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAdoptionDialog());
    }
  }

  List<PetOwnedItem> get _ownedSnacks => _ownedItems
      .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.snack)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '我的宠物',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          _initialized
              ? Column(
                  children: [
                    // ====== 宠物大卡片（占据主要空间）======
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildPetBigCard(),
                            const SizedBox(height: 12),
                            _buildStatsRow(),
                            const SizedBox(height: 12),
                            _buildPersonalityRadarChart(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                // ====== 底部横向滑动互动按钮 ======
                _buildActionScroll(),
                const SizedBox(height: 12),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          // ====== 底部属性分配面板 ======
          if (_showAllocatePanel && _personality != null)
            _buildAllocatePanel(),
        ],
      ),
    );
  }

  // ====== 宠物大卡片（站立平台光效）======
  Widget _buildPetBigCard() {
    final costume = _equippedCostume != null
        ? PetShopConfig.getById(_equippedCostume!)
        : null;

    // 获取已装备的家居装饰
    final equippedDecos = _equippedDecorations
        .map((id) => PetShopConfig.getById(id))
        .whereType<PetShopItem>()
        .toList();

    // 颜色变体服装的渐变色
    final costumeGradient = _getCostumeGradient(costume?.id);

    // 判断是否配件类服装
    final isAccessoryCostume = ['costume_hat', 'costume_glasses', 'costume_scarf', 'costume_cape'].contains(costume?.id);
    // 判断是否特效服装
    final isEffectCostume = ['costume_fire', 'costume_star'].contains(costume?.id);

    return GestureDetector(
      onTap: _showDecorationSheet, // 点击卡片进入装饰模式
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ===== 场景区域（200px高度，展示宠物+装饰） =====
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景装饰（挂毯、窗户等大装饰）- 直接用emoji
                  if (equippedDecos.any((d) => d.id == 'deco_tapestry'))
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: 0.3,
                        child: Text('🧶', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                  if (equippedDecos.any((d) => d.id == 'deco_window'))
                    Positioned(
                      top: 5,
                      left: 15,
                      child: Opacity(
                        opacity: 0.3,
                        child: Text('🪟', style: TextStyle(fontSize: 45)),
                      ),
                    ),
                  if (equippedDecos.any((d) => d.id == 'deco_frame'))
                    Positioned(
                      left: 5,
                      top: 20,
                      child: Opacity(
                        opacity: 0.35,
                        child: Text('🖼️', style: TextStyle(fontSize: 30)),
                      ),
                    ),

                  // 底部平台或软垫
                  if (equippedDecos.any((d) => d.id == 'deco_cushion'))
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 100,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B7355).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 8,
                      child: Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                  // 左右装饰（灯笼、植物）- 直接用emoji
                  if (equippedDecos.any((d) => d.id == 'deco_lantern'))
                    Positioned(
                      left: 10,
                      bottom: 30,
                      child: Text('🏮', style: TextStyle(fontSize: 32)),
                    ),
                  if (equippedDecos.any((d) => d.id == 'deco_plant'))
                    Positioned(
                      right: 10,
                      bottom: 30,
                      child: Text('🪴', style: TextStyle(fontSize: 32)),
                    ),

                  // 星星灯闪烁效果
                  if (equippedDecos.any((d) => d.id == 'deco_starlight'))
                    Positioned(
                      top: 10,
                      right: 20,
                      child: const _StarlightDecoration(),
                    ),

                  // 宠物大头像（中心，重点展示）
                  // 特效服装：火焰光环
                  if (costume?.id == 'costume_fire')
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.orange.withValues(alpha: 0.4),
                            Colors.red.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                  // 宠物本体：直接显示emoji文本，更清晰
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          costumeGradient.withValues(alpha: 0.2),
                          costumeGradient.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: costumeGradient.withValues(alpha: 0.5),
                        width: 3,
                      ),
                      boxShadow: isEffectCostume
                          ? [
                              BoxShadow(
                                color: costumeGradient.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 宠物用emoji直接显示（60px大字体）- 使用NotoColor字体
                        Container(
                          child: Center(
                            child: _buildPetAvatar(),
                          ),
                        ),
                        // 配件服装叠加emoji在宠物周围
                        if (costume?.id == 'costume_hat')
                          const Positioned(
                            top: -5,
                            child: Text('🎩', style: TextStyle(fontSize: 24)),
                          ),
                        if (costume?.id == 'costume_glasses')
                          const Positioned(
                            top: 32,
                            child: Text('🕶️', style: TextStyle(fontSize: 22)),
                          ),
                        if (costume?.id == 'costume_scarf')
                          const Positioned(
                            bottom: 0,
                            child: Text('🧣', style: TextStyle(fontSize: 20)),
                          ),
                        if (costume?.id == 'costume_cape')
                          Positioned(
                            bottom: 10,
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Opacity(
                                opacity: 0.7,
                                child: Text('🛡️', style: TextStyle(fontSize: 32)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 等级星星（进化效果）
                  if (_appearanceLevel > 1)
                    Positioned(
                      bottom: 25,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _appearanceLevel.clamp(1, 5),
                          (i) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1),
                            child: Text('⭐', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 名字 + 等级标签
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _petName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Lv$_appearanceLevel',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined, size: 14, color: AppColors.textLight),
              ],
            ),
            const SizedBox(height: 6),

            // 性格标签
            if (_personality != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _personality!.archetype,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // 记忆亮点
            _buildMemoryHighlights(),
          ],
        ),
      ),
    );
  }

  /// 构建背景装饰（大装饰物）
  List<Widget> _buildBackgroundDecorations(List<PetShopItem> decorations) {
    final widgets = <Widget>[];

    for (final deco in decorations) {
      switch (deco.id) {
        case 'deco_tapestry':
          widgets.add(Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildDecorationEmoji('🧶', 50, opacity: 0.3),
          ));
          break;
        case 'deco_window':
          widgets.add(Positioned(
            top: 5,
            left: 15,
            child: _buildDecorationEmoji('🪟', 45, opacity: 0.3),
          ));
          break;
        case 'deco_frame':
          widgets.add(Positioned(
            left: 5,
            top: 20,
            child: _buildDecorationEmoji('🖼️', 30, opacity: 0.35),
          ));
          break;
      }
    }

    return widgets;
  }

  /// 构建装饰emoji（更清晰可见）
  Widget _buildDecorationEmoji(String emoji, double size, {double opacity = 0.8}) {
    return Opacity(
      opacity: opacity,
      child: Text(emoji, style: TextStyle(fontSize: size)),
    );
  }

  /// 宠物图标映射
  IconData _getPetIcon() {
    switch (_petEmoji) {
      case '🦊': return CupertinoIcons.paw;
      case '🐺': return CupertinoIcons.flame;
      case '🐰': return CupertinoIcons.hare;
      case '🦌': return CupertinoIcons.leaf_arrow_circlepath;
      case '🦋': return CupertinoIcons.sparkles;
      case '🖤': return CupertinoIcons.moon_fill;
      default: return CupertinoIcons.paw;
    }
  }

  /// 宠物配色方案
  Color _getPetColor() {
    switch (_petEmoji) {
      case '🦊': return const Color(0xFFFF6B35); // 橙色
      case '🐺': return const Color(0xFF6B7280); // 灰色
      case '🐰': return const Color(0xFFFFB7C5); // 粉色
      case '🦌': return const Color(0xFFD4A574); // 棕色
      case '🦋': return const Color(0xFF9333EA); // 紫色
      case '🖤': return const Color(0xFF1F2937); // 深灰
      default: return AppColors.primary;
    }
  }

  /// 获取宠物图片资源路径
  String? _getPetImageAsset() {
    final petConfig = getPetTypeConfig(_storage.getPetType());
    return petConfig?.imageAsset;
  }

  /// 构建宠物头像（图片优先，降级到美化图标）
  Widget _buildPetAvatar() {
    final petColor = _getPetColor();
    final petIcon = _getPetIcon();
    final imageAsset = _getPetImageAsset();

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外层光环
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  petColor.withValues(alpha: 0.3),
                  petColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // 中层装饰圈
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  petColor.withValues(alpha: 0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: petColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // 核心内容：图片或图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  petColor,
                  petColor.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: petColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: imageAsset != null
                  ? Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) {
                        // 图片加载失败，降级到图标
                        return Icon(petIcon, size: 40, color: Colors.white);
                      },
                    )
                  : Icon(petIcon, size: 40, color: Colors.white),
            ),
          ),
          // 内层高光
          Positioned(
            top: 25,
            left: 35,
            child: Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建装饰图标（避免emoji渲染问题）
  Widget _buildDecorationIcon(IconData icon, double size, {Color? color}) {
    return Icon(
      icon,
      size: size,
      color: color ?? AppColors.textSecondary.withValues(alpha: 0.8),
    );
  }

  /// 根据服装ID获取渐变色
  Color _getCostumeGradient(String? costumeId) {
    if (costumeId == null) return AppColors.primary;
    switch (costumeId) {
      case 'costume_spring': return const Color(0xFFFFB7C5); // 粉色
      case 'costume_summer': return const Color(0xFF40E0D0); // 绿松石
      case 'costume_autumn': return const Color(0xFFFFD700); // 金色
      case 'costume_winter': return const Color(0xFF87CEEB); // 冰蓝
      case 'costume_neon': return const Color(0xFFFF00FF); // 霓虹紫
      default: return AppColors.primary;
    }
  }

  /// 显示装饰弹窗（点击宠物卡片触发）
  void _showDecorationSheet() {
    if (!_initialized || _storage.getPetAdoptDate() == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DecorationMainSheet(
        ownedItems: _ownedItems,
        equippedCostume: _equippedCostume,
        equippedDecorations: _equippedDecorations,
        onToggleCostume: _toggleCostume,
        onToggleDecoration: _toggleDecoration,
        onRefresh: _loadData,
      ),
    );
  }

  // ====== 统计行（宠物币 + 亲密度）======
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatTile(CupertinoIcons.bitcoin_circle, '宠物币', '$_coins', AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile(CupertinoIcons.heart, '亲密度', '$_intimacyLevel', const Color(0xFFFF6B6B))),
      ],
    );
  }

  Widget _buildStatTile(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity( 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====== 大五人格雷达图 ======
  Widget _buildPersonalityRadarChart() {
    if (_personality == null) return const SizedBox.shrink();
    final p = _personality!;

    // ✅ 每次 build 都检查 storage 中的最新值，如果不同就更新 state
    final latestPoints = _storage.getPetUnallocatedPoints();
    if (latestPoints != _unallocatedPoints) {
      print('🔄 更新: _unallocatedPoints 从 $_unallocatedPoints 更新到 $latestPoints');
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _unallocatedPoints = latestPoints;
          });
        }
      });
    }

    final unallocatedPoints = _unallocatedPoints;
    print('🔍 调试: _unallocatedPoints = $_unallocatedPoints');
    print('🔍 调试: _storage.getPetUnallocatedPoints() = $latestPoints');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withOpacity( 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '性格分析',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (unallocatedPoints > 0)
                GestureDetector(
                  onTap: _showAllocatePointsDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity( 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$unallocatedPoints 点可用',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.archetypeDescription,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                height: 140,
                child: CustomPaint(
                  painter: RadarChartPainter(
                    data: [
                      RadarDataPoint('开放性', p.openness.toDouble(), AppColors.primary),
                      RadarDataPoint('尽责性', p.conscientiousness.toDouble(), const Color(0xFFE85A1C)),
                      RadarDataPoint('外向性', p.extraversion.toDouble(), Colors.green),
                      RadarDataPoint('宜人性', p.agreeableness.toDouble(), Colors.blue),
                      RadarDataPoint('神经质', p.neuroticism.toDouble(), Colors.purple),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====== 记忆亮点区域 ======
  Widget _buildMemoryHighlights() {
    if (_memoryHighlights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
              const SizedBox(width: 3),
              Text(
                '我们的记忆',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _memoryHighlights.take(5).map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity( 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(anyEmojiToIcon(m.emoji), size: 12, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      m.title,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ====== 底部横向滑动互动按钮 ======
  Widget _buildActionScroll() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, bottom: 6),
          child: Text(
            '互动',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildActionChip(Icons.restaurant, '喂零食', _openSnackSheet),
              const SizedBox(width: 10),
              _buildActionChip(Icons.store, '商店', _openShop),
              const SizedBox(width: 10),
              _buildActionChip(Icons.chat_bubble, '聊天', _openChat),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.textLight.withOpacity( 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity( 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== Bottom Sheet 入口 ======
  void _openSnackSheet() {
    if (!_initialized || _storage.getPetAdoptDate() == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SnackSheet(
        ownedSnacks: _ownedSnacks,
        coins: _coins,
        onUse: _useSnack,
        onRefresh: _loadData,
      ),
    );
  }

  void _openCostumeSheet() {
    if (!_initialized || _storage.getPetAdoptDate() == null) return;
    final costumes = _ownedItems
        .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.costume)
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CostumeSheet(
        ownedCostumes: costumes,
        equippedCostume: _equippedCostume,
        onToggle: _toggleCostume,
        onRefresh: _loadData,
      ),
    );
  }

  void _openDecorationSheet() {
    if (!_initialized || _storage.getPetAdoptDate() == null) return;
    final decorations = _ownedItems
        .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.decoration)
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DecorationSheet(
        ownedDecorations: decorations,
        equippedDecorations: _equippedDecorations,
        onToggle: _toggleDecoration,
        onRefresh: _loadData,
      ),
    );
  }

  void _openShop() {
    Navigator.pushNamed(context, '/pet-shop');
  }

  void _openChat() {
    if (!_initialized || _storage.getPetAdoptDate() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('先领养你的宠物吧'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/pet');
  }

  void _openEvolution() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PetEvolutionScreen()),
    );
  }

  void _showAllocatePointsDialog() {
    if (_personality == null) return;
    setState(() {
      _showAllocatePanel = true;
    });
  }

  Future<void> _allocatePoint(String traitKey) async {
    final success = await _storage.allocateTraitPoint(traitKey);
    if (!mounted) return;
    if (success) {
      // 直接更新本地状态
      setState(() {
        _personality = _storage.getPetPersonality();
        _unallocatedPoints = _storage.getPetUnallocatedPoints();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('属性点不足或已达上限'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ====== 底部属性分配面板 ======
  Widget _buildAllocatePanel() {
    final p = _personality ?? _storage.getPetPersonality();
    final unallocatedPoints = _unallocatedPoints;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showAllocatePanel = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity( 0.4),
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity( 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 顶部把手
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textLight.withOpacity( 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // 标题栏
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity( 0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity( 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '分配属性点',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '提升你宠物的性格特质',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 可用点数显示
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity( 0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity( 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$unallocatedPoints',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '可用',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 分隔线
                        Container(
                          height: 1,
                          color: AppColors.textLight.withOpacity( 0.1),
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        const SizedBox(height: 16),
                        // 属性列表
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _NewTraitAllocateTile(
                                  name: '开放性',
                                  description: '影响宠物对话的创意和想象力',
                                  current: p.openness,
                                  color: AppColors.primary,
                                  icon: Icons.lightbulb_outline,
                                  canAdd: unallocatedPoints > 0 && p.openness < 10,
                                  onTap: () => _allocatePoint('openness'),
                                ),
                                _NewTraitAllocateTile(
                                  name: '尽责性',
                                  description: '影响宠物提醒打卡的严格程度',
                                  current: p.conscientiousness,
                                  color: const Color(0xFFE85A1C),
                                  icon: Icons.check_circle_outline,
                                  canAdd: unallocatedPoints > 0 && p.conscientiousness < 10,
                                  onTap: () => _allocatePoint('conscientiousness'),
                                ),
                                _NewTraitAllocateTile(
                                  name: '外向性',
                                  description: '影响宠物的话痨程度和热情度',
                                  current: p.extraversion,
                                  color: const Color(0xFF10B981),
                                  icon: Icons.wb_sunny_outlined,
                                  canAdd: unallocatedPoints > 0 && p.extraversion < 10,
                                  onTap: () => _allocatePoint('extraversion'),
                                ),
                                _NewTraitAllocateTile(
                                  name: '宜人性',
                                  description: '影响宠物的温暖和鼓励程度',
                                  current: p.agreeableness,
                                  color: const Color(0xFF3B82F6),
                                  icon: Icons.favorite_border,
                                  canAdd: unallocatedPoints > 0 && p.agreeableness < 10,
                                  onTap: () => _allocatePoint('agreeableness'),
                                ),
                                _NewTraitAllocateTile(
                                  name: '神经质',
                                  description: '影响宠物的情绪波动和敏感度',
                                  current: p.neuroticism,
                                  color: const Color(0xFF8B5CF6),
                                  icon: Icons.opacity_outlined,
                                  canAdd: unallocatedPoints > 0 && p.neuroticism < 10,
                                  onTap: () => _allocatePoint('neuroticism'),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        // 底部按钮
                        if (unallocatedPoints == 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showAllocatePanel = false;
                                });
                              },
                              child: const Text(
                                '分配完成',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (unallocatedPoints > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showAllocatePanel = false;
                                });
                              },
                              child: Text(
                                '稍后分配',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _useSnack(PetOwnedItem owned) async {
    final item = PetShopConfig.getById(owned.itemId);
    if (item == null) return;
    await _storage.removePetOwnedItem(owned.itemId);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_petName 吃了 ${item.name}，很开心！'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleCostume(PetOwnedItem owned, bool currentlyEquipped) async {
    if (currentlyEquipped) {
      await _storage.saveEquippedCostume(null);
    } else {
      await _storage.saveEquippedCostume(owned.itemId);
    }
    await _loadData();
  }

  Future<void> _toggleDecoration(PetOwnedItem owned, bool currentlyEquipped) async {
    final current = List<String>.from(_equippedDecorations);
    if (currentlyEquipped) {
      current.remove(owned.itemId);
    } else {
      current.add(owned.itemId);
    }
    await _storage.saveEquippedDecorations(current);
    await _loadData();
  }
}

// ====== Bottom Sheet 组件（复用原逻辑）=====

class _SnackSheet extends StatelessWidget {
  final List<PetOwnedItem> ownedSnacks;
  final int coins;
  final void Function(PetOwnedItem) onUse;
  final VoidCallback onRefresh;

  const _SnackSheet({
    required this.ownedSnacks,
    required this.coins,
    required this.onUse,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('零食', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: [
                  const Icon(CupertinoIcons.bitcoin_circle, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('$coins', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          if (ownedSnacks.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('还没有零食，快去商店买一些吧～', style: TextStyle(color: AppColors.textSecondary))))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ownedSnacks.map((o) {
                final item = PetShopConfig.getById(o.itemId)!;
                return _SnackChip(item: item, onTap: () { onUse(o); Navigator.pop(context); });
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SnackChip extends StatelessWidget {
  final PetShopItem item;
  final VoidCallback onTap;
  const _SnackChip({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity( 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity( 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(anyEmojiToIcon(item.icon), size: 22, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _CostumeSheet extends StatelessWidget {
  final List<PetOwnedItem> ownedCostumes;
  final String? equippedCostume;
  final void Function(PetOwnedItem, bool) onToggle;
  final VoidCallback onRefresh;

  const _CostumeSheet({
    required this.ownedCostumes,
    required this.equippedCostume,
    required this.onToggle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checkroom, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('换装', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          if (ownedCostumes.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('还没有外观，快去商店买一些吧～', style: TextStyle(color: AppColors.textSecondary))))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ownedCostumes.map((o) {
                final item = PetShopConfig.getById(o.itemId)!;
                final isEquipped = equippedCostume == o.itemId;
                return _ItemChip(item: item, isEquipped: isEquipped, onTap: () { onToggle(o, isEquipped); Navigator.pop(context); });
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DecorationSheet extends StatelessWidget {
  final List<PetOwnedItem> ownedDecorations;
  final List<String> equippedDecorations;
  final void Function(PetOwnedItem, bool) onToggle;
  final VoidCallback onRefresh;

  const _DecorationSheet({
    required this.ownedDecorations,
    required this.equippedDecorations,
    required this.onToggle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('家居', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          if (ownedDecorations.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('还没有家居，快去商店买一些吧～', style: TextStyle(color: AppColors.textSecondary))))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ownedDecorations.map((o) {
                final item = PetShopConfig.getById(o.itemId)!;
                final isEquipped = equippedDecorations.contains(o.itemId);
                return _ItemChip(item: item, isEquipped: isEquipped, onTap: () { onToggle(o, isEquipped); Navigator.pop(context); });
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final PetShopItem item;
  final bool isEquipped;
  final VoidCallback onTap;

  const _ItemChip({
    required this.item,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isEquipped ? AppColors.primary : AppColors.primary.withOpacity( 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isEquipped ? AppColors.primary : AppColors.primary.withOpacity( 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(anyEmojiToIcon(item.icon), size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isEquipped ? Colors.white : AppColors.primary,
              ),
            ),
            if (isEquipped) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: Colors.white.withOpacity( 0.8)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 首次领养宠物对话框
class _PetAdoptionDialog extends StatefulWidget {
  final void Function(String petType, String petName) onAdopted;

  const _PetAdoptionDialog({required this.onAdopted});

  @override
  State<_PetAdoptionDialog> createState() => _PetAdoptionDialogState();
}

class _PetAdoptionDialogState extends State<_PetAdoptionDialog> {
  int _selectedIndex = 0;
  final _nameController = TextEditingController(text: '炭炭');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPets = petTypes;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.paw, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  '领养你的宠物',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '选择一个陪伴你的伙伴',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // 宠物选择横向滚动
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allPets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final pet = allPets[index];
                  final isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity( 0.12)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(petEmojiToIcon(pet.emoji), size: 36, color: AppColors.primary),
                          const SizedBox(height: 4),
                          Text(
                            pet.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            // 名字输入
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '给TA取个名字',
                labelStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // 确认按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final name = _nameController.text.trim().isNotEmpty
                      ? _nameController.text.trim()
                      : allPets[_selectedIndex].name;
                  widget.onAdopted(allPets[_selectedIndex].type, name);
                  Navigator.pop(context);
                },
                child: Text(
                  '领养 ${allPets[_selectedIndex].name}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== 雷达图支持类 ======

class RadarDataPoint {
  final String label;
  final double value;
  final Color color;

  RadarDataPoint(this.label, this.value, this.color);
}

class RadarChartPainter extends CustomPainter {
  final List<RadarDataPoint> data;

  RadarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2 * 0.7;

    // 画背景网格
    _drawGrid(canvas, center, maxRadius);

    // 画数据多边形
    _drawData(canvas, center, maxRadius);

    // 画标签
    _drawLabels(canvas, center, maxRadius);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity( 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 画10个同心圆
    for (int i = 1; i <= 10; i++) {
      canvas.drawCircle(center, radius * i / 10, paint);
    }

    // 画5条辐射线
    final angleStep = 2 * pi / data.length;
    for (int i = 0; i < data.length; i++) {
      final angle = angleStep * i - pi / 2;
      final endX = center.dx + radius * cos(angle);
      final endY = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }
  }

  void _drawData(Canvas canvas, Offset center, double radius) {
    final angleStep = 2 * pi / data.length;
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final angle = angleStep * i - pi / 2;
      final value = data[i].value;
      final r = radius * value / 10;
      points.add(Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      ));
    }

    // 画填充区域
    final path = Path()..addPolygon(points, true);
    final fillPaint = Paint()
      ..color = AppColors.primary.withOpacity( 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 画边框
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, strokePaint);

    // 画数据点
    for (int i = 0; i < points.length; i++) {
      final dotPaint = Paint()
        ..color = data[i].color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], 5, dotPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius) {
    const labelRadius = 1.15;
    final angleStep = 2 * pi / data.length;

    for (int i = 0; i < data.length; i++) {
      final angle = angleStep * i - pi / 2;
      final x = center.dx + radius * labelRadius * cos(angle);
      final y = center.dy + radius * labelRadius * sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TraitAllocateTile extends StatelessWidget {
  final String name;
  final String description;
  final int current;
  final Color color;
  final bool canAdd;
  final VoidCallback onTap;

  const _TraitAllocateTile({
    required this.name,
    required this.description,
    required this.current,
    required this.color,
    required this.canAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity( 0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity( 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$current/10',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: current / 10,
                    color: color,
                    backgroundColor: color.withOpacity( 0.2),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: canAdd ? onTap : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: canAdd ? color.withOpacity( 0.15) : AppColors.textLight.withOpacity( 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: canAdd ? color : AppColors.textLight,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewTraitAllocateTile extends StatelessWidget {
  final String name;
  final String description;
  final int current;
  final Color color;
  final IconData icon;
  final bool canAdd;
  final VoidCallback onTap;

  const _NewTraitAllocateTile({
    required this.name,
    required this.description,
    required this.current,
    required this.color,
    required this.icon,
    required this.canAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity( 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity( 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity( 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity( 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$current/10',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: current / 10,
                    color: color,
                    backgroundColor: color.withOpacity( 0.15),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: canAdd ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canAdd ? color : AppColors.textLight.withOpacity( 0.1),
                shape: BoxShape.circle,
                boxShadow: canAdd
                    ? [
                        BoxShadow(
                          color: color.withOpacity( 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.add,
                color: canAdd ? Colors.white : AppColors.textLight,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 星星灯装饰动画
class _StarlightDecoration extends StatefulWidget {
  const _StarlightDecoration();

  @override
  State<_StarlightDecoration> createState() => _StarlightDecorationState();
}

class _StarlightDecorationState extends State<_StarlightDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = i * 0.33;
            final opacity = (((_controller.value + offset) % 1.0) * 2 - 1).abs();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity * 0.7 + 0.3,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Color(0xFFFFD700),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// 装饰主面板（点击宠物卡片弹出）
class _DecorationMainSheet extends StatelessWidget {
  final List<PetOwnedItem> ownedItems;
  final String? equippedCostume;
  final List<String> equippedDecorations;
  final void Function(PetOwnedItem, bool) onToggleCostume;
  final void Function(PetOwnedItem, bool) onToggleDecoration;
  final VoidCallback onRefresh;

  const _DecorationMainSheet({
    required this.ownedItems,
    this.equippedCostume,
    required this.equippedDecorations,
    required this.onToggleCostume,
    required this.onToggleDecoration,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final costumes = ownedItems
        .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.costume)
        .toList();
    final decorations = ownedItems
        .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.decoration)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              const Icon(Icons.pets, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('我的宠物', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          // Tab切换：换装 / 家居
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: '换装'),
                      Tab(text: '家居'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 换装Tab
                        _buildCostumeGrid(costumes),
                        // 家居Tab
                        _buildDecorationGrid(decorations),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostumeGrid(List<PetOwnedItem> costumes) {
    if (costumes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('还没有外观，快去商店买一些吧～', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: costumes.length,
      itemBuilder: (context, index) {
        final item = PetShopConfig.getById(costumes[index].itemId)!;
        final isEquipped = equippedCostume == costumes[index].itemId;
        return GestureDetector(
          onTap: () {
            onToggleCostume(costumes[index], isEquipped);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isEquipped ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEquipped ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.2),
                width: isEquipped ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(anyEmojiToIcon(item.icon), size: 28, color: AppColors.primary),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                if (isEquipped)
                  const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorationGrid(List<PetOwnedItem> decorations) {
    if (decorations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('还没有家居，快去商店买一些吧～', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: decorations.length,
      itemBuilder: (context, index) {
        final item = PetShopConfig.getById(decorations[index].itemId)!;
        final isEquipped = equippedDecorations.contains(decorations[index].itemId);
        return GestureDetector(
          onTap: () {
            onToggleDecoration(decorations[index], isEquipped);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isEquipped ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEquipped ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.2),
                width: isEquipped ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(anyEmojiToIcon(item.icon), size: 28, color: AppColors.primary),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                if (isEquipped)
                  const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}
