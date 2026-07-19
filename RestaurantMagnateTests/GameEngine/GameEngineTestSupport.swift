import Foundation
@testable import RestaurantMagnate

struct SequenceDiceRoller: DiceRolling {
    private var rolls: [DiceRoll]

    init(_ rolls: [DiceRoll]) {
        self.rolls = rolls
    }

    mutating func roll() -> DiceRoll {
        precondition(!rolls.isEmpty, "Test dice sequence exhausted")
        return rolls.removeFirst()
    }
}

func testPlayerSetups() -> [PlayerSetup] {
    [
        PlayerSetup(name: "Maya", token: .chefHat),
        PlayerSetup(name: "Theo", token: .takeoutBag)
    ]
}

func startedGameState(currentPlayerIndex: Int = 0) throws -> GameState {
    var state = try GameSetupFactory.makeGame(players: testPlayerSetups())
    state.currentPlayerIndex = currentPlayerIndex
    state.phase = .awaitingRoll
    state.openingRollPlayerIDs = []
    state.openingRolls = [:]
    return state
}

func propertyID(at position: Int) -> PropertyID {
    guard case let .property(property) = Board.restaurantMagnate[position].kind else {
        preconditionFailure("Expected property at position \(position)")
    }
    return property.id
}

