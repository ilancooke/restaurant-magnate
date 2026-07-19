import Testing
@testable import RestaurantMagnate

@Suite("Doubles and detention")
struct DoublesAndDetentionTests {
    @Test
    func doublesGrantAnotherRollAfterLandingResolves() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        state.players[0].position = BoardSpaceID(rawValue: 18)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 1)])
        )

        _ = try engine.perform(.rollDice, by: mayaID)

        #expect(engine.state.players[0].position == BoardSpaceID(rawValue: 20))
        #expect(engine.state.phase == .awaitingRoll)
        #expect(engine.state.consecutiveDoubles == 1)
        #expect(engine.legalActions(for: mayaID) == [.rollDice])
    }

    @Test
    func thirdConsecutiveDoubleSendsPlayerToDetentionWithoutMoving() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        state.players[0].position = BoardSpaceID(rawValue: 5)
        state.consecutiveDoubles = 2
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 4, second: 4)])
        )

        let events = try engine.perform(.rollDice, by: mayaID)

        #expect(engine.state.players[0].position == BoardSpaceID(rawValue: 10))
        #expect(engine.state.players[0].detention == DetentionStatus())
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(engine.state.consecutiveDoubles == 0)
        #expect(events.contains(.thirdConsecutiveDouble(playerID: mayaID)))
    }

    @Test
    func detentionDoublesReleaseAndMoveWithoutExtraRoll() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        state.players[0].position = BoardSpaceID(rawValue: 10)
        state.players[0].detention = DetentionStatus(failedRolls: 1)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 3, second: 3)])
        )

        let events = try engine.perform(.rollDice, by: mayaID)

        #expect(engine.state.players[0].position == BoardSpaceID(rawValue: 16))
        #expect(engine.state.players[0].detention == nil)
        #expect(engine.state.phase == .awaitingPurchase(propertyID: propertyID(at: 16)))
        #expect(events.contains(.releasedFromDetention(playerID: mayaID)))

        _ = try engine.perform(.buyProperty(propertyID(at: 16)), by: mayaID)
        #expect(engine.state.phase == .awaitingEndTurn)
    }

    @Test
    func failedDetentionRollEndsTurnAndIncrementsAttempts() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        state.players[0].position = BoardSpaceID(rawValue: 10)
        state.players[0].detention = DetentionStatus()
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        let events = try engine.perform(.rollDice, by: mayaID)

        #expect(engine.state.players[0].position == BoardSpaceID(rawValue: 10))
        #expect(engine.state.players[0].detention == DetentionStatus(failedRolls: 1))
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(events.contains(.detentionRollFailed(playerID: mayaID, failedRolls: 1)))
    }

    @Test
    func playerMayPayFeeBeforeRolling() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        state.players[0].position = BoardSpaceID(rawValue: 10)
        state.players[0].detention = DetentionStatus(failedRolls: 1)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([])
        )

        #expect(engine.legalActions(for: mayaID) == [
            .rollDice,
            .payDetentionFee(amount: Money(50))
        ])

        let events = try engine.perform(.payDetentionFee, by: mayaID)

        #expect(engine.state.players[0].cash == Money(1_450))
        #expect(engine.state.players[0].detention == nil)
        #expect(engine.state.phase == .awaitingRoll)
        #expect(events.contains(.detentionFeePaid(playerID: mayaID, amount: Money(50))))
    }

    @Test
    func thirdFailedRollChargesFeeAndMoves() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        state.players[0].position = BoardSpaceID(rawValue: 10)
        state.players[0].detention = DetentionStatus(failedRolls: 2)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        _ = try engine.perform(.rollDice, by: mayaID)

        #expect(engine.state.players[0].cash == Money(1_450))
        #expect(engine.state.players[0].position == BoardSpaceID(rawValue: 13))
        #expect(engine.state.players[0].detention == nil)
        #expect(engine.state.phase == .awaitingPurchase(propertyID: propertyID(at: 13)))
    }
}
