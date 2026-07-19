import Testing
@testable import RestaurantMagnate

@Suite("Mandatory auctions")
struct AuctionTests {
    @Test
    func highestBidderWinsAfterOtherPlayersWithdraw() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        let propertyID = propertyID(at: 1)
        state.players[0].position = BoardSpaceID(rawValue: 38)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        _ = try engine.perform(.rollDice, by: mayaID)
        let startEvents = try engine.perform(.declinePurchase(propertyID), by: mayaID)
        #expect(startEvents == [.auctionStarted(propertyID: propertyID, firstBidderID: mayaID)])

        _ = try engine.perform(
            .placeAuctionBid(propertyID: propertyID, amount: Money(10)),
            by: mayaID
        )
        _ = try engine.perform(
            .placeAuctionBid(propertyID: propertyID, amount: Money(20)),
            by: theoID
        )
        let winningEvents = try engine.perform(.withdrawFromAuction(propertyID), by: mayaID)

        #expect(engine.state.propertyStates[propertyID]?.ownerID == theoID)
        #expect(engine.state.players[1].cash == Money(1_480))
        #expect(engine.state.auction == nil)
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(winningEvents.contains(.auctionWon(
            propertyID: propertyID,
            bid: AuctionBid(bidderID: theoID, amount: Money(20))
        )))
    }

    @Test
    func decliningPlayerMayStillWinAuction() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        let propertyID = propertyID(at: 1)
        state.players[0].position = BoardSpaceID(rawValue: 38)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        _ = try engine.perform(.rollDice, by: mayaID)
        _ = try engine.perform(.declinePurchase(propertyID), by: mayaID)
        _ = try engine.perform(
            .placeAuctionBid(propertyID: propertyID, amount: Money(1)),
            by: mayaID
        )
        _ = try engine.perform(.withdrawFromAuction(propertyID), by: theoID)

        #expect(engine.state.propertyStates[propertyID]?.ownerID == mayaID)
        #expect(engine.state.players[0].cash == Money(1_699))
    }

    @Test
    func auctionMayEndWithoutSaleWhenEveryoneWithdraws() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        let propertyID = propertyID(at: 1)
        state.players[0].position = BoardSpaceID(rawValue: 38)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        _ = try engine.perform(.rollDice, by: mayaID)
        _ = try engine.perform(.declinePurchase(propertyID), by: mayaID)
        _ = try engine.perform(.withdrawFromAuction(propertyID), by: mayaID)
        let events = try engine.perform(.withdrawFromAuction(propertyID), by: theoID)

        #expect(engine.state.propertyStates[propertyID]?.ownerID == nil)
        #expect(engine.state.phase == .awaitingEndTurn)
        #expect(events.contains(.auctionEndedWithoutSale(propertyID: propertyID)))
    }

    @Test
    func legalActionPublishesMinimumBid() throws {
        var state = try startedGameState()
        let mayaID = state.players[0].id
        let theoID = state.players[1].id
        let propertyID = propertyID(at: 1)
        state.players[0].position = BoardSpaceID(rawValue: 38)
        var engine = GameEngine(
            state: state,
            diceRoller: SequenceDiceRoller([DiceRoll(first: 1, second: 2)])
        )

        _ = try engine.perform(.rollDice, by: mayaID)
        _ = try engine.perform(.declinePurchase(propertyID), by: mayaID)
        _ = try engine.perform(
            .placeAuctionBid(propertyID: propertyID, amount: Money(25)),
            by: mayaID
        )

        #expect(engine.legalActions(for: theoID) == [
            .placeAuctionBid(propertyID: propertyID, minimumBid: Money(26)),
            .withdrawFromAuction(propertyID)
        ])
    }
}
