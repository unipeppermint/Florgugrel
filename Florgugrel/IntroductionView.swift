import SwiftUI

struct IntroductionView: View {
    var onComplete: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var selected = false
    @State private var placed = false
    var body: some View {
        ZStack {
            InkTheme.ink.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("牌阵师").font(.inkTitle(22)).foregroundColor(InkTheme.gold)
                        Spacer()
                        Button("直接进入") { onComplete() }.font(.inkBody(14)).foregroundColor(InkTheme.textSecondary).frame(minHeight: 44)
                    }
                    if step == 0 {
                        GeometryReader { proxy in
                            Image("BoardHero").resizable().scaledToFill()
                                .frame(width: proxy.size.width, height: 240).clipped()
                        }.frame(height: 240).clipShape(RoundedRectangle(cornerRadius: 18))
                        title("01 · 入局", "五行五列，落子成阵")
                        Text("将手中的扑克牌放上棋盘。与山海棋手轮流落子，争夺行、列和对角线的得分。")
                            .font(.inkBody(17)).foregroundColor(InkTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
                        Text("无需登录，随时开局。每一步都会自动保存。")
                            .font(.inkBody(13)).foregroundColor(InkTheme.gold)
                    } else if step == 1 {
                        title("02 · 试一手", "这条阵线，归你了")
                        Text("先选中 6♥，再点亮最后一格。金色「我」属于你，白色「对」属于山海棋手。")
                            .font(.inkBody(16)).foregroundColor(InkTheme.textSecondary)
                        HStack(spacing: 6) {
                            ForEach(0..<5) { index in
                                Button {
                                    if index == 4 && selected { placed = true }
                                } label: {
                                    VStack(spacing: 10) {
                                        Text(index == 4 && !placed ? "+" : "\(index + 2)♥").font(.inkBody(18, weight: .bold))
                                        Text(index == 4 && !placed ? "落子" : (index % 2 == 0 ? "我" : "对")).font(.inkBody(11))
                                    }.frame(maxWidth: .infinity).frame(height: 84)
                                    .foregroundColor(index % 2 == 0 ? InkTheme.gold : InkTheme.textPrimary)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(InkTheme.cardStrong))
                                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(index == 4 && selected ? InkTheme.gold : InkTheme.border))
                                }.buttonStyle(InkBoardButtonStyle()).disabled(index != 4 || !selected || placed)
                                .accessibilityLabel(index == 4 ? "演示落点" : "演示棋子 \(index + 2) 红心")
                            }
                        }
                        if !placed {
                            Button { selected.toggle() } label: {
                                Text("6♥").font(.inkBody(25, weight: .semibold)).foregroundColor(InkTheme.suitRed)
                                    .frame(width: 72, height: 96).background(RoundedRectangle(cornerRadius: 10).fill(InkTheme.parchment))
                                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? InkTheme.gold : .clear, lineWidth: 3))
                            }.frame(maxWidth: .infinity).buttonStyle(InkBoardButtonStyle())
                        }
                        FrostedCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(placed ? "同花顺 · 我方 +30" : "拥有 3 枚棋子，即可赢下整条阵线")
                                    .font(.inkTitle(20)).foregroundColor(InkTheme.gold)
                                Text(placed ? "2♥ 到 6♥ 连续且同花。你占了 3 格，因此这 30 分全部归你。" : "牌型决定分数，棋子数量决定归属。每条满线只计分一次。")
                                    .font(.inkBody(14)).foregroundColor(InkTheme.textSecondary)
                            }
                        }
                    } else {
                        title("03 · 启程", "找到你的对弈节奏")
                        mode("问道对弈", "与策略棋手交锋，积累段位与连胜。")
                        mode("闲庭对弈", "放松思考，可选入门或策略难度。")
                        mode("每日一题", "同日同题，仅一步机会，结算后查看最佳解。")
                        Text("完成对局积累灵玉与旅程经验，收藏山海印章。灵玉只用于游戏内收藏，无需付费。")
                            .font(.inkBody(15)).foregroundColor(InkTheme.textSecondary)
                    }
                    HStack(spacing: 7) {
                        ForEach(0..<3) { dot in Capsule().fill(dot == step ? InkTheme.gold : InkTheme.border).frame(width: dot == step ? 28 : 8, height: 5) }
                    }.frame(maxWidth: .infinity).accessibilityLabel("引导第 \(step + 1) 页，共 3 页")
                    GoldButton(title: step == 2 ? "开启山海棋局" : (step == 1 && !placed ? "先试着落下一张牌" : "继续")) {
                        if step == 2 { onComplete() }
                        else { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { step += 1 } }
                    }.disabled(step == 1 && !placed).opacity(step == 1 && !placed ? 0.5 : 1)
                }.padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
        }.preferredColorScheme(.dark)
    }
    private func title(_ kicker: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            KickerText(text: kicker)
            Text(text).font(.inkTitle(28)).foregroundColor(InkTheme.textPrimary)
        }
    }
    private func mode(_ name: String, _ detail: String) -> some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(name).font(.inkTitle(21)).foregroundColor(InkTheme.gold)
                Text(detail).font(.inkBody(14)).foregroundColor(InkTheme.textSecondary)
            }
        }
    }
}

struct IntroductionReplayView: View {
    @Environment(\.presentationMode) private var presentation
    var body: some View { IntroductionView { presentation.wrappedValue.dismiss() } }
}
