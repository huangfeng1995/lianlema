import 'storage_service.dart';
// import 'mnn_inference_service.dart';
// import 'model_download_service.dart';

/// 推送信息实体
class PushInfo {
  final String title;
  final String content;
  final String route;

  PushInfo({
    required this.title,
    required this.content,
    required this.route,
  });
}

/// 宠物服务
class PetService {
  static final PetService _instance = PetService._internal();
  factory PetService() => _instance;
  PetService._internal();

  final StorageService _storage = StorageService();
  // final MnnInferenceService _inferService = MnnInferenceService();
  // final ModelDownloadService _modelService = ModelDownloadService();

  /// 固定系统提示词
  static const String _systemPrompt = """
你是「练了吗」App的专属陪伴宠物「小炭」，性格阳光毒舌又暖心，是用户的成长伙伴。
回复要求：
1. 语气口语化，像朋友聊天，字数控制在20-50字
2. 结合用户的打卡天数、目标进度，鼓励用户坚持，不要说教
3. 懈怠时适当调侃，取得进展时真诚表扬
4. 只回答和成长、打卡、目标相关的问题，不回答无关内容
""";

  /// 初始化服务
  Future<void> init() async {
    // await _modelService.init();
    // await _inferService.init();
  }

  /// 对话交互接口
  Future<String> chat(String input) async {
    // 1. 读取上下文信息
    final history = await _storage.getPetChatHistory(limit: 10);
    final streak = await _storage.getStreakDays();
    final progress = await _storage.getMonthlyBossProgress();

    // 2. 构造完整prompt
    final prompt = _buildChatPrompt(history, streak, progress, input);

    // 3. Mock回复
    final reply = "今天也要加油打卡哦~ 坚持就是胜利！";

    // 4. 保存对话历史
    await _storage.savePetChatMessage(input, reply);

    // 5. 自动释放资源
    // _inferService.autoRelease();

    return reply;
  }

  /// 情绪判断接口（返回：happy/sad/encourage/tease）
  Future<String> getEmotion(String userInput, String petReply) async {
    // final prompt = """
    // 根据用户输入和宠物回复，判断宠物应该是什么情绪：
    // 用户输入：$userInput
    // 宠物回复：$petReply
    // 情绪只能是这四个选项其中一个：happy/sad/encourage/tease，不要返回其他内容，不要解释。
    // """;
    // final emotion = await _inferService.infer(prompt, maxTokens: 10);
    // _inferService.autoRelease();
    // return emotion.trim().toLowerCase();
    return "happy";
  }

  /// 推送生成接口
  Future<PushInfo> generatePush() async {
    // 读取用户数据
    final todayChecked = await _storage.isTodayChecked();
    final streak = await _storage.getStreakDays();
    final progress = await _storage.getMonthlyBossProgress();

    // final prompt = """
    // 根据用户的打卡情况生成一条主动推送，要求：
    // 1. 今天是否打卡：${todayChecked ? "已打卡" : "未打卡"}
    // 2. 连续打卡天数：$streak 天
    // 3. 本月目标完成进度：$progress%
    // 4. 推送标题控制在10字以内，内容控制在20-30字
    // 5. 跳转路径：/home（打卡页）或者/pet（宠物页）
    // 返回格式要求：
    // 标题：xxx
    // 内容：xxx
    // 路径：xxx
    // 不要返回其他内容。
    // """;

    // final result = await _inferService.infer(prompt);
    // _inferService.autoRelease();

    // return _parsePushResult(result);
    return PushInfo(
      title: "今日打卡",
      content: "今天的目标完成了吗？快来打卡吧~",
      route: "/home",
    );
  }

  /// 构造对话prompt
  String _buildChatPrompt(List<Map<String, String>> history, int streak, int progress, String input) {
    StringBuffer sb = StringBuffer(_systemPrompt);
    sb.writeln("\n当前用户信息：");
    sb.writeln("连续打卡天数：$streak 天");
    sb.writeln("本月目标完成进度：$progress%");
    sb.writeln("\n历史对话：");
    for (final msg in history) {
      sb.writeln("用户：${msg['user']}");
      sb.writeln("小炭：${msg['assistant']}");
    }
    sb.writeln("\n用户最新输入：$input");
    sb.writeln("小炭回复：");
    return sb.toString();
  }

  /// 解析推送结果
  PushInfo _parsePushResult(String result) {
    String title = "今日打卡";
    String content = "今天的目标完成了吗？快来打卡吧~";
    String route = "/home";

    final lines = result.split("\n");
    for (final line in lines) {
      if (line.startsWith("标题：")) {
        title = line.replaceFirst("标题：", "").trim();
      } else if (line.startsWith("内容：")) {
        content = line.replaceFirst("内容：", "").trim();
      } else if (line.startsWith("路径：")) {
        route = line.replaceFirst("路径：", "").trim();
      }
    }

    return PushInfo(
      title: title,
      content: content,
      route: route,
    );
  }
}
