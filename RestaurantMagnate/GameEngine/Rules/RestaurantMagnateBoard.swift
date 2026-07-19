import Foundation

extension Board {
    static let restaurantMagnate: Board = {
        try! Board(spaces: [
            BoardSpace(
                id: BoardSpaceID(rawValue: 0),
                name: "Grand Opening",
                kind: .start(payment: Money(200))
            ),
            restaurant(1, "dollar-drive-thru", "The Dollar Drive-Thru", 60, 30, 50, .valueBudget, [2, 10, 30, 90, 160, 250]),
            event(2, "Secret Recipe", .secretRecipe),
            restaurant(3, "bargain-burger", "Bargain Burger", 60, 30, 50, .valueBudget, [4, 20, 60, 180, 320, 450]),
            tax(4, "Franchise Tax", 200),
            deliveryService(5, "uberfeeds", "UberFeeds"),
            restaurant(6, "mcronalds", "McRonald's", 100, 50, 50, .classicBurgers, [6, 30, 90, 270, 400, 550]),
            event(7, "Drive-Thru Order", .driveThruOrder),
            restaurant(8, "wandas-frosty-burgers", "Wanda's Frosty Burgers", 100, 50, 50, .classicBurgers, [6, 30, 90, 270, 400, 550]),
            restaurant(9, "kings-castle", "The King's Castle", 120, 60, 50, .classicBurgers, [8, 40, 100, 300, 450, 600]),
            BoardSpace(
                id: BoardSpaceID(rawValue: 10),
                name: "Closed for Renovation / Just Visiting",
                kind: .detention
            ),
            restaurant(11, "taco-chime", "Taco Chime", 140, 70, 100, .texMex, [10, 50, 150, 450, 625, 750]),
            infrastructure(12, "soda-fountain", "The Soda Fountain"),
            restaurant(13, "del-rio-burrito", "Del Rio Burrito", 140, 70, 100, .texMex, [10, 50, 150, 450, 625, 750]),
            restaurant(14, "nachos-locos", "Nachos Locos", 160, 80, 100, .texMex, [12, 60, 180, 500, 700, 900]),
            deliveryService(15, "doordashers", "DoorDashers"),
            restaurant(16, "dixie-fried-chicken", "Dixie Fried Chicken", 180, 90, 100, .friedChicken, [14, 70, 200, 550, 750, 950]),
            event(17, "Secret Recipe", .secretRecipe),
            restaurant(18, "cluck-shack", "The Cluck Shack", 180, 90, 100, .friedChicken, [14, 70, 200, 550, 750, 950]),
            restaurant(19, "pollo-loco-hub", "Pollo Loco Hub", 200, 100, 100, .friedChicken, [16, 80, 220, 600, 800, 1_000]),
            BoardSpace(
                id: BoardSpaceID(rawValue: 20),
                name: "Staff Break",
                kind: .neutral
            ),
            restaurant(21, "pizza-hutlet", "Pizza Hutlet", 220, 110, 150, .pizzaChains, [18, 90, 250, 700, 875, 1_050]),
            event(22, "Drive-Thru Order", .driveThruOrder),
            restaurant(23, "dominos-brick-oven", "Domino's Brick Oven", 220, 110, 150, .pizzaChains, [18, 90, 250, 700, 875, 1_050]),
            restaurant(24, "papas-pizzeria", "Papa's Pizzeria", 240, 120, 150, .pizzaChains, [20, 100, 300, 750, 925, 1_100]),
            deliveryService(25, "grubguzzlers", "GrubGuzzlers"),
            restaurant(26, "underground-subs", "Underground Subs", 260, 130, 150, .sandwichesAndCafes, [22, 110, 330, 800, 975, 1_150]),
            restaurant(27, "star-buckets-coffee", "Star-Buckets Coffee", 260, 130, 150, .sandwichesAndCafes, [22, 110, 330, 800, 975, 1_150]),
            infrastructure(28, "deep-fryer", "The Deep Fryer"),
            restaurant(29, "donut-hole", "Donut Hole", 280, 140, 150, .sandwichesAndCafes, [24, 120, 360, 850, 1_025, 1_200]),
            BoardSpace(
                id: BoardSpaceID(rawValue: 30),
                name: "Health Inspector Shutdown",
                kind: .sendToDetention(destination: BoardSpaceID(rawValue: 10))
            ),
            restaurant(31, "apple-beeswax-grill", "Apple-Beeswax Grill", 300, 150, 200, .casualDiningAndGrills, [26, 130, 390, 900, 1_100, 1_275]),
            restaurant(32, "chilis-pepper-shack", "Chili's Pepper Shack", 300, 150, 200, .casualDiningAndGrills, [26, 130, 390, 900, 1_100, 1_275]),
            event(33, "Secret Recipe", .secretRecipe),
            restaurant(34, "olive-gardenia", "Olive Gardenia", 320, 160, 200, .casualDiningAndGrills, [28, 150, 450, 1_000, 1_200, 1_400]),
            deliveryService(35, "postmates-express", "PostMates Express"),
            event(36, "Drive-Thru Order", .driveThruOrder),
            restaurant(37, "golden-steakhouse", "The Golden Steakhouse", 350, 175, 200, .highEndFranchises, [35, 175, 500, 1_100, 1_300, 1_500]),
            tax(38, "Spoiled Inventory Fee", 100),
            restaurant(39, "angus-prime-core", "The Angus Prime Core", 400, 200, 200, .highEndFranchises, [50, 200, 600, 1_400, 1_700, 2_000])
        ])
    }()
}

private extension Board {
    static func restaurant(
        _ position: Int,
        _ id: String,
        _ name: String,
        _ price: Int,
        _ mortgage: Int,
        _ upgradeCost: Int,
        _ group: RestaurantGroup,
        _ rents: [Int]
    ) -> BoardSpace {
        precondition(rents.count == 6)
        let schedule = RestaurantRentSchedule(
            base: Money(rents[0]),
            oneUpgrade: Money(rents[1]),
            twoUpgrades: Money(rents[2]),
            threeUpgrades: Money(rents[3]),
            fourUpgrades: Money(rents[4]),
            flagship: Money(rents[5])
        )
        return BoardSpace(
            id: BoardSpaceID(rawValue: position),
            name: name,
            kind: .property(
                PropertyDefinition(
                    id: PropertyID(rawValue: id),
                    name: name,
                    purchasePrice: Money(price),
                    mortgageValue: Money(mortgage),
                    upgradeCost: Money(upgradeCost),
                    rentRule: .restaurant(group: group, schedule: schedule)
                )
            )
        )
    }

    static func deliveryService(_ position: Int, _ id: String, _ name: String) -> BoardSpace {
        BoardSpace(
            id: BoardSpaceID(rawValue: position),
            name: name,
            kind: .property(
                PropertyDefinition(
                    id: PropertyID(rawValue: id),
                    name: name,
                    purchasePrice: Money(200),
                    mortgageValue: Money(100),
                    upgradeCost: nil,
                    rentRule: .deliveryService(
                        rentsByOwnedCount: [Money(25), Money(50), Money(100), Money(200)]
                    )
                )
            )
        )
    }

    static func infrastructure(_ position: Int, _ id: String, _ name: String) -> BoardSpace {
        BoardSpace(
            id: BoardSpaceID(rawValue: position),
            name: name,
            kind: .property(
                PropertyDefinition(
                    id: PropertyID(rawValue: id),
                    name: name,
                    purchasePrice: Money(150),
                    mortgageValue: Money(75),
                    upgradeCost: nil,
                    rentRule: .infrastructure(oneOwnedMultiplier: 4, bothOwnedMultiplier: 10)
                )
            )
        )
    }

    static func event(_ position: Int, _ name: String, _ deck: EventDeck) -> BoardSpace {
        BoardSpace(
            id: BoardSpaceID(rawValue: position),
            name: name,
            kind: .event(deck)
        )
    }

    static func tax(_ position: Int, _ name: String, _ amount: Int) -> BoardSpace {
        BoardSpace(
            id: BoardSpaceID(rawValue: position),
            name: name,
            kind: .tax(amount: Money(amount))
        )
    }
}

