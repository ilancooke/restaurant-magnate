import Testing
@testable import RestaurantMagnate

@Suite("Solvency and bankruptcy")
struct SolvencyAndBankruptcyTests {
    @Test
    func mortgageProceedsAutomaticallySettleOutstandingDebt() throws {
        var state = try startedGameState()
        let debtorID = state.players[0].id
        let creditorID = state.players[1].id
        let propertyID = propertyID(at: 1)
        let debt = Debt(
            debtorID: debtorID,
            creditor: .player(creditorID),
            amount: Money(20),
            reason: .rent(propertyID)
        )
        state.players[0].cash = Money(0)
        state.propertyStates[propertyID]?.ownerID = debtorID
        state.debt = debt
        state.debtContinuation = .finishLanding(allowsExtraRoll: false)
        state.phase = .resolvingDebt(debt)
        var engine = GameEngine(state: state, diceRoller: SequenceDiceRoller([]))

        #expect(!engine.legalActions(for: debtorID).contains(.declareBankruptcy))

        let events = try engine.perform(.mortgageProperty(propertyID), by: debtorID)

        #expect(engine.state.players[0].cash == Money(10))
        #expect(engine.state.players[1].cash == Money(1_520))
        #expect(engine.state.propertyStates[propertyID]?.isMortgaged == true)
        #expect(engine.state.debt == nil)
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(events.contains(.debtPaid(debt)))
    }

    @Test
    func restaurantCannotBeMortgagedWhileItsGroupHasAnUpgrade() throws {
        var state = try startedGameState()
        let playerID = state.players[0].id
        let firstPropertyID = propertyID(at: 1)
        let secondPropertyID = propertyID(at: 3)
        state.propertyStates[firstPropertyID]?.ownerID = playerID
        state.propertyStates[secondPropertyID]?.ownerID = playerID
        state.propertyStates[secondPropertyID]?.upgradeLevel = 1
        let engine = GameEngine(state: state, diceRoller: SequenceDiceRoller([]))

        #expect(!engine.legalActions(for: playerID).contains {
            guard case let .mortgageProperty(propertyID, _) = $0 else {
                return false
            }
            return propertyID == firstPropertyID
        })
    }

    @Test
    func unmortgageChargesPrincipalPlusRoundedUpInterest() throws {
        var state = try startedGameState()
        let playerID = state.players[0].id
        let propertyID = propertyID(at: 37)
        state.propertyStates[propertyID]?.ownerID = playerID
        state.propertyStates[propertyID]?.isMortgaged = true
        var engine = GameEngine(state: state, diceRoller: SequenceDiceRoller([]))

        let events = try engine.perform(.unmortgageProperty(propertyID), by: playerID)

        #expect(engine.state.players[0].cash == Money(1_307))
        #expect(engine.state.propertyStates[propertyID]?.isMortgaged == false)
        #expect(events.contains(.propertyUnmortgaged(
            playerID: playerID,
            propertyID: propertyID,
            cost: Money(193)
        )))
    }

    @Test
    func mortgageSettlesThirdRenovationFeeAndResumesMovement() throws {
        var state = try startedGameState()
        let playerID = state.players[0].id
        let mortgagePropertyID = propertyID(at: 39)
        state.players[0].cash = Money(0)
        state.players[0].position = BoardSpaceID(rawValue: 10)
        state.players[0].detention = DetentionStatus(failedRolls: 2)
        state.propertyStates[mortgagePropertyID]?.ownerID = playerID
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        _ = try engine.perform(.rollDice, by: playerID)
        _ = try engine.perform(.mortgageProperty(mortgagePropertyID), by: playerID)

        #expect(engine.state.players[0].cash == Money(150))
        #expect(engine.state.players[0].detention == nil)
        #expect(engine.state.players[0].position == BoardSpaceID(rawValue: 13))
        #expect(engine.state.phase == .awaitingPurchase(propertyID: propertyID(at: 13)))
    }

    @Test
    func bankruptcyToPlayerTransfersAssetsAndDeclaresWinner() throws {
        var state = try startedGameState()
        let debtorID = state.players[0].id
        let creditorID = state.players[1].id
        let propertyID = propertyID(at: 1)
        let debt = Debt(
            debtorID: debtorID,
            creditor: .player(creditorID),
            amount: Money(100),
            reason: .rent(propertyID)
        )
        state.players[0].cash = Money(25)
        state.propertyStates[propertyID]?.ownerID = debtorID
        state.debt = debt
        state.debtContinuation = .finishLanding(allowsExtraRoll: false)
        state.phase = .resolvingDebt(debt)
        var engine = GameEngine(state: state, diceRoller: SequenceDiceRoller([]))

        _ = try engine.perform(.mortgageProperty(propertyID), by: debtorID)
        let events = try engine.perform(.declareBankruptcy, by: debtorID)

        #expect(engine.state.players[0].status == .bankrupt)
        #expect(engine.state.players[1].cash == Money(1_555))
        #expect(engine.state.propertyStates[propertyID]?.ownerID == creditorID)
        #expect(engine.state.phase == .gameOver(winnerID: creditorID))
        #expect(events.contains(.winnerDeclared(creditorID)))
    }

    @Test
    func recipientChoosesHowToHandleTransferredMortgage() throws {
        var state = try threePlayerStartedGameState()
        let debtorID = state.players[0].id
        let creditorID = state.players[1].id
        let propertyID = propertyID(at: 1)
        let debt = Debt(
            debtorID: debtorID,
            creditor: .player(creditorID),
            amount: Money(100),
            reason: .rent(propertyID)
        )
        state.players[0].cash = Money(0)
        state.propertyStates[propertyID]?.ownerID = debtorID
        state.propertyStates[propertyID]?.isMortgaged = true
        state.debt = debt
        state.debtContinuation = .finishLanding(allowsExtraRoll: false)
        state.phase = .resolvingDebt(debt)
        var engine = GameEngine(state: state, diceRoller: SequenceDiceRoller([]))

        _ = try engine.perform(.declareBankruptcy, by: debtorID)

        #expect(engine.state.phase == .resolvingMortgageTransfer(
            MortgageTransferResolution(
                recipientID: creditorID,
                eliminatedPlayerID: debtorID,
                remainingPropertyIDs: [propertyID]
            )
        ))
        #expect(engine.legalActions(for: creditorID).contains(
            .keepTransferredMortgage(propertyID: propertyID, interest: Money(3))
        ))

        _ = try engine.perform(.keepTransferredMortgage(propertyID), by: creditorID)

        #expect(engine.state.players[1].cash == Money(1_497))
        #expect(engine.state.propertyStates[propertyID]?.isMortgaged == true)
        #expect(engine.state.phase == .awaitingRoll)
    }

    @Test
    func bankruptcyToBankCancelsMortgagesAndAuctionsEachProperty() throws {
        var state = try threePlayerStartedGameState()
        let debtorID = state.players[0].id
        let firstBidderID = state.players[1].id
        let secondBidderID = state.players[2].id
        let firstPropertyID = propertyID(at: 1)
        let secondPropertyID = propertyID(at: 3)
        let debt = Debt(
            debtorID: debtorID,
            creditor: .bank,
            amount: Money(200),
            reason: .tax
        )
        state.players[0].cash = Money(0)
        state.propertyStates[firstPropertyID]?.ownerID = debtorID
        state.propertyStates[firstPropertyID]?.isMortgaged = true
        state.propertyStates[secondPropertyID]?.ownerID = debtorID
        state.debt = debt
        state.debtContinuation = .finishLanding(allowsExtraRoll: false)
        state.phase = .resolvingDebt(debt)
        var engine = GameEngine(state: state, diceRoller: SequenceDiceRoller([]))

        _ = try engine.perform(.mortgageProperty(secondPropertyID), by: debtorID)
        _ = try engine.perform(.declareBankruptcy, by: debtorID)

        #expect(engine.state.propertyStates[firstPropertyID]?.isMortgaged == false)
        #expect(engine.state.auction?.propertyID == firstPropertyID)
        #expect(engine.state.auction?.purpose == .bankruptcy)

        _ = try engine.perform(.withdrawFromAuction(firstPropertyID), by: firstBidderID)
        _ = try engine.perform(.withdrawFromAuction(firstPropertyID), by: secondBidderID)

        #expect(engine.state.auction?.propertyID == secondPropertyID)

        _ = try engine.perform(.withdrawFromAuction(secondPropertyID), by: firstBidderID)
        let events = try engine.perform(.withdrawFromAuction(secondPropertyID), by: secondBidderID)

        #expect(engine.state.players[0].status == .bankrupt)
        #expect(engine.state.phase == .awaitingRoll)
        #expect(engine.state.currentPlayerIndex == 1)
        #expect(events.contains(.turnEnded(
            playerID: debtorID,
            nextPlayerID: firstBidderID
        )))
    }
}

private func threePlayerStartedGameState() throws -> GameState {
    var state = try GameSetupFactory.makeGame(players: [
        PlayerSetup(name: "Maya", token: .chefHat),
        PlayerSetup(name: "Theo", token: .takeoutBag),
        PlayerSetup(name: "Ari", token: .receiptRoll)
    ])
    state.currentPlayerIndex = 0
    state.phase = .awaitingRoll
    state.openingRollPlayerIDs = []
    state.openingRolls = [:]
    return state
}
