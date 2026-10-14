import SwiftUI
import Combine

struct DailyChallengeView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: ProgressStore
    @State private var now = Date()
    @State private var share = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var result: MatchRecord? { store.dailyResult(on: now) }
    private var recent: [MatchRecord] {
        store.data.dailyResults.values.sorted { $0.date > $1.date }.prefix(7).map { $0 }
    }
    private var countdown: String {
        let seconds = max(0, Int(DailyPuzzle.nextRefresh(after: now).timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, seconds % 3600 / 60, seconds % 60)
    }
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    KickerText(text: "ONE MOVE · ONE DAY")
                    Text("一步落子，山海成阵").font(.inkTitle(27)).foregroundColor(InkTheme.textPrimary)
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(DailyPuzzle.key(for: now)).font(.inkBody(14, weight: .semibold)).foregroundColor(InkTheme.gold)
                            Text("同日同题 · 五处落点").font(.inkTitle(23)).foregroundColor(InkTheme.textPrimary)
                            Text("观察棋子归属与牌型，用唯一的一张手牌找出得分最高的位置。")
                                .font(.inkBody(14)).foregroundColor(InkTheme.textSecondary)
                            InfoChip(text: "下题倒计时 \(countdown)", gold: true)
                        }
                    }
                    if let result {
                        FrostedCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(result.title).font(.inkTitle(23)).foregroundColor(InkTheme.gold)
                                Text("今日得分 \(result.playerScore) · 最佳 \(result.dailyBest)")
                                    .font(.inkBody(16)).foregroundColor(InkTheme.textPrimary)
                                Text("灵玉 +\(result.reward) · 明天再来试试新的残局。")
                                    .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                                GoldButton(title: "分享今日战绩") { share = true }
                            }
                        }
                    } else if let saved = store.data.activeGame {
                        if saved.mode == .daily {
                            GoldButton(title: "继续 \(saved.dailyKey) 的挑战") {
                                app.pendingGame = GameRequest(mode: .daily, snapshot: saved)
                                app.showDaily = false
                            }
                        } else {
                            Text("你还有一局未完成的练习，请先返回主页继续或结束该局。")
                                .font(.inkBody(14)).foregroundColor(InkTheme.gold)
                        }
                    } else {
                        GoldButton(title: "开始今日挑战") { app.openDailyGame() }
                    }
                    Text("每日一次，按 UTC 0 点刷新（北京时间 8 点）。每日同题，无需网络。只计算本次新完成的阵线，预置满线不计分。")
                        .font(.inkBody(13)).foregroundColor(InkTheme.textSecondary)
                    Text("我的挑战足迹").font(.inkTitle(20)).foregroundColor(InkTheme.textPrimary)
                    if recent.isEmpty {
                        EmptyState(symbol: "calendar", title: "从今天开始", detail: "完成挑战后，这里会留下你的每日成绩。")
                    } else {
                        FrostedCard {
                            VStack(spacing: 16) {
                                ForEach(recent) { record in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(record.dailyKey ?? "").foregroundColor(InkTheme.textPrimary)
                                            Text(record.title).font(.inkBody(11)).foregroundColor(InkTheme.textSecondary)
                                        }
                                        Spacer()
                                        Text("\(record.playerScore) / \(record.dailyBest)").foregroundColor(InkTheme.gold)
                                    }.font(.inkBody(14))
                                }
                            }
                        }
                    }
                }.padding(20)
            }
            .background(InkTheme.ink.ignoresSafeArea())
            .navigationTitle("每日一题").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { app.showDaily = false } } }
        }
        .accentColor(InkTheme.gold).preferredColorScheme(.dark)
        .onReceive(timer) { now = $0 }
        .sheet(isPresented: $share) {
            if let result {
                ShareSheet(items: ["牌阵师 · 每日一题 \(result.dailyKey ?? "")\n我的得分 \(result.playerScore) / 最佳 \(result.dailyBest)\n一步落子，山海成阵。"])
            }
        }
    }
}
