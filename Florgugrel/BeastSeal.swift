import SwiftUI

/// A graphical seal shared by the collection, equipped avatar and playing cards.
struct BeastSeal: View {
    let card: BeastCard
    var ink: Color = InkTheme.gold
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                SealOutline().stroke(ink.opacity(0.8), lineWidth: max(1, size * 0.018))
                SealOutline().inset(by: size * 0.07).stroke(ink.opacity(0.3), lineWidth: max(0.5, size * 0.006))
                Image(systemName: card.symbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(ink)
                    .padding(size * 0.24)
                HStack {
                    ornament(size)
                    Spacer()
                    ornament(size).rotationEffect(.degrees(180))
                }.padding(.horizontal, size * 0.09)
            }.frame(width: size, height: size)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.aspectRatio(1, contentMode: .fit).accessibilityHidden(true)
    }
    private func ornament(_ size: CGFloat) -> some View {
        VStack(spacing: size * 0.035) {
            ForEach(0..<3) { _ in
                Rectangle().fill(ink.opacity(0.6)).frame(width: size * 0.07, height: max(1, size * 0.015))
            }
        }
    }
}

private struct SealOutline: InsettableShape {
    var insetAmount: CGFloat = 0
    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount + 2, dy: insetAmount + 2)
        let cut = r.width * 0.17
        var p = Path()
        p.move(to: CGPoint(x: r.minX + cut, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - cut, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + cut))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - cut))
        p.addLine(to: CGPoint(x: r.maxX - cut, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + cut, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - cut))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + cut))
        p.closeSubpath()
        return p
    }
    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self; copy.insetAmount += amount; return copy
    }
}
