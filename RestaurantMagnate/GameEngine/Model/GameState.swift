import Foundation

struct GameState: Sendable {
    let board: Board
    var players: [Player]
    var propertyStates: [PropertyID: PropertyState]
    var currentPlayerIndex: Int?
    var phase: TurnPhase
    var latestRoll: DiceRoll?
    var openingRollPlayerIDs: [PlayerID]
    var openingRolls: [PlayerID: DiceRoll]
    var auction: AuctionState?
    var debt: Debt?
    var consecutiveDoubles: Int

    var activePlayers: [Player] {
        players.filter { $0.status == .active }
    }
}

enum GameSetupError: Error, Equatable {
    case invalidPlayerCount
    case emptyPlayerName
    case duplicatePlayerName
    case duplicatePlayerID
    case duplicatePlayerToken
}

enum GameSetupFactory {
    static let startingCash = Money(1_500)
    static let minimumPlayers = 2
    static let maximumPlayers = 4

    static func makeGame(
        players setups: [PlayerSetup],
        board: Board = .restaurantMagnate
    ) throws -> GameState {
        guard (minimumPlayers...maximumPlayers).contains(setups.count) else {
            throw GameSetupError.invalidPlayerCount
        }

        let trimmedNames = setups.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard trimmedNames.allSatisfy({ !$0.isEmpty }) else {
            throw GameSetupError.emptyPlayerName
        }
        guard Set(trimmedNames.map { $0.lowercased() }).count == setups.count else {
            throw GameSetupError.duplicatePlayerName
        }
        guard Set(setups.map(\.id)).count == setups.count else {
            throw GameSetupError.duplicatePlayerID
        }
        guard Set(setups.map(\.token)).count == setups.count else {
            throw GameSetupError.duplicatePlayerToken
        }

        let players = zip(setups, trimmedNames).map { setup, trimmedName in
            Player(
                id: setup.id,
                name: trimmedName,
                token: setup.token,
                cash: startingCash,
                position: BoardSpaceID(rawValue: 0),
                status: .active,
                detention: nil
            )
        }
        let propertyStates = Dictionary(
            uniqueKeysWithValues: board.properties.map { property in
                (property.id, PropertyState(propertyID: property.id))
            }
        )

        return GameState(
            board: board,
            players: players,
            propertyStates: propertyStates,
            currentPlayerIndex: nil,
            phase: .openingRoll(remainingPlayerIDs: players.map(\.id)),
            latestRoll: nil,
            openingRollPlayerIDs: players.map(\.id),
            openingRolls: [:],
            auction: nil,
            debt: nil,
            consecutiveDoubles: 0
        )
    }
}
