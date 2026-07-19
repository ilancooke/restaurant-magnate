import Foundation

enum TurnPhase: Hashable, Sendable {
    case openingRoll(remainingPlayerIDs: [PlayerID])
    case awaitingRoll
    case resolvingLanding
    case awaitingPurchase(propertyID: PropertyID)
    case awaitingAuction(propertyID: PropertyID)
    case awaitingEndTurn
    case resolvingDebt(Debt)
    case gameOver(winnerID: PlayerID)
}

enum PlayerAction: Hashable, Sendable {
    case rollDice
    case payDetentionFee
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

struct AuctionBid: Hashable, Sendable {
    let bidderID: PlayerID
    let amount: Money
}

struct AuctionState: Hashable, Sendable {
    let propertyID: PropertyID
    let bidderOrder: [PlayerID]
    var remainingBidderIDs: [PlayerID]
    var highBid: AuctionBid?
    var currentBidderID: PlayerID
}
