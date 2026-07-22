# Restaurant Magnate

Restaurant Magnate is an original, local pass-and-play property-trading board
game for iPhone. It uses the familiar base rules of the genre with an original
restaurant-franchise theme, names, interface, and prototype artwork.

The prototype supports two to four human players sharing one device. It has no
networking, accounts, persistence, purchases, advertising, sound, or external
dependencies.

## Current State

The project has a playable 40-space board and currently supports:

- Two-to-four-player setup with unique names and tokens
- Opening rolls to choose the first player, including tied rerolls
- Two-die movement, passing Grand Opening, and automatic bank payments
- Property purchases and mandatory auctions with a $10 opening bid
- Restaurant-group, delivery-service, and infrastructure rent
- Doubles, three consecutive doubles, and Closed for Renovation behavior
- Taxes and automatic required payments
- Mortgaging, unmortgaging, debt resolution, and mortgage-transfer interest
- Bankruptcy to another player or the bank, bank liquidation auctions,
  elimination, and last-solvent-player victory
- A square 11-by-11 board with 11 positions per edge, including corners
- A landscape-first SwiftUI presentation with a full-height board, scrollable
  operations rail, and functional portrait fallback
- An original illustrated restaurant district beneath live SwiftUI board state

Drive-Thru Order and Secret Recipe spaces currently have no card effects.
Restaurant upgrades, trading, and final production artwork are also intentionally
deferred.

## Project Layout

```text
RestaurantMagnate/
  GameEngine/
    Model/          Value types for state, players, board, turns, and events
    Rules/          Pure game-rule transitions and board/economy definitions
  Presentation/     GameSession adapter and shared visual theme
  Views/            SwiftUI setup, game board, and gameplay screens
  Assets.xcassets/  App assets and the illustrated board-center district
RestaurantMagnateTests/
  GameEngine/       Swift Testing coverage for rules and state transitions
  Presentation/     GameSession presentation tests
RestaurantMagnateUITests/
Design/
  ArtDirection.md   Canonical visual principles
  BoardSpecification.md  Canonical 40-space layout and prototype economy
  Concepts/         Mood references only; never use their text as game data
```

`GameEngine` is independent of SwiftUI. `GameSession` exposes engine state and
legal actions to the views, and the views dispatch actions without reimplementing
rules.

## Running The Project

Open `RestaurantMagnate.xcodeproj` in Xcode and run the `RestaurantMagnate`
scheme on an iPhone simulator. Gameplay is designed primarily for landscape:
the square board fills the left side while players, actions, space details, and
events appear in a scrollable operations rail on the right. Portrait remains a
supported fallback. The current UI has been verified on iPhone 13 in landscape
and portrait, including two-player and four-player setup states.

Command-line build:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project RestaurantMagnate.xcodeproj \
  -scheme RestaurantMagnate \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build-for-testing
```

Command-line tests, using an installed simulator name:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project RestaurantMagnate.xcodeproj \
  -scheme RestaurantMagnate \
  -destination 'platform=iOS Simulator,name=iPhone 13' \
  CODE_SIGNING_ALLOWED=NO test
```

The complete iPhone 13 scheme last passed 51 test cases with 56 executions,
including parameterized and launch-configuration runs. Xcode currently emits
Swift Testing warnings about main-actor-isolated generated conformances; these
warnings are known technical debt and do not represent test failures.

## Locked Prototype Decisions

- Starting cash is $1,500; passing Grand Opening pays $200.
- The board uses the final 40-space count and the economy in
  `Design/BoardSpecification.md`.
- The board remains square with an 11-by-11 perimeter, 11 positions per edge
  including corners, and corner spaces at positions 0, 10, 20, and 30.
- Gameplay is landscape-first with a functional portrait fallback; it is not
  locked to landscape-only.
- The illustrated center is atmospheric. All names, ownership, mortgages,
  upgrades, tokens, dice, and controls remain live UI driven by game state.
- Player order is decided by opening roll.
- Declined purchases trigger mandatory auctions.
- Rent and required payments happen automatically.
- Staff Break has no jackpot or other house rule.
- Trades will allow immediate cash and properties only, with no deferred deals.
- Upgrade inventory is unlimited for the prototype.
- All game information is public during pass-and-play.
- Victory goes to the last solvent player.
- Card copy remains placeholder content until prompts are supplied.

## Next Milestones

1. **Restaurant upgrades and flagships**
   Add legal buy/sell actions, complete-group requirements, even development,
   upgrade costs, mortgage restrictions, rent progression, and management UI.

2. **Player trading**
   Support immediate cash-and-property offers, validation, acceptance/rejection,
   and transferred-mortgage handling without promises or future consideration.

3. **Drive-Thru Order and Secret Recipe decks**
   Add deterministic deck models and placeholder effects first, then replace the
   content when final prompts are provided.

4. **Rules-completeness pass**
   Exercise long end-to-end games and close remaining edge cases around upgrades,
   trades, detention, auctions, insolvency, and resignation.

5. **Accessibility and final-art pass**
   Expand Dynamic Type, VoiceOver, contrast, and device-matrix checks before
   reviewing the generated center illustration and replacing remaining
   placeholders with original production assets.

The first milestone above is the recommended next implementation slice because
upgrade levels and rent schedules already exist in the model, but the engine
does not yet expose development actions.

## Trademark Boundary

Do not add trademarks, copied board-space names, card copy, tokens, artwork, or
visual design from any existing commercial board game or restaurant company.
Current restaurant names are working parody-style placeholders and still require
a final naming and trademark review before release.
