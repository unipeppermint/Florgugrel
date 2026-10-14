import SwiftUI

struct GameReviewView: View {
    @ObservedObject var engine: GameEngine
    @Environment(\.presentationMode) private var presentation
    @State private var selectedLine: Int?
    private var focusCells: Set<Int> { Set(engine.lineResults.first { $0.id == selectedLine }?.cells ?? []) }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(engine.resultText ?? "棋局复盘").font(.inkTitle(25)).foregroundColor(InkTheme.gold)
                    VStack(spacing: 5) {
                        ForEach(0..<5) { row in
                            HStack(spacing: 5) {
                                ForEach(0..<5) { column in
                                    reviewCell(row * 5 + column)
                                }
                            }
                        }
                    }
                    if engine.mode == .daily {
                        Text("五处落点 · 逐一比较").font(.inkTitle(20)).foregroundColor(InkTheme.textPrimary)
                        Text("只比较我方新完成阵线的得分。金色棋子为你持有，预置满线不参与本题结算。")
                            .font(.inkBody(13)).foregroundColor(InkTheme.textSecondary)
                        ForEach(engine.dailyOptions) { option in
                            HStack {
                                Text("第 \(option.id / 5 + 1) 行 · 第 \(option.id % 5 + 1) 列")
                                Spacer()
                                if option.chosen { Text("你的选择").font(.inkBody(11)) }
                                Text("\(option.points) 分").font(.inkBody(16, weight: .semibold))
                                if option.points == engine.dailyBest { Image(systemName: "crown.fill") }
                            }.foregroundColor(option.points == engine.dailyBest ? InkTheme.gold : InkTheme.textSecondary)
                            .padding(14).background(RoundedRectangle(cornerRadius: 10).fill(InkTheme.card))
                        }
                    }
                    Text("阵线明细").font(.inkTitle(20)).foregroundColor(InkTheme.textPrimary)
                    if engine.lineResults.isEmpty {
                        Text("尚未形成完整阵线。").font(.inkBody(14)).foregroundColor(InkTheme.textSecondary)
                    }
                    ForEach(engine.lineResults) { line in
                        Button { selectedLine = selectedLine == line.id ? nil : line.id } label: {
                            FrostedCard(padding: 14) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(line.title + " · " + line.rank.name)
                                        Spacer()
                                        Text("\(line.playerOwns ? "我方" : "对方") +\(line.rank.points)")
                                            .foregroundColor(line.playerOwns ? InkTheme.gold : InkTheme.textSecondary)
                                    }.font(.inkBody(14, weight: .semibold))
                                    Text(line.cards.map(\.label).joined(separator: "   "))
                                        .font(.inkBody(13)).foregroundColor(InkTheme.textSecondary)
                                }.foregroundColor(InkTheme.textPrimary)
                            }
                        }.buttonStyle(PlainButtonStyle())
                    }
                    Text("点击一条明细，高亮它在棋盘上的位置。")
                        .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                }.padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.background(InkTheme.ink.ignoresSafeArea())
            .navigationTitle("棋局复盘").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { presentation.wrappedValue.dismiss() } } }
        }.preferredColorScheme(.dark).accentColor(InkTheme.gold)
    }
    private func reviewCell(_ index: Int) -> some View {
        let cell = engine.board[index]
        return VStack(spacing: 4) {
            Text(cell.card?.label ?? "·").font(.inkBody(15, weight: .semibold))
            if cell.card != nil { Text(cell.owner == .player ? "我" : "对").font(.inkBody(9)) }
        }.frame(maxWidth: .infinity).frame(height: 60)
        .foregroundColor(cell.owner == .player ? InkTheme.gold : InkTheme.textPrimary)
        .background(RoundedRectangle(cornerRadius: 8).fill(focusCells.contains(index) ? InkTheme.goldSoft : InkTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(focusCells.contains(index) ? InkTheme.gold : InkTheme.border))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("第 \(index / 5 + 1) 行第 \(index % 5 + 1) 列，\(cell.card?.label ?? "空格")，\(cell.owner == .player ? "我方" : cell.owner == .opponent ? "对方" : "")")
    }
}
