# Agent Guidelines

These instructions apply to future automated coding sessions in this repository.

## Product And IP Boundaries

- Keep Restaurant Magnate original. Do not copy trademarks, branded artwork,
  board-space names, card copy, tokens, or visual layouts from existing games or
  restaurant companies.
- Treat names as prototype placeholders pending trademark review.
- Do not add online multiplayer, Game Center, accounts, persistence, purchases,
  ads, sound, third-party dependencies, or final artwork unless explicitly asked.
- Keep the game local pass-and-play for two to four human players.

## Architecture

- `RestaurantMagnate/GameEngine` must remain independent of SwiftUI.
- Put state transitions and legal-action validation in `GameEngine`, not views or
  `GameSession`.
- Views should render state and dispatch only actions published as legal by the
  engine. Do not duplicate rule calculations in SwiftUI.
- Prefer value types, explicit events, deterministic injected dice, and small
  native Swift abstractions.
- Use `Design/BoardSpecification.md` as the canonical board/economy source.
- Use `Design/ArtDirection.md` and `Design/Concepts` only for visual direction.
  Generated concept labels, numbering, and controls are not authoritative data.

## Xcode And Files

- Preserve the existing app target and project settings unless a change is
  required for the requested feature.
- The project uses file-system-synchronized Xcode groups. New Swift files under
  the existing target directories are discovered automatically; do not edit
  `project.pbxproj` merely to add a source file.
- Keep the project dependency-free and use native Swift, SwiftUI, and Apple
  frameworks.
- Avoid unrelated project-file or generated-metadata churn.

## Testing

- Use Swift Testing for unit and presentation tests. Use XCTest only in the
  existing UI-test target.
- Inject `SequenceDiceRoller` for deterministic engine tests.
- Every rule change should cover its legal actions, state mutation, money flow,
  emitted events, and continuation phase.
- Verify UI changes in both two-player and four-player setup states on iPhone 13,
  and inspect screenshots for clipping, overlap, contrast, and hit targets.
- Run `git diff --check` and the complete scheme before committing.
- Discover simulator identifiers locally rather than committing a device UUID.

Typical full test command:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -quiet -project RestaurantMagnate.xcodeproj \
  -scheme RestaurantMagnate \
  -destination 'platform=iOS Simulator,name=iPhone 13' \
  CODE_SIGNING_ALLOWED=NO test
```

In this environment, an `xcodebuild` wrapper can return before its child UI-test
process and `.xcresult` bundle finish. Before reporting completion, check for
remaining `xcodebuild` or `RestaurantMagnateUITests-Runner` processes and wait
for the result bundle's `Info.plist` before using `xcresulttool`.

The project currently produces Swift Testing warnings about actor-isolated
generated conformances. Do not hide new warnings, but do not mistake these known
warnings for failures.

## UI Direction

- Preserve the Modern Franchise Atlas language: dark operational mastheads,
  warm paper surfaces, saturated category colors, crisp pictograms, and compact
  restaurant-district graphics.
- Keep cards at an 8-point corner radius or less. Avoid cards nested in cards.
- Use SF Symbols for placeholder controls and provide accessibility labels.
- Pair property colors with icons or labels; never encode state by color alone.
- Ensure names, cash, controls, and token menus do not clip at supported player
  counts or on the iPhone 13 viewport.

## Current Recommended Work

Implement restaurant upgrades and flagships next. Preserve even-development and
even-selling rules, block mortgages while any property in a restaurant group has
upgrades, use the existing rent schedules, and assume unlimited bank inventory
for this prototype. Add engine tests before extending the management UI.
