# Restaurant Magnate Art Direction

## Direction

Restaurant Magnate uses a **Modern Franchise Atlas** style: a lively restaurant
district rendered with crisp forms, clear food-category symbols, layered urban
detail, warm storefront light, and restrained print texture. The result should
feel colorful, prosperous, and alive without reducing the readability required
by a 40-space board on an iPhone.

The concept renders in `Design/Concepts` are mood references, not literal UI or
board specifications. Their generated labels, numbering, layouts, and controls
must not be treated as game data.

`Design/Concepts/modern-franchise-atlas-board.png` is the preferred reference
for environmental richness, depth, lighting, and density. Do not copy its board
layout or generated content. `modern-franchise-atlas-iphone.png` remains useful
for basic information hierarchy, but its plainer visual treatment is not the
target style.

The current project-local center illustration is
`RestaurantMagnate/Assets.xcassets/RestaurantDistrict.imageset`. It is an
original generated prototype asset, not final production artwork.

## Gameplay Layout

- Keep the board square with an 11-by-11 perimeter: 11 positions per edge when
  both corners are included and 40 unique spaces total.
- Treat landscape as the primary gameplay composition. Place the square board
  at the left at nearly the full available height and use a compact, scrollable
  operations rail at the right for players, actions, space details, and events.
- Retain a functional portrait composition for accessibility and device
  adaptability.
- The illustrated center is atmospheric only. Property names, ownership,
  mortgages, upgrades, tokens, dice, and controls must remain live UI rendered
  from game state.
- Do not lock the app to landscape-only without an explicit product decision;
  the adaptive portrait fallback remains supported.

## Visual Principles

- Use a top-down or high three-quarter view of a compact restaurant district.
- Favor a dense, lived-in district with varied building silhouettes, streets,
  landscaping, outdoor dining, delivery activity, and warm storefront light.
- Make every board space recognizable by position, group color, and pictogram.
- Keep game controls quiet and operational, inspired by order tickets and
  digital kitchen displays.
- Use varied original restaurant silhouettes and oversized generic food signs.
- Layer environmental detail inside the district while keeping buildings and
  interactive perimeter spaces readable at normal iPhone viewing size.
- Use subtle texture in illustrations only; keep controls and text crisp.
- Use original generic symbols. Do not reproduce real restaurant branding.
- Keep board-center raster art square, text-free, and free of baked-in game
  state, board borders, numbers, dice, pieces, or interface controls.

## Palette

The interface should balance off-white and charcoal neutrals with category
accents: tomato red, mustard yellow, aqua, leafy green, coral pink, cobalt blue,
brown, and light blue. Property-group colors must remain distinguishable under
common forms of color-vision deficiency, so color should always be paired with
a label or pictogram.

## Typography And UI

- Start with the system typeface for legibility and Dynamic Type support.
- Use condensed, sign-like lettering only in final illustrative signage.
- Keep cards at an 8-point corner radius or less.
- Use familiar icons for actions and provide accessibility labels.
- Do not imitate the layout, typography, deeds, cards, or corner artwork of any
  existing property-trading game.

## Placeholder Pieces

Initial player pieces may use a chef hat, takeout bag, receipt roll, and serving
tray. These are thematic placeholders rather than final character designs.
