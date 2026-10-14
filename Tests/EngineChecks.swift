import Foundation

@main
struct EngineChecks {
    @MainActor static func main() async throws {
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            guard condition() else { fatalError(message) }
        }
        func cards(_ ranks: [Int], flush: Bool = false) -> [Card] {
            ranks.enumerated().map { Card(rank: $0.element, suit: flush ? .spades : Suit.allCases[$0.offset % 4]) }
        }
        let cases: [([Card], Int)] = [
            (cards([10, 11, 12, 13, 14], flush: true), 50),
            (cards([2, 3, 4, 5, 14], flush: true), 30),
            (cards([9, 9, 9, 9, 3]), 20), (cards([3, 3, 3, 8, 8]), 14),
            (cards([2, 4, 7, 10, 13], flush: true), 10), (cards([2, 3, 4, 5, 14]), 8),
            (cards([3, 3, 3, 8, 9]), 6), (cards([3, 3, 8, 8, 9]), 4),
            (cards([3, 3, 7, 8, 9]), 2), (cards([2, 5, 8, 11, 14]), 1),
            (cards([12, 13, 14, 2, 3]), 1), ([], 0), (cards([2, 3]), 0)
        ]
        for (hand, expected) in cases { check(GameEngine.evaluate(hand).points == expected, "Poker rank \(hand)") }
        check(Set(Card.fullDeck.map(\.id)).count == 52, "Deck must have 52 unique cards")
        print("PASS: all ten hand ranks, wheel, wraparound and invalid hand sizes")

        let start = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        var sawBaseline = false
        for day in 0..<366 {
            let date = start.addingTimeInterval(Double(day) * 86400)
            let original = GameEngine(mode: .daily, date: date)
            let repeatGame = GameEngine(mode: .daily, date: date.addingTimeInterval(86399))
            check(original.board == repeatGame.board && original.playerHand == repeatGame.playerHand, "Daily reproducibility")
            check(original.snapshot.isValid && original.filledCount == 20, "Daily valid state")
            let baseline = Set(GameEngine.lines.indices.filter { i in GameEngine.lines[i].allSatisfy { original.board[$0].card != nil } })
            sawBaseline = sawBaseline || !baseline.isEmpty
            var highest = 0
            for index in original.board.indices where original.board[index].card == nil {
                let game = GameEngine(mode: .daily, snapshot: original.snapshot)
                game.selectedHandIndex = 0
                game.place(at: -1); game.place(at: 25)
                check(game.filledCount == 20, "Out-of-range placement must be ignored")
                game.place(at: index)
                var player = 0, opponent = 0
                for (lineID, line) in GameEngine.lines.enumerated() where !baseline.contains(lineID) {
                    let hand = line.compactMap { game.board[$0].card }
                    guard hand.count == 5 else { continue }
                    let value = GameEngine.evaluate(hand).points
                    if line.filter({ game.board[$0].owner == .player }).count >= 3 { player += value }
                    else { opponent += value }
                }
                check(game.playerScore == player && game.opponentScore == opponent, "Daily must exclude baseline lines")
                check(game.turn == .finished && game.moves == 1 && player > 0, "Every daily option must be playable")
                let score = game.playerScore
                game.selectedHandIndex = 0; game.place(at: index)
                check(game.playerScore == score, "Finished daily must reject moves")
                highest = max(highest, player)
            }
            check(highest == original.dailyBest, "Daily best must equal exhaustive search")
        }
        check(sawBaseline, "Must exercise pre-existing full diagonals")
        check(DailyPuzzle.key(for: start.addingTimeInterval(-1)) == "2025-12-31", "UTC midnight boundary")
        check(DailyPuzzle.nextRefresh(after: start) == start.addingTimeInterval(86400), "Next UTC day")
        print("PASS: 366 daily puzzles, 1,830 legal final moves, baseline scoring and UTC refresh")

        var lastGame: GameEngine!
        for run in 0..<24 {
            let game = GameEngine(mode: .ranked, difficulty: run % 2 == 0 ? .strategic : .easy)
            game.pause()
            var turns = 0
            while game.turn != .finished {
                if game.turn == .player {
                    let prior = game.filledCount
                    game.place(at: 0)
                    check(game.filledCount == prior, "Selection required")
                    game.selectedHandIndex = game.playerHand.count - 1
                    let empty = game.board.indices.filter { game.board[$0].card == nil }
                    game.place(at: empty[(run + turns) % empty.count])
                    game.pause()
                } else { game.performOpponentMove() }
                turns += 1
                check(turns <= 25 && game.snapshot.isValid, "Legal complete game and no duplicate cards")
                let encoded = try JSONEncoder().encode(game.snapshot)
                let decoded = try JSONDecoder().decode(GameEngine.Snapshot.self, from: encoded)
                let restored = GameEngine(mode: .ranked, snapshot: decoded)
                check(restored.board == game.board && restored.turn == game.turn && restored.playerHand == game.playerHand, "Snapshot round trip")
                restored.pause()
            }
            var player = 0, opponent = 0
            for line in GameEngine.lines {
                let points = GameEngine.evaluate(line.compactMap { game.board[$0].card }).points
                if line.filter({ game.board[$0].owner == .player }).count >= 3 { player += points }
                else { opponent += points }
            }
            check(game.playerScore == player && game.opponentScore == opponent, "Every line scored exactly once")
            check(game.filledCount == 25 && turns == 25, "Game completes at 25 cells")
            lastGame = game
        }
        print("PASS: 24 complete games, both difficulties, 600 snapshot round trips, independent final scores")

        // A forced last move: strategy must choose the straight flush from its hand.
        let opening = [2, 3, 4, 5].map { Card(rank: $0, suit: .spades) }
        let enemyHand = [Card(rank: 6, suit: .hearts), Card(rank: 9, suit: .diamonds),
                         Card(rank: 10, suit: .diamonds), Card(rank: 11, suit: .diamonds),
                         Card(rank: 6, suit: .spades)]
        let myHand = [12, 13, 14, 8, 7].map { Card(rank: $0, suit: .diamonds) }
        let reserved = Set((opening + enemyHand + myHand).map(\.id))
        var remaining = Card.fullDeck.filter { !reserved.contains($0.id) }
        var board = Array(repeating: BoardCell(), count: 25)
        for index in 0..<4 { board[index] = BoardCell(card: opening[index], owner: index < 3 ? .opponent : .player) }
        for index in 5..<25 { board[index] = BoardCell(card: remaining.removeFirst(), owner: index < 16 ? .player : .opponent) }
        let complete = Set(GameEngine.lines.indices.filter { line in GameEngine.lines[line].allSatisfy { board[$0].card != nil } })
        let fixturePlayer = complete.reduce(0) { sum, index in
            let line = GameEngine.lines[index]
            return sum + (line.filter { board[$0].owner == .player }.count >= 3 ? GameEngine.evaluate(line.compactMap { board[$0].card }).points : 0)
        }
        let fixtureTotal = complete.reduce(0) { $0 + GameEngine.evaluate(GameEngine.lines[$1].compactMap { board[$0].card }).points }
        let tactical = GameEngine.Snapshot(id: UUID(), mode: .casual, difficulty: .strategic,
            dailyKey: "2026-01-01", board: board, playerHand: myHand, opponentHand: enemyHand,
            deck: remaining, playerScore: fixturePlayer, opponentScore: fixtureTotal - fixturePlayer, turn: .opponent,
            scoredLines: complete, moves: 12, dailyBest: 0, lastEvent: "", playerStarts: false)
        check(tactical.isValid, "Tactical fixture must be legal")
        let strategist = GameEngine(mode: .casual, snapshot: tactical)
        strategist.performOpponentMove()
        check(strategist.board[4].card == Card(rank: 6, suit: .spades), "AI must select straight flush instead of first card")
        let invalid = GameEngine.Snapshot(id: UUID(), mode: .casual, difficulty: .easy,
            dailyKey: "2026-01-01", board: [], playerHand: [], opponentHand: [], deck: [],
            playerScore: 0, opponentScore: 0, turn: .player, scoredLines: [], moves: 0,
            dailyBest: 0, lastEvent: "", playerStarts: true)
        check(!invalid.isValid, "Reject malformed snapshots")
        let recovered = GameEngine(mode: .casual, snapshot: invalid)
        recovered.pause()
        check(recovered.snapshot.isValid, "Invalid snapshots recover into a legal new game")
        print("PASS: tactical AI chooses a scoring card, malformed snapshot recovery")

        let suite = "handcraft.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ProgressStore(defaults: defaults)
        store.record(lastGame)
        let coins = store.data.coins
        store.record(lastGame)
        check(store.data.totalGames == 1 && store.data.coins == coins, "Exactly-once rewards")
        let daily = GameEngine(mode: .daily, date: start)
        daily.selectedHandIndex = 0; daily.place(at: daily.board.firstIndex { $0.card == nil }!)
        store.record(daily)
        let sameDay = GameEngine(mode: .daily, date: start)
        sameDay.selectedHandIndex = 0; sameDay.place(at: sameDay.board.firstIndex { $0.card == nil }!)
        store.record(sameDay)
        check(store.data.totalGames == 2 && store.data.dailyResults.count == 1, "Once per UTC day")
        let target = BeastCatalog.cards.first { $0.price == 100 }!
        check(store.unlock(target), "Can unlock affordable card")
        let afterPurchase = store.data.coins
        check(!store.unlock(target) && store.data.coins == afterPurchase, "No duplicate purchase")
        store.equip(target)
        let locked = BeastCatalog.cards.last!
        store.equip(locked)
        check(store.data.equipped == target.id, "Cannot equip locked card")
        check(!store.unlock(locked), "Cannot overspend")
        let restoredStore = ProgressStore(defaults: defaults)
        check(restoredStore.data.coins == afterPurchase && restoredStore.data.equipped == target.id && restoredStore.data.totalGames == 2, "Progress round trip")
        for _ in 0..<8 {
            let game = GameEngine(mode: .casual)
            game.pause()
            while game.turn != .finished {
                if game.turn == .opponent { game.performOpponentMove() }
                else { game.selectedHandIndex = 0; game.place(at: game.board.firstIndex { $0.card == nil }!); game.pause() }
            }
            store.record(game)
        }
        let mission = JourneyMission.all.first { $0.id == "games" }!
        let beforeClaim = store.data.coins
        store.claim(mission); store.claim(mission)
        check(store.data.coins == beforeClaim + mission.reward, "Mission rewards exactly once")
        let ongoing = GameEngine(mode: .casual)
        ongoing.pause()
        store.checkpoint(ongoing)
        let resumeStore = ProgressStore(defaults: defaults)
        check(resumeStore.data.activeGame?.id == ongoing.id, "Unfinished game saved")
        store.abandonGame()
        check(ProgressStore(defaults: defaults).data.activeGame == nil, "Abandon clears saved game")
        print("PASS: persistence, daily limits, rewards, purchases, equipment and mission claims")

        let paused = GameEngine(mode: .casual)
        paused.pause()
        if paused.turn == .player {
            paused.selectedHandIndex = 0; paused.place(at: 0); paused.pause()
        }
        let count = paused.filledCount
        try await Task.sleep(nanoseconds: 800_000_000)
        check(paused.filledCount == count, "Cancelled opponent must not move")
        paused.resume()
        try await Task.sleep(nanoseconds: 800_000_000)
        check(paused.filledCount == count + 1, "Resume makes exactly one opponent move")
        paused.pause()
        print("PASS: opponent cancellation and resume")
        let beforeResign = store.data
        let resignation = GameEngine(mode: .ranked)
        resignation.pause(); resignation.resign()
        check(resignation.snapshot.isValid && resignation.turn == .finished, "Resignation snapshot is valid")
        store.record(resignation); store.record(resignation)
        check(store.data.rankedGames == beforeResign.rankedGames + 1, "Resignation recorded once")
        check(store.data.rating == max(0, beforeResign.rating - 10), "Resignation loses rating")
        check(store.data.coins == beforeResign.coins && store.data.experience == beforeResign.experience && store.data.totalGames == beforeResign.totalGames, "No farming rewards or missions by resigning")
        check(store.data.history.first?.title == "认负" && store.data.history.first?.finalSnapshot?.isValid == true, "Persisted resignation review")
        check(daily.dailyOptions.count == 5 && daily.dailyOptions.map(\.points).max() == daily.dailyBest, "Daily review agrees with best score")
        check(daily.lineResults.filter(\.playerOwns).reduce(0) { $0 + $1.rank.points } == daily.playerScore, "Daily review excludes baseline")
        // Decode the preceding app version's data (new optional fields absent).
        var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(beforeResign)) as! [String: Any]
        legacy.removeValue(forKey: "introductionCompleted")
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: "handcraft.progress.v1")
        let migrated = ProgressStore(defaults: defaults)
        check(migrated.data.coins == beforeResign.coins && migrated.data.totalGames == beforeResign.totalGames, "Backward compatible progress")
        legacy["rating"] = -500; legacy["coins"] = -1; legacy["equipped"] = "missing"
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: "handcraft.progress.v1")
        let repaired = ProgressStore(defaults: defaults)
        check(repaired.rankTitle == "初入山海" && repaired.data.coins == 0 && repaired.data.equipped == "fuzhu", "Negative counters and unknown cosmetics repaired")
        check(defaults.data(forKey: "handcraft.progress.recovery") != nil, "Corrupt data kept for recovery")
        repaired.resetProgress()
        check(ProgressStore(defaults: defaults).data.history.isEmpty && defaults.data(forKey: "handcraft.progress.recovery") == nil, "Explicit reset deletes progress and backup")
        // Alter a structurally valid match's score to exercise semantic validation.
        var badScore = try JSONSerialization.jsonObject(with: JSONEncoder().encode(lastGame.snapshot)) as! [String: Any]
        badScore["playerScore"] = lastGame.playerScore + 1
        let forged = try JSONDecoder().decode(GameEngine.Snapshot.self, from: JSONSerialization.data(withJSONObject: badScore))
        check(!forged.isValid, "Reject score inconsistent with completed lines")
        print("PASS: resignations, persisted reviews, old-save migration, numeric corruption, reset and score validation")
        print("All engine and persistence checks passed.")
    }
}
