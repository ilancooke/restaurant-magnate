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
                    .stroke(RestaurantTheme.ink, lineWidth: 1.5)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityIdentifier("board-grid")
    }

    private var centerPanel: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(RestaurantTheme.tomato)
            Text("RESTAURANT")
                .font(.headline.weight(.black))
                .foregroundStyle(RestaurantTheme.ink)
            Text("MAGNATE")
                .font(.title3.weight(.black))
                .foregroundStyle(RestaurantTheme.tomato)
            if let roll = state.latestRoll {
                HStack(spacing: 8) {
                    DieView(value: roll.first)
                    DieView(value: roll.second)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RestaurantTheme.canvas)
    }

    private func players(at spaceID: BoardSpaceID) -> [Player] {
        state.players.filter { $0.position == spaceID && $0.status == .active }
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
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 1) {
            Rectangle()
                .fill(space.kind.accentColor)
                .frame(height: 4)

            HStack(spacing: 1) {
                Text("\(space.position)")
                    .font(.system(size: 7, weight: .bold))
                    .lineLimit(1)
                    .fixedSize()
                Spacer(minLength: 0)
                Image(systemName: space.kind.symbolName)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(RestaurantTheme.ink)
            .padding(.horizontal, 2)

            Spacer(minLength: 0)

            HStack(spacing: 2) {
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
        }
        .background(isSelected ? RestaurantTheme.mustard.opacity(0.22) : RestaurantTheme.surface)
        .overlay {
            Rectangle()
                .stroke(isSelected ? RestaurantTheme.ink : RestaurantTheme.line, lineWidth: isSelected ? 1.5 : 0.5)
        }
    }
}

private struct DieView: View {
    let value: Int

    var body: some View {
        Text("\(value)")
            .font(.headline.monospacedDigit())
            .frame(width: 34, height: 34)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(RestaurantTheme.ink, lineWidth: 1)
            }
            .accessibilityLabel("Die showing \(value)")
    }
}
