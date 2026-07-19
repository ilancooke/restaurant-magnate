import Foundation

enum RentCalculator {
    static func rent(
        for property: PropertyDefinition,
        propertyState: PropertyState,
        in gameState: GameState
    ) -> Money {
        guard let ownerID = propertyState.ownerID, !propertyState.isMortgaged else {
            return Money(0)
        }

        switch property.rentRule {
        case let .restaurant(group, schedule):
            precondition((0...5).contains(propertyState.upgradeLevel))
            if propertyState.upgradeLevel > 0 {
                return schedule.allValues[propertyState.upgradeLevel]
            }
            return ownsCompleteGroup(group, ownerID: ownerID, in: gameState)
                ? Money(schedule.base.amount * 2)
                : schedule.base

        case let .deliveryService(rentsByOwnedCount):
            let ownedCount = gameState.board.properties.count { candidate in
                guard case .deliveryService = candidate.rentRule else {
                    return false
                }
                return gameState.propertyStates[candidate.id]?.ownerID == ownerID
            }
            precondition((1...rentsByOwnedCount.count).contains(ownedCount))
            return rentsByOwnedCount[ownedCount - 1]

        case let .infrastructure(oneOwnedMultiplier, bothOwnedMultiplier):
            let ownedCount = gameState.board.properties.count { candidate in
                guard case .infrastructure = candidate.rentRule else {
                    return false
                }
                return gameState.propertyStates[candidate.id]?.ownerID == ownerID
            }
            let multiplier = ownedCount == 2 ? bothOwnedMultiplier : oneOwnedMultiplier
            return Money((gameState.latestRoll?.total ?? 0) * multiplier)
        }
    }

    private static func ownsCompleteGroup(
        _ group: RestaurantGroup,
        ownerID: PlayerID,
        in gameState: GameState
    ) -> Bool {
        let groupProperties = gameState.board.properties.filter { property in
            guard case let .restaurant(candidateGroup, _) = property.rentRule else {
                return false
            }
            return candidateGroup == group
        }
        return !groupProperties.isEmpty && groupProperties.allSatisfy { property in
            gameState.propertyStates[property.id]?.ownerID == ownerID
        }
    }
}

