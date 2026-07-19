import Testing
@testable import RestaurantMagnate

@Suite("Opening and turn flow")
struct OpeningTurnTests {
    @Test
    func openingRollSelectsHighestPlayer() throws {
        let state = try GameSetupFactory.makeGame(players: testPlayerSetups())
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([
                DiceRoll(first: 1, second: 2),
                DiceRoll(first: 5, second: 4)
            ])
        )

        #expect(engine.legalActions(for: mayaID) == [.rollDice])
        _ = try engine.perform(.rollDice, by: mayaID)
        #expect(engine.legalActions(for: theoID) == [.rollDice])

        let events = try engine.perform(.rollDice, by: theoID)

        #expect(engine.state.currentPlayerIndex == 1)
        #expect(engine.state.phase == .awaitingRoll)
        #expect(events.contains(.starterSelected(theoID)))
    }

    @Test
    func tiedOpeningLeadersReroll() throws {
        let state = try GameSetupFactory.makeGame(players: testPlayerSetups())
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([
                DiceRoll(first: 5, second: 5),
                DiceRoll(first: 6, second: 4),
                DiceRoll(first: 2, second: 3),
                DiceRoll(first: 6, second: 2)
            ])
        )

        _ = try engine.perform(.rollDice, by: mayaID)
        let tieEvents = try engine.perform(.rollDice, by: theoID)

        #expect(engine.state.phase == .openingRoll(remainingPlayerIDs: [mayaID, theoID]))
        #expect(tieEvents.contains(.openingRollTied(playerIDs: [mayaID, theoID])))

        _ = try engine.perform(.rollDice, by: mayaID)
        _ = try engine.perform(.rollDice, by: theoID)

        #expect(engine.state.currentPlayerIndex == 1)
        #expect(engine.state.phase == .awaitingRoll)
    }

    @Test
    func wrongPlayerCannotAct() throws {
        let state = try startedGameState()
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 1)])
        )

        #expect(throws: GameEngineError.wrongPlayer(expected: mayaID, actual: theoID)) {
            try engine.perform(.rollDice, by: theoID)
        }
    }

    @Test
    func endTurnAdvancesToNextPlayer() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        state.players[0].position = BoardSpaceID(rawValue: 17)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        _ = try engine.perform(.rollDice, by: mayaID)
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(engine.legalActions(for: mayaID) == [.endTurn])

        let events = try engine.perform(.endTurn, by: mayaID)

        #expect(engine.state.currentPlayerIndex == 1)
        #expect(engine.state.phase == .awaitingRoll)
        #expect(events == [.turnEnded(playerID: mayaID, nextPlayerID: theoID)])
    }
}
