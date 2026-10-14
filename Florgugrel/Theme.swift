//
//  Theme.swift
//  Florgugrel · 牌阵师 Handcraft
//
//  视觉体系：东方幻墨 —— 墨黑底 + 哑金点缀 + 宣纸牌面
//

import SwiftUI

enum InkTheme {
    static let ink          = Color(red: 0x0F/255, green: 0x0E/255, blue: 0x0E/255) // 墨黑 #0F0E0E
    static let inkDeep      = Color(red: 0x1A/255, green: 0x18/255, blue: 0x16/255) // 深墨 #1A1816
    static let card         = Color.white.opacity(0.06)                             // 雾化卡片
    static let cardStrong   = Color.white.opacity(0.10)
    static let border       = Color.white.opacity(0.12)
    static let borderStrong = Color.white.opacity(0.20)
    static let gold         = Color(red: 0xE8/255, green: 0xC2/255, blue: 0x68/255) // 哑金 #E8C268
    static let goldSoft     = Color(red: 0xE8/255, green: 0xC2/255, blue: 0x68/255).opacity(0.12)
    static let parchment    = Color(red: 0xEF/255, green: 0xE7/255, blue: 0xD8/255) // 宣纸 #EFE7D8
    static let textPrimary  = Color(red: 0xF2/255, green: 0xF2/255, blue: 0xF2/255)
    static let textSecondary = Color(red: 0xA8/255, green: 0xA8/255, blue: 0xA8/255)
    static let suitRed      = Color(red: 0xB0/255, green: 0x3A/255, blue: 0x2E/255) // 朱砂 #B03A2E
    static let jade         = Color(red: 0x7D/255, green: 0xD9/255, blue: 0xA6/255) // 成功 #7DD9A6
    static let epicPurple   = Color(red: 0x8E/255, green: 0x7C/255, blue: 0xC3/255)
    static let rareBlue     = Color(red: 0x5B/255, green: 0x8D/255, blue: 0xD9/255)
}

extension Font {
    /// 中文衬线标题（宋体感）
    static func inkTitle(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func inkBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

/// 雾化卡片容器
struct FrostedCard<Content: View>: View {
    var padding: CGFloat = 18
    var radius: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(InkTheme.card))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(InkTheme.border, lineWidth: 1)
            )
    }
}

/// 哑金主按钮
struct GoldButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.inkBody(16, weight: .semibold))
                .foregroundColor(InkTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(InkTheme.gold))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 小号描边按钮
struct OutlineButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.inkBody(15, weight: .medium))
                .foregroundColor(InkTheme.textPrimary)
                .frame(width: 116, height: 52)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(InkTheme.card))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(InkTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 英文小标（Kicker）
struct KickerText: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.inkBody(11, weight: .semibold))
            .tracking(2)
            .foregroundColor(InkTheme.gold)
    }
}

/// 胶囊信息标签
struct InfoChip: View {
    let text: String
    var gold: Bool = false

    var body: some View {
        Text(text)
            .font(.inkBody(12, weight: .medium))
            .foregroundColor(gold ? InkTheme.gold : InkTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(gold ? InkTheme.goldSoft : InkTheme.card))
            .overlay(Capsule().strokeBorder(gold ? Color.clear : InkTheme.border, lineWidth: 1))
    }
}

/// Keep occupied cells legible while still disabling their interaction.
struct InkBoardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.8 : 1)
    }
}
