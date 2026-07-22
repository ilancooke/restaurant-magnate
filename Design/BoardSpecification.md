# Restaurant Magnate Board Specification

This document is the canonical prototype layout. It preserves the conventional
40-space economy and position sequence while using original working names and
restaurant-themed presentation. Card content remains intentionally undefined.

## Board Geometry

- The board is square with an 11-by-11 perimeter.
- Each side contains 11 positions when its two corners are included: nine
  non-corner spaces and ten movement steps from one corner to the next.
- The four corner positions are 0, 10, 20, and 30.
- Positions advance from 0 right-to-left along the bottom, bottom-to-top along
  the left, left-to-right along the top, and top-to-bottom along the right.
- The illustrated center and responsive gameplay shell are presentation only.
  They do not change space order, economy, legal actions, or state.

## Global Economy

- Starting cash: $1,500
- Grand Opening payment: $200 when reached or passed
- Franchise Tax: $200
- Spoiled Inventory Fee: $100
- Delivery service purchase price: $200; mortgage value: $100
- Delivery service rents for 1/2/3/4 owned: $25/$50/$100/$200
- Infrastructure purchase price: $150; mortgage value: $75
- Infrastructure rent: dice total times 4 when one is owned, times 10 when both
  are owned
- Restaurant groups: 8
- Ownable assets: 28 (22 restaurants, 4 delivery services, 2 infrastructure)

## Space Order

| # | Working name | Type | Group | Price |
|---:|---|---|---|---:|
| 0 | Grand Opening | Start | - | - |
| 1 | The Dollar Drive-Thru | Restaurant | Value/Budget | $60 |
| 2 | Secret Recipe | Event | - | - |
| 3 | Bargain Burger | Restaurant | Value/Budget | $60 |
| 4 | Franchise Tax | Tax | - | $200 |
| 5 | UberFeeds | Delivery service | - | $200 |
| 6 | McRonald's | Restaurant | Classic Burgers | $100 |
| 7 | Drive-Thru Order | Event | - | - |
| 8 | Wanda's Frosty Burgers | Restaurant | Classic Burgers | $100 |
| 9 | The King's Castle | Restaurant | Classic Burgers | $120 |
| 10 | Closed for Renovation / Just Visiting | Detention | - | - |
| 11 | Taco Chime | Restaurant | Tex-Mex | $140 |
| 12 | The Soda Fountain | Infrastructure | - | $150 |
| 13 | Del Rio Burrito | Restaurant | Tex-Mex | $140 |
| 14 | Nachos Locos | Restaurant | Tex-Mex | $160 |
| 15 | DoorDashers | Delivery service | - | $200 |
| 16 | Dixie Fried Chicken | Restaurant | Fried Chicken | $180 |
| 17 | Secret Recipe | Event | - | - |
| 18 | The Cluck Shack | Restaurant | Fried Chicken | $180 |
| 19 | Pollo Loco Hub | Restaurant | Fried Chicken | $200 |
| 20 | Staff Break | Neutral | - | - |
| 21 | Pizza Hutlet | Restaurant | Pizza Chains | $220 |
| 22 | Drive-Thru Order | Event | - | - |
| 23 | Domino's Brick Oven | Restaurant | Pizza Chains | $220 |
| 24 | Papa's Pizzeria | Restaurant | Pizza Chains | $240 |
| 25 | GrubGuzzlers | Delivery service | - | $200 |
| 26 | Underground Subs | Restaurant | Sandwiches & Cafes | $260 |
| 27 | Star-Buckets Coffee | Restaurant | Sandwiches & Cafes | $260 |
| 28 | The Deep Fryer | Infrastructure | - | $150 |
| 29 | Donut Hole | Restaurant | Sandwiches & Cafes | $280 |
| 30 | Health Inspector Shutdown | Send to detention | - | - |
| 31 | Apple-Beeswax Grill | Restaurant | Casual Dining/Grills | $300 |
| 32 | Chili's Pepper Shack | Restaurant | Casual Dining/Grills | $300 |
| 33 | Secret Recipe | Event | - | - |
| 34 | Olive Gardenia | Restaurant | Casual Dining/Grills | $320 |
| 35 | PostMates Express | Delivery service | - | $200 |
| 36 | Drive-Thru Order | Event | - | - |
| 37 | The Golden Steakhouse | Restaurant | High-End Franchises | $350 |
| 38 | Spoiled Inventory Fee | Tax | - | $100 |
| 39 | The Angus Prime Core | Restaurant | High-End Franchises | $400 |

## Restaurant Economics

Rents are listed as base, one upgrade, two upgrades, three upgrades, four
upgrades, and flagship. Owning an unimproved complete group doubles base rent.

| # | Price | Mortgage | Upgrade | Rent schedule |
|---:|---:|---:|---:|---|
| 1 | $60 | $30 | $50 | $2 / $10 / $30 / $90 / $160 / $250 |
| 3 | $60 | $30 | $50 | $4 / $20 / $60 / $180 / $320 / $450 |
| 6 | $100 | $50 | $50 | $6 / $30 / $90 / $270 / $400 / $550 |
| 8 | $100 | $50 | $50 | $6 / $30 / $90 / $270 / $400 / $550 |
| 9 | $120 | $60 | $50 | $8 / $40 / $100 / $300 / $450 / $600 |
| 11 | $140 | $70 | $100 | $10 / $50 / $150 / $450 / $625 / $750 |
| 13 | $140 | $70 | $100 | $10 / $50 / $150 / $450 / $625 / $750 |
| 14 | $160 | $80 | $100 | $12 / $60 / $180 / $500 / $700 / $900 |
| 16 | $180 | $90 | $100 | $14 / $70 / $200 / $550 / $750 / $950 |
| 18 | $180 | $90 | $100 | $14 / $70 / $200 / $550 / $750 / $950 |
| 19 | $200 | $100 | $100 | $16 / $80 / $220 / $600 / $800 / $1,000 |
| 21 | $220 | $110 | $150 | $18 / $90 / $250 / $700 / $875 / $1,050 |
| 23 | $220 | $110 | $150 | $18 / $90 / $250 / $700 / $875 / $1,050 |
| 24 | $240 | $120 | $150 | $20 / $100 / $300 / $750 / $925 / $1,100 |
| 26 | $260 | $130 | $150 | $22 / $110 / $330 / $800 / $975 / $1,150 |
| 27 | $260 | $130 | $150 | $22 / $110 / $330 / $800 / $975 / $1,150 |
| 29 | $280 | $140 | $150 | $24 / $120 / $360 / $850 / $1,025 / $1,200 |
| 31 | $300 | $150 | $200 | $26 / $130 / $390 / $900 / $1,100 / $1,275 |
| 32 | $300 | $150 | $200 | $26 / $130 / $390 / $900 / $1,100 / $1,275 |
| 34 | $320 | $160 | $200 | $28 / $150 / $450 / $1,000 / $1,200 / $1,400 |
| 37 | $350 | $175 | $200 | $35 / $175 / $500 / $1,100 / $1,300 / $1,500 |
| 39 | $400 | $200 | $200 | $50 / $200 / $600 / $1,400 / $1,700 / $2,000 |

## Deferred Content

- Drive-Thru Order card instructions
- Secret Recipe card instructions
- Final restaurant names and trademark clearance
- Final names and artwork for upgrades and flagship locations
