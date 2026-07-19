import Testing
@testable import RestaurantMagnate

@Suite("Dice and opening roll")
struct DiceAndOpeningRollTests {
    private struct FixedDiceRoller: DiceRolling {
        var rolls: [DiceRoll]

        mutating func roll() -> DiceRoll {
            rolls.removeFirst()
        }
    }

    @Test
    func diceExposeTotalAndDoubles() {
        let roll = DiceRoll(first: 4, second: 4)

        #expect(roll.total == 8)
        #expect(roll.isDouble)
    }

    @Test
    func diceRollerCanBeDeterministic() {
        var roller = FixedDiceRoller(rolls: [
            DiceRoll(first: 1, second: 2),
            DiceRoll(first: 6, second: 5)
        ])

        #expect(roller.roll().total == 3)
        #expect(roller.roll().total == 11)
    }

    @Test
    func highestOpeningRollStarts() throws {
        let maya = PlayerID()
        let theo = PlayerID()
        let nina = PlayerID()

        let result = try OpeningRollResolver.resolve(
            playerIDs: [maya, theo, nina],
            rolls: [
                maya: DiceRoll(first: 2, second: 3),
                theo: DiceRoll(first: 6, second: 4),
                nina: DiceRoll(first: 3, second: 5)
            ]
        )

        #expect(result == .starter(theo))
    }

    @Test
    func onlyHighestTiedPlayersReroll() throws {
        let maya = PlayerID()
        let theo = PlayerID()
        let nina = PlayerID()

        let result = try OpeningRollResolver.resolve(
            playerIDs: [maya, theo, nina],
            rolls: [
                maya: DiceRoll(first: 5, second: 5),
                theo: DiceRoll(first: 6, second: 4),
                nina: DiceRoll(first: 3, second: 5)
            ]
        )

        #expect(result == .reroll(playerIDs: [maya, theo]))
    }
}

