import Testing
@testable import RestaurantMagnate

@Suite("Movement and purchases")
struct MovementAndPurchaseTests {
    @Test
    func passingGrandOpeningPaysAndOffersProperty() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        let dollarDriveThruID = propertyID(at: 1)
        state.players[0].position = BoardSpaceID(rawValue: 38)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        let events = try engine.perform(.rollDice, by: mayaID)

        #expect(engine.state.players[0].position == BoardSpaceID(rawValue: 1))
        #expect(engine.state.players[0].cash == Money(1_700))
        #expect(engine.state.phase == .awaitingPurchase(propertyID: dollarDriveThruID))
        #expect(events.contains(.passedGrandOpening(playerID: mayaID, amount: Money(200))))
        #expect(events.contains(.purchaseOffered(playerID: mayaID, propertyID: dollarDriveThruID)))
    }

    @Test
    func playerCanPurchaseOfferedProperty() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        let dollarDriveThruID = propertyID(at: 1)
        state.players[0].position = BoardSpaceID(rawValue: 38)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        _ = try engine.perform(.rollDice, by: mayaID)
        #expect(engine.legalActions(for: mayaID) == [
            .buyProperty(dollarDriveThruID),
            .declinePurchase(dollarDriveThruID)
        ])

        let events = try engine.perform(.buyProperty(dollarDriveThruID), by: mayaID)

        #expect(engine.state.players[0].cash == Money(1_640))
        #expect(engine.state.propertyStates[dollarDriveThruID]?.ownerID == mayaID)
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(events.contains(.propertyPurchased(
            playerID: mayaID,
            propertyID: dollarDriveThruID,
            price: Money(60)
        )))
    }

    @Test
    func taxIsPaidAutomatically() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        state.players[0].position = BoardSpaceID(rawValue: 38)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 2, second: 4)])
        )

        let events = try engine.perform(.rollDice, by: mayaID)

        #expect(engine.state.players[0].position == BoardSpaceID(rawValue: 4))
        #expect(engine.state.players[0].cash == Money(1_500))
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(events.contains(.taxPaid(playerID: mayaID, amount: Money(200))))
    }

    @Test
    func healthInspectorSendsPlayerToDetention() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        state.players[0].position = BoardSpaceID(rawValue: 28)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 1)])
        )

        let events = try engine.perform(.rollDice, by: mayaID)

        #expect(engine.state.players[0].position == BoardSpaceID(rawValue: 10))
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(events.contains(.sentToDetention(
            playerID: mayaID,
            destination: BoardSpaceID(rawValue: 10)
        )))
    }
}
