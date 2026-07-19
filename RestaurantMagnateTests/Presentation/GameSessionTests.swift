import Testing
@testable import RestaurantMagnate

@MainActor
@Suite("Game session presentation")
struct GameSessionTests {
    @Test
    func exposesOpeningRollActorAndLegalControl() throws {
        let setups = testPlayerSetups()
        let session = try GameSession(
            players: setups,
            diceRoller: AnyDiceRoller(SequenceDiceRoller([
                DiceRoll(first: 1, second: 2),
                DiceRoll(first: 5, second: 4)
            ]))
        )

        #expect(session.actingPlayer?.name == "Maya")
        #expect(session.canRoll)

        session.rollDice()

        #expect(session.actingPlayer?.name == "Theo")
        #expect(session.eventLog.last == "Maya rolled 1 + 2.")

        session.rollDice()

        #expect(session.currentPlayer?.name == "Theo")
        #expect(session.state.phase == .awaitingRoll)
        #expect(session.eventLog.contains("Theo takes the first turn."))
    }

    @Test
    func purchaseControlDispatchesToEngine() throws {
        let session = try GameSession(
            players: testPlayerSetups(),
            diceRoller: AnyDiceRoller(SequenceDiceRoller([
                DiceRoll(first: 6, second: 5),
                DiceRoll(first: 1, second: 1),
                DiceRoll(first: 1, second: 2)
            ]))
        )

        session.rollDice()
        session.rollDice()
        session.rollDice()

        let bargainBurgerID = propertyID(at: 3)
        #expect(session.offeredProperty?.id == bargainBurgerID)

        session.buyOfferedProperty()

        #expect(session.state.propertyStates[bargainBurgerID]?.ownerID == session.currentPlayer?.id)
        #expect(session.currentPlayer?.cash == Money(1_440))
        #expect(session.state.phase == .awaitingEndTurn)
        #expect(session.eventLog.last?.contains("bought Bargain Burger") == true)
    }
}
