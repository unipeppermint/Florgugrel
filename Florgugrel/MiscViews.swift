import SwiftUI

struct SeasonView: View {
    @EnvironmentObject private var store: ProgressStore
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("山海旅程").font(.inkTitle(28)).foregroundColor(InkTheme.textPrimary)
                ZStack(alignment: .bottomLeading) {
                    GeometryReader { proxy in
                        Image("BoardHero").resizable().scaledToFill().frame(width: proxy.size.width, height: 200).clipped()
                    }
                    LinearGradient(colors: [.clear, InkTheme.ink.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 8) {
                        KickerText(text: "山 海 漫 行")
                        Text("每一步，都留下回响").font(.inkTitle(23)).foregroundColor(InkTheme.textPrimary)
                    }.padding(18)
                }.frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                FrostedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("旅程等级").foregroundColor(InkTheme.textPrimary)
                            Spacer()
                            Text("Lv. \(store.level)").foregroundColor(InkTheme.gold)
                        }.font(.inkBody(18, weight: .semibold))
                        ProgressView(value: store.levelProgress).accentColor(InkTheme.gold)
                        Text("\(store.data.experience % 200) / 200 经验 · 完成对弈 +100，每日一题 +80")
                            .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                    }
                }
                ForEach(JourneyMission.all) { mission in
                    missionCard(mission)
                }
                Text("旅程任务长期有效，每项奖励可领取一次。")
                    .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
            }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 100)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background(InkTheme.ink)
    }
    private func missionCard(_ mission: JourneyMission) -> some View {
        let progress = store.missionProgress(mission)
        let claimed = store.data.claimed.contains(mission.id)
        return FrostedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(mission.title).font(.inkTitle(19)).foregroundColor(InkTheme.textPrimary)
                    Spacer()
                    Text("◈ \(mission.reward)").font(.inkBody(14, weight: .semibold)).foregroundColor(InkTheme.gold)
                }
                Text(mission.detail).font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                ProgressView(value: Double(min(progress, mission.target)), total: Double(mission.target)).accentColor(InkTheme.gold)
                HStack {
                    Text("\(min(progress, mission.target)) / \(mission.target)")
                    Spacer()
                    Button(claimed ? "已领取 ✓" : (progress >= mission.target ? "领取奖励" : "进行中")) { store.claim(mission) }
                        .foregroundColor(progress >= mission.target && !claimed ? InkTheme.gold : InkTheme.textSecondary)
                        .disabled(claimed || progress < mission.target)
                }.font(.inkBody(13)).foregroundColor(InkTheme.textSecondary)
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var page: ProfilePage?
    enum ProfilePage: String, Identifiable { case history, settings, rules, introduction, privacy, help; var id: String { rawValue } }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack(spacing: 14) {
                    FlorgugrelBeastArtwork(card: store.equippedCard).frame(width: 60, height: 60)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.data.nickname).font(.inkTitle(24)).foregroundColor(InkTheme.textPrimary)
                        Text("\(store.rankTitle) · Lv. \(store.level)").font(.inkBody(13)).foregroundColor(InkTheme.gold)
                    }
                    Spacer()
                }.padding(.top, 12)
                FrostedCard {
                    HStack {
                        metric("\(store.data.totalGames)", "完成对局")
                        metric(store.winRate, "段位胜率")
                        metric("\(store.data.bestStreak)", "最高连胜")
                    }
                }
                FrostedCard {
                    VStack(spacing: 0) {
                        row("战绩回顾", "clock.arrow.circlepath", .history)
                        Divider().background(InkTheme.border)
                        row("对弈指南", "book", .rules)
                        Divider().background(InkTheme.border)
                        row("个人设置", "slider.horizontal.3", .settings)
                        Divider().background(InkTheme.border)
                        row("重看入门教学", "hand.tap", .introduction)
                        Divider().background(InkTheme.border)
                        row("隐私政策", "hand.raised", .privacy)
                        Divider().background(InkTheme.border)
                        row("帮助与反馈", "questionmark.circle", .help)
                    }
                }
                FrostedCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("问道段位 · \(store.data.rating) 分").font(.inkBody(16, weight: .semibold)).foregroundColor(InkTheme.gold)
                        Text("问道对弈采用策略对手。胜利 +25 分，失败 −10 分，平局不变。每 100 分进阶一档，最高为天衍。认负同样计为失败，不发放对局奖励。")
                            .font(.inkBody(13)).foregroundColor(InkTheme.textSecondary)
                    }
                }
                if let warning = store.storageWarning {
                    Text(warning).font(.inkBody(13)).foregroundColor(InkTheme.gold)
                }
                Text("牌阵师 · \(AppInformation.version)\n以牌成阵，以阵会友。")
                    .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary).multilineTextAlignment(.center).lineSpacing(5)
            }.padding(.horizontal, 20).padding(.bottom, 100)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background(InkTheme.ink)
        .sheet(item: $page) { page in
            Group {
                switch page {
                case .history: HistoryView().environmentObject(store)
                case .settings: SettingsView(store: store)
                case .rules: RulesView()
                case .introduction: IntroductionReplayView()
                case .privacy: PrivacyView()
                case .help: HelpView()
                }
            }.preferredColorScheme(.dark)
        }
    }
    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 7) {
            Text(value).font(.inkBody(23, weight: .bold)).foregroundColor(InkTheme.gold)
            Text(label).font(.inkBody(11)).foregroundColor(InkTheme.textSecondary)
        }.frame(maxWidth: .infinity)
    }
    private func row(_ title: String, _ icon: String, _ destination: ProfilePage) -> some View {
        Button { page = destination } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).frame(width: 22).foregroundColor(InkTheme.gold)
                Text(title).foregroundColor(InkTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(InkTheme.textSecondary)
            }.font(.inkBody(15)).padding(.vertical, 18).contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.presentationMode) private var presentation
    @State private var selected: MatchRecord?
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    if store.data.history.isEmpty {
                        EmptyState(symbol: "square.grid.3x3", title: "棋局尚未落笔", detail: "完成一局练习或每日一题，战绩将自动保存在这里。")
                    }
                    ForEach(store.data.history) { record in
                        Button { selected = record } label: {
                        FrostedCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(record.mode.title + " · " + record.title).foregroundColor(InkTheme.textPrimary)
                                    Spacer()
                                    Text(record.mode == .daily ? "\(record.playerScore)/\(record.dailyBest)" : "\(record.playerScore) : \(record.opponentScore)")
                                        .foregroundColor(InkTheme.gold)
                                }.font(.inkBody(15, weight: .semibold))
                                HStack {
                                    Text(record.date, style: .date)
                                    Text(record.date, style: .time)
                                    Spacer()
                                    Text("◈ +\(record.reward)")
                                }.font(.inkBody(11)).foregroundColor(InkTheme.textSecondary)
                                if record.finalSnapshot != nil {
                                    Text("查看棋局复盘 ›").font(.inkBody(12)).foregroundColor(InkTheme.gold)
                                }
                            }
                        }
                        }.buttonStyle(PlainButtonStyle()).disabled(record.finalSnapshot == nil)
                    }
                    if !store.data.history.isEmpty {
                        Text("展示最近 100 局，累计统计保留累计数据。")
                            .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                    }
                }.padding(20)
            }.background(InkTheme.ink.ignoresSafeArea())
            .navigationTitle("战绩回顾").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { presentation.wrappedValue.dismiss() } } }
        }.accentColor(InkTheme.gold).preferredColorScheme(.dark)
        .sheet(item: $selected) { record in
            if let snapshot = record.finalSnapshot, snapshot.isValid {
                GameReviewView(engine: GameEngine(mode: snapshot.mode, snapshot: snapshot))
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: ProgressStore
    @Environment(\.presentationMode) private var presentation
    @State private var nickname: String
    @State private var difficulty: GameEngine.Difficulty
    @State private var haptics: Bool
    @State private var confirmReset = false
    init(store: ProgressStore) {
        self.store = store
        _nickname = State(initialValue: store.data.nickname)
        _difficulty = State(initialValue: store.data.difficulty)
        _haptics = State(initialValue: store.data.haptics)
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("个人资料"), footer: Text("昵称最多 12 个字符，仅保存在本机。")) {
                    TextField("昵称", text: $nickname)
                        .onChange(of: nickname) { if $0.count > 12 { nickname = String($0.prefix(12)) } }
                }
                Section(header: Text("对弈偏好"), footer: Text("难度对下一局闲庭对弈生效；问道对弈固定为策略难度。")) {
                    Picker("闲庭对弈难度", selection: $difficulty) {
                        ForEach(GameEngine.Difficulty.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Toggle("落子触感反馈", isOn: $haptics)
                }
                Section(header: Text("关于存档")) {
                    Text("每次落子后自动保存。退出对局或关闭应用后，可在首页继续。每日一题完成记录按 UTC 日期保存。")
                        .font(.inkBody(14)).foregroundColor(.secondary)
                    Button("清除本机全部进度") { confirmReset = true }.foregroundColor(.red)
                }
            }
            .alert(isPresented: $confirmReset) {
                Alert(title: Text("清除全部进度？"), message: Text("这将删除本机战绩、收藏、灵玉、设置和未完成对局，包括异常存档备份。操作不可恢复。"),
                      primaryButton: .destructive(Text("确认清除")) {
                        store.resetProgress(); presentation.wrappedValue.dismiss()
                      }, secondaryButton: .cancel(Text("取消")))
            }
            .navigationTitle("个人设置").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { presentation.wrappedValue.dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.updateSettings(nickname: nickname, difficulty: difficulty, haptics: haptics)
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
        }.accentColor(InkTheme.gold).preferredColorScheme(.dark)
    }
}
