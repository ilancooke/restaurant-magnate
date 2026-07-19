import Testing
@testable import RestaurantMagnate

@Suite("Rent and debt")
struct RentAndDebtTests {
    @Test
    func baseRentTransfersAutomatically() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        let propertyID = propertyID(at: 1)
        state.players[0].position = BoardSpaceID(rawValue: 38)
        state.propertyStates[propertyID]?.ownerID = theoID
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        let events = try engine.perform(.rollDice, by: mayaID)

        #expect(engine.state.players[0].cash == Money(1_698))
        #expect(engine.state.players[1].cash == Money(1_502))
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(events.contains(.rentPaid(
            propertyID: propertyID,
            from: mayaID,
            to: theoID,
            amount: Money(2)
        )))
    }

    @Test
    func completeRestaurantGroupDoublesUnimprovedRent() throws {
        var state = try startedGameState()
        let theoID = state.players[1].id
        let firstPropertyID = propertyID(at: 1)
        let secondPropertyID = propertyID(at: 3)
        state.propertyStates[firstPropertyID]?.ownerID = theoID
        state.propertyStates[secondPropertyID]?.ownerID = theoID
        guard case let .property(property) = state.board[1].kind,
              let propertyState = state.propertyStates[firstPropertyID] else {
            Issue.record("Missing test property")
            return
        }

        let rent = RentCalculator.rent(
            for: property,
            propertyState: propertyState,
            in: state
        )

        #expect(rent == Money(4))
    }

    @Test
    func deliveryRentUsesNumberOwned() throws {
        var state = try startedGameState()
        let theoID = state.players[1].id
        for position in [5, 15, 25] {
            state.propertyStates[propertyID(at: position)]?.ownerID = theoID
        }
        let landedPropertyID = propertyID(at: 5)
        guard case let .property(property) = state.board[5].kind,
              let propertyState = state.propertyStates[landedPropertyID] else {
            Issue.record("Missing delivery property")
            return
        }

        let rent = RentCalculator.rent(
            for: property,
            propertyState: propertyState,
            in: state
        )

        #expect(rent == Money(100))
    }

    @Test
    func infrastructureRentUsesDiceTotal() throws {
        var state = try startedGameState()
        let theoID = state.players[1].id
        let sodaID = propertyID(at: 12)
        let fryerID = propertyID(at: 28)
        state.propertyStates[sodaID]?.ownerID = theoID
        state.propertyStates[fryerID]?.ownerID = theoID
        state.latestRoll = DiceRoll(first: 3, second: 3)
        guard case let .property(property) = state.board[12].kind,
              let propertyState = state.propertyStates[sodaID] else {
            Issue.record("Missing infrastructure property")
            return
        }

        let rent = RentCalculator.rent(
            for: property,
            propertyState: propertyState,
            in: state
        )

        #expect(rent == Money(60))
    }

    @Test
    func unaffordableRentCreatesDebtWithoutPartialPayment() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        let propertyID = propertyID(at: 3)
        state.players[0].position = BoardSpaceID(rawValue: 0)
        state.players[0].cash = Money(1)
        state.propertyStates[propertyID]?.ownerID = theoID
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        let events = try engine.perform(.rollDice, by: mayaID)
        let expectedDebt = Debt(
            debtorID: mayaID,
            creditor: .player(theoID),
            amount: Money(4),
            reason: .rent(propertyID)
        )

        #expect(engine.state.players[0].cash == Money(1))
        #expect(engine.state.players[1].cash == Money(1_500))
        #expect(engine.state.debt == expectedDebt)
        #expect(engine.state.phase == .resolvingDebt(expectedDebt))
        #expect(events.contains(.debtRequired(expectedDebt)))
        #expect(engine.legalActions(for: mayaID) == [.declareBankruptcy])
    }
}
