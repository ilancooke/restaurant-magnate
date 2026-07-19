import Foundation

struct DiceRoll: Hashable, Sendable {
    let first: Int
    let second: Int

    init(first: Int, second: Int) {
        precondition((1...6).contains(first) && (1...6).contains(second))
        self.first = first
        self.second = second
    }

    var total: Int {
        first + second
    }

    var isDouble: Bool {
        first == second
    }
}

protocol DiceRolling {
    mutating func roll() -> DiceRoll
}

struct SystemDiceRoller: DiceRolling {
    mutating func roll() -> DiceRoll {
        DiceRoll(
            first: Int.random(in: 1...6),
            second: Int.random(in: 1...6)
        )
    }
}

