import WidgetKit
import SwiftUI

// MARK: - 数据模型

struct LianlemaData: Codable {
    let antiVision: String          // 反愿景全文
    let antiVisionCore: String      // 反愿景核心句
    let streak: Int                 // 连续打卡天数
    let todayLevers: [LeverItem]    // 今日杠杆列表
    let monthlyBoss: MonthlyBossItem? // 月度Boss
    let level: Int                  // 当前等级
    let todayCompleted: Int         // 今日完成数
    let todayTotal: Int             // 今日总数
    let lastUpdated: String         // 最后更新时间

    struct LeverItem: Codable, Identifiable {
        let id: String
        let content: String
        let isCompleted: Bool
    }

    struct MonthlyBossItem: Codable {
        let content: String
        let hp: Int
        let totalDays: Int
    }

    static var placeholder: LianlemaData {
        LianlemaData(
            antiVision: "我不想成为一个每天抱怨却不行动、推卸责任、安于现状的人。",
            antiVisionCore: "每天抱怨却不行动的人",
            streak: 7,
            todayLevers: [
                LeverItem(id: "1", content: "阅读30分钟", isCompleted: true),
                LeverItem(id: "2", content: "运动30分钟", isCompleted: false),
                LeverItem(id: "3", content: "写作500字", isCompleted: false)
            ],
            monthlyBoss: MonthlyBossItem(content: "养成早起习惯", hp: 15, totalDays: 30),
            level: 5,
            todayCompleted: 1,
            todayTotal: 3,
            lastUpdated: "2024-01-15 08:00"
        )
    }
}

// MARK: - Widget 数据提供

struct LianlemaProvider: TimelineProvider {
    func placeholder(in context: Context) -> LianlemaEntry {
        LianlemaEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (LianlemaEntry) -> Void) {
        let entry = LianlemaEntry(date: Date(), data: loadData() ?? .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LianlemaEntry>) -> Void) {
        let data = loadData() ?? .placeholder
        let entry = LianlemaEntry(date: Date(), data: data)
        // 每小时刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadData() -> LianlemaData? {
        // 通过 App Groups 读取共享数据
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.lianlema.app"
        ) else { return nil }

        let fileURL = containerURL.appendingPathComponent("widget_data.json")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        let decoder = JSONDecoder()
        return try? decoder.decode(LianlemaData.self, from: data)
    }
}

struct LianlemaEntry: TimelineEntry {
    let date: Date
    let data: LianlemaData
}

// MARK: - Small Widget

struct LianlemaSmallWidget: Widget {
    let kind: String = "LianlemaSmall"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LianlemaProvider()) { entry in
            LianlemaSmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("练了吗")
        .description("显示反愿景一句话和连续打卡天数")
        .supportedFamilies([.systemSmall])
    }
}

struct LianlemaSmallWidgetView: View {
    let entry: LianlemaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 反愿景一句话
            Text(entry.data.antiVisionCore)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "1A1A1A"))
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer()

            // Streak 天数
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 18))
                Text("\(entry.data.streak)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "E85A1C"))
                Text("天")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8B7355"))
            }
        }
        .padding(14)
    }
}

// MARK: - Medium Widget

struct LianlemaMediumWidget: Widget {
    let kind: String = "LianlemaMedium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LianlemaProvider()) { entry in
            LianlemaMediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("练了吗")
        .description("显示反愿景核心句、今日杠杆进度和连续打卡天数")
        .supportedFamilies([.systemMedium])
    }
}

struct LianlemaMediumWidgetView: View {
    let entry: LianlemaEntry

    var body: some View {
        HStack(spacing: 16) {
            // 左侧：反愿景
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "E85A1C"))
                    Text("反愿景")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "8B7355"))
                }

                Text(entry.data.antiVisionCore)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Streak
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 16))
                    Text("\(entry.data.streak)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "E85A1C"))
                    Text("天连续打卡")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8B7355"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 右侧：今日进度
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "E85A1C"))
                    Text("今日杠杆")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "8B7355"))
                }

                // 进度条
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(entry.data.todayCompleted)/\(entry.data.todayTotal)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        Text("完成")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8B7355"))
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "E85A1C").opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "E85A1C"))
                                .frame(
                                    width: geometry.size.width * progress,
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }

                Spacer()

                // 等级
                HStack(spacing: 4) {
                    Text("Lv\(entry.data.level)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "E85A1C"))
                    Text("职场新人")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "8B7355"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }

    private var progress: CGFloat {
        guard entry.data.todayTotal > 0 else { return 0 }
        return CGFloat(entry.data.todayCompleted) / CGFloat(entry.data.todayTotal)
    }
}

// MARK: - Large Widget

struct LianlemaLargeWidget: Widget {
    let kind: String = "LianlemaLarge"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LianlemaProvider()) { entry in
            LianlemaLargeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("练了吗")
        .description("显示反愿景全文、今日杠杆列表、连续打卡天数和月度Boss进度")
        .supportedFamilies([.systemLarge])
    }
}

struct LianlemaLargeWidgetView: View {
    let entry: LianlemaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：标题栏
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("练了吗")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "E85A1C"))
                    Text("每天行动，成为想成为的人")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8B7355"))
                }

                Spacer()

                // Streak
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 18))
                    Text("\(entry.data.streak)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "E85A1C"))
                    Text("天")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8B7355"))
                }
            }

            Divider()

            // 反愿景全文
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "E85A1C"))
                    Text("反愿景提醒")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "8B7355"))
                    Spacer()
                    Text("锁定中")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "8B7355"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "8B7355").opacity(0.1))
                        .cornerRadius(4)
                }

                Text(entry.data.antiVision)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(10)
            .background(Color(hex: "E85A1C").opacity(0.05))
            .cornerRadius(10)

            // 今日杠杆列表
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "E85A1C"))
                    Text("今日杠杆")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "8B7355"))
                    Spacer()
                    Text("\(entry.data.todayCompleted)/\(entry.data.todayTotal)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "E85A1C"))
                }

                ForEach(entry.data.todayLevers.prefix(3)) { lever in
                    HStack(spacing: 8) {
                        Image(systemName: lever.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundColor(
                                lever.isCompleted
                                    ? Color(hex: "4CAF50")
                                    : Color(hex: "8B7355").opacity(0.4)
                            )

                        Text(lever.content)
                            .font(.system(size: 13))
                            .foregroundColor(
                                lever.isCompleted
                                    ? Color(hex: "8B7355")
                                    : Color(hex: "1A1A1A")
                            )
                            .strikethrough(lever.isCompleted, color: Color(hex: "8B7355"))

                        Spacer()
                    }
                }
            }
            .padding(10)
            .background(Color(hex: "E85A1C").opacity(0.05))
            .cornerRadius(10)

            // 月度Boss进度
            if let boss = entry.data.monthlyBoss {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("👹")
                            .font(.system(size: 11))
                        Text("本月Boss战")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "8B7355"))
                        Spacer()
                        Text("HP: \(boss.hp)/\(boss.totalDays)")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "8B7355"))
                    }

                    Text(boss.content)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "1A1A1A"))
                        .lineLimit(1)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "E85A1C").opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "E85A1C"), Color(hex: "FF8E72")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * bossProgress(boss),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }
                .padding(10)
                .background(Color(hex: "E85A1C").opacity(0.05))
                .cornerRadius(10)
            }

            Spacer(minLength: 0)

            // 底部等级栏
            HStack {
                Text("Lv\(entry.data.level)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "E85A1C"))
                    .cornerRadius(6)

                Text(XpService.levelTitle(entry.data.level))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8B7355"))

                Spacer()

                Text("更新于 \(entry.data.lastUpdated)")
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "8B7355"))
            }
        }
        .padding(16)
    }

    private func bossProgress(_ boss: LianlemaData.MonthlyBossItem) -> CGFloat {
        guard boss.totalDays > 0 else { return 0 }
        return CGFloat(boss.hp) / CGFloat(boss.totalDays)
    }
}

// MARK: - XpService

enum XpService {
    static func levelTitle(_ level: Int) -> String {
        switch level {
        case 1...5: return "职场新人"
        case 6...10: return "行动派"
        case 11...20: return "习惯达人"
        case 21...50: return "自律高手"
        default: return "人生赢家"
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Bundle

@main
struct LianlemaWidgetBundle: WidgetBundle {
    var body: some Widget {
        LianlemaSmallWidget()
        LianlemaMediumWidget()
        LianlemaLargeWidget()
    }
}
