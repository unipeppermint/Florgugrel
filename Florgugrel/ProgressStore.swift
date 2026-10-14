import Foundation
import Combine

struct MatchRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mode: GameEngine.Mode
    let playerScore: Int
    let opponentScore: Int
    let dailyKey: String?
    let dailyBest: Int
    let reward: Int
    var resigned: Bool? = nil
    var finalSnapshot: GameEngine.Snapshot? = nil
    var title: String {
        if resigned == true { return "认负" }
        if mode == .daily { return playerScore == dailyBest ? "最佳解" : "挑战完成" }
        return playerScore == opponentScore ? "平局" : (playerScore > opponentScore ? "胜利" : "惜败")
    }
}

struct PlayerProgress: Codable {
    var nickname = "子夜观星"
    var coins = 120
    var experience = 0
    var rankedGames = 0
    var rankedWins = 0
    var rating = 0
    var streak = 0
    var bestStreak = 0
    var totalGames = 0
    var totalMoves = 0
    var difficulty: GameEngine.Difficulty = .strategic
    var haptics = true
    var unlocked: Set<String> = ["fuzhu", "zheng"]
    var equipped = "fuzhu"
    var claimed: Set<String> = []
    var completedIDs: Set<UUID> = []
    var history: [MatchRecord] = []
    var dailyResults: [String: MatchRecord] = [:]
    var introductionCompleted: Bool? = nil
    var activeGame: GameEngine.Snapshot?
}

private extension PlayerProgress {
    mutating func sanitize() {
        coins = min(max(coins, 0), 10_000_000)
        experience = min(max(experience, 0), 100_000_000)
        rankedGames = min(max(rankedGames, 0), 1_000_000)
        rankedWins = min(max(rankedWins, 0), rankedGames)
        rating = min(max(rating, 0), 10_000_000)
        streak = min(max(streak, 0), rankedWins)
        bestStreak = min(max(bestStreak, streak), rankedWins)
        totalGames = min(max(totalGames, 0), 1_000_000)
        totalMoves = min(max(totalMoves, 0), 25_000_000)
        nickname = String(nickname.trimmingCharacters(in: .whitespacesAndNewlines).prefix(12))
        if nickname.isEmpty { nickname = "子夜观星" }
        unlocked = unlocked.intersection(Set(BeastCatalog.cards.map(\.id))).union(["fuzhu", "zheng"])
        if !unlocked.contains(equipped) { equipped = "fuzhu" }
        history = Array(history.prefix(100))
    }
}

@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var data: PlayerProgress
    @Published private(set) var storageWarning: String?
    private let defaults: UserDefaults
    private let storageKey = "handcraft.progress.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let saved = defaults.data(forKey: storageKey) {
            do {
                data = try JSONDecoder().decode(PlayerProgress.self, from: saved)
                if let game = data.activeGame, !game.isValid {
                    defaults.set(saved, forKey: "handcraft.progress.recovery")
                    data.activeGame = nil
                    storageWarning = "未完成对局的数据异常，已保留备份。其他进度不受影响。"
                }
                let previous = data
                data.sanitize()
                if previous.rating != data.rating || previous.coins != data.coins {
                    defaults.set(saved, forKey: "handcraft.progress.recovery")
                    storageWarning = "已修复异常进度数值，原始数据已保留备份。"
                }
            } catch {
                // Keep the original blob available for recovery rather than silently destroying it.
                defaults.set(saved, forKey: "handcraft.progress.recovery")
                data = PlayerProgress()
                storageWarning = "旧存档无法读取，已保留备份。本次从新的本地进度开始。"
            }
        } else { data = PlayerProgress() }
    }
    var needsIntroduction: Bool { data.introductionCompleted != true && data.totalGames == 0 && data.history.isEmpty }
    func completeIntroduction() { data.introductionCompleted = true; save() }
    var level: Int { data.experience / 200 + 1 }
    var levelProgress: Double { Double(data.experience % 200) / 200 }
    var rankTitle: String {
        let names = ["初入山海", "青岚", "玄岳", "归墟", "天衍"]
        return names[min(max(0, data.rating / 100), names.count - 1)]
    }
    var winRate: String {
        data.rankedGames == 0 ? "—" : "\(Int(Double(data.rankedWins) / Double(data.rankedGames) * 100))%"
    }
    var equippedCard: BeastCard { BeastCatalog.cards.first { $0.id == data.equipped } ?? BeastCatalog.cards[0] }
    func dailyResult(on date: Date = Date()) -> MatchRecord? { data.dailyResults[DailyPuzzle.key(for: date)] }

    private func save() {
        do { defaults.set(try JSONEncoder().encode(data), forKey: storageKey) }
        catch { storageWarning = "进度暂时无法保存，请稍后重试。" }
    }
    func resetProgress() {
        data = PlayerProgress()
        data.introductionCompleted = true
        defaults.removeObject(forKey: "handcraft.progress.recovery")
        storageWarning = nil
        save()
    }
    func acknowledgeWarning() { storageWarning = nil }
    func updateSettings(nickname: String, difficulty: GameEngine.Difficulty, haptics: Bool) {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        data.nickname = trimmed.isEmpty ? "子夜观星" : String(trimmed.prefix(12))
        data.difficulty = difficulty; data.haptics = haptics
        save()
    }
    func checkpoint(_ engine: GameEngine) {
        let snapshot = engine.snapshot
        guard snapshot.isValid else { return }
        if engine.turn == .finished { record(engine) }
        else { data.activeGame = snapshot; save() }
    }
    func abandonGame() { data.activeGame = nil; save() }
    func record(_ engine: GameEngine) {
        guard engine.turn == .finished, engine.snapshot.isValid, !data.completedIDs.contains(engine.id) else { return }
        if engine.mode == .daily, data.dailyResults[engine.dailyKey] != nil {
            data.activeGame = nil; save(); return
        }
        let won = !engine.resigned && engine.playerScore > engine.opponentScore
        let reward = engine.resigned ? 0 : engine.mode == .daily ? 50 : (engine.mode == .ranked && won ? 60 : 20)
        let record = MatchRecord(id: engine.id, date: Date(), mode: engine.mode,
                                 playerScore: engine.playerScore, opponentScore: engine.opponentScore,
                                 dailyKey: engine.mode == .daily ? engine.dailyKey : nil,
                                 dailyBest: engine.dailyBest, reward: reward, resigned: engine.resigned, finalSnapshot: engine.snapshot)
        data.completedIDs.insert(engine.id)
        data.history.insert(record, at: 0)
        data.history = Array(data.history.prefix(100))
        if !engine.resigned {
            data.totalGames += 1; data.totalMoves += engine.moves
            data.experience += engine.mode == .daily ? 80 : 100
        }
        data.coins += reward
        if engine.mode == .ranked {
            data.rankedGames += 1
            if won {
                data.rankedWins += 1; data.streak += 1; data.rating += 25
                data.bestStreak = max(data.bestStreak, data.streak)
            } else {
                data.streak = 0
                if engine.resigned || engine.playerScore < engine.opponentScore { data.rating = max(0, data.rating - 10) }
            }
        }
        if engine.mode == .daily {
            var summary = record
            summary.finalSnapshot = nil // Avoid duplicating board snapshots in long-lived daily statistics.
            data.dailyResults[engine.dailyKey] = summary
        }
        data.activeGame = nil
        save()
    }
    @discardableResult func unlock(_ card: BeastCard) -> Bool {
        guard !data.unlocked.contains(card.id), data.coins >= card.price else { return false }
        data.coins -= card.price; data.unlocked.insert(card.id); save(); return true
    }
    func equip(_ card: BeastCard) {
        guard data.unlocked.contains(card.id) else { return }
        data.equipped = card.id; save()
    }
    func missionProgress(_ mission: JourneyMission) -> Int {
        switch mission.id {
        case "moves": return data.totalMoves
        case "games": return data.totalGames
        case "daily": return data.dailyResults.count
        default: return data.rankedWins
        }
    }
    func claim(_ mission: JourneyMission) {
        guard missionProgress(mission) >= mission.target, !data.claimed.contains(mission.id) else { return }
        data.claimed.insert(mission.id); data.coins += mission.reward; save()
    }
}

struct JourneyMission: Identifiable {
    let id: String
    let title: String
    let target: Int
    let reward: Int
    static let all = [
        JourneyMission(id: "moves", title: "落子成章", target: 50, reward: 100),
        JourneyMission(id: "games", title: "山海初行", target: 10, reward: 200),
        JourneyMission(id: "daily", title: "三日问道", target: 3, reward: 150),
        JourneyMission(id: "wins", title: "五战告捷", target: 5, reward: 200)
    ]
    var detail: String {
        switch id {
        case "moves": return "在已完成对局中累计落子 50 次"
        case "games": return "完成任意 10 局对弈"
        case "daily": return "完成 3 天的每日一题"
        default: return "赢得 5 局问道对弈"
        }
    }
}
