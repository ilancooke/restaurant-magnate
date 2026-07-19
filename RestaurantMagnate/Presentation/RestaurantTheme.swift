import SwiftUI

enum RestaurantTheme {
    static let canvas = Color(red: 0.965, green: 0.953, blue: 0.918)
    static let surface = Color.white
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.13)
    static let secondaryInk = Color(red: 0.36, green: 0.37, blue: 0.34)
    static let line = Color(red: 0.78, green: 0.76, blue: 0.69)
    static let tomato = Color(red: 0.78, green: 0.18, blue: 0.15)
    static let mustard = Color(red: 0.91, green: 0.65, blue: 0.08)
    static let aqua = Color(red: 0.10, green: 0.62, blue: 0.66)
    static let leaf = Color(red: 0.20, green: 0.54, blue: 0.28)
    static let cobalt = Color(red: 0.12, green: 0.33, blue: 0.68)

    static func color(for token: PlayerToken) -> Color {
        switch token {
        case .chefHat: tomato
        case .takeoutBag: cobalt
        case .receiptRoll: leaf
        case .servingTray: mustard
        }
    }

    static func color(for group: RestaurantGroup) -> Color {
        switch group {
        case .valueBudget: Color(red: 0.48, green: 0.30, blue: 0.19)
        case .classicBurgers: Color(red: 0.42, green: 0.72, blue: 0.86)
        case .texMex: Color(red: 0.88, green: 0.34, blue: 0.52)
        case .friedChicken: Color(red: 0.91, green: 0.43, blue: 0.12)
        case .pizzaChains: tomato
        case .sandwichesAndCafes: mustard
        case .casualDiningAndGrills: leaf
        case .highEndFranchises: cobalt
        }
    }
}

extension PlayerToken {
    var displayName: String {
        switch self {
        case .chefHat: "Chef Hat"
        case .takeoutBag: "Takeout Bag"
        case .receiptRoll: "Receipt Roll"
        case .servingTray: "Serving Tray"
        }
    }

    var symbolName: String {
        switch self {
        case .chefHat: "frying.pan"
        case .takeoutBag: "bag"
        case .receiptRoll: "receipt"
        case .servingTray: "takeoutbag.and.cup.and.straw"
        }
    }
}

extension BoardSpaceKind {
    var symbolName: String {
        switch self {
        case .start: "door.left.hand.open"
        case let .property(property):
            switch property.rentRule {
            case .restaurant: "fork.knife"
            case .deliveryService: "bicycle"
            case .infrastructure: "bolt.fill"
            }
        case .event(.driveThruOrder): "car.side"
        case .event(.secretRecipe): "doc.text.magnifyingglass"
        case .tax: "banknote"
        case .detention: "wrench.and.screwdriver"
        case .neutral: "cup.and.saucer"
        case .sendToDetention: "exclamationmark.triangle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case let .property(property):
            if case let .restaurant(group, _) = property.rentRule {
                return RestaurantTheme.color(for: group)
            }
            return RestaurantTheme.aqua
        case .event: return RestaurantTheme.mustard
        case .tax, .sendToDetention: return RestaurantTheme.tomato
        case .start, .neutral: return RestaurantTheme.leaf
        case .detention: return RestaurantTheme.cobalt
        }
    }
}
