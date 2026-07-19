import Foundation

enum EventDeck: Hashable, Sendable {
    case driveThruOrder
    case secretRecipe
}

enum BoardSpaceKind: Hashable, Sendable {
    case start(payment: Money)
    case property(PropertyDefinition)
    case event(EventDeck)
    case tax(amount: Money)
    case detention
    case neutral
    case sendToDetention(destination: BoardSpaceID)
}

struct BoardSpace: Hashable, Sendable {
    let id: BoardSpaceID
    let name: String
    let kind: BoardSpaceKind

    var position: Int {
        id.rawValue
    }
}

enum BoardValidationError: Error, Equatable {
    case empty
    case positionsMustStartAtZero
    case nonContiguousPosition(expected: Int, actual: Int)
    case duplicatePropertyID(PropertyID)
    case missingStartSpace
}

struct Board: Hashable, Sendable {
    let spaces: [BoardSpace]

    init(spaces: [BoardSpace]) throws {
        guard !spaces.isEmpty else {
            throw BoardValidationError.empty
        }
        guard spaces[0].position == 0 else {
            throw BoardValidationError.positionsMustStartAtZero
        }

        var propertyIDs = Set<PropertyID>()
        for (expectedPosition, space) in spaces.enumerated() {
            guard space.position == expectedPosition else {
                throw BoardValidationError.nonContiguousPosition(
                    expected: expectedPosition,
                    actual: space.position
                )
            }
            if case let .property(property) = space.kind,
               !propertyIDs.insert(property.id).inserted {
                throw BoardValidationError.duplicatePropertyID(property.id)
            }
        }

        guard case .start = spaces[0].kind else {
            throw BoardValidationError.missingStartSpace
        }
        self.spaces = spaces
    }

    var properties: [PropertyDefinition] {
        spaces.compactMap { space in
            guard case let .property(property) = space.kind else {
                return nil
            }
            return property
        }
    }

    subscript(position: Int) -> BoardSpace {
        spaces[position]
    }
}

