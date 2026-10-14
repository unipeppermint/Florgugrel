//
//  BattleView.swift
//  Florgugrel · 牌阵师 Handcraft
//
//  核心对局「牌阵」：对手栏、比分、5×5 棋盘、手牌、出牌按钮
//

import SwiftUI
import UIKit

struct BattleView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var engine: GameEngine
    @State private var showRules = false
    @State private var showAbandon = false
    @State private var showReview = false
    @State private var dailyCell: Int?
    @State private var shareContent: ShareContent?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(request: GameRequest, difficulty: GameEngine.Difficulty) {
        _engine = StateObject(wrappedValue: GameEngine(mode: request.mode,
            difficulty: request.mode == .ranked ? .strategic : difficulty, snapshot: request.snapshot))
    }

    var body: some View {
        ZStack {
            InkTheme.ink.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    opponentBar
                    scoreStrip
                    HStack {
                        Text(engine.mode.title + " · \(engine.filledCount)/25 格")
                        Spacer()
                        Button("规则") { engine.pause(); showRules = true }.frame(minWidth: 44, minHeight: 44)
                    }
                    .font(.inkBody(12)).foregroundColor(InkTheme.gold)
                    boardGrid
                    Text(engine.lastEvent)
                        .font(.inkBody(12)).foregroundColor(InkTheme.gold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("最近得分：" + engine.lastEvent)
                    handRow.frame(maxWidth: .infinity).padding(.top, 12)
                    hintText
                    if engine.mode == .daily && engine.turn != .finished {
                        GoldButton(title: dailyCell.map { "确认落子 · 第 \($0 / 5 + 1) 行第 \($0 % 5 + 1) 列" } ?? "选牌后，选择一个落点") {
                            guard let cell = dailyCell else { return }
                            engine.place(at: cell); dailyCell = nil
                            if store.data.haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                        }.disabled(dailyCell == nil || !engine.canPlace).opacity(dailyCell == nil || !engine.canPlace ? 0.5 : 1)
                    }
                    HStack {
                        Label(engine.mode == .daily ? "确认前可更换落点" : "点击空格直接落子", systemImage: "hand.tap")
                        Spacer()
                        Button(engine.mode == .ranked ? "认负" : "结束本局") { engine.pause(); showAbandon = true }.frame(minWidth: 60, minHeight: 44)
                    }
                    .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
            }
            .accessibilityHidden(engine.resultText != nil)

            if let result = engine.resultText {
                resultOverlay(result)
            }
        }
        .onAppear {
            engine.onChange = { [weak engine = engine] in
                guard let engine else { return }
                store.checkpoint(engine)
            }
            store.checkpoint(engine)
            engine.resume()
        }
        .onDisappear { engine.pause(); engine.onChange = nil }
        .onChange(of: scenePhase) { phase in
            if phase == .active && !showRules && !showAbandon { engine.resume() }
            else { engine.pause(); store.checkpoint(engine) }
        }
        .sheet(isPresented: $showRules, onDismiss: engine.resume) { RulesView() }
        .sheet(item: $shareContent) { content in ShareSheet(items: content.items) }
        .sheet(isPresented: $showReview) { GameReviewView(engine: engine) }
        .alert(isPresented: $showAbandon) {
            Alert(title: Text(engine.mode == .ranked ? "收子认负？" : "结束这局对弈？"),
                  message: Text(engine.mode == .ranked ? "本局将计为失败，扣除 10 段位分（最低为 0），且不发放奖励。左上角返回可保存棋局，稍后继续。" : "本局不计入战绩。左上角返回可保存棋局，稍后继续。"),
                  primaryButton: .destructive(Text(engine.mode == .ranked ? "确认认负" : "结束本局")) {
                    if engine.mode == .ranked { engine.resign() }
                    else { engine.pause(); store.abandonGame(); app.gameRequest = nil }
                  }, secondaryButton: .cancel(Text("继续对弈"), action: engine.resume))
        }
    }

    private var shareText: String {
        if engine.mode == .daily {
            return "牌阵师 · 每日一题 \(engine.dailyKey)\n我的得分 \(engine.playerScore) / 最佳 \(engine.dailyBest)\n一步落子，山海成阵。"
        }
        return "牌阵师 · \(engine.mode.title)\n\(engine.resultText ?? "对局结束") · \(engine.playerScore) : \(engine.opponentScore)\n以牌成阵，以阵会友。"
    }

    // MARK: 对手栏

    private var opponentBar: some View {
        HStack(spacing: 12) {
            Button {
                engine.pause()
                store.checkpoint(engine)
                app.gameRequest = nil
            } label: {
                Image(systemName: "chevron.left")
                    .font(.inkBody(14, weight: .semibold))
                    .foregroundColor(InkTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(InkTheme.card))
            }
            .buttonStyle(InkBoardButtonStyle())
            .accessibilityLabel("暂存并返回主页")

            Text("山")
                .font(.inkTitle(15))
                .foregroundColor(InkTheme.textPrimary)
                .frame(width: 38, height: 38)
                .background(Circle().fill(InkTheme.cardStrong))

            VStack(alignment: .leading, spacing: 2) {
                Text(engine.mode == .daily ? "每日一题 · 一步成阵" : "山海棋手 · \(engine.difficulty.title)")
                    .font(.inkTitle(15))
                    .foregroundColor(InkTheme.textPrimary)
                Text(engine.statusText)
                    .font(.inkBody(12))
                    .foregroundColor(InkTheme.gold)
                    .lineLimit(1)
            }
            Spacer()
            InfoChip(text: engine.mode == .daily ? "残局" : "手牌 \(engine.opponentHandCount)")
        }
    }

    // MARK: 比分条

    private var scoreStrip: some View {
        FrostedCard(padding: 14) {
            HStack(spacing: 32) {
                Spacer()
                VStack(spacing: 2) {
                    Text("\(engine.playerScore)")
                        .font(.inkBody(30, weight: .bold))
                        .foregroundColor(InkTheme.gold)
                    Text(engine.mode == .daily ? "本次得分" : (engine.playerStarts ? "我方 · 先手" : "我方 · 后手"))
                        .font(.inkBody(11))
                        .foregroundColor(InkTheme.textSecondary)
                }
                Text("︰")
                    .font(.inkBody(20))
                    .foregroundColor(InkTheme.textSecondary)
                VStack(spacing: 2) {
                    Text("\(engine.opponentScore)")
                        .font(.inkBody(30, weight: .bold))
                        .foregroundColor(InkTheme.textPrimary)
                    Text(engine.mode == .daily ? "对方阵线" : (engine.playerStarts ? "对方 · 后手" : "对方 · 先手"))
                        .font(.inkBody(11))
                        .foregroundColor(InkTheme.textSecondary)
                }
                Spacer()
            }
        }
    }

    // MARK: 棋盘

    private var boardGrid: some View {
        let n = GameEngine.size
        return VStack(spacing: 6) {
            ForEach(0..<n, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<n, id: \.self) { col in
                        let idx = row * n + col
                        cellView(index: idx)
                    }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.04)))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(InkTheme.border, lineWidth: 1)
        )
    }

    private func cellView(index: Int) -> some View {
        let cell = engine.board[index]
        let highlighted = engine.scoredLineCells.contains(index)

        return Button {
            if engine.mode == .daily { dailyCell = index }
            else { engine.place(at: index) }
            if store.data.haptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(fillColor(for: cell, highlighted: highlighted))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(borderColor(for: cell, highlighted: highlighted),
                                          lineWidth: highlighted ? 1.5 : 1)
                    )
                if let card = cell.card {
                    VStack(spacing: 3) {
                        Text(card.label).font(.inkBody(16, weight: .semibold))
                            .minimumScaleFactor(0.7).lineLimit(1)
                        Text(cell.owner == .player ? "我" : "对")
                            .font(.inkBody(9, weight: .semibold))
                    }.foregroundColor(cell.owner == .player ? InkTheme.gold : InkTheme.textPrimary)
                } else if dailyCell == index {
                    Image(systemName: "checkmark").foregroundColor(InkTheme.gold)
                } else if engine.canPlace {
                    Circle().fill(InkTheme.gold.opacity(0.4)).frame(width: 5, height: 5)
                }
                if dailyCell == index || engine.lastPlacedIndex == index {
                    RoundedRectangle(cornerRadius: 10).strokeBorder(InkTheme.gold, lineWidth: 2)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(InkBoardButtonStyle())
        .disabled(cell.card != nil || !engine.canPlace)
        .accessibilityLabel("第 \(index / 5 + 1) 行第 \(index % 5 + 1) 列，" + (cell.card.map { "\($0.label)，\(cell.owner == .player ? "我方" : "对方")" } ?? "空格"))
        .accessibilityHint(cell.card == nil ? "先选择手牌，再落子" : "已有棋子")
    }

    private func fillColor(for cell: BoardCell, highlighted: Bool) -> Color {
        if highlighted { return InkTheme.gold.opacity(0.22) }
        switch cell.owner {
        case .player:   return InkTheme.gold.opacity(0.10)
        case .opponent: return Color.white.opacity(0.08)
        case .none:     return Color.white.opacity(0.04)
        }
    }

    private func borderColor(for cell: BoardCell, highlighted: Bool) -> Color {
        if highlighted { return InkTheme.gold }
        switch cell.owner {
        case .player:   return InkTheme.gold.opacity(0.5)
        case .opponent: return Color.white.opacity(0.25)
        case .none:     return Color.white.opacity(0.08)
        }
    }

    // MARK: 手牌

    private var handRow: some View {
        HStack(spacing: 8) {
            ForEach(engine.playerHand.indices, id: \.self) { i in
                let card = engine.playerHand[i]
                let selected = engine.selectedHandIndex == i
                Button {
                    engine.selectedHandIndex = selected ? nil : i
                    if selected { dailyCell = nil }
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(card.label).font(.inkBody(14, weight: .semibold))
                        BeastSeal(card: store.equippedCard, ink: InkTheme.ink.opacity(0.6))
                            .frame(height: 30).frame(maxWidth: .infinity)
                    }
                        .foregroundColor(card.suit.isRed ? InkTheme.suitRed : InkTheme.ink)
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .frame(height: 78, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(InkTheme.parchment)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(InkTheme.gold, lineWidth: selected ? 2 : 0)
                                )
                        )
                        .offset(y: selected ? -10 : 0)
                }
                .buttonStyle(InkBoardButtonStyle())
                .disabled(engine.turn != .player)
                .accessibilityLabel(card.label + (selected ? "，已选中" : ""))
                .accessibilityHint("选中后点击棋盘空格落子")
            }
        }
        .frame(maxWidth: engine.mode == .daily ? 82 : .infinity)
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: engine.selectedHandIndex)
    }

    private var hintText: some View {
        Text(engine.canPlace ? (engine.mode == .daily ? "选择落点后，请点击确认落子" : "手牌已选中 · 点击棋盘空格落子")
             : (engine.turn == .opponent ? "对方正在思考，请稍候" : "先点选一张手牌"))
            .font(.inkBody(12))
            .foregroundColor(InkTheme.textSecondary)
            .frame(maxWidth: .infinity)
    }

    // MARK: 结算浮层

    private func resultOverlay(_ result: String) -> some View {
        ZStack {
            InkTheme.ink.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 10) {
                KickerText(text: engine.mode == .daily ? "今日题记" : "终局 · 山海有回响")
                Text(result)
                    .font(.inkTitle(24))
                    .foregroundColor(InkTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(engine.mode == .daily
                     ? "得分 \(engine.playerScore) / 最佳 \(engine.dailyBest)"
                     : "\(engine.playerScore) : \(engine.opponentScore)")
                    .font(.inkBody(24, weight: .bold)).foregroundColor(InkTheme.gold)
                Text("战绩已保存 · 灵玉 +\(store.data.history.first(where: { $0.id == engine.id })?.reward ?? 0)")
                    .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                if engine.mode != .daily {
                    GoldButton(title: "再来一局") { engine.newGame() }
                }
                Button("复盘棋局") { showReview = true }
                    .font(.inkBody(15, weight: .semibold)).foregroundColor(InkTheme.gold).frame(minHeight: 44)
                Button("分享战绩") {
                    shareContent = ShareContent(items: [ResultPoster.make(engine: engine, nickname: store.data.nickname), shareText])
                }
                    .font(.inkBody(15, weight: .semibold)).foregroundColor(InkTheme.gold).frame(minHeight: 44)
                Button("返回主页") { app.gameRequest = nil }
                    .font(.inkBody(14, weight: .medium))
                    .foregroundColor(InkTheme.textSecondary).frame(minHeight: 44)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(InkTheme.inkDeep))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(InkTheme.gold.opacity(0.5), lineWidth: 1)
            )
        }
        .transition(.opacity)
    }
}
