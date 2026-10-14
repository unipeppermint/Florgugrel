import SwiftUI

struct BeastCard: Identifiable {
    let id: String
    let card: String
    let name: String
    let rarity: Rarity
    var symbol: String {
        switch id {
        case "fuzhu": return "leaf.fill"
        case "zheng": return "flame.fill"
        case "dangkang": return "sun.max.fill"
        case "chenghuang": return "wind"
        case "jingwei": return "drop.fill"
        case "baize": return "eye.fill"
        case "bifang": return "sparkles"
        case "qilin": return "star.fill"
        case "wenyao": return "moon.stars.fill"
        case "jiuwei": return "moon.fill"
        case "kunpeng": return "cloud.fill"
        case "zhulong": return "bolt.fill"
        default: return "suit.spade.fill"
        }
    }
    let detail: String
    let price: Int
    enum Rarity: String, CaseIterable {
        case normal = "普通", rare = "稀有", epic = "史诗", legendary = "传说"
        var color: Color {
            switch self {
            case .normal: return InkTheme.textSecondary
            case .rare: return InkTheme.rareBlue
            case .epic: return InkTheme.epicPurple
            case .legendary: return InkTheme.gold
            }
        }
    }
    var isRedSuit: Bool { card.contains("♥") || card.contains("♦") }
}

enum BeastCatalog {
    static let cards: [BeastCard] = [
        .init(id: "fuzhu", card: "6♠", name: "夫诸", rarity: .normal, detail: "白鹿逐水，静候一线生机。", price: 0),
        .init(id: "zheng", card: "5♣", name: "狰", rarity: .normal, detail: "赤色之兽，落子如鸣石。", price: 0),
        .init(id: "dangkang", card: "10♠", name: "当康", rarity: .rare, detail: "丰年之兆，稳守每一寸棋盘。", price: 100),
        .init(id: "chenghuang", card: "8♥", name: "乘黄", rarity: .rare, detail: "乘风越山，先见下一步。", price: 100),
        .init(id: "jingwei", card: "7♦", name: "精卫", rarity: .rare, detail: "衔石填海，每一步都算数。", price: 120),
        .init(id: "baize", card: "J♣", name: "白泽", rarity: .epic, detail: "知万物之情，观阵而后行。", price: 240),
        .init(id: "bifang", card: "A♦", name: "毕方", rarity: .epic, detail: "丹青为羽，一步点亮全局。", price: 240),
        .init(id: "qilin", card: "9♣", name: "麒麟", rarity: .epic, detail: "仁心有锋，胜负自有章法。", price: 260),
        .init(id: "wenyao", card: "K♠", name: "文鳐鱼", rarity: .legendary, detail: "游于深渊，跃出星海。", price: 400),
        .init(id: "jiuwei", card: "Q♥", name: "九尾狐", rarity: .legendary, detail: "九尾藏机，一线定乾坤。", price: 400),
        .init(id: "kunpeng", card: "A♠", name: "鲲鹏", rarity: .legendary, detail: "扶摇直上，俯看山海棋局。", price: 500),
        .init(id: "zhulong", card: "K♦", name: "烛龙", rarity: .legendary, detail: "睁目为昼，照见终局。", price: 500)
    ]
}
