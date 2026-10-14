import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: ProgressStore
    @State private var showRules = false
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                hero
                if let saved = store.data.activeGame {
                    GoldButton(title: "继续\(saved.mode.title) · 已落 \(saved.board.filter { $0.card != nil }.count) 格") {
                        app.gameRequest = GameRequest(mode: saved.mode, snapshot: saved)
                    }
                    Text("当前对局已自动保存，结束后可开启新局。")
                        .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                } else {
                    HStack(spacing: 12) {
                        GoldButton(title: "问道对弈") { app.gameRequest = GameRequest(mode: .ranked) }
                        OutlineButton(title: "闲庭对弈") { app.gameRequest = GameRequest(mode: .casual) }
                    }
                }
                FrostedCard {
                    HStack {
                        stat(store.winRate, "段位胜率")
                        Spacer()
                        stat(store.rankTitle, "问道段位")
                        Spacer()
                        stat("\(store.data.streak)", "当前连胜")
                    }
                }
                Button { app.showDaily = true } label: {
                    FrostedCard(padding: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("每日一题 · 一步成阵").font(.inkTitle(17)).foregroundColor(InkTheme.textPrimary)
                                Text("按 UTC 日期出题 · 查看今日挑战")
                                    .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").foregroundColor(InkTheme.gold)
                        }
                    }
                }.buttonStyle(PlainButtonStyle())
                Button { app.selectedTab = 2 } label: {
                    FrostedCard(padding: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("山海旅程 · 落子成章").font(.inkBody(15, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }.foregroundColor(InkTheme.textPrimary)
                            ProgressView(value: Double(min(store.data.totalMoves, 50)), total: 50).accentColor(InkTheme.gold)
                            Text("已完成对局中落子 \(min(store.data.totalMoves, 50)) / 50 · 奖励 100 灵玉")
                                .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                        }
                    }
                }.buttonStyle(PlainButtonStyle())
                Button("第一次来？查看对弈指南") { showRules = true }
                    .font(.inkBody(13)).foregroundColor(InkTheme.gold)
                Text("与山海棋手对弈 · 无需网络")
                    .font(.inkBody(11)).foregroundColor(InkTheme.textSecondary)
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 100)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(InkTheme.ink)
        .sheet(isPresented: $showRules) { RulesView() }
    }
    private var header: some View {
        HStack(spacing: 12) {
            BeastSeal(card: store.equippedCard)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("山海有约，落子有声").font(.inkBody(11)).foregroundColor(InkTheme.textSecondary)
                Text(store.data.nickname).font(.inkTitle(19)).foregroundColor(InkTheme.textPrimary)
            }
            Spacer()
            InfoChip(text: "◈ \(store.data.coins)", gold: true)
        }
    }
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { proxy in
                Image("BoardHero").resizable().scaledToFill().frame(width: proxy.size.width, height: 236).clipped()
            }
            LinearGradient(colors: [.clear, InkTheme.ink.opacity(0.95)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                KickerText(text: "牌 阵 师  ·  山 海 棋 局")
                Text("以牌成阵，以阵会友").font(.inkTitle(25)).foregroundColor(InkTheme.textPrimary)
                Text("五行五列，争一线之机。").font(.inkBody(13)).foregroundColor(InkTheme.textSecondary)
            }.padding(20)
        }.frame(height: 236).clipShape(RoundedRectangle(cornerRadius: 18))
    }
    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.inkBody(20, weight: .semibold)).foregroundColor(InkTheme.gold).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.inkBody(11)).foregroundColor(InkTheme.textSecondary)
        }.frame(maxWidth: .infinity)
    }
}
