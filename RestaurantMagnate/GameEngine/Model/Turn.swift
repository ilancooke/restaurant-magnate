import Foundation

enum TurnPhase: Hashable, Sendable {
    case openingRoll(remainingPlayerIDs: [PlayerID])
    case awaitingRoll
    case resolvingLanding
    case awaitingPurchase(propertyID: PropertyID)
    case awaitingAuction(propertyID: PropertyID)
    case awaitingEndTurn
    case resolvingDebt(Debt)
    case resolvingMortgageTransfer(MortgageTransferResolution)
    case gameOver(winnerID: PlayerID)
}

enum PlayerAction: Hashable, Sendable {
    case rollDice
    case payDetentionFee
    case mortgageProperty(PropertyID)
    case unmortgageProperty(PropertyID)
    case keepTransferredMortgage(PropertyID)
    case unmortgageTransferredProperty(PropertyID)
    case declareBankruptcy
    case buyProperty(PropertyID)
    case declinePurchase(PropertyID)
    case placeAuctionBid(propertyID: PropertyID, amount: Money)
    case withdrawFromAuction(PropertyID)
    case endTurn
    case resign
}

enum LegalPlayerAction: Hashable, Sendable {
    case rollDice
    case payDetentionFee(amount: Money)
    case mortgageProperty(propertyID: PropertyID, proceeds: Money)
    case unmortgageProperty(propertyID: PropertyID, cost: Money)
    case keepTransferredMortgage(propertyID: PropertyID, interest: Money)
    case unmortgageTransferredProperty(propertyID: PropertyID, cost: Money)
    case declareBankruptcy
    case buyProperty(PropertyID)
    case declinePurchase(PropertyID)
    case placeAuctionBid(propertyID: PropertyID, minimumBid: Money)
    case withdrawFromAuction(PropertyID)
    case endTurn
}

enum TransactionAccount: Hashable, Sendable {
    case bank
    case player(PlayerID)
}

enum TransactionReason: Hashable, Sendable {
    case startingCash
    case passedStart
    case propertyPurchase(PropertyID)
    case auctionPurchase(PropertyID)
    case rent(PropertyID)
    case tax
    case detentionFee
    case mortgageInterest(PropertyID)
    case bankruptcy
    case card
    case mortgage(PropertyID)
}

struct BankTransaction: Hashable, Sendable {
    let from: TransactionAccount
    let to: TransactionAccount
    let amount: Money
    let reason: TransactionReason
}

struct Debt: Hashable, Sendable {
    let debtorID: PlayerID
    let creditor: TransactionAccount
    let amount: Money
    let reason: TransactionReason
}

enum DebtContinuation: Hashable, Sendable {
    case finishLanding(allowsExtraRoll: Bool)
    case moveAfterDetentionFee(playerID: PlayerID, roll: DiceRoll)
}

struct MortgageTransferResolution: Hashable, Sendable {
    let recipientID: PlayerID
    let eliminatedPlayerID: PlayerID
    var remainingPropertyIDs: [PropertyID]
}

struct BankruptcyAuctionResolution: Hashable, Sendable {
    let eliminatedPlayerID: PlayerID
    var remainingPropertyIDs: [PropertyID]
}

struct AuctionBid: Hashable, Sendable {
    let bidderID: PlayerID
    let amount: Money
}

enum AuctionPurpose: Hashable, Sendable {
    case declinedPurchase
    case bankruptcy
}

struct AuctionState: Hashable, Sendable {
    let propertyID: PropertyID
    let purpose: AuctionPurpose
    let bidderOrder: [PlayerID]
    var remainingBidderIDs: [PlayerID]
    var highBid: AuctionBid?
    var currentBidderID: PlayerID
}
