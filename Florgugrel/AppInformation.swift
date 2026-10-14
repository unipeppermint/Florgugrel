import SwiftUI
import UIKit

enum AppInformation {
    static var version: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
    static var privacyURL: URL? { configuredURL("HandcraftPrivacyURL") }
    static var supportURL: URL? { configuredURL("HandcraftSupportURL") }
    private static func configuredURL(_ key: String) -> URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              let url = URL(string: raw), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
    static let privacySections: [(String, String)] = [
        ("数据留在你的设备", "牌阵师无需注册或登录，不向开发者服务器收集或上传个人信息，不包含广告、行为分析或跟踪 SDK。游戏不会读取通讯录、位置、相机、麦克风或广告标识符。"),
        ("为了保存你的棋局", "应用在本机保存昵称、偏好设置、对局快照、战绩、每日挑战记录、收藏和旅程进度。这些数据用于继续对局、计算统计、解锁收藏及保留设置。昵称不需要使用真实姓名。"),
        ("分享由你决定", "只有你主动点击分享并选择接收应用后，所选战绩、昵称或诊断摘要才会交给该应用处理。分享前可以取消。选择保存海报到相册时，系统可能请求添加照片的权限；应用不会读取你的相册。接收应用的数据处理遵循其自身隐私政策。"),
        ("保留、备份与删除", "本机数据会保留至你在「个人设置」中清除进度或删除应用。系统设备备份可能包含应用数据，由你的 Apple 备份设置管理；牌阵师不提供自己的云同步。解析失败的存档备份也会在清除进度时删除。清除操作不可恢复。"),
        ("隐私与联系", "如需咨询，请使用 App Store 产品页的「App 支持」联系开发者。本说明更新于 2026 年 10 月 8 日；如数据处理方式发生改变，将同步更新说明。")
    ]
}

struct PrivacyView: View {
    @Environment(\.presentationMode) private var presentation
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    KickerText(text: "隐 私 政 策")
                    Text("安心落子，数据由你掌握").font(.inkTitle(25)).foregroundColor(InkTheme.textPrimary)
                    ForEach(AppInformation.privacySections, id: \.0) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.0).font(.inkBody(17, weight: .semibold)).foregroundColor(InkTheme.gold)
                            Text(section.1).font(.inkBody(15)).foregroundColor(InkTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let url = AppInformation.privacyURL { Link("浏览网页版隐私政策", destination: url).foregroundColor(InkTheme.gold).frame(minHeight: 44) }
                }.padding(24)
            }.background(InkTheme.ink.ignoresSafeArea())
            .navigationTitle("隐私政策").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { presentation.wrappedValue.dismiss() } } }
        }.preferredColorScheme(.dark).accentColor(InkTheme.gold)
    }
}

struct HelpView: View {
    @Environment(\.presentationMode) private var presentation
    @State private var showReport = false
    private var report: String { "牌阵师问题反馈\n应用版本：\(AppInformation.version)\n系统版本：iOS \(UIDevice.current.systemVersion)\n\n遇到的问题：\n复现步骤：\n\n此摘要不包含昵称、棋局或个人标识。" }
    private let questions = [
        ("退出后如何继续？", "每次落子自动保存。点击棋局左上角可暂存退出，首页会显示继续入口。问道对弈中选择认负会记录失败；闲庭对弈可直接结束。"),
        ("每日一题何时更新？", "按 UTC 日期，每天北京时间 8 点更新。已开启的旧题可继续完成，其成绩归原题日期。当天成绩已完成后不再重复发放奖励。"),
        ("为什么一条线给对方加分？", "归属取决于线上的棋子数量，拥有至少 3 枚的一方获得整条线的分数；并不是谁落下最后一张牌谁得分。结算后的复盘可查看每条阵线。"),
        ("灵玉需要购买吗？", "不需要。完成对局和旅程任务即可获得灵玉，用于解锁印章。印章只改变外观，不影响胜负。"),
        ("更换设备能恢复进度吗？", "应用没有账号或独立云同步。系统备份是否恢复应用数据取决于你的设备备份设置。清除本机进度后，应用无法恢复。")
    ]
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("常见问题").font(.inkTitle(26)).foregroundColor(InkTheme.textPrimary)
                    ForEach(questions, id: \.0) { question in
                        FrostedCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(question.0).font(.inkBody(16, weight: .semibold)).foregroundColor(InkTheme.gold)
                                Text(question.1).font(.inkBody(14)).foregroundColor(InkTheme.textSecondary)
                            }
                        }
                    }
                    if let url = AppInformation.supportURL {
                        Link("联系开发者", destination: url).font(.inkBody(16, weight: .semibold)).foregroundColor(InkTheme.gold).frame(minHeight: 44)
                    }
                    Text("通过 App Store 产品页的「App 支持」反馈问题时，可附上以下版本摘要。摘要仅含应用和系统版本，你可以在发送前补充问题说明。")
                        .font(.inkBody(13)).foregroundColor(InkTheme.textSecondary)
                    GoldButton(title: "分享问题反馈摘要") { showReport = true }
                    Text("牌阵师 · \(AppInformation.version)").font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                }.padding(20)
            }.background(InkTheme.ink.ignoresSafeArea())
            .navigationTitle("帮助与反馈").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { presentation.wrappedValue.dismiss() } } }
        }.preferredColorScheme(.dark).accentColor(InkTheme.gold)
        .sheet(isPresented: $showReport) { ShareSheet(items: [report]) }
    }
}
