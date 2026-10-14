import Foundation
import Combine

enum Suit: String, CaseIterable, Codable {
    case spades, hearts, clubs, diamonds
    var symbol: String {
        switch self {
        case .spades: return "♠"
        case .hearts: return "♥"
        case .clubs: return "♣"
        case .diamonds: return "♦"
        }
    }
    var isRed: Bool { self == .hearts || self == .diamonds }
}

struct Card: Identifiable, Equatable, Codable {
    let rank: Int
    let suit: Suit
    var id: String { "\(suit.rawValue)-\(rank)" }
    var rankText: String {
        switch rank {
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        case 14: return "A"
        default: return String(rank)
        }
    }
    var label: String { rankText + suit.symbol }
    static var fullDeck: [Card] {
        Suit.allCases.flatMap { suit in (2...14).map { Card(rank: $0, suit: suit) } }
    }
}

enum CellOwner: String, Codable { case none, player, opponent }
struct BoardCell: Equatable, Codable {
    var card: Card? = nil
    var owner: CellOwner = .none
}
struct HandRank { let name: String; let points: Int }

/// Fixed algorithm and UTC day key keep the offline daily puzzle reproducible.
struct PuzzleRandom {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func shuffle<T>(_ input: [T]) -> [T] {
        var result = input
        guard result.count > 1 else { return result }
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            result.swapAt(i, Int(next() % UInt64(i + 1)))
        }
        return result
    }
}

enum DailyPuzzle {
    static func key(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    static func nextRefresh(after date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
    }
}

@MainActor
final class GameEngine: ObservableObject {
    enum Turn: String, Codable { case player, opponent, finished }
    enum Mode: String, Codable {
        case ranked, casual, daily
        var title: String {
            switch self {
            case .ranked: return "问道对弈"
            case .casual: return "闲庭对弈"
            case .daily: return "每日一题"
            }
        }
    }
    enum Difficulty: String, CaseIterable, Codable {
        case easy, strategic
        var title: String { self == .easy ? "入门" : "策略" }
    }
    struct Snapshot: Codable {
        let id: UUID
        let mode: Mode
        let difficulty: Difficulty
        let dailyKey: String
        let board: [BoardCell]
        let playerHand: [Card]
        let opponentHand: [Card]
        let deck: [Card]
        let playerScore: Int
        let opponentScore: Int
        let turn: Turn
        let scoredLines: Set<Int>
        let moves: Int
        let dailyBest: Int
        let lastEvent: String
        let playerStarts: Bool
        var resigned: Bool? = nil
        var lastPlacedIndex: Int? = nil
        var isValid: Bool {
            guard board.count == 25, playerHand.count <= 5, opponentHand.count <= 5,
                  scoredLines.allSatisfy({ (0..<12).contains($0) }),
                  (0...600).contains(playerScore), (0...600).contains(opponentScore), (0...25).contains(moves),
                  lastPlacedIndex.map({ board.indices.contains($0) }) ?? true,
                  board.allSatisfy({ ($0.card == nil) == ($0.owner == .none) }) else { return false }
            let cards = board.compactMap(\.card) + playerHand + opponentHand + deck
            guard cards.count == 52, Set(cards.map(\.id)).count == 52,
                  cards.allSatisfy({ (2...14).contains($0.rank) }) else { return false }
            let filled = board.filter { $0.card != nil }.count
            let completed = Set(GameEngine.lines.indices.filter { i in
                GameEngine.lines[i].allSatisfy { board[$0].card != nil }
            })
            guard completed == scoredLines else { return false }
            if mode == .daily {
                return dailyBest > 0 && opponentHand.isEmpty &&
                    ((turn == .player && filled == 20 && playerHand.count == 1 && moves == 0) ||
                     (turn == .finished && filled == 21 && playerHand.isEmpty && moves == 1))
            }
            let ours = board.filter { $0.owner == .player }.count
            let theirs = filled - ours
            guard ours == moves, abs(ours - theirs) <= 1,
                  playerHand.count == 5, opponentHand.count == 5 else { return false }
            let expectedPlayer = scoredLines.reduce(0) { sum, index in
                let line = GameEngine.lines[index]
                return sum + (line.filter { board[$0].owner == .player }.count >= 3
                    ? GameEngine.evaluate(line.compactMap { board[$0].card }).points : 0)
            }
            let expectedTotal = scoredLines.reduce(0) { $0 + GameEngine.evaluate(GameEngine.lines[$1].compactMap { board[$0].card }).points }
            guard playerScore == expectedPlayer, opponentScore == expectedTotal - expectedPlayer else { return false }
            if resigned == true { return mode == .ranked && turn == .finished && filled < 25 }
            if turn == .finished { return filled == 25 && (playerStarts ? ours == 13 : theirs == 13) }
            guard filled < 25 else { return false }
            let playerTurn = playerStarts ? ours == theirs : theirs > ours
            return turn == (playerTurn ? .player : .opponent)
        }
    }
    static let size = 5
    static let lines: [[Int]] = {
        (0..<5).map { r in (0..<5).map { r * 5 + $0 } } +
        (0..<5).map { c in (0..<5).map { $0 * 5 + c } } +
        [(0..<5).map { $0 * 6 }, (0..<5).map { $0 * 4 + 4 }]
    }()

    private(set) var id = UUID()
    let mode: Mode
    let difficulty: Difficulty
    private(set) var dailyKey: String
    private(set) var playerStarts = true
    private(set) var resigned = false
    @Published private(set) var board = Array(repeating: BoardCell(), count: 25)
    @Published private(set) var playerHand: [Card] = []
    @Published private(set) var opponentHandCount = 0
    @Published private(set) var playerScore = 0
    @Published private(set) var opponentScore = 0
    @Published private(set) var turn: Turn = .player
    @Published private(set) var lastPlacedIndex: Int?
    @Published private(set) var scoredLineCells: Set<Int> = []
    @Published var selectedHandIndex: Int?
    @Published private(set) var resultText: String?
    @Published private(set) var statusText = "轮到你落子"
    @Published private(set) var lastEvent = "选一张手牌，再点击空格落子。"
    private(set) var moves = 0
    private(set) var dailyBest = 0
    private var deck: [Card] = []
    private var opponentHand: [Card] = []
    private var scoredLines: Set<Int> = []
    private var opponentTask: Task<Void, Never>?
    var onChange: (() -> Void)?

    init(mode: Mode, difficulty: Difficulty = .strategic, snapshot: Snapshot? = nil, date: Date = Date()) {
        let validSnapshot = snapshot.flatMap { $0.isValid ? $0 : nil }
        self.mode = validSnapshot?.mode ?? mode
        self.difficulty = validSnapshot?.difficulty ?? difficulty
        dailyKey = validSnapshot?.dailyKey ?? DailyPuzzle.key(for: date)
        if let saved = validSnapshot {
            id = saved.id; board = saved.board; playerHand = saved.playerHand
            resigned = saved.resigned == true; lastPlacedIndex = saved.lastPlacedIndex
            opponentHand = saved.opponentHand; deck = saved.deck
            playerScore = saved.playerScore; opponentScore = saved.opponentScore
            turn = saved.turn; scoredLines = saved.scoredLines; moves = saved.moves
            dailyBest = saved.dailyBest; lastEvent = saved.lastEvent; playerStarts = saved.playerStarts
            opponentHandCount = opponentHand.count
            scoredLineCells = saved.mode == .daily && saved.moves == 0 ? [] : Set(scoredLines.flatMap { Self.lines[$0] })
            statusText = turn == .opponent ? "对方思考中…" : "轮到你落子"
            if turn == .finished { finish() }
        } else { newGame() }
    }

    var snapshot: Snapshot {
        Snapshot(id: id, mode: mode, difficulty: difficulty, dailyKey: dailyKey,
                 board: board, playerHand: playerHand, opponentHand: opponentHand, deck: deck,
                 playerScore: playerScore, opponentScore: opponentScore, turn: turn,
                 scoredLines: scoredLines, moves: moves, dailyBest: dailyBest,
                 lastEvent: lastEvent, playerStarts: playerStarts, resigned: resigned, lastPlacedIndex: lastPlacedIndex)
    }
    var canPlace: Bool {
        turn == .player && resultText == nil &&
            selectedHandIndex.map { playerHand.indices.contains($0) } == true
    }
    var filledCount: Int { board.filter { $0.card != nil }.count }

    func newGame() {
        pause()
        id = UUID(); deck = Card.fullDeck.shuffled()
        board = Array(repeating: BoardCell(), count: 25)
        scoredLines = []; scoredLineCells = []; lastPlacedIndex = nil
        selectedHandIndex = nil; resultText = nil; moves = 0; resigned = false
        playerScore = 0; opponentScore = 0; dailyBest = 0
        lastEvent = "选一张手牌，再点击空格落子。"
        if mode == .daily {
            setupDaily()
        } else {
            playerHand = Array(deck.prefix(5)); deck.removeFirst(5)
            opponentHand = Array(deck.prefix(5)); deck.removeFirst(5)
            playerStarts = Bool.random()
            turn = playerStarts ? .player : .opponent
        }
        opponentHandCount = opponentHand.count
        statusText = turn == .player ? "轮到你落子" : "对方思考中…"
        onChange?()
        resume()
    }

    private func setupDaily() {
        let seed = dailyKey.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
        var random = PuzzleRandom(state: seed)
        deck = random.shuffle(Card.fullDeck)
        let holes = random.shuffle(Array(0..<5))
        for row in 0..<5 {
            let owners: [CellOwner] = random.shuffle([.player, .player, .opponent, .opponent])
            var slot = 0
            for col in 0..<5 where col != holes[row] {
                board[row * 5 + col] = BoardCell(card: deck.removeFirst(), owner: owners[slot])
                slot += 1
            }
        }
        playerHand = [deck.removeFirst()]; opponentHand = []; turn = .player; playerStarts = true
        // Pre-existing complete diagonals are baseline, never awarded by the final move.
        scoredLines = Set(Self.lines.indices.filter { i in Self.lines[i].allSatisfy { board[$0].card != nil } })
        dailyBest = board.indices.filter { board[$0].card == nil }.map {
            incrementalPoints(card: playerHand[0], at: $0, owner: .player).player
        }.max() ?? 0
        lastEvent = "仅一次落子机会。金色属于你，白色属于对手；只计算新完成的阵线。"
    }

    func place(at index: Int) {
        guard board.indices.contains(index), canPlace, board[index].card == nil,
              let selected = selectedHandIndex else { return }
        let card = playerHand.remove(at: selected)
        selectedHandIndex = nil
        board[index] = BoardCell(card: card, owner: .player)
        lastPlacedIndex = index; moves += 1
        evaluateLines()
        if mode == .daily { finish(); onChange?(); return }
        if !deck.isEmpty { playerHand.append(deck.removeFirst()) }
        if filledCount == 25 { finish() }
        else { turn = .opponent; statusText = "对方思考中…" }
        onChange?()
        resume()
    }

    func pause() { opponentTask?.cancel(); opponentTask = nil }
    func resume() {
        guard turn == .opponent, opponentTask == nil else { return }
        opponentTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 650_000_000) } catch { return }
            guard !Task.isCancelled, let self else { return }
            self.opponentTask = nil
            self.performOpponentMove()
        }
    }

    /// Also used by the deterministic engine checks, without a wall-clock delay.
    func performOpponentMove() {
        pause()
        guard turn == .opponent, !opponentHand.isEmpty else { return }
        let empty = board.indices.filter { board[$0].card == nil }
        guard let fallback = empty.randomElement() else { finish(); onChange?(); return }
        var best = (hand: 0, cell: fallback, value: -Double.infinity)
        if difficulty == .strategic {
            for hand in opponentHand.indices {
                for cell in empty {
                    let points = incrementalPoints(card: opponentHand[hand], at: cell, owner: .opponent)
                    var value = Double(points.opponent - points.player) * 100
                    for (lineID, line) in Self.lines.enumerated() where line.contains(cell) && !scoredLines.contains(lineID) {
                        let own = line.filter { board[$0].owner == .opponent }.count + 1
                        let other = line.filter { board[$0].owner == .player }.count
                        let remaining = line.filter { board[$0].card == nil }.count - 1
                        if remaining > 0 {
                            value += Double(own - other) * 3 + (own >= 3 ? 14 : 0)
                            let cards = line.compactMap { board[$0].card } + [opponentHand[hand]]
                            let pairs = cards.count - Set(cards.map(\.rank)).count
                            value += Double(pairs) * (own >= other ? 2 : -2)
                            if remaining == 1 && other >= 2 { value -= 18 }
                        }
                    }
                    if value > best.value { best = (hand, cell, value) }
                }
            }
        }
        let card = opponentHand.remove(at: best.hand)
        board[best.cell] = BoardCell(card: card, owner: .opponent)
        lastPlacedIndex = best.cell
        if !deck.isEmpty { opponentHand.append(deck.removeFirst()) }
        opponentHandCount = opponentHand.count
        evaluateLines()
        if filledCount == 25 { finish() }
        else { turn = .player; statusText = "轮到你落子" }
        onChange?()
    }

    private func incrementalPoints(card: Card, at index: Int, owner: CellOwner) -> (player: Int, opponent: Int) {
        var preview = board
        preview[index] = BoardCell(card: card, owner: owner)
        var result = (player: 0, opponent: 0)
        for (lineID, line) in Self.lines.enumerated() where !scoredLines.contains(lineID) && line.contains(index) {
            let cards = line.compactMap { preview[$0].card }
            guard cards.count == 5 else { continue }
            let points = Self.evaluate(cards).points
            if line.filter({ preview[$0].owner == .player }).count >= 3 { result.player += points }
            else { result.opponent += points }
        }
        return result
    }

    private func evaluateLines() {
        var events: [String] = []
        for (lineID, line) in Self.lines.enumerated() where !scoredLines.contains(lineID) {
            let cards = line.compactMap { board[$0].card }
            guard cards.count == 5 else { continue }
            scoredLines.insert(lineID); scoredLineCells.formUnion(line)
            let rank = Self.evaluate(cards)
            let ours = line.filter { board[$0].owner == .player }.count >= 3
            if ours { playerScore += rank.points } else { opponentScore += rank.points }
            events.append("\(ours ? "我方" : "对方") · \(rank.name) +\(rank.points)")
        }
        if !events.isEmpty { lastEvent = events.joined(separator: "  /  ") }
    }

    /// 5 张牌的牌型评价
    static func evaluate(_ cards: [Card]) -> HandRank {
        guard cards.count == 5 else { return HandRank(name: "未成阵", points: 0) }
        let ranks = cards.map(\.rank).sorted()
        let flush = Set(cards.map(\.suit)).count == 1
        let unique = Set(ranks)
        var straight = unique.count == 5 && (ranks.last! - ranks.first! == 4)
        if !straight && unique.count == 5 && unique == Set([2, 3, 4, 5, 14]) { straight = true } // A-5 轮子
        let counts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count).values.sorted(by: >)

        switch (flush, straight, counts) {
        case (true, true, _):
            return unique.contains(14) && unique.contains(13)
                ? HandRank(name: "皇家同花顺", points: 50)
                : HandRank(name: "同花顺", points: 30)
        case (_, _, [4, 1]):    return HandRank(name: "四条", points: 20)
        case (_, _, [3, 2]):    return HandRank(name: "葫芦", points: 14)
        case (true, false, _):  return HandRank(name: "同花", points: 10)
        case (false, true, _):  return HandRank(name: "顺子", points: 8)
        case (_, _, [3, 1, 1]): return HandRank(name: "三条", points: 6)
        case (_, _, [2, 2, 1]): return HandRank(name: "两对", points: 4)
        case (_, _, [2, 1, 1, 1]): return HandRank(name: "一对", points: 2)
        default:                return HandRank(name: "高牌", points: 1)
        }
    }

    struct LineResult: Identifiable {
        let id: Int
        let cells: [Int]
        let cards: [Card]
        let rank: HandRank
        let playerOwns: Bool
        var title: String {
            if id < 5 { return "第 \(id + 1) 行" }
            if id < 10 { return "第 \(id - 4) 列" }
            return id == 10 ? "左上至右下" : "右上至左下"
        }
    }
    var lineResults: [LineResult] {
        Self.lines.enumerated().compactMap { index, cells in
            let cards = cells.compactMap { board[$0].card }
            guard cards.count == 5 else { return nil }
            if mode == .daily, let last = lastPlacedIndex, !cells.contains(last) { return nil }
            return LineResult(id: index, cells: cells, cards: cards, rank: Self.evaluate(cards),
                              playerOwns: cells.filter { board[$0].owner == .player }.count >= 3)
        }
    }
    struct DailyOption: Identifiable {
        let id: Int
        let points: Int
        let chosen: Bool
    }
    var dailyOptions: [DailyOption] {
        guard mode == .daily, turn == .finished, let last = lastPlacedIndex, let card = board[last].card else { return [] }
        var initial = board
        initial[last] = BoardCell()
        let baseline = Set(Self.lines.indices.filter { i in Self.lines[i].allSatisfy { initial[$0].card != nil } })
        return initial.indices.filter { initial[$0].card == nil }.map { index in
            var candidate = initial
            candidate[index] = BoardCell(card: card, owner: .player)
            let points = Self.lines.enumerated().reduce(0) { sum, pair in
                let (lineID, cells) = pair
                guard !baseline.contains(lineID), cells.allSatisfy({ candidate[$0].card != nil }),
                      cells.filter({ candidate[$0].owner == .player }).count >= 3 else { return sum }
                return sum + Self.evaluate(cells.compactMap { candidate[$0].card }).points
            }
            return DailyOption(id: index, points: points, chosen: index == last)
        }
    }
    func resign() {
        guard mode == .ranked, turn != .finished else { return }
        pause(); selectedHandIndex = nil; resigned = true
        finish(); onChange?()
    }

    private func finish() {
        turn = .finished; statusText = "对局结束"
        if resigned { resultText = "收子认负 · 来日再战"; return }
        if mode == .daily {
            resultText = playerScore == dailyBest ? "妙手成阵 · 今日最佳解" : "今日得分 \(playerScore)"
        } else {
            resultText = playerScore == opponentScore ? "握手言和" : (playerScore > opponentScore ? "旗开得胜" : "再接再厉")
        }
    }
}

struct GameRequest: Identifiable {
    let id = UUID()
    let mode: GameEngine.Mode
    var snapshot: GameEngine.Snapshot? = nil
}

final class AppState: ObservableObject {
    @Published var selectedTab = 0
    @Published var gameRequest: GameRequest?
    @Published var showDaily = false
    var pendingGame: GameRequest?
    func openDailyGame() {
        pendingGame = GameRequest(mode: .daily)
        showDaily = false
    }
    func dailyDidDismiss() {
        if let request = pendingGame { pendingGame = nil; gameRequest = request }
    }
}
