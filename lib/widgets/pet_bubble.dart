import 'package:flutter/material.dart';
import '../models/pet_models.dart';
import '../theme/app_theme.dart';
import '../utils/pet_service.dart';

/// 宠物浮动气泡
/// 悬浮在首页右下角，点击展开对话/功能面板
class PetBubble extends StatefulWidget {
  final VoidCallback? onMoodChanged;

  const PetBubble({super.key, this.onMoodChanged});

  @override
  State<PetBubble> createState() => PetBubbleState();
}

class PetBubbleState extends State<PetBubble>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isSending = false;
  String _petMessage = '';
  String? _proactiveInsight; // 主动洞察（未读）
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  PetContext? _context;
  PetMood _mood = PetMood.calm;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _loadContext();
  }

  Future<void> _loadContext() async {
    // 加载并保存心情状态
    await PetService.instance.loadState();

    final ctx = await PetService.instance.buildContext();
    final moodState = PetService.instance.calculateMood(ctx);
    // 保存更新后的心情
    await PetService.instance.updateMood(moodState);

    final greeting = PetService.instance.generateGreeting();
    final suggestion = PetService.instance.generateSuggestion(ctx);

    // 生成主动洞察（仅在用户未打卡且有洞察时显示）
    String? insight;
    if (!ctx.checkedInToday) {
      insight = PetService.instance.generateProactiveInsight(ctx);
    }

    setState(() {
      _context = ctx;
      _mood = moodState.mood;
      _petMessage = '$greeting $suggestion';
      _proactiveInsight = insight;
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: _isExpanded ? _buildExpandedPanel() : _buildBubble(),
    );
  }

  Widget _buildBubble() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity( 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: _buildMoodIcon(_mood),
              ),
              // 新消息/洞察提示
              if (_petMessage.isNotEmpty || _proactiveInsight != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _proactiveInsight != null
                          ? Colors.amber
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodIcon(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return const Icon(Icons.sentiment_very_satisfied,
            color: Colors.white, size: 32);
      case PetMood.sleepy:
        return const Icon(Icons.nightlight, color: Colors.white70, size: 32);
      case PetMood.excited:
        return const Icon(Icons.bolt, color: Colors.yellow, size: 32);
      case PetMood.thinking:
        return const Icon(Icons.psychology, color: Colors.white, size: 32);
      case PetMood.calm:
        return const Icon(Icons.local_fire_department,
            color: Colors.white, size: 32);
      case PetMood.resting:
        return const Icon(Icons.bedtime, color: Colors.white70, size: 32);
    }
  }

  Widget _buildExpandedPanel() {
    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPanelHeader(),
          Expanded(child: _buildMessageList()),
          if (_isLoading) _buildLoadingIndicator(),
          _buildInputArea(),
          _buildQuickCommands(),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity( 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(child: _buildMoodIcon(_mood)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '炭炭',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '你的成长小精灵',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = false),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity( 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_petMessage.isNotEmpty) _buildPetBubble(_petMessage),
            if (_proactiveInsight != null) ...[
              const SizedBox(height: 8),
              _buildInsightCard(_proactiveInsight!),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (ctx, index) {
        final msg = _messages[index];
        return _buildChatBubble(msg);
      },
    );
  }

  Widget _buildPetBubble(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity( 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity( 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_fire_department, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textPrimary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInsightCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity( 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 16, color: Colors.amber[700]),
              const SizedBox(width: 6),
              Text(
                '炭炭的洞察',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity( 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.local_fire_department,
                    size: 16, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : AppColors.primary.withOpacity( 0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 12),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: AppColors.primary.withOpacity( 0.2)),
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
          const SizedBox(width: 28),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity( 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withOpacity( 0.2)),
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
                const Text('炭炭在思考...',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
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
        border: Border(
            top: BorderSide(color: AppColors.primary.withOpacity( 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.textLight.withOpacity( 0.3)),
              ),
              child: TextField(
                controller: _inputController,
                decoration: const InputDecoration(
                  hintText: '问炭炭...',
                  hintStyle:
                      TextStyle(fontSize: 14, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommands() {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: PetQuickCommand.all.map((cmd) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _handleCommand(cmd.command),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity( 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withOpacity( 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cmd.icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      cmd.label,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    _isSending = true;
    try {
      final text = _inputController.text.trim();
      if (text.isEmpty) {
        _isSending = false;
        return;
      }

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
          _petMessage = '';
        });
      } catch (e) {
        setState(() {
          _messages.add(ChatMessage(text: '网络有点问题，稍后再试试吧 😅', isUser: false));
          _isLoading = false;
        });
      }

      _scrollToBottom();
    } finally {
      _isSending = false;
    }
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

  /// 公开方法：刷新宠物心情（打卡后由外部调用）
  void refreshMood() {
    _loadContext();
    widget.onMoodChanged?.call();
  }
}

/// 聊天消息模型
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
