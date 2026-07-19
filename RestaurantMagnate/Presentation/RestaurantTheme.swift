import SwiftUI

enum RestaurantTheme {
    static let canvas = Color(red: 0.94, green: 0.93, blue: 0.88)
    static let paper = Color(red: 0.985, green: 0.975, blue: 0.94)
    static let surface = Color(red: 0.995, green: 0.992, blue: 0.98)
    static let asphalt = Color(red: 0.07, green: 0.085, blue: 0.08)
    static let road = Color(red: 0.24, green: 0.26, blue: 0.24)
    static let ink = Color(red: 0.09, green: 0.105, blue: 0.10)
    static let secondaryInk = Color(red: 0.34, green: 0.35, blue: 0.32)
    static let line = Color(red: 0.70, green: 0.68, blue: 0.61)
    static let tomato = Color(red: 0.84, green: 0.18, blue: 0.12)
    static let coral = Color(red: 0.93, green: 0.34, blue: 0.22)
    static let mustard = Color(red: 0.95, green: 0.67, blue: 0.04)
    static let aqua = Color(red: 0.07, green: 0.60, blue: 0.61)
    static let leaf = Color(red: 0.20, green: 0.57, blue: 0.29)
    static let cobalt = Color(red: 0.10, green: 0.31, blue: 0.64)

    static let compactTitle = Font.system(.headline, design: .rounded).weight(.black)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.black)

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

    var boardFill: Color {
        switch self {
        case let .property(property):
            if case let .restaurant(group, _) = property.rentRule {
                return RestaurantTheme.color(for: group)
            }
            switch property.rentRule {
            case .deliveryService: return RestaurantTheme.cobalt
            case .infrastructure: return RestaurantTheme.aqua
            case .restaurant: return accentColor
            }
        case .event(.driveThruOrder): return RestaurantTheme.mustard
        case .event(.secretRecipe): return RestaurantTheme.paper
        case .tax: return RestaurantTheme.tomato
        case .detention: return RestaurantTheme.cobalt
        case .neutral: return RestaurantTheme.mustard
        case .sendToDetention: return RestaurantTheme.tomato
        case .start: return RestaurantTheme.leaf
        }
    }

    var boardForeground: Color {
        switch self {
        case let .property(property):
            switch property.rentRule {
            case let .restaurant(group, _):
                switch group {
                case .classicBurgers, .sandwichesAndCafes:
                    return RestaurantTheme.ink
                default:
                    return .white
                }
            case .deliveryService, .infrastructure:
                return .white
            }
        case .event(.secretRecipe), .event(.driveThruOrder), .neutral:
            return RestaurantTheme.ink
        default:
            return .white
        }
    }
}
