import Testing
@testable import RestaurantMagnate

@Suite("Restaurant Magnate board")
struct BoardDefinitionTests {
    private let board = Board.restaurantMagnate

    @Test
    func hasFortyContiguousSpaces() {
        #expect(board.spaces.count == 40)
        #expect(board.spaces.map(\.position) == Array(0..<40))
    }

    @Test
    func hasExpectedOwnableAssetComposition() {
        let restaurantCount = board.properties.count { property in
            if case .restaurant = property.rentRule { return true }
            return false
        }
        let deliveryServiceCount = board.properties.count { property in
            if case .deliveryService = property.rentRule { return true }
            return false
        }
        let infrastructureCount = board.properties.count { property in
            if case .infrastructure = property.rentRule { return true }
            return false
        }

        #expect(board.properties.count == 28)
        #expect(restaurantCount == 22)
        #expect(deliveryServiceCount == 4)
        #expect(infrastructureCount == 2)
        #expect(Set(board.properties.map(\.id)).count == 28)
    }

    @Test
    func hasAllEightRestaurantGroups() {
        let groups = board.properties.compactMap { property -> RestaurantGroup? in
            guard case let .restaurant(group, _) = property.rentRule else {
                return nil
            }
            return group
        }
        let counts = Dictionary(grouping: groups, by: { $0 }).mapValues(\.count)

        #expect(Set(groups) == Set(RestaurantGroup.allCases))
        #expect(counts[.valueBudget] == 2)
        #expect(counts[.classicBurgers] == 3)
        #expect(counts[.texMex] == 3)
        #expect(counts[.friedChicken] == 3)
        #expect(counts[.pizzaChains] == 3)
        #expect(counts[.sandwichesAndCafes] == 3)
        #expect(counts[.casualDiningAndGrills] == 3)
        #expect(counts[.highEndFranchises] == 2)
    }

    @Test
    func hasExpectedEventAndTaxSpaces() {
        let driveThruCount = board.spaces.count { space in
            space.kind == .event(.driveThruOrder)
        }
        let secretRecipeCount = board.spaces.count { space in
            space.kind == .event(.secretRecipe)
        }

        #expect(driveThruCount == 3)
        #expect(secretRecipeCount == 3)
        #expect(board[4].kind == .tax(amount: Money(200)))
        #expect(board[38].kind == .tax(amount: Money(100)))
        #expect(board[30].kind == .sendToDetention(destination: BoardSpaceID(rawValue: 10)))
    }

    @Test
    func mortgageValuesAreHalfOfPurchasePrices() {
        #expect(board.properties.allSatisfy { property in
            property.mortgageValue.amount * 2 == property.purchasePrice.amount
        })
    }

    @Test
    func restaurantRentSchedulesHaveSixLevels() {
        let schedules = board.properties.compactMap { property -> RestaurantRentSchedule? in
            guard case let .restaurant(_, schedule) = property.rentRule else {
                return nil
            }
            return schedule
        }

        #expect(schedules.count == 22)
        #expect(schedules.allSatisfy { $0.allValues.count == 6 })
        #expect(schedules.allSatisfy { schedule in
            zip(schedule.allValues, schedule.allValues.dropFirst()).allSatisfy(<)
        })
    }
}

