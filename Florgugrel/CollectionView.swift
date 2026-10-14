import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var filter = "全部"
    @State private var selected: BeastCard?
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private var visible: [BeastCard] {
        BeastCatalog.cards.filter { filter == "全部" || (filter == "已拥有" ? store.data.unlocked.contains($0.id) : $0.rarity.rawValue == filter) }
    }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("山海图鉴").font(.inkTitle(28)).foregroundColor(InkTheme.textPrimary)
                    Spacer()
                    Menu {
                        ForEach(["全部", "已拥有"] + BeastCard.Rarity.allCases.map(\.rawValue), id: \.self) { option in
                            Button(option) { filter = option }
                        }
                    } label: { InfoChip(text: filter + " ▾") }
                }
                FrostedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("收集 \(store.data.unlocked.count) / \(BeastCatalog.cards.count)").foregroundColor(InkTheme.textPrimary)
                            Spacer()
                            Text("◈ \(store.data.coins)").foregroundColor(InkTheme.gold)
                        }.font(.inkBody(15, weight: .semibold))
                        ProgressView(value: Double(store.data.unlocked.count), total: Double(BeastCatalog.cards.count)).accentColor(InkTheme.gold)
                        Text("当前印章：\(store.equippedCard.name) · 应用于头像与手牌")
                            .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
                    }
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(visible) { beast in
                        Button { selected = beast } label: { tile(beast) }.buttonStyle(PlainButtonStyle())
                    }
                }
                Text("灵玉通过游玩获得。印章仅改变外观，不影响牌型和得分。")
                    .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary)
            }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 100)
            .frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background(InkTheme.ink)
        .sheet(item: $selected) { card in BeastDetailView(card: card).environmentObject(store) }
    }
    private func tile(_ card: BeastCard) -> some View {
        let unlocked = store.data.unlocked.contains(card.id)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(card.card).font(.inkBody(16, weight: .bold)).foregroundColor(card.isRedSuit ? InkTheme.suitRed : InkTheme.ink)
                Spacer()
                if store.data.equipped == card.id { Image(systemName: "checkmark.seal.fill").foregroundColor(InkTheme.suitRed) }
                else if !unlocked { Image(systemName: "lock.fill").foregroundColor(InkTheme.ink.opacity(0.4)) }
            }
            FlorgugrelBeastArtwork(card: card)
                .padding(6)
                .frame(height: 124)
                .frame(maxWidth: .infinity)
            Text(card.name).font(.inkTitle(20)).foregroundColor(InkTheme.ink)
            HStack {
                Circle()
                    .fill(card.rarity.color)
                    .frame(width: 5, height: 5)
                Text(card.rarity.rawValue)
                Spacer()
                Text(unlocked ? "已拥有" : "◈ \(card.price)")
            }.font(.inkBody(11)).foregroundColor(InkTheme.ink.opacity(0.7))
        }
        .padding(14).background(RoundedRectangle(cornerRadius: 14).fill(InkTheme.parchment))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(card.rarity.color.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

struct BeastDetailView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.presentationMode) private var presentation
    let card: BeastCard
    private var owned: Bool { store.data.unlocked.contains(card.id) }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    KickerText(text: "山 海 图 鉴")
                    FlorgugrelBeastArtwork(card: card)
                        .padding(12)
                        .frame(width: 208, height: 208)
                    Text(card.name).font(.inkTitle(32)).foregroundColor(InkTheme.textPrimary)
                    InfoChip(text: card.rarity.rawValue, gold: true)
                    Text(card.detail).font(.inkBody(16)).foregroundColor(InkTheme.textSecondary)
                    if owned {
                        GoldButton(title: store.data.equipped == card.id ? "已装备" : "装备印章") { store.equip(card) }
                            .disabled(store.data.equipped == card.id)
                    } else {
                        GoldButton(title: store.data.coins >= card.price ? "解锁印章 · \(card.price) 灵玉" : "还需 \(card.price - store.data.coins) 灵玉") {
                            if store.unlock(card) { store.equip(card) }
                        }.disabled(store.data.coins < card.price).opacity(store.data.coins < card.price ? 0.5 : 1)
                    }
                    Text("拥有 \(store.data.coins) 灵玉 · 完成对局和旅程任务可获得更多")
                        .font(.inkBody(12)).foregroundColor(InkTheme.textSecondary).multilineTextAlignment(.center)
                }.padding(28)
            }.background(InkTheme.ink.ignoresSafeArea())
            .navigationTitle("印章详情").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { presentation.wrappedValue.dismiss() } } }
        }.preferredColorScheme(.dark).accentColor(InkTheme.gold)
    }
}
