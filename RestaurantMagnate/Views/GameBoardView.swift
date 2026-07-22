import SwiftUI

struct GameBoardView: View {
    let state: GameState
    @Binding var selectedSpaceID: BoardSpaceID

    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width
            let cell = side / 11

            ZStack(alignment: .topLeading) {
                RestaurantTheme.surface

                centerPanel
                    .frame(width: cell * 9, height: cell * 9)
                    .offset(x: cell, y: cell)

                ForEach(state.board.spaces, id: \.id) { space in
                    BoardSpaceCell(
                        space: space,
                        players: players(at: space.id),
                        ownerColor: ownerColor(for: space),
                        isMortgaged: isMortgaged(space),
                        isSelected: selectedSpaceID == space.id
                    )
                    .frame(width: cell, height: cell)
                    .offset(
                        x: CGFloat(coordinate(for: space.position).column) * cell,
                        y: CGFloat(coordinate(for: space.position).row) * cell
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSpaceID = space.id
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Space \(space.position), \(space.name)")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .overlay {
                Rectangle()
                    .stroke(RestaurantTheme.ink, lineWidth: 3)
            }
            .shadow(color: RestaurantTheme.ink.opacity(0.22), radius: 3, y: 4)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityIdentifier("board-grid")
    }

    private var centerPanel: some View {
        ZStack {
            Image("RestaurantDistrict")
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    RestaurantTheme.asphalt.opacity(0.42),
                    .clear,
                    RestaurantTheme.asphalt.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.multiply)

            VStack(spacing: 5) {
                Image(systemName: "fork.knife")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                Text("RESTAURANT")
                    .foregroundStyle(.white)
                Text("MAGNATE")
                    .foregroundStyle(RestaurantTheme.coral)
            }
            .font(.system(size: 9, weight: .black, design: .rounded))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(RestaurantTheme.asphalt.opacity(0.9))
            .overlay {
                Rectangle()
                    .stroke(RestaurantTheme.mustard, lineWidth: 1.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(8)

            if let roll = state.latestRoll {
                HStack(spacing: 8) {
                    DieView(value: roll.first)
                    DieView(value: roll.second)
                }
                .padding(6)
                .background(RestaurantTheme.asphalt.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private func players(at spaceID: BoardSpaceID) -> [Player] {
        state.players.filter { $0.position == spaceID && $0.status == .active }
    }

    private func ownerColor(for space: BoardSpace) -> Color? {
        guard case let .property(property) = space.kind,
              let ownerID = state.propertyStates[property.id]?.ownerID,
              let owner = state.players.first(where: { $0.id == ownerID }) else {
            return nil
        }
        return RestaurantTheme.color(for: owner.token)
    }

    private func isMortgaged(_ space: BoardSpace) -> Bool {
        guard case let .property(property) = space.kind else {
            return false
        }
        return state.propertyStates[property.id]?.isMortgaged == true
    }

    private func coordinate(for position: Int) -> (row: Int, column: Int) {
        switch position {
        case 0...10:
            return (10, 10 - position)
        case 11...20:
            return (20 - position, 0)
        case 21...30:
            return (0, position - 20)
        default:
            return (position - 30, 10)
        }
    }
}

private struct BoardSpaceCell: View {
    let space: BoardSpace
    let players: [Player]
    let ownerColor: Color?
    let isMortgaged: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 1) {
                Text("\(space.position)")
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .fixedSize()
                Spacer(minLength: 0)
                if isMortgaged {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 6, weight: .black))
                }
            }
            .padding(.horizontal, 3)
            .padding(.top, 2)

            Image(systemName: space.kind.symbolName)
                .font(.system(size: 11, weight: .bold))
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 2) {
                if let ownerColor {
                    Rectangle()
                        .fill(ownerColor)
                        .frame(width: 8, height: 4)
                        .overlay {
                            Rectangle().stroke(.white, lineWidth: 0.5)
                        }
                }
                ForEach(players, id: \.id) { player in
                    Circle()
                        .fill(RestaurantTheme.color(for: player.token))
                        .frame(width: 6, height: 6)
                        .overlay {
                            Circle().stroke(.white, lineWidth: 0.75)
                        }
                }
            }
            .frame(height: 8)
            .padding(.bottom, 1)
        }
        .foregroundStyle(space.kind.boardForeground)
        .background(space.kind.boardFill)
        .saturation(isMortgaged ? 0.12 : 1)
        .overlay {
            Rectangle()
                .stroke(
                    isSelected ? RestaurantTheme.mustard : RestaurantTheme.ink.opacity(0.7),
                    lineWidth: isSelected ? 2.5 : 0.75
                )
        }
    }
}

private struct DieView: View {
    let value: Int

    var body: some View {
        GeometryReader { proxy in
            ForEach(pipPositions, id: \.self) { position in
                Circle()
                    .fill(RestaurantTheme.ink)
                    .frame(width: 6, height: 6)
                    .position(
                        x: proxy.size.width * position.x,
                        y: proxy.size.height * position.y
                    )
            }
        }
        .frame(width: 34, height: 34)
        .background(RestaurantTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(RestaurantTheme.ink, lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.18), radius: 2, y: 2)
            .accessibilityLabel("Die showing \(value)")
    }

    private var pipPositions: [UnitPoint] {
        let positions: [UnitPoint]
        switch value {
        case 1: positions = [.center]
        case 2: positions = [.topLeading, .bottomTrailing]
        case 3: positions = [.topLeading, .center, .bottomTrailing]
        case 4: positions = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]
        case 5: positions = [.topLeading, .topTrailing, .center, .bottomLeading, .bottomTrailing]
        default: positions = [
            .topLeading, .topTrailing,
            UnitPoint(x: 0, y: 0.5), UnitPoint(x: 1, y: 0.5),
            .bottomLeading, .bottomTrailing
        ]
        }
        return positions.map {
            UnitPoint(x: 0.22 + ($0.x * 0.56), y: 0.22 + ($0.y * 0.56))
        }
    }
}
