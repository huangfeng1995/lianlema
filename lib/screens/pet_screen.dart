import 'package:flutter/material.dart';
import '../models/pet_models.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../utils/pet_service.dart';
import '../services/pet_push_service.dart';

class PetScreen extends StatefulWidget {
  /// 可选：打开时自动发送的消息（如障碍引导）
  final String? initialMessage;

  const PetScreen({super.key, this.initialMessage});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  PetContext? _context;
  PetMoodState? _moodState;
  PetPreferences? _prefs;
  String _petName = StorageService.defaultPetName;
  late StorageService _storage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    await PetService.instance.loadState();
    final ctx = await PetService.instance.buildContext();
    final mood = PetService.instance.moodState;
    final prefs = PetService.instance.preferences;

    setState(() {
      _context = ctx;
      _moodState = mood;
      _prefs = prefs;
      _petName = _storage.getPetName();
    });

    // 如果有初始消息（障碍引导），自动发送
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _inputController.text = widget.initialMessage!;
        await _sendMessage();
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 8),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '宠物',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          if (_isLoading) _buildLoadingIndicator(),
          _buildInputArea(),
          _buildQuickCommands(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final mood = _moodState?.mood ?? PetMood.calm;
    final moodText = _getMoodText(mood);
    final isEggPhase = _storage.getPetAdoptDate() == null || _storage.isInEggPhase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ===== 宠物完整视觉形象（放大到80x80） =====
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEggPhase
                        ? [Colors.brown.shade400, Colors.brown.shade600]
                        : [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isEggPhase
                          ? Colors.brown.withValues(alpha: 0.4)
                          : AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isEggPhase
                    ? const Center(
                        child: Icon(Icons.egg, color: Colors.white, size: 36),
                      )
                    : Center(
                        child: _buildMoodIcon(mood, size: 34),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名字单独一行，可点击编辑
                    GestureDetector(
                      onTap: () => _showEditPetNameDialog(),
                      child: Row(
                        children: [
                          Text(
                            _petName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEggPhase ? '还在蛋里...' : moodText,
                      style: TextStyle(
                        fontSize: 13,
                        color: isEggPhase
                            ? Colors.brown.shade400
                            : AppColors.textSecondary,
                        fontWeight: isEggPhase ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEggPhase
                          ? '再等${7 - DateTime.now().difference(_storage.getPetAdoptDate() ?? DateTime.now()).inDays}天就孵化了'
                          : (_moodState != null
                              ? PetService.instance.generateSuggestion(_context!)
                              : '正在加载...'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (_context == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(Icons.local_fire_department, Color(0xFFFF4500), '${_context!.streak}天', '连续打卡'),
        _buildStatItem(Icons.star, Color(0xFFFFD700), '等级${(_context!.totalCheckIns ~/ 10) + 1}', '当前等级'),
        _buildStatItem(Icons.whatshot, AppColors.primary, '${_context!.currentBossHp}/${_context!.currentBossTotal}', '挑战进度'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMoodIcon(PetMood mood, {double size = 32}) {
    switch (mood) {
      case PetMood.happy:
        return Icon(Icons.emoji_emotions, color: Colors.white, size: size);
      case PetMood.sleepy:
        return Icon(Icons.nightlight, color: Colors.white70, size: size);
      case PetMood.excited:
        return Icon(Icons.bolt, color: Colors.yellow, size: size);
      case PetMood.thinking:
        return Icon(Icons.psychology, color: Colors.white, size: size);
      case PetMood.calm:
        return Icon(Icons.local_fire_department, color: Colors.white, size: size);
      case PetMood.resting:
        return Icon(Icons.bedtime, color: Colors.white70, size: size);
    }
  }

  String _getMoodText(PetMood mood) {
    switch (mood) {
      case PetMood.happy: return '开心';
      case PetMood.sleepy: return '困了';
      case PetMood.excited: return '兴奋';
      case PetMood.thinking: return '思考中';
      case PetMood.calm: return '平静';
      case PetMood.resting: return '休息中';
    }
  }

  String _getMoodEmoji(PetMood mood) {
    switch (mood) {
      case PetMood.happy: return '😊';
      case PetMood.sleepy: return '😴';
      case PetMood.excited: return '🤩';
      case PetMood.thinking: return '🤔';
      case PetMood.calm: return '😌';
      case PetMood.resting: return '💤';
    }
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          '$_petName正在等你...',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (ctx, index) => _buildChatBubble(_messages[index]),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.local_fire_department, size: 18, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 12),
                ),
                border: isUser ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text('$_petName在思考...', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: '问$_petName...',
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommands() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildCommandChip(PetCommand.checkInRecord, Icons.checklist_rounded, '查打卡'),
          _buildCommandChip(PetCommand.setReminder, Icons.alarm, '设提醒'),
          _buildCommandChip(PetCommand.askGrowth, Icons.lightbulb_outline, '问成长'),
          _buildCommandChip(PetCommand.status, Icons.bar_chart, '状态'),
          _buildCommandChip(PetCommand.feed, Icons.restaurant, '打卡'),
        ],
      ),
    );
  }

  Widget _buildCommandChip(PetCommand command, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _handleCommand(command),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final ctx = _context ?? await PetService.instance.buildContext();
      final response = await PetService.instance.chat(text, ctx);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: '网络有点问题，稍后再试试吧 😅', isUser: false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _handleCommand(PetCommand command) async {
    setState(() => _isLoading = true);
    try {
      final ctx = _context ?? await PetService.instance.buildContext();
      final response = await PetService.instance.handleCommand(command, ctx);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  static const List<String> _presetNames = [
    '炭炭', '小火', '元气', '旺财', '团团',
    '小青', '阿绿', '橙子', '煤球', '阿黄',
  ];

  void _showEditPetNameDialog() {
    final controller = TextEditingController(text: _petName);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.pets, size: 24, color: AppColors.primary),
              SizedBox(width: 8),
              Text('修改宠物名字'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: '输入新名字（最多10字）',
                  hintStyle: TextStyle(color: AppColors.textLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: 16),
              const Text(
                '快速选择：',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetNames.map((name) {
                  final isSelected = controller.text == name;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        controller.text = name;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  await _storage.savePetName(newName);
                  setState(() {
                    _petName = newName.length > 10 ? newName.substring(0, 10) : newName;
                  });
                  if (mounted) Navigator.pop(dialogContext);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

// ===== 宠物主动推送气泡 =====
class _PetPushBanner extends StatefulWidget {
  final PetPush push;
  final VoidCallback onClicked;
  final VoidCallback onDismissed;

  const _PetPushBanner({
    required this.push,
    required this.onClicked,
    required this.onDismissed,
  });

  @override
  State<_PetPushBanner> createState() => _PetPushBannerState();
}

class _PetPushBannerState extends State<_PetPushBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -0.1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismissed());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, _slideAnimation.value),
          end: Offset.zero,
        ).animate(_controller),
        child: GestureDetector(
          onTap: widget.onClicked,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35).withValues(alpha: 0.12),
                  const Color(0xFFE85D2D).withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.push.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE85D2D),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.push.body,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
