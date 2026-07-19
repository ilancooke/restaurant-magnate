import Foundation

enum GameEngineError: Error, Equatable {
    case unknownPlayer(PlayerID)
    case wrongPlayer(expected: PlayerID, actual: PlayerID)
    case illegalAction(PlayerAction, phase: TurnPhase)
    case propertyNotFound(PropertyID)
    case propertyUnavailable(PropertyID)
    case insufficientFunds(playerID: PlayerID, required: Money)
    case invalidAuctionBid(minimum: Money)
    case invalidState
}

struct GameEngine<Roller: DiceRolling> {
    static var detentionFee: Money { Money(50) }

    private(set) var state: GameState
    private var diceRoller: Roller

    init(state: GameState, diceRoller: Roller) {
        self.state = state
        self.diceRoller = diceRoller
    }

    func legalActions(for playerID: PlayerID) -> [LegalPlayerAction] {
        guard let playerIndex = playerIndex(for: playerID),
              state.players[playerIndex].status == .active else {
            return []
        }

        switch state.phase {
        case let .openingRoll(remainingPlayerIDs):
            return remainingPlayerIDs.first == playerID ? [.rollDice] : []

        case .awaitingRoll:
            guard currentPlayerID == playerID else {
                return []
            }
            var actions: [LegalPlayerAction] = [.rollDice]
            if state.players[playerIndex].detention != nil,
               playerCash(playerID) >= Self.detentionFee {
                actions.append(.payDetentionFee(amount: Self.detentionFee))
            }
            return actions + assetManagementActions(for: playerID, allowsUnmortgage: true)

        case let .awaitingPurchase(propertyID):
            guard currentPlayerID == playerID,
                  let property = property(for: propertyID) else {
                return []
            }
            var actions: [LegalPlayerAction] = [.declinePurchase(propertyID)]
            if playerCash(playerID) >= property.purchasePrice {
                actions.insert(.buyProperty(propertyID), at: 0)
            }
            return actions + assetManagementActions(for: playerID, allowsUnmortgage: true)

        case let .awaitingAuction(propertyID):
            guard let auction = state.auction,
                  auction.propertyID == propertyID,
                  auction.currentBidderID == playerID else {
                return []
            }
            let minimumBid = auctionMinimumBid(auction)
            var actions: [LegalPlayerAction] = [.withdrawFromAuction(propertyID)]
            if playerCash(playerID) >= minimumBid {
                actions.insert(
                    .placeAuctionBid(propertyID: propertyID, minimumBid: minimumBid),
                    at: 0
                )
            }
            return actions + assetManagementActions(for: playerID, allowsUnmortgage: false)

        case .awaitingEndTurn:
            guard currentPlayerID == playerID else {
                return []
            }
            return [.endTurn] + assetManagementActions(
                for: playerID,
                allowsUnmortgage: true
            )

        case let .resolvingDebt(debt):
            guard debt.debtorID == playerID else {
                return []
            }
            let mortgageActions = assetManagementActions(
                for: playerID,
                allowsUnmortgage: false
            )
            return mortgageActions.isEmpty ? [.declareBankruptcy] : mortgageActions

        case let .resolvingMortgageTransfer(resolution):
            guard resolution.recipientID == playerID,
                  let propertyID = resolution.remainingPropertyIDs.first,
                  let property = property(for: propertyID) else {
                return []
            }
            var actions = assetManagementActions(for: playerID, allowsUnmortgage: false)
            let interest = mortgageInterest(for: property)
            let unmortgageCost = self.unmortgageCost(for: property)
            if playerCash(playerID) >= interest {
                actions.append(.keepTransferredMortgage(
                    propertyID: propertyID,
                    interest: interest
                ))
            }
            if playerCash(playerID) >= unmortgageCost {
                actions.append(.unmortgageTransferredProperty(
                    propertyID: propertyID,
                    cost: unmortgageCost
                ))
            }
            let hasPaymentChoice = actions.contains { action in
                switch action {
                case .keepTransferredMortgage, .unmortgageTransferredProperty:
                    return true
                default:
                    return false
                }
            }
            let hasMortgageOption = actions.contains { action in
                if case .mortgageProperty = action {
                    return true
                }
                return false
            }
            if !hasPaymentChoice && !hasMortgageOption {
                actions.append(.declareBankruptcy)
            }
            return actions

        case .resolvingLanding, .gameOver:
            return []
        }
    }

    mutating func perform(_ action: PlayerAction, by playerID: PlayerID) throws -> [GameEvent] {
        guard playerIndex(for: playerID) != nil else {
            throw GameEngineError.unknownPlayer(playerID)
        }

        switch action {
        case let .mortgageProperty(propertyID):
            guard legalActions(for: playerID).contains(where: { legalAction in
                if case let .mortgageProperty(legalPropertyID, _) = legalAction {
                    return legalPropertyID == propertyID
                }
                return false
            }) else {
                throw GameEngineError.illegalAction(action, phase: state.phase)
            }
            return try mortgage(propertyID: propertyID, by: playerID)

        case let .unmortgageProperty(propertyID):
            guard legalActions(for: playerID).contains(where: { legalAction in
                if case let .unmortgageProperty(legalPropertyID, _) = legalAction {
                    return legalPropertyID == propertyID
                }
                return false
            }) else {
                throw GameEngineError.illegalAction(action, phase: state.phase)
            }
            return try unmortgage(propertyID: propertyID, by: playerID)

        case let .keepTransferredMortgage(propertyID):
            return try resolveTransferredMortgage(
                propertyID: propertyID,
                by: playerID,
                shouldUnmortgage: false
            )

        case let .unmortgageTransferredProperty(propertyID):
            return try resolveTransferredMortgage(
                propertyID: propertyID,
                by: playerID,
                shouldUnmortgage: true
            )

        case .declareBankruptcy:
            guard legalActions(for: playerID).contains(.declareBankruptcy) else {
                throw GameEngineError.illegalAction(action, phase: state.phase)
            }
            return try declareBankruptcy(by: playerID)

        default:
            break
        }

        switch state.phase {
        case let .openingRoll(remainingPlayerIDs):
            guard let expectedPlayerID = remainingPlayerIDs.first else {
                throw GameEngineError.invalidState
            }
            try requirePlayer(playerID, expected: expectedPlayerID)
            guard action == .rollDice else {
                throw GameEngineError.illegalAction(action, phase: state.phase)
            }
            return try performOpeningRoll(by: playerID, remainingPlayerIDs: remainingPlayerIDs)

        case .awaitingRoll:
            try requireCurrentPlayer(playerID)
            switch action {
            case .rollDice:
                return try performTurnRoll(by: playerID)
            case .payDetentionFee:
                return try payDetentionFee(by: playerID)
            default:
                throw GameEngineError.illegalAction(action, phase: state.phase)
            }

        case let .awaitingPurchase(propertyID):
            try requireCurrentPlayer(playerID)
            switch action {
            case let .buyProperty(actionPropertyID) where actionPropertyID == propertyID:
                return try purchase(propertyID: propertyID, by: playerID)
            case let .declinePurchase(actionPropertyID) where actionPropertyID == propertyID:
                return try beginAuction(propertyID: propertyID)
            default:
                throw GameEngineError.illegalAction(action, phase: state.phase)
            }

        case let .awaitingAuction(propertyID):
            guard let auction = state.auction else {
                throw GameEngineError.invalidState
            }
            try requirePlayer(playerID, expected: auction.currentBidderID)
            switch action {
            case let .placeAuctionBid(actionPropertyID, amount)
                where actionPropertyID == propertyID:
                return try placeAuctionBid(
                    propertyID: propertyID,
                    amount: amount,
                    bidderID: playerID
                )
            case let .withdrawFromAuction(actionPropertyID) where actionPropertyID == propertyID:
                return try withdrawFromAuction(propertyID: propertyID, playerID: playerID)
            default:
                throw GameEngineError.illegalAction(action, phase: state.phase)
            }

        case .awaitingEndTurn:
            try requireCurrentPlayer(playerID)
            guard action == .endTurn else {
                throw GameEngineError.illegalAction(action, phase: state.phase)
            }
            return try endTurn(for: playerID)

        case .resolvingLanding, .resolvingDebt, .resolvingMortgageTransfer, .gameOver:
            throw GameEngineError.illegalAction(action, phase: state.phase)
        }
    }
}

extension GameEngine where Roller == SystemDiceRoller {
    init(state: GameState) {
        self.init(state: state, diceRoller: SystemDiceRoller())
    }
}

private extension GameEngine {
    var currentPlayerID: PlayerID? {
        guard let index = state.currentPlayerIndex,
              state.players.indices.contains(index) else {
            return nil
        }
        return state.players[index].id
    }

    func playerIndex(for playerID: PlayerID) -> Int? {
        state.players.firstIndex { $0.id == playerID }
    }

    func playerCash(_ playerID: PlayerID) -> Money {
        guard let index = playerIndex(for: playerID) else {
            return Money(0)
        }
        return state.players[index].cash
    }

    func property(for propertyID: PropertyID) -> PropertyDefinition? {
        state.board.properties.first { $0.id == propertyID }
    }

    func requirePlayer(_ actual: PlayerID, expected: PlayerID) throws {
        guard actual == expected else {
            throw GameEngineError.wrongPlayer(expected: expected, actual: actual)
        }
    }

    func requireCurrentPlayer(_ playerID: PlayerID) throws {
        guard let expected = currentPlayerID else {
            throw GameEngineError.invalidState
        }
        try requirePlayer(playerID, expected: expected)
    }

    mutating func performOpeningRoll(
        by playerID: PlayerID,
        remainingPlayerIDs: [PlayerID]
    ) throws -> [GameEvent] {
        let roll = diceRoller.roll()
        state.openingRolls[playerID] = roll
        var events: [GameEvent] = [.diceRolled(playerID: playerID, roll: roll)]

        let remaining = Array(remainingPlayerIDs.dropFirst())
        guard remaining.isEmpty else {
            state.phase = .openingRoll(remainingPlayerIDs: remaining)
            return events
        }

        let resolution = try OpeningRollResolver.resolve(
            playerIDs: state.openingRollPlayerIDs,
            rolls: state.openingRolls
        )
        switch resolution {
        case let .starter(starterID):
            guard let starterIndex = playerIndex(for: starterID) else {
                throw GameEngineError.invalidState
            }
            state.currentPlayerIndex = starterIndex
            state.openingRolls = [:]
            state.openingRollPlayerIDs = []
            state.latestRoll = nil
            state.phase = .awaitingRoll
            events.append(.starterSelected(starterID))

        case let .reroll(playerIDs):
            state.openingRollPlayerIDs = playerIDs
            state.openingRolls = [:]
            state.phase = .openingRoll(remainingPlayerIDs: playerIDs)
            events.append(.openingRollTied(playerIDs: playerIDs))
        }
        return events
    }

    mutating func performTurnRoll(by playerID: PlayerID) throws -> [GameEvent] {
        guard let playerIndex = playerIndex(for: playerID) else {
            throw GameEngineError.unknownPlayer(playerID)
        }

        let roll = diceRoller.roll()
        state.latestRoll = roll

        if state.players[playerIndex].detention != nil {
            return try performDetentionRoll(roll, by: playerID, playerIndex: playerIndex)
        }

        if roll.isDouble {
            state.consecutiveDoubles += 1
        } else {
            state.consecutiveDoubles = 0
        }

        if state.consecutiveDoubles == 3 {
            state.players[playerIndex].position = BoardSpaceID(rawValue: 10)
            state.players[playerIndex].detention = DetentionStatus()
            state.consecutiveDoubles = 0
            state.phase = .awaitingEndTurn
            return [
                .diceRolled(playerID: playerID, roll: roll),
                .thirdConsecutiveDouble(playerID: playerID),
                .sentToDetention(
                    playerID: playerID,
                    destination: BoardSpaceID(rawValue: 10)
                )
            ]
        }

        return try moveAndResolve(
            playerID: playerID,
            playerIndex: playerIndex,
            roll: roll,
            allowsExtraRoll: roll.isDouble
        )
    }

    mutating func moveAndResolve(
        playerID: PlayerID,
        playerIndex: Int,
        roll: DiceRoll,
        allowsExtraRoll: Bool
    ) throws -> [GameEvent] {
        state.phase = .resolvingLanding

        let oldPosition = state.players[playerIndex].position
        let unwrappedPosition = oldPosition.rawValue + roll.total
        let newPosition = BoardSpaceID(rawValue: unwrappedPosition % state.board.spaces.count)
        state.players[playerIndex].position = newPosition

        var events: [GameEvent] = [
            .diceRolled(playerID: playerID, roll: roll),
            .playerMoved(playerID: playerID, from: oldPosition, to: newPosition)
        ]

        if unwrappedPosition >= state.board.spaces.count,
           case let .start(payment) = state.board[0].kind {
            let transaction = try transfer(
                payment,
                from: .bank,
                to: .player(playerID),
                reason: .passedStart
            )
            events.append(.passedGrandOpening(playerID: playerID, amount: payment))
            events.append(.moneyTransferred(transaction))
        }

        events.append(contentsOf: try resolveLanding(
            for: playerID,
            at: newPosition,
            allowsExtraRoll: allowsExtraRoll
        ))
        return events
    }

    mutating func resolveLanding(
        for playerID: PlayerID,
        at spaceID: BoardSpaceID,
        allowsExtraRoll: Bool
    ) throws -> [GameEvent] {
        let space = state.board[spaceID.rawValue]
        var events: [GameEvent] = [.landed(playerID: playerID, spaceID: spaceID)]

        switch space.kind {
        case .start, .event, .detention, .neutral:
            state.phase = phaseAfterLanding(allowsExtraRoll: allowsExtraRoll)

        case let .sendToDetention(destination):
            guard let index = playerIndex(for: playerID) else {
                throw GameEngineError.unknownPlayer(playerID)
            }
            state.players[index].position = destination
            state.players[index].detention = DetentionStatus()
            state.consecutiveDoubles = 0
            state.phase = .awaitingEndTurn
            events.append(.sentToDetention(playerID: playerID, destination: destination))

        case let .tax(amount):
            events.append(contentsOf: try chargeOrCreateDebt(
                amount,
                from: playerID,
                to: .bank,
                reason: .tax,
                paidEvent: .taxPaid(playerID: playerID, amount: amount),
                allowsExtraRoll: allowsExtraRoll
            ))

        case let .property(property):
            guard let propertyState = state.propertyStates[property.id] else {
                throw GameEngineError.propertyNotFound(property.id)
            }
            guard let ownerID = propertyState.ownerID else {
                state.phase = .awaitingPurchase(propertyID: property.id)
                events.append(.purchaseOffered(playerID: playerID, propertyID: property.id))
                return events
            }
            guard ownerID != playerID, !propertyState.isMortgaged else {
                state.phase = phaseAfterLanding(allowsExtraRoll: allowsExtraRoll)
                return events
            }

            let rent = RentCalculator.rent(
                for: property,
                propertyState: propertyState,
                in: state
            )
            events.append(contentsOf: try chargeOrCreateDebt(
                rent,
                from: playerID,
                to: .player(ownerID),
                reason: .rent(property.id),
                paidEvent: .rentPaid(
                    propertyID: property.id,
                    from: playerID,
                    to: ownerID,
                    amount: rent
                ),
                allowsExtraRoll: allowsExtraRoll
            ))
        }
        return events
    }

    mutating func purchase(
        propertyID: PropertyID,
        by playerID: PlayerID
    ) throws -> [GameEvent] {
        guard let property = property(for: propertyID) else {
            throw GameEngineError.propertyNotFound(propertyID)
        }
        guard state.propertyStates[propertyID]?.ownerID == nil else {
            throw GameEngineError.propertyUnavailable(propertyID)
        }
        guard playerCash(playerID) >= property.purchasePrice else {
            throw GameEngineError.insufficientFunds(
                playerID: playerID,
                required: property.purchasePrice
            )
        }

        let transaction = try transfer(
            property.purchasePrice,
            from: .player(playerID),
            to: .bank,
            reason: .propertyPurchase(propertyID)
        )
        state.propertyStates[propertyID]?.ownerID = playerID
        state.phase = phaseAfterLanding()
        return [
            .moneyTransferred(transaction),
            .propertyPurchased(
                playerID: playerID,
                propertyID: propertyID,
                price: property.purchasePrice
            )
        ]
    }

    mutating func beginAuction(
        propertyID: PropertyID,
        purpose: AuctionPurpose = .declinedPurchase
    ) throws -> [GameEvent] {
        guard property(for: propertyID) != nil else {
            throw GameEngineError.propertyNotFound(propertyID)
        }
        guard state.propertyStates[propertyID]?.ownerID == nil,
              let currentIndex = state.currentPlayerIndex else {
            throw GameEngineError.propertyUnavailable(propertyID)
        }

        let orderedPlayers = (0..<state.players.count).compactMap { offset -> PlayerID? in
            let player = state.players[(currentIndex + offset) % state.players.count]
            return player.status == .active ? player.id : nil
        }
        guard let firstBidderID = orderedPlayers.first else {
            throw GameEngineError.invalidState
        }
        state.auction = AuctionState(
            propertyID: propertyID,
            purpose: purpose,
            bidderOrder: orderedPlayers,
            remainingBidderIDs: orderedPlayers,
            highBid: nil,
            currentBidderID: firstBidderID
        )
        state.phase = .awaitingAuction(propertyID: propertyID)
        return [.auctionStarted(propertyID: propertyID, firstBidderID: firstBidderID)]
    }

    mutating func placeAuctionBid(
        propertyID: PropertyID,
        amount: Money,
        bidderID: PlayerID
    ) throws -> [GameEvent] {
        guard var auction = state.auction,
              auction.propertyID == propertyID else {
            throw GameEngineError.invalidState
        }
        let minimumBid = auctionMinimumBid(auction)
        guard amount >= minimumBid else {
            throw GameEngineError.invalidAuctionBid(minimum: minimumBid)
        }
        guard playerCash(bidderID) >= amount else {
            throw GameEngineError.insufficientFunds(playerID: bidderID, required: amount)
        }

        let bid = AuctionBid(bidderID: bidderID, amount: amount)
        auction.highBid = bid
        var events: [GameEvent] = [.auctionBidPlaced(propertyID: propertyID, bid: bid)]

        if let nextBidderID = nextBidder(after: bidderID, in: auction) {
            auction.currentBidderID = nextBidderID
            state.auction = auction
        } else {
            events.append(contentsOf: try finishAuction(auction, winningBid: bid))
        }
        return events
    }

    mutating func withdrawFromAuction(
        propertyID: PropertyID,
        playerID: PlayerID
    ) throws -> [GameEvent] {
        guard var auction = state.auction,
              auction.propertyID == propertyID else {
            throw GameEngineError.invalidState
        }
        auction.remainingBidderIDs.removeAll { $0 == playerID }
        var events: [GameEvent] = [
            .auctionBidderWithdrew(propertyID: propertyID, playerID: playerID)
        ]

        if let highBid = auction.highBid,
           auction.remainingBidderIDs == [highBid.bidderID] {
            events.append(contentsOf: try finishAuction(auction, winningBid: highBid))
            return events
        }

        if let nextBidderID = nextBidder(after: playerID, in: auction) {
            auction.currentBidderID = nextBidderID
            state.auction = auction
            return events
        }

        state.auction = nil
        events.append(.auctionEndedWithoutSale(propertyID: propertyID))
        if auction.purpose == .bankruptcy {
            events.append(contentsOf: try continueBankruptcyAuctions())
        } else {
            state.phase = phaseAfterLanding()
        }
        return events
    }

    func nextBidder(after playerID: PlayerID, in auction: AuctionState) -> PlayerID? {
        guard let currentIndex = auction.bidderOrder.firstIndex(of: playerID) else {
            return nil
        }
        for offset in 1...auction.bidderOrder.count {
            let candidate = auction.bidderOrder[
                (currentIndex + offset) % auction.bidderOrder.count
            ]
            if auction.remainingBidderIDs.contains(candidate),
               candidate != auction.highBid?.bidderID {
                return candidate
            }
        }
        return nil
    }

    mutating func finishAuction(
        _ auction: AuctionState,
        winningBid: AuctionBid
    ) throws -> [GameEvent] {
        let transaction = try transfer(
            winningBid.amount,
            from: .player(winningBid.bidderID),
            to: .bank,
            reason: .auctionPurchase(auction.propertyID)
        )
        state.propertyStates[auction.propertyID]?.ownerID = winningBid.bidderID
        state.auction = nil
        var events: [GameEvent] = [
            .moneyTransferred(transaction),
            .auctionWon(propertyID: auction.propertyID, bid: winningBid)
        ]
        if auction.purpose == .bankruptcy {
            events.append(contentsOf: try continueBankruptcyAuctions())
        } else {
            state.phase = phaseAfterLanding()
        }
        return events
    }

    mutating func chargeOrCreateDebt(
        _ amount: Money,
        from playerID: PlayerID,
        to creditor: TransactionAccount,
        reason: TransactionReason,
        paidEvent: GameEvent,
        allowsExtraRoll: Bool
    ) throws -> [GameEvent] {
        guard playerCash(playerID) >= amount else {
            let debt = Debt(
                debtorID: playerID,
                creditor: creditor,
                amount: amount,
                reason: reason
            )
            state.debt = debt
            state.debtContinuation = .finishLanding(allowsExtraRoll: allowsExtraRoll)
            state.phase = .resolvingDebt(debt)
            return [.debtRequired(debt)]
        }
        let transaction = try transfer(
            amount,
            from: .player(playerID),
            to: creditor,
            reason: reason
        )
        state.phase = phaseAfterLanding(allowsExtraRoll: allowsExtraRoll)
        return [.moneyTransferred(transaction), paidEvent]
    }

    mutating func transfer(
        _ amount: Money,
        from source: TransactionAccount,
        to destination: TransactionAccount,
        reason: TransactionReason
    ) throws -> BankTransaction {
        if case let .player(playerID) = source {
            guard let index = playerIndex(for: playerID) else {
                throw GameEngineError.unknownPlayer(playerID)
            }
            guard state.players[index].cash >= amount else {
                throw GameEngineError.insufficientFunds(playerID: playerID, required: amount)
            }
            state.players[index].cash = Money(state.players[index].cash.amount - amount.amount)
        }
        if case let .player(playerID) = destination {
            guard let index = playerIndex(for: playerID) else {
                throw GameEngineError.unknownPlayer(playerID)
            }
            state.players[index].cash = Money(state.players[index].cash.amount + amount.amount)
        }
        return BankTransaction(from: source, to: destination, amount: amount, reason: reason)
    }

    mutating func endTurn(for playerID: PlayerID) throws -> [GameEvent] {
        guard let currentIndex = state.currentPlayerIndex else {
            throw GameEngineError.invalidState
        }
        let nextIndex = (1...state.players.count).compactMap { offset -> Int? in
            let candidateIndex = (currentIndex + offset) % state.players.count
            return state.players[candidateIndex].status == .active ? candidateIndex : nil
        }.first
        guard let nextIndex else {
            throw GameEngineError.invalidState
        }

        let nextPlayerID = state.players[nextIndex].id
        state.currentPlayerIndex = nextIndex
        state.latestRoll = nil
        state.auction = nil
        state.debt = nil
        state.debtContinuation = nil
        state.mortgageTransfer = nil
        state.bankruptcyAuction = nil
        state.consecutiveDoubles = 0
        state.phase = .awaitingRoll
        return [.turnEnded(playerID: playerID, nextPlayerID: nextPlayerID)]
    }

    func phaseAfterLanding(allowsExtraRoll: Bool? = nil) -> TurnPhase {
        let shouldRollAgain = allowsExtraRoll ?? (state.consecutiveDoubles > 0)
        return shouldRollAgain ? .awaitingRoll : .awaitingEndTurn
    }

    mutating func payDetentionFee(by playerID: PlayerID) throws -> [GameEvent] {
        guard let playerIndex = playerIndex(for: playerID),
              state.players[playerIndex].detention != nil else {
            throw GameEngineError.illegalAction(.payDetentionFee, phase: state.phase)
        }
        let transaction = try transfer(
            Self.detentionFee,
            from: .player(playerID),
            to: .bank,
            reason: .detentionFee
        )
        state.players[playerIndex].detention = nil
        return [
            .moneyTransferred(transaction),
            .detentionFeePaid(playerID: playerID, amount: Self.detentionFee),
            .releasedFromDetention(playerID: playerID)
        ]
    }

    mutating func performDetentionRoll(
        _ roll: DiceRoll,
        by playerID: PlayerID,
        playerIndex: Int
    ) throws -> [GameEvent] {
        guard var detention = state.players[playerIndex].detention else {
            throw GameEngineError.invalidState
        }

        if roll.isDouble {
            state.players[playerIndex].detention = nil
            state.consecutiveDoubles = 0
            var events: [GameEvent] = [
                .diceRolled(playerID: playerID, roll: roll),
                .releasedFromDetention(playerID: playerID)
            ]
            let movementEvents = try moveAndResolve(
                playerID: playerID,
                playerIndex: playerIndex,
                roll: roll,
                allowsExtraRoll: false
            )
            events.append(contentsOf: movementEvents.dropFirst())
            return events
        }

        detention.failedRolls += 1
        if detention.failedRolls < 3 {
            state.players[playerIndex].detention = detention
            state.phase = .awaitingEndTurn
            return [
                .diceRolled(playerID: playerID, roll: roll),
                .detentionRollFailed(playerID: playerID, failedRolls: detention.failedRolls)
            ]
        }

        guard playerCash(playerID) >= Self.detentionFee else {
            let debt = Debt(
                debtorID: playerID,
                creditor: .bank,
                amount: Self.detentionFee,
                reason: .detentionFee
            )
            state.debt = debt
            state.debtContinuation = .moveAfterDetentionFee(
                playerID: playerID,
                roll: roll
            )
            state.phase = .resolvingDebt(debt)
            return [
                .diceRolled(playerID: playerID, roll: roll),
                .detentionRollFailed(playerID: playerID, failedRolls: 3),
                .debtRequired(debt)
            ]
        }

        let transaction = try transfer(
            Self.detentionFee,
            from: .player(playerID),
            to: .bank,
            reason: .detentionFee
        )
        state.players[playerIndex].detention = nil
        state.consecutiveDoubles = 0
        var events: [GameEvent] = [
            .diceRolled(playerID: playerID, roll: roll),
            .detentionRollFailed(playerID: playerID, failedRolls: 3),
            .moneyTransferred(transaction),
            .detentionFeePaid(playerID: playerID, amount: Self.detentionFee),
            .releasedFromDetention(playerID: playerID)
        ]
        let movementEvents = try moveAndResolve(
            playerID: playerID,
            playerIndex: playerIndex,
            roll: roll,
            allowsExtraRoll: false
        )
        events.append(contentsOf: movementEvents.dropFirst())
        return events
    }

    func auctionMinimumBid(_ auction: AuctionState) -> Money {
        guard let highBid = auction.highBid else {
            return Money(10)
        }
        return Money(highBid.amount.amount + 1)
    }

    func mortgageInterest(for property: PropertyDefinition) -> Money {
        Money((property.mortgageValue.amount + 9) / 10)
    }

    func unmortgageCost(for property: PropertyDefinition) -> Money {
        Money(property.mortgageValue.amount + mortgageInterest(for: property).amount)
    }

    func assetManagementActions(
        for playerID: PlayerID,
        allowsUnmortgage: Bool
    ) -> [LegalPlayerAction] {
        state.board.properties.compactMap { property in
            guard let propertyState = state.propertyStates[property.id],
                  propertyState.ownerID == playerID else {
                return nil
            }
            if canMortgage(property, propertyState: propertyState) {
                return .mortgageProperty(
                    propertyID: property.id,
                    proceeds: property.mortgageValue
                )
            }
            if allowsUnmortgage, propertyState.isMortgaged {
                let cost = unmortgageCost(for: property)
                if playerCash(playerID) >= cost {
                    return .unmortgageProperty(propertyID: property.id, cost: cost)
                }
            }
            return nil
        }
    }

    func canMortgage(
        _ property: PropertyDefinition,
        propertyState: PropertyState
    ) -> Bool {
        guard !propertyState.isMortgaged, propertyState.upgradeLevel == 0 else {
            return false
        }
        guard case let .restaurant(group, _) = property.rentRule else {
            return true
        }
        return !state.board.properties.contains { candidate in
            guard case let .restaurant(candidateGroup, _) = candidate.rentRule,
                  candidateGroup == group else {
                return false
            }
            return (state.propertyStates[candidate.id]?.upgradeLevel ?? 0) > 0
        }
    }

    mutating func mortgage(
        propertyID: PropertyID,
        by playerID: PlayerID
    ) throws -> [GameEvent] {
        guard let property = property(for: propertyID),
              let propertyState = state.propertyStates[propertyID],
              propertyState.ownerID == playerID,
              canMortgage(property, propertyState: propertyState) else {
            throw GameEngineError.propertyUnavailable(propertyID)
        }

        state.propertyStates[propertyID]?.isMortgaged = true
        let transaction = try transfer(
            property.mortgageValue,
            from: .bank,
            to: .player(playerID),
            reason: .mortgage(propertyID)
        )
        var events: [GameEvent] = [
            .moneyTransferred(transaction),
            .propertyMortgaged(
                playerID: playerID,
                propertyID: propertyID,
                proceeds: property.mortgageValue
            )
        ]

        if let debt = state.debt,
           debt.debtorID == playerID,
           playerCash(playerID) >= debt.amount {
            events.append(contentsOf: try settleDebt(debt))
        }
        return events
    }

    mutating func unmortgage(
        propertyID: PropertyID,
        by playerID: PlayerID
    ) throws -> [GameEvent] {
        guard let property = property(for: propertyID),
              state.propertyStates[propertyID]?.ownerID == playerID,
              state.propertyStates[propertyID]?.isMortgaged == true else {
            throw GameEngineError.propertyUnavailable(propertyID)
        }
        let cost = unmortgageCost(for: property)
        let transaction = try transfer(
            cost,
            from: .player(playerID),
            to: .bank,
            reason: .mortgage(propertyID)
        )
        state.propertyStates[propertyID]?.isMortgaged = false
        return [
            .moneyTransferred(transaction),
            .propertyUnmortgaged(
                playerID: playerID,
                propertyID: propertyID,
                cost: cost
            )
        ]
    }

    mutating func settleDebt(_ debt: Debt) throws -> [GameEvent] {
        let transaction = try transfer(
            debt.amount,
            from: .player(debt.debtorID),
            to: debt.creditor,
            reason: debt.reason
        )
        let continuation = state.debtContinuation
        state.debt = nil
        state.debtContinuation = nil
        var events: [GameEvent] = [
            .moneyTransferred(transaction),
            .debtPaid(debt)
        ]

        switch continuation {
        case let .finishLanding(allowsExtraRoll):
            state.phase = phaseAfterLanding(allowsExtraRoll: allowsExtraRoll)

        case let .moveAfterDetentionFee(playerID, roll):
            guard let playerIndex = playerIndex(for: playerID) else {
                throw GameEngineError.unknownPlayer(playerID)
            }
            state.players[playerIndex].detention = nil
            state.consecutiveDoubles = 0
            events.append(.detentionFeePaid(playerID: playerID, amount: debt.amount))
            events.append(.releasedFromDetention(playerID: playerID))
            let movementEvents = try moveAndResolve(
                playerID: playerID,
                playerIndex: playerIndex,
                roll: roll,
                allowsExtraRoll: false
            )
            events.append(contentsOf: movementEvents.dropFirst())

        case nil:
            throw GameEngineError.invalidState
        }
        return events
    }

    mutating func resolveTransferredMortgage(
        propertyID: PropertyID,
        by playerID: PlayerID,
        shouldUnmortgage: Bool
    ) throws -> [GameEvent] {
        guard var resolution = state.mortgageTransfer,
              resolution.recipientID == playerID,
              resolution.remainingPropertyIDs.first == propertyID,
              let property = property(for: propertyID),
              state.propertyStates[propertyID]?.ownerID == playerID,
              state.propertyStates[propertyID]?.isMortgaged == true else {
            throw GameEngineError.illegalAction(
                shouldUnmortgage
                    ? .unmortgageTransferredProperty(propertyID)
                    : .keepTransferredMortgage(propertyID),
                phase: state.phase
            )
        }

        let cost = shouldUnmortgage
            ? unmortgageCost(for: property)
            : mortgageInterest(for: property)
        guard playerCash(playerID) >= cost else {
            throw GameEngineError.insufficientFunds(playerID: playerID, required: cost)
        }
        let transaction = try transfer(
            cost,
            from: .player(playerID),
            to: .bank,
            reason: shouldUnmortgage ? .mortgage(propertyID) : .mortgageInterest(propertyID)
        )
        if shouldUnmortgage {
            state.propertyStates[propertyID]?.isMortgaged = false
        }
        resolution.remainingPropertyIDs.removeFirst()
        state.mortgageTransfer = resolution

        var events: [GameEvent] = [.moneyTransferred(transaction)]
        if shouldUnmortgage {
            events.append(.propertyUnmortgaged(
                playerID: playerID,
                propertyID: propertyID,
                cost: cost
            ))
        } else {
            events.append(.transferredMortgageKept(
                playerID: playerID,
                propertyID: propertyID,
                interest: cost
            ))
        }

        if resolution.remainingPropertyIDs.isEmpty {
            state.mortgageTransfer = nil
            events.append(contentsOf: try finishElimination(
                eliminatedPlayerID: resolution.eliminatedPlayerID
            ))
        } else {
            state.phase = .resolvingMortgageTransfer(resolution)
        }
        return events
    }

    mutating func declareBankruptcy(by playerID: PlayerID) throws -> [GameEvent] {
        let creditor: TransactionAccount
        switch state.phase {
        case let .resolvingDebt(debt) where debt.debtorID == playerID:
            creditor = debt.creditor
        case let .resolvingMortgageTransfer(resolution)
            where resolution.recipientID == playerID:
            creditor = .bank
        default:
            throw GameEngineError.illegalAction(.declareBankruptcy, phase: state.phase)
        }

        var events: [GameEvent] = [
            .bankruptcyDeclared(playerID: playerID, creditor: creditor)
        ]
        switch creditor {
        case let .player(creditorID):
            events.append(contentsOf: try bankrupt(
                playerID,
                toPlayer: creditorID
            ))
        case .bank:
            events.append(contentsOf: try bankruptToBank(playerID))
        }
        return events
    }

    mutating func bankrupt(
        _ debtorID: PlayerID,
        toPlayer creditorID: PlayerID
    ) throws -> [GameEvent] {
        guard let debtorIndex = playerIndex(for: debtorID),
              let creditorIndex = playerIndex(for: creditorID),
              state.players[creditorIndex].status == .active else {
            throw GameEngineError.invalidState
        }

        var events: [GameEvent] = []
        let remainingCash = state.players[debtorIndex].cash
        if remainingCash.amount > 0 {
            let transaction = try transfer(
                remainingCash,
                from: .player(debtorID),
                to: .player(creditorID),
                reason: state.debt?.reason ?? .tax
            )
            events.append(.moneyTransferred(transaction))
        }

        let ownedPropertyIDs = ownedPropertyIDs(for: debtorID)
        for propertyID in ownedPropertyIDs {
            state.propertyStates[propertyID]?.ownerID = creditorID
            events.append(.propertyTransferred(
                propertyID: propertyID,
                from: debtorID,
                to: creditorID
            ))
        }

        eliminatePlayer(at: debtorIndex)
        state.debt = nil
        state.debtContinuation = nil
        events.append(.playerEliminated(debtorID))

        if state.activePlayers.count == 1 {
            events.append(contentsOf: try finishElimination(eliminatedPlayerID: debtorID))
            return events
        }

        let mortgagedPropertyIDs = ownedPropertyIDs.filter {
            state.propertyStates[$0]?.isMortgaged == true
        }
        if mortgagedPropertyIDs.isEmpty {
            events.append(contentsOf: try finishElimination(eliminatedPlayerID: debtorID))
        } else {
            let resolution = MortgageTransferResolution(
                recipientID: creditorID,
                eliminatedPlayerID: debtorID,
                remainingPropertyIDs: mortgagedPropertyIDs
            )
            state.mortgageTransfer = resolution
            state.phase = .resolvingMortgageTransfer(resolution)
        }
        return events
    }

    mutating func bankruptToBank(_ playerID: PlayerID) throws -> [GameEvent] {
        guard let playerIndex = playerIndex(for: playerID) else {
            throw GameEngineError.unknownPlayer(playerID)
        }
        var events: [GameEvent] = []
        let remainingCash = state.players[playerIndex].cash
        if remainingCash.amount > 0 {
            let transaction = try transfer(
                remainingCash,
                from: .player(playerID),
                to: .bank,
                reason: state.debt?.reason ?? .bankruptcy
            )
            events.append(.moneyTransferred(transaction))
        }

        let propertyIDs = ownedPropertyIDs(for: playerID)
        for propertyID in propertyIDs {
            state.propertyStates[propertyID]?.ownerID = nil
            state.propertyStates[propertyID]?.isMortgaged = false
        }
        eliminatePlayer(at: playerIndex)
        state.debt = nil
        state.debtContinuation = nil
        state.mortgageTransfer = nil
        state.consecutiveDoubles = 0
        events.append(.playerEliminated(playerID))

        if state.activePlayers.count <= 1 {
            events.append(contentsOf: try finishElimination(eliminatedPlayerID: playerID))
            return events
        }

        guard let firstPropertyID = propertyIDs.first else {
            events.append(contentsOf: try finishElimination(eliminatedPlayerID: playerID))
            return events
        }
        let resolution = BankruptcyAuctionResolution(
            eliminatedPlayerID: playerID,
            remainingPropertyIDs: Array(propertyIDs.dropFirst())
        )
        state.bankruptcyAuction = resolution
        events.append(contentsOf: try beginAuction(
            propertyID: firstPropertyID,
            purpose: .bankruptcy
        ))
        return events
    }

    mutating func continueBankruptcyAuctions() throws -> [GameEvent] {
        guard var resolution = state.bankruptcyAuction else {
            throw GameEngineError.invalidState
        }
        guard let nextPropertyID = resolution.remainingPropertyIDs.first else {
            state.bankruptcyAuction = nil
            return try finishElimination(
                eliminatedPlayerID: resolution.eliminatedPlayerID
            )
        }
        resolution.remainingPropertyIDs.removeFirst()
        state.bankruptcyAuction = resolution
        return try beginAuction(propertyID: nextPropertyID, purpose: .bankruptcy)
    }

    mutating func finishElimination(
        eliminatedPlayerID: PlayerID
    ) throws -> [GameEvent] {
        let activePlayers = state.activePlayers
        guard !activePlayers.isEmpty else {
            throw GameEngineError.invalidState
        }
        if activePlayers.count == 1, let winner = activePlayers.first {
            state.currentPlayerIndex = playerIndex(for: winner.id)
            state.phase = .gameOver(winnerID: winner.id)
            return [.winnerDeclared(winner.id)]
        }

        guard let currentIndex = state.currentPlayerIndex else {
            throw GameEngineError.invalidState
        }
        let nextIndex = (1...state.players.count).compactMap { offset -> Int? in
            let candidateIndex = (currentIndex + offset) % state.players.count
            return state.players[candidateIndex].status == .active ? candidateIndex : nil
        }.first
        guard let nextIndex else {
            throw GameEngineError.invalidState
        }
        let nextPlayerID = state.players[nextIndex].id
        state.currentPlayerIndex = nextIndex
        state.latestRoll = nil
        state.auction = nil
        state.debt = nil
        state.debtContinuation = nil
        state.mortgageTransfer = nil
        state.bankruptcyAuction = nil
        state.consecutiveDoubles = 0
        state.phase = .awaitingRoll
        return [.turnEnded(
            playerID: eliminatedPlayerID,
            nextPlayerID: nextPlayerID
        )]
    }

    func ownedPropertyIDs(for playerID: PlayerID) -> [PropertyID] {
        state.board.properties.compactMap { property in
            state.propertyStates[property.id]?.ownerID == playerID ? property.id : nil
        }
    }

    mutating func eliminatePlayer(at index: Int) {
        state.players[index].cash = Money(0)
        state.players[index].status = .bankrupt
        state.players[index].detention = nil
    }
}
