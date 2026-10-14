import SwiftUI
import UIKit

struct ShareContent: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct RulesView: View {
    @Environment(\.presentationMode) private var presentation
    private let ranks: [(String, Int)] = [
        ("皇家同花顺", 50), ("同花顺", 30), ("四条", 20), ("葫芦", 14),
        ("同花", 10), ("顺子", 8), ("三条", 6), ("两对", 4), ("一对", 2), ("高牌", 1)
    ]
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    KickerText(text: "HOW TO PLAY")
                    Text("以牌成阵，以阵取胜").font(.inkTitle(26))
                    instruction("01", "选牌与落子", "点击手牌，再点击棋盘上的空格。落子后自动补牌，双方轮流行动。金色棋子属于你，白色属于对手。")
                    instruction("02", "争夺阵线", "每行、每列和两条长对角线都能计分，共 12 条。填满 5 张牌时，拥有至少 3 枚棋子的一方获得整条线的牌型分数，每条线只计一次。")
                    instruction("03", "一局胜负", "棋盘填满后，总分高者获胜。普通对弈随机决定先后手；问道对弈固定使用策略对手，闲庭对弈的难度可在设置中调整。")
                    instruction("04", "每日一题", "UTC 每日 0 点更新固定残局，北京时间 8 点。每台设备每天完成一次，仅计算你这一步新完成的阵线。完成后可比较最佳分数，退出未完成挑战可以继续。")
                    FrostedCard {
                        VStack(spacing: 12) {
                            ForEach(ranks, id: \.0) { rank in
                                HStack { Text(rank.0); Spacer(); Text("\(rank.1) 分").foregroundColor(InkTheme.gold) }
                            }
                        }.font(.inkBody(14))
                    }
                    Text("A 可组成 A-2-3-4-5 或 10-J-Q-K-A，不能跨首尾连接。灵玉由完成对局和旅程任务获得，仅用于图鉴解锁。")
                        .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                }.padding(20)
            }
            .background(InkTheme.ink.ignoresSafeArea())
            .foregroundColor(InkTheme.textPrimary)
            .navigationTitle("对弈指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { presentation.wrappedValue.dismiss() } } }
        }.preferredColorScheme(.dark).accentColor(InkTheme.gold)
    }
    private func instruction(_ number: String, _ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number)  \(title)").font(.inkBody(16, weight: .semibold)).foregroundColor(InkTheme.gold)
            Text(text).font(.inkBody(14)).foregroundColor(InkTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 30)).foregroundColor(InkTheme.gold)
            Text(title).font(.inkTitle(20)).foregroundColor(InkTheme.textPrimary)
            Text(detail).font(.inkBody(13)).foregroundColor(InkTheme.textSecondary).multilineTextAlignment(.center)
        }.padding(28).frame(maxWidth: .infinity)
    }
}
