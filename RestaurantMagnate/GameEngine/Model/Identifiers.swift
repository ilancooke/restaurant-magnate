import Foundation

struct PlayerID: Hashable, Sendable {
    let rawValue: UUID

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

struct PropertyID: Hashable, RawRepresentable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        precondition(!rawValue.isEmpty, "Property ID cannot be empty")
        self.rawValue = rawValue
    }
}

struct BoardSpaceID: Hashable, RawRepresentable, Sendable {
    let rawValue: Int

    init(rawValue: Int) {
        precondition(rawValue >= 0, "Board space ID cannot be negative")
        self.rawValue = rawValue
    }
}

