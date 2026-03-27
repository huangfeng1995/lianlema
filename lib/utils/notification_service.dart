import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  String? _pendingPayload;
  static final tz.Location _location = tz.getLocation('Asia/Shanghai');

  NotificationService._();

  static Future<NotificationService> getInstance() async {
    if (_instance == null) {
      _instance = NotificationService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        onDidReceiveNotificationResponse: _onNotificationTap,
        settings: initSettings,
      );

      // 请求iOS权限
      await _requestPermissions();
    } catch (e) {
      // 通知服务初始化失败，App仍可正常运行
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTap(NotificationResponse response) {
    _pendingPayload = response.payload;
  }

  String? get pendingPayload => _pendingPayload;

  void clearPendingPayload() {
    _pendingPayload = null;
  }

  /// 获取应用启动时点击的通知详情
  Future<String?> getNotificationLaunchPayload() async {
    final launchDetails = await _notifications.getNotificationAppLaunchDetails();
    return launchDetails?.notificationResponse?.payload;
  }

  /// 调度每日日报通知（每天早上8点）
  Future<void> scheduleDailyReport() async {
    await _notifications.cancel(id: DailyReportNotificationId);

    final scheduledDate = _nextInstanceOfTime(8, 0);

    await _notifications.zonedSchedule(
      id: DailyReportNotificationId,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'daily_report',
        ),
        android: const AndroidNotificationDetails(
          'daily_report',
          '日报',
          channelDescription: '每日日报提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: '📋 今日战报',
      body: '今天的你又前进了一步，快来回顾一下！',
      payload: 'daily_report',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 调度每周周报通知（每周一早上8点）
  Future<void> scheduleWeeklyReport() async {
    await _notifications.cancel(id: WeeklyReportNotificationId);

    final scheduledDate = _nextInstanceOfWeekday(DateTime.monday, 8, 0);

    await _notifications.zonedSchedule(
      id: WeeklyReportNotificationId,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'weekly_report',
        ),
        android: const AndroidNotificationDetails(
          'weekly_report',
          '周报',
          channelDescription: '每周周报提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: '📊 本周战报',
      body: '一周的行动，塑造不一样的你 ✨',
      payload: 'weekly_report',
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// 调度每月月报通知（每月1号早上8点）
  Future<void> scheduleMonthlyReport() async {
    await _notifications.cancel(id: MonthlyReportNotificationId);

    final scheduledDate = _nextInstanceOfMonth(1, 8, 0);

    await _notifications.zonedSchedule(
      id: MonthlyReportNotificationId,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'monthly_report',
        ),
        android: const AndroidNotificationDetails(
          'monthly_report',
          '月报',
          channelDescription: '每月月报提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: '📈 本月战报',
      body: '一个月的坚持，你正在成为想成为的人 💪',
      payload: 'monthly_report',
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// 调度每年年报通知（每年1月1号早上8点）
  Future<void> scheduleYearlyReport() async {
    await _notifications.cancel(id: YearlyReportNotificationId);

    final scheduledDate = _nextInstanceOfNewYear(8, 0);

    await _notifications.zonedSchedule(
      id: YearlyReportNotificationId,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'yearly_report',
        ),
        android: const AndroidNotificationDetails(
          'yearly_report',
          '年报',
          channelDescription: '每年年报提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: '🎉 年度战报',
      body: '回顾这一年，你已经走了很远 🚀',
      payload: 'yearly_report',
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// 调度每日杠杆早安提醒（每天早上9点）
  Future<void> scheduleLeverReminder() async {
    await _notifications.cancel(id: LeverReminderNotificationId);

    final scheduledDate = _nextInstanceOfTime(9, 0);

    await _notifications.zonedSchedule(
      id: LeverReminderNotificationId,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'lever_reminder',
        ),
        android: const AndroidNotificationDetails(
          'lever_reminder',
          '杠杆提醒',
          channelDescription: '每日杠杆提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: '🔥 今天也要行动',
      body: '小行动，大改变。你准备好了吗？',
      payload: 'lever_reminder',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 取消每日杠杆提醒
  Future<void> cancelLeverReminder() async {
    await _notifications.cancel(id: LeverReminderNotificationId);
  }

  /// 调度专注时段提醒（开始通知 + 结束通知）
  Future<void> scheduleFocusReminder({
    required int leverIndex,
    required String content,
    required int hour,
    required int minute,
    required int durationMinutes,
  }) async {
    final baseId = FocusReminderBaseId + (leverIndex * 2);

    // 取消旧的（如果存在）
    await _notifications.cancel(id: baseId);
    await _notifications.cancel(id: baseId + 1);

    // 计算开始时间（明天这个时间）
    final now = DateTime.now();
    var startTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (startTime.isBefore(now) || startTime.isAtSameMomentAs(now)) {
      startTime = startTime.add(const Duration(days: 1));
    }

    // 结束时间
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    // 调度开始提醒
    await _notifications.zonedSchedule(
      id: baseId,
      scheduledDate: tz.TZDateTime.from(startTime, _location),
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'focus_reminder',
        ),
        android: const AndroidNotificationDetails(
          'focus_reminder',
          '专注提醒',
          channelDescription: '专注时段提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: '🎯 专注时间开始',
      body: content,
      payload: 'focus_start',
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 调度结束提醒
    await _notifications.zonedSchedule(
      id: baseId + 1,
      scheduledDate: tz.TZDateTime.from(endTime, _location),
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'focus_reminder',
        ),
        android: const AndroidNotificationDetails(
          'focus_reminder',
          '专注提醒',
          channelDescription: '专注时段提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: '⏰ 专注时间结束',
      body: '$durationMinutes分钟的专注完成！你做到了！',
      payload: 'focus_end',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 取消单个专注提醒
  Future<void> cancelFocusReminder(int leverIndex) async {
    final baseId = FocusReminderBaseId + (leverIndex * 2);
    await _notifications.cancel(id: baseId);
    await _notifications.cancel(id: baseId + 1);
  }

  /// 取消所有专注提醒
  Future<void> cancelAllFocusReminders() async {
    for (int i = 0; i < 10; i++) {
      await cancelFocusReminder(i);
    }
  }

  /// 调度所有报告通知
  Future<void> scheduleAllReports() async {
    await Future.wait([
      scheduleDailyReport(),
      scheduleWeeklyReport(),
      scheduleMonthlyReport(),
      scheduleYearlyReport(),
      scheduleLeverReminder(),
    ]);
  }

  /// 取消所有报告通知
  Future<void> cancelAllReportNotifications() async {
    await Future.wait([
      _notifications.cancel(id: DailyReportNotificationId),
      _notifications.cancel(id: WeeklyReportNotificationId),
      _notifications.cancel(id: MonthlyReportNotificationId),
      _notifications.cancel(id: YearlyReportNotificationId),
      _notifications.cancel(id: LeverReminderNotificationId),
    ]);
  }

  /// 获取下一个特定时间点
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 获取下一个特定周几的早上8点
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 获取下个月1号的早上8点
  tz.TZDateTime _nextInstanceOfMonth(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        day,
        hour,
        minute,
      );
    }

    return scheduledDate;
  }

  /// 获取明年1月1号的早上8点
  tz.TZDateTime _nextInstanceOfNewYear(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year + 1,
      1,
      1,
      hour,
      minute,
    );

    return scheduledDate;
  }
}

// 通知 ID 常量
const int DailyReportNotificationId = 1;
const int WeeklyReportNotificationId = 2;
const int MonthlyReportNotificationId = 3;
const int YearlyReportNotificationId = 4;
const int LeverReminderNotificationId = 5;
const int FocusReminderBaseId = 100; // 专注提醒从100开始，每个lever占2个ID（开始+结束）
