import Foundation
import Observation

struct AnyDiceRoller: DiceRolling {
    private var nextRoll: () -> DiceRoll

    init<R: DiceRolling>(_ roller: R) {
        var roller = roller
        nextRoll = { roller.roll() }
    }

    mutating func roll() -> DiceRoll {
        nextRoll()
    }
}

@MainActor
@Observable
final class GameSession {
    private var engine: GameEngine<AnyDiceRoller>
    private(set) var eventLog: [String]
    private(set) var errorMessage: String?

    convenience init(players: [PlayerSetup]) throws {
        try self.init(players: players, diceRoller: AnyDiceRoller(SystemDiceRoller()))
    }

    init(players: [PlayerSetup], diceRoller: AnyDiceRoller) throws {
        engine = GameEngine(
            state: try GameSetupFactory.makeGame(players: players),
            diceRoller: diceRoller
        )
        eventLog = ["Opening rolls will choose the first player."]
    }

    var state: GameState {
        engine.state
    }

    var actingPlayer: Player? {
        guard let playerID = actingPlayerID else {
            return nil
        }
        return state.players.first { $0.id == playerID }
    }

    var currentPlayer: Player? {
        guard let index = state.currentPlayerIndex,
              state.players.indices.contains(index) else {
            return nil
        }
        return state.players[index]
    }

    var legalActions: [LegalPlayerAction] {
        guard let actingPlayerID else {
            return []
        }
        return engine.legalActions(for: actingPlayerID)
    }

    var canRoll: Bool {
        legalActions.contains(.rollDice)
    }

    var canPayDetentionFee: Bool {
        legalActions.contains { action in
            if case .payDetentionFee = action {
                return true
            }
            return false
        }
    }

    var offeredProperty: PropertyDefinition? {
        guard case let .awaitingPurchase(propertyID) = state.phase else {
            return nil
        }
        return property(propertyID)
    }

    var auctionProperty: PropertyDefinition? {
        guard let propertyID = state.auction?.propertyID else {
            return nil
        }
        return property(propertyID)
    }

    var minimumAuctionBid: Money? {
        legalActions.compactMap { action -> Money? in
            guard case let .placeAuctionBid(_, minimumBid) = action else {
                return nil
            }
            return minimumBid
        }.first
    }

    var ownedProperties: [PropertyDefinition] {
        guard let playerID = actingPlayer?.id else {
            return []
        }
        return state.board.properties.filter {
            state.propertyStates[$0.id]?.ownerID == playerID
        }
    }

    var transferredMortgageProperty: PropertyDefinition? {
        guard case let .resolvingMortgageTransfer(resolution) = state.phase,
              let propertyID = resolution.remainingPropertyIDs.first else {
            return nil
        }
        return property(propertyID)
    }

    var canDeclareBankruptcy: Bool {
        legalActions.contains(.declareBankruptcy)
    }

    func rollDice() {
        perform(.rollDice)
    }

    func payDetentionFee() {
        perform(.payDetentionFee)
    }

    func mortgage(_ propertyID: PropertyID) {
        perform(.mortgageProperty(propertyID))
    }

    func unmortgage(_ propertyID: PropertyID) {
        perform(.unmortgageProperty(propertyID))
    }

    func keepTransferredMortgage(_ propertyID: PropertyID) {
        perform(.keepTransferredMortgage(propertyID))
    }

    func unmortgageTransferredProperty(_ propertyID: PropertyID) {
        perform(.unmortgageTransferredProperty(propertyID))
    }

    func declareBankruptcy() {
        perform(.declareBankruptcy)
    }

    func buyOfferedProperty() {
        guard let propertyID = offeredProperty?.id else {
            return
        }
        perform(.buyProperty(propertyID))
    }

    func declineOfferedProperty() {
        guard let propertyID = offeredProperty?.id else {
            return
        }
        perform(.declinePurchase(propertyID))
    }

    func placeAuctionBid(_ amount: Int) {
        guard let propertyID = state.auction?.propertyID, amount >= 0 else {
            return
        }
        perform(.placeAuctionBid(propertyID: propertyID, amount: Money(amount)))
    }

    func withdrawFromAuction() {
        guard let propertyID = state.auction?.propertyID else {
            return
        }
        perform(.withdrawFromAuction(propertyID))
    }

    func endTurn() {
        perform(.endTurn)
    }

    func property(_ propertyID: PropertyID) -> PropertyDefinition? {
        state.board.properties.first { $0.id == propertyID }
    }

    func playerName(_ playerID: PlayerID) -> String {
        state.players.first { $0.id == playerID }?.name ?? "Unknown player"
    }

    func ownerName(for propertyID: PropertyID) -> String? {
        guard let ownerID = state.propertyStates[propertyID]?.ownerID else {
            return nil
        }
        return playerName(ownerID)
    }

    func mortgageProceeds(for propertyID: PropertyID) -> Money? {
        legalActions.compactMap { action -> Money? in
            guard case let .mortgageProperty(actionPropertyID, proceeds) = action,
                  actionPropertyID == propertyID else {
                return nil
            }
            return proceeds
        }.first
    }

    func unmortgageCost(for propertyID: PropertyID) -> Money? {
        legalActions.compactMap { action -> Money? in
            guard case let .unmortgageProperty(actionPropertyID, cost) = action,
                  actionPropertyID == propertyID else {
                return nil
            }
            return cost
        }.first
    }

    func transferredMortgageInterest(for propertyID: PropertyID) -> Money? {
        legalActions.compactMap { action -> Money? in
            guard case let .keepTransferredMortgage(actionPropertyID, interest) = action,
                  actionPropertyID == propertyID else {
                return nil
            }
            return interest
        }.first
    }

    func transferredUnmortgageCost(for propertyID: PropertyID) -> Money? {
        legalActions.compactMap { action -> Money? in
            guard case let .unmortgageTransferredProperty(actionPropertyID, cost) = action,
                  actionPropertyID == propertyID else {
                return nil
            }
            return cost
        }.first
    }
}

private extension GameSession {
    var actingPlayerID: PlayerID? {
        switch state.phase {
        case let .openingRoll(remainingPlayerIDs):
            return remainingPlayerIDs.first
        case .awaitingAuction:
            return state.auction?.currentBidderID
        case let .resolvingDebt(debt):
            return debt.debtorID
        case let .resolvingMortgageTransfer(resolution):
            return resolution.recipientID
        default:
            return currentPlayer?.id
        }
    }

    func perform(_ action: PlayerAction) {
        guard let actingPlayerID else {
            return
        }
        do {
            let events = try engine.perform(action, by: actingPlayerID)
            errorMessage = nil
            append(events)
        } catch {
            errorMessage = "That action is not available right now."
        }
    }

    func append(_ events: [GameEvent]) {
        let messages = events.compactMap(eventDescription)
        eventLog.append(contentsOf: messages)
        if eventLog.count > 30 {
            eventLog.removeFirst(eventLog.count - 30)
        }
    }

    func eventDescription(_ event: GameEvent) -> String? {
        switch event {
        case let .diceRolled(playerID, roll):
            let doubles = roll.isDouble ? " Doubles." : ""
            return "\(playerName(playerID)) rolled \(roll.first) + \(roll.second).\(doubles)"
        case let .openingRollTied(playerIDs):
            return "\(playerIDs.map(playerName).joined(separator: " and ")) tied and roll again."
        case let .starterSelected(playerID):
            return "\(playerName(playerID)) takes the first turn."
        case let .playerMoved(playerID, _, destination):
            return "\(playerName(playerID)) moved to \(state.board[destination.rawValue].name)."
        case let .passedGrandOpening(playerID, amount):
            return "\(playerName(playerID)) collected $\(amount.amount) at Grand Opening."
        case .landed, .moneyTransferred:
            return nil
        case let .purchaseOffered(playerID, propertyID):
            return "\(property(propertyID)?.name ?? "A restaurant") is available to \(playerName(playerID))."
        case let .propertyPurchased(playerID, propertyID, price):
            return "\(playerName(playerID)) bought \(property(propertyID)?.name ?? "a restaurant") for $\(price.amount)."
        case let .auctionStarted(propertyID, firstBidderID):
            return "Auction opened for \(property(propertyID)?.name ?? "a restaurant"). \(playerName(firstBidderID)) bids first."
        case let .auctionBidPlaced(_, bid):
            return "\(playerName(bid.bidderID)) bid $\(bid.amount.amount)."
        case let .auctionBidderWithdrew(_, playerID):
            return "\(playerName(playerID)) left the auction."
        case let .auctionWon(propertyID, bid):
            return "\(playerName(bid.bidderID)) won \(property(propertyID)?.name ?? "the property") for $\(bid.amount.amount)."
        case let .auctionEndedWithoutSale(propertyID):
            return "\(property(propertyID)?.name ?? "The property") returned to the bank."
        case let .rentPaid(propertyID, playerID, ownerID, amount):
            return "\(playerName(playerID)) paid \(playerName(ownerID)) $\(amount.amount) rent at \(property(propertyID)?.name ?? "a restaurant")."
        case let .taxPaid(playerID, amount):
            return "\(playerName(playerID)) paid $\(amount.amount) in fees."
        case let .debtRequired(debt):
            return "\(playerName(debt.debtorID)) owes $\(debt.amount.amount)."
        case let .debtPaid(debt):
            return "\(playerName(debt.debtorID)) paid the $\(debt.amount.amount) balance."
        case let .propertyMortgaged(playerID, propertyID, proceeds):
            return "\(playerName(playerID)) mortgaged \(property(propertyID)?.name ?? "a location") for $\(proceeds.amount)."
        case let .propertyUnmortgaged(playerID, propertyID, cost):
            return "\(playerName(playerID)) unmortgaged \(property(propertyID)?.name ?? "a location") for $\(cost.amount)."
        case let .propertyTransferred(propertyID, playerID, recipientID):
            return "\(property(propertyID)?.name ?? "A location") transferred from \(playerName(playerID)) to \(playerName(recipientID))."
        case let .transferredMortgageKept(playerID, propertyID, interest):
            return "\(playerName(playerID)) paid $\(interest.amount) interest on \(property(propertyID)?.name ?? "a location")."
        case let .bankruptcyDeclared(playerID, _):
            return "\(playerName(playerID)) declared bankruptcy."
        case let .playerEliminated(playerID):
            return "\(playerName(playerID)) is out of the game."
        case let .winnerDeclared(playerID):
            return "\(playerName(playerID)) is the last restaurant group standing."
        case let .sentToDetention(playerID, _):
            return "\(playerName(playerID)) was closed for renovation."
        case let .thirdConsecutiveDouble(playerID):
            return "\(playerName(playerID)) rolled three doubles in a row."
        case let .detentionRollFailed(playerID, failedRolls):
            return "\(playerName(playerID)) remains closed after attempt \(failedRolls)."
        case let .detentionFeePaid(playerID, amount):
            return "\(playerName(playerID)) paid $\(amount.amount) to reopen."
        case let .releasedFromDetention(playerID):
            return "\(playerName(playerID)) reopened for business."
        case let .turnEnded(_, nextPlayerID):
            return "\(playerName(nextPlayerID)) is up next."
        }
    }
}
