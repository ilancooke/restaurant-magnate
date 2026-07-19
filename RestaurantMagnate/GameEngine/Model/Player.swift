import Foundation

enum PlayerToken: String, CaseIterable, Hashable, Sendable {
    case chefHat
    case takeoutBag
    case receiptRoll
    case servingTray
}

enum PlayerStatus: Hashable, Sendable {
    case active
    case bankrupt
}

struct PlayerSetup: Hashable, Sendable {
    let id: PlayerID
    let name: String
    let token: PlayerToken

    init(id: PlayerID = PlayerID(), name: String, token: PlayerToken) {
        self.id = id
        self.name = name
        self.token = token
    }
}

struct Player: Hashable, Sendable {
    let id: PlayerID
    let name: String
    let token: PlayerToken
    var cash: Money
    var position: BoardSpaceID
    var status: PlayerStatus
    var detention: DetentionStatus?
}

struct DetentionStatus: Hashable, Sendable {
    var failedRolls: Int

    init(failedRolls: Int = 0) {
        precondition((0...2).contains(failedRolls))
        self.failedRolls = failedRolls
    }
}
