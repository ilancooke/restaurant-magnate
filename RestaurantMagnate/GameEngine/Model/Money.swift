import Foundation

struct Money: Hashable, Comparable, Sendable {
    let amount: Int

    init(_ amount: Int) {
        precondition(amount >= 0, "Money cannot be negative")
        self.amount = amount
    }

    static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.amount < rhs.amount
    }
}

