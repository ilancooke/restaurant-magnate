import Foundation

enum RestaurantGroup: String, CaseIterable, Hashable, Sendable {
    case valueBudget
    case classicBurgers
    case texMex
    case friedChicken
    case pizzaChains
    case sandwichesAndCafes
    case casualDiningAndGrills
    case highEndFranchises
}

struct RestaurantRentSchedule: Hashable, Sendable {
    let base: Money
    let oneUpgrade: Money
    let twoUpgrades: Money
    let threeUpgrades: Money
    let fourUpgrades: Money
    let flagship: Money

    var allValues: [Money] {
        [base, oneUpgrade, twoUpgrades, threeUpgrades, fourUpgrades, flagship]
    }
}

enum RentRule: Hashable, Sendable {
    case restaurant(group: RestaurantGroup, schedule: RestaurantRentSchedule)
    case deliveryService(rentsByOwnedCount: [Money])
    case infrastructure(oneOwnedMultiplier: Int, bothOwnedMultiplier: Int)
}

struct PropertyDefinition: Hashable, Sendable {
    let id: PropertyID
    let name: String
    let purchasePrice: Money
    let mortgageValue: Money
    let upgradeCost: Money?
    let rentRule: RentRule
}

struct PropertyState: Hashable, Sendable {
    let propertyID: PropertyID
    var ownerID: PlayerID?
    var isMortgaged: Bool
    var upgradeLevel: Int

    init(propertyID: PropertyID) {
        self.propertyID = propertyID
        ownerID = nil
        isMortgaged = false
        upgradeLevel = 0
    }
}

