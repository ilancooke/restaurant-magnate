//
//  RestaurantMagnateTests.swift
//  RestaurantMagnateTests
//
//  Created by ilan on 7/18/26.
//

import Testing
@testable import RestaurantMagnate

@Suite("Game setup")
struct RestaurantMagnateTests {
    private func setups(count: Int) -> [PlayerSetup] {
        let names = ["Maya", "Theo", "Nina", "Leo"]
        return (0..<count).map { index in
            PlayerSetup(
                name: names[index],
                token: PlayerToken.allCases[index]
            )
        }
    }

    @Test(arguments: [2, 3, 4])
    func createsSupportedPlayerCounts(count: Int) throws {
        let game = try GameSetupFactory.makeGame(players: setups(count: count))

        #expect(game.players.count == count)
        #expect(game.players.allSatisfy { $0.cash == Money(1_500) })
        #expect(game.players.allSatisfy { $0.position == BoardSpaceID(rawValue: 0) })
        #expect(game.currentPlayerIndex == nil)
        #expect(game.propertyStates.count == 28)
        #expect(game.propertyStates.values.allSatisfy { $0.ownerID == nil })
        #expect(game.propertyStates.values.allSatisfy { !$0.isMortgaged })
    }

    @Test
    func rejectsUnsupportedPlayerCounts() {
        #expect(throws: GameSetupError.invalidPlayerCount) {
            try GameSetupFactory.makeGame(players: setups(count: 1))
        }
    }

    @Test
    func rejectsDuplicateNamesIgnoringCase() {
        let duplicateNames = [
            PlayerSetup(name: "Maya", token: .chefHat),
            PlayerSetup(name: "maya", token: .takeoutBag)
        ]

        #expect(throws: GameSetupError.duplicatePlayerName) {
            try GameSetupFactory.makeGame(players: duplicateNames)
        }
    }

    @Test
    func rejectsDuplicateTokens() {
        let duplicateTokens = [
            PlayerSetup(name: "Maya", token: .chefHat),
            PlayerSetup(name: "Theo", token: .chefHat)
        ]

        #expect(throws: GameSetupError.duplicatePlayerToken) {
            try GameSetupFactory.makeGame(players: duplicateTokens)
        }
    }

    @Test
    func trimsPlayerNames() throws {
        let game = try GameSetupFactory.makeGame(players: [
            PlayerSetup(name: "  Maya  ", token: .chefHat),
            PlayerSetup(name: "Theo", token: .takeoutBag)
        ])

        #expect(game.players[0].name == "Maya")
    }
}
