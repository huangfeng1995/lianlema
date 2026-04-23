import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/pet_models.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import 'pet_evolution_screen.dart';

/// 宠物emoji → IconData 映射
IconData petEmojiToIcon(String emoji) {
  switch (emoji) {
    case '🥚': return Icons.egg_outlined;
    case '🦊': return CupertinoIcons.hare;
    case '🐺': return CupertinoIcons.flame;
    case '🐰': return CupertinoIcons.hare;
    case '🦌': return CupertinoIcons.leaf_arrow_circlepath;
    case '🦔': return CupertinoIcons.leaf_arrow_circlepath;
    case '🐦': return CupertinoIcons.paperplane;
    case '🐿️': return CupertinoIcons.bolt;
    case '🦝': return CupertinoIcons.eye;
    case '🐻': return CupertinoIcons.house;
    case '🐧': return CupertinoIcons.snow;
    case '🦉': return CupertinoIcons.moon;
    case '🐨': return CupertinoIcons.cloud;
    case '🐼': return CupertinoIcons.circle_grid_hex;
    case '🦋': return CupertinoIcons.sparkles;
    case '🖤': return CupertinoIcons.moon_fill;
    case '🐾': return CupertinoIcons.paw;
    default: return CupertinoIcons.hare;
  }
}

/// 心情emoji → IconData 映射
IconData moodEmojiToIcon(String emoji) {
  switch (emoji) {
    case '😄': return CupertinoIcons.hand_thumbsup_fill;
    case '🙂': return CupertinoIcons.hand_thumbsup;
    case '😌': return CupertinoIcons.heart;
    case '😢': return CupertinoIcons.drop;
    case '😭': return CupertinoIcons.cloud_rain;
    default: return CupertinoIcons.smiley;
  }
}

/// 通用emoji → IconData 映射（记忆亮点、道具图标等）
IconData anyEmojiToIcon(String emoji) {
  switch (emoji) {
    // 记忆亮点
    case '🎯': return CupertinoIcons.scope;
    case '🔥': return CupertinoIcons.flame;
    case '⚡': return CupertinoIcons.bolt_fill;
    case '💬': return CupertinoIcons.chat_bubble_2;
    case '🏆': return CupertinoIcons.rosette;
    case '⬆️': return CupertinoIcons.arrow_up_circle_fill;
    // 心情
    case '😄': return CupertinoIcons.hand_thumbsup_fill;
    case '🙂': return CupertinoIcons.hand_thumbsup;
    case '😌': return CupertinoIcons.heart;
    case '😢': return CupertinoIcons.drop;
    case '😭': return CupertinoIcons.cloud_rain;
    // 道具/零食
    case '🍪': return CupertinoIcons.gift;
    case '🏠': return CupertinoIcons.house_fill;
    case '👗': return CupertinoIcons.checkmark_seal;
    case '🛒': return CupertinoIcons.cart;
    case '💬': return CupertinoIcons.chat_bubble_2;
    case '🪙': return CupertinoIcons.bitcoin_circle;
    default: return CupertinoIcons.circle;
  }
}

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: AppColors.textSecondary,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _initialized
          ? Column(
              children: [
                // ====== 宠物大卡片（占据主要空间）======
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildPetBigCard(),
                        const SizedBox(height: 16),
                        _buildStatsRow(),
                        const SizedBox(height: 16),
                        _buildPersonalityRadarChart(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // ====== 底部横向滑动互动按钮 ======
                _buildActionScroll(),
                const SizedBox(height: 16),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
    );
  }

  // ====== 宠物大卡片（站立平台光效）======
  Widget _buildPetBigCard() {
    final costume = _equippedCostume != null
        ? PetShopConfig.getById(_equippedCostume!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ===== 站立平台（光效）=====
          Stack(
            alignment: Alignment.center,
            children: [
              // 光效底座
              Container(
                width: 160,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // 平台装饰线
              Positioned(
                bottom: 8,
                child: Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // 宠物大头像
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(petEmojiToIcon(_petEmoji), size: 64, color: AppColors.primary),
                    if (costume != null)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(costume.icon, style: const TextStyle(fontSize: 14)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 名字 + 等级标签
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _petName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv$_appearanceLevel',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 性格标签
          if (_personality != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _personality!.archetype,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // 记忆亮点
          _buildMemoryHighlights(),
        ],
      ),
    );
  }

  // ====== 统计行（宠物币 + 亲密度）======
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatTile(CupertinoIcons.bitcoin_circle, '宠物币', '$_coins', AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatTile(CupertinoIcons.heart, '亲密度', '$_intimacyLevel', const Color(0xFFFF6B6B))),
      ],
    );
  }

  Widget _buildStatTile(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: accent),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
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
              Text(
                p.archetype,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 240,
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
          const SizedBox(height: 8),
          Text(
            p.archetypeDescription,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
            ),
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
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '我们的记忆',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _memoryHighlights.take(5).map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(anyEmojiToIcon(m.emoji), size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      m.title,
                      style: TextStyle(
                        fontSize: 11,
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
          padding: EdgeInsets.only(left: 20, bottom: 10),
          child: Text(
            '互动',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildActionChip(Icons.restaurant, '喂零食', _openSnackSheet),
              const SizedBox(width: 10),
              _buildActionChip(Icons.home, '家居', _openDecorationSheet),
              const SizedBox(width: 10),
              _buildActionChip(Icons.checkroom, '换装', _openCostumeSheet),
              const SizedBox(width: 10),
              _buildActionChip(Icons.store, '商店', _openShop),
              const SizedBox(width: 10),
              _buildActionChip(Icons.chat_bubble, '聊天', _openChat),
              const SizedBox(width: 10),
              _buildActionChip(Icons.local_fire_department, '进化', _openEvolution),
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
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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

  void _openSettings() {
    // TODO: 宠物设置页面
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
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
          color: isEquipped ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isEquipped ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3)),
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
              Icon(Icons.check_circle, size: 14, color: Colors.white.withValues(alpha: 0.8)),
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
                            ? AppColors.primary.withValues(alpha: 0.12)
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
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 画5个同心圆
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, paint);
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
      final r = radius * value / 5;
      points.add(Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      ));
    }

    // 画填充区域
    final path = Path()..addPolygon(points, true);
    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
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
