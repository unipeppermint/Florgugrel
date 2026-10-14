//
//  RootView.swift
//  Florgugrel · 牌阵师 Handcraft
//
//  根视图：自定义胶囊底部导航 + 四个主目的地
//

import SwiftUI

struct RootView: View {
    @StateObject private var app = AppState()
    @StateObject private var store = ProgressStore()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tabs: [(icon: String, label: String)] = [
        ("♠", "开局"), ("♥", "牌库"), ("♣", "旅程"), ("♦", "我的")
    ]

    var body: some View {
        Group {
            if store.needsIntroduction { IntroductionView(onComplete: store.completeIntroduction) }
            else { mainContent }
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            InkTheme.ink.ignoresSafeArea()

            Group {
                switch app.selectedTab {
                case 0: HomeView()
                case 1: CollectionView()
                case 2: SeasonView()
                default: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .environmentObject(app)
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $app.gameRequest) { req in
            BattleView(request: req, difficulty: store.data.difficulty)
                .environmentObject(app)
                .environmentObject(store)
        }
        .sheet(isPresented: $app.showDaily, onDismiss: app.dailyDidDismiss) {
            DailyChallengeView()
                .environmentObject(app)
                .environmentObject(store)
        }
    }

    // MARK: 胶囊标签栏

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(tabs.indices, id: \.self) { i in
                let active = app.selectedTab == i
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                        app.selectedTab = i
                    }
                } label: {
                    VStack(spacing: 3) {
                        Text(tabs[i].icon)
                            .font(.inkBody(17, weight: .medium))
                        Text(tabs[i].label)
                            .font(.inkBody(10, weight: .semibold))
                    }
                    .foregroundColor(active ? InkTheme.ink : InkTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(active ? InkTheme.gold : Color.clear))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(tabs[i].label)
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
        .padding(4)
        .frame(height: 62)
        .background(Capsule().fill(InkTheme.inkDeep))
        .overlay(Capsule().strokeBorder(InkTheme.border, lineWidth: 1))
        .padding(.horizontal, 21)
        .padding(.bottom, 8)
    }
}
