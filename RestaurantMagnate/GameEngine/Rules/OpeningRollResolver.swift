import Foundation

enum OpeningRollResolution: Equatable, Sendable {
    case starter(PlayerID)
    case reroll(playerIDs: [PlayerID])
}

enum OpeningRollError: Error, Equatable {
    case noPlayers
    case missingRoll(PlayerID)
}

enum OpeningRollResolver {
    static func resolve(
        playerIDs: [PlayerID],
        rolls: [PlayerID: DiceRoll]
    ) throws -> OpeningRollResolution {
        guard !playerIDs.isEmpty else {
            throw OpeningRollError.noPlayers
        }
        for playerID in playerIDs where rolls[playerID] == nil {
            throw OpeningRollError.missingRoll(playerID)
        }

        let highestTotal = playerIDs.compactMap { rolls[$0]?.total }.max()!
        let leaders = playerIDs.filter { rolls[$0]?.total == highestTotal }
        if leaders.count == 1 {
            return .starter(leaders[0])
        }
        return .reroll(playerIDs: leaders)
    }
}

