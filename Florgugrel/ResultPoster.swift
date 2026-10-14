import UIKit

@MainActor
enum ResultPoster {
    static func make(engine: GameEngine, nickname: String) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1; format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: 900, height: 1200), format: format).image { output in
            let ink = UIColor(red: 15/255, green: 14/255, blue: 14/255, alpha: 1)
            let gold = UIColor(red: 232/255, green: 194/255, blue: 104/255, alpha: 1)
            let paper = UIColor(red: 239/255, green: 231/255, blue: 216/255, alpha: 1)
            ink.setFill(); output.fill(CGRect(x: 0, y: 0, width: 900, height: 1200))
            func text(_ string: String, y: CGFloat, size: CGFloat, color: UIColor, weight: UIFont.Weight = .regular) {
                let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
                (string as NSString).draw(in: CGRect(x: 40, y: y, width: 820, height: size * 2.5),
                    withAttributes: [.font: UIFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: paragraph])
            }
            text("牌 阵 师", y: 64, size: 32, color: gold, weight: .semibold)
            text(engine.mode == .daily ? engine.dailyKey + " · 每日一题" : engine.mode.title, y: 116, size: 21, color: paper)
            text(engine.resultText ?? "棋局已定", y: 174, size: 42, color: paper, weight: .bold)
            text(engine.mode == .daily ? "\(engine.playerScore) 分 / 最佳 \(engine.dailyBest)" : "\(engine.playerScore) : \(engine.opponentScore)",
                 y: 242, size: 52, color: gold, weight: .semibold)
            for index in 0..<25 {
                let cell = engine.board[index]
                let rect = CGRect(x: 90 + (index % 5) * 146, y: 350 + (index / 5) * 128, width: 136, height: 118)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 14)
                UIColor(white: 1, alpha: cell.owner == .player ? 0.10 : 0.05).setFill(); path.fill()
                (cell.owner == .player ? gold.withAlphaComponent(0.5) : UIColor(white: 1, alpha: 0.15)).setStroke()
                path.lineWidth = 2; path.stroke()
                let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
                let color = cell.owner == .player ? gold : paper
                ((cell.card?.label ?? "·") as NSString).draw(in: rect.insetBy(dx: 5, dy: 24), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 29, weight: .semibold), .foregroundColor: color, .paragraphStyle: paragraph])
                if cell.card != nil {
                    ((cell.owner == .player ? "我" : "对") as NSString).draw(in: CGRect(x: rect.minX, y: rect.maxY - 34, width: rect.width, height: 25),
                        withAttributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: color, .paragraphStyle: paragraph])
                }
            }
            text(nickname + " · 以牌成阵，以阵会友", y: 1024, size: 25, color: gold)
            text("五行五列，争一线之机。", y: 1080, size: 22, color: paper.withAlphaComponent(0.7))
        }
    }
}
