import SwiftUI

struct GameSetupView: View {
    @State private var playerCount = 2
    @State private var names = ["Maya", "Theo", "Jordan", "Casey"]
    @State private var tokens = PlayerToken.allCases
    let startGame: ([PlayerSetup]) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                brandHeader

                VStack(alignment: .leading, spacing: 22) {
                    playerCountPicker
                    playerEditors

                    Button(action: beginGame) {
                        Label("Start Opening Rolls", systemImage: "dice.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(!canStart)
                    .accessibilityIdentifier("setup-start")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .background(RestaurantTheme.canvas)
        .navigationBarHidden(true)
    }

    private var brandHeader: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(RestaurantTheme.tomato)
                Image(systemName: "fork.knife")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 0) {
                Text("RESTAURANT")
                    .foregroundStyle(.white)
                Text("MAGNATE")
                    .foregroundStyle(RestaurantTheme.coral)
            }
            .font(.system(size: 27, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Image(systemName: "building.2.fill")
                .font(.title2)
                .foregroundStyle(RestaurantTheme.mustard)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 24)
        .background(RestaurantTheme.asphalt)
        .overlay(alignment: .bottom) {
            HStack(spacing: 0) {
                RestaurantTheme.tomato
                RestaurantTheme.mustard
                RestaurantTheme.aqua
                RestaurantTheme.leaf
                RestaurantTheme.cobalt
            }
            .frame(height: 5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Restaurant Magnate")
        .accessibilityIdentifier("game-title")
    }

    private var sectionHeading: some View {
        HStack {
            Text("GAME SETUP")
                .font(RestaurantTheme.sectionTitle)
                .foregroundStyle(RestaurantTheme.ink)
            Spacer()
            Text("LOCAL PASS & PLAY")
                .font(.caption.weight(.bold))
                .foregroundStyle(RestaurantTheme.secondaryInk)
        }
    }

    private var playerCountPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading
            Picker("Player count", selection: $playerCount) {
                ForEach(2...4, id: \.self) { count in
                    Text("\(count) PLAYERS").tag(count)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("player-count")
        }
    }

    private var playerEditors: some View {
        VStack(spacing: 0) {
            ForEach(0..<playerCount, id: \.self) { index in
                HStack(spacing: 12) {
                    ZStack {
                        Rectangle()
                            .fill(RestaurantTheme.color(for: tokens[index]))
                        VStack(spacing: 2) {
                            Text("\(index + 1)")
                                .font(.caption2.bold().monospacedDigit())
                            Image(systemName: tokens[index].symbolName)
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                    }
                    .frame(width: 46, height: 50)

                    TextField("Player \(index + 1)", text: $names[index])
                        .font(.body.weight(.semibold))
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .accessibilityIdentifier("player-name-\(index)")

                    Menu {
                        ForEach(PlayerToken.allCases, id: \.self) { token in
                            Button {
                                tokens[index] = token
                            } label: {
                                Label(token.displayName, systemImage: token.symbolName)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RestaurantTheme.ink)
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Choose token for player \(index + 1)")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                if index < playerCount - 1 {
                    Divider()
                        .padding(.leading, 70)
                }
            }
        }
        .background(RestaurantTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RestaurantTheme.line, lineWidth: 1)
        }
    }

    private var canStart: Bool {
        let activeNames = names.prefix(playerCount).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        let activeTokens = Array(tokens.prefix(playerCount))
        return activeNames.allSatisfy { !$0.isEmpty }
            && Set(activeNames).count == playerCount
            && Set(activeTokens).count == playerCount
    }

    private func beginGame() {
        let setups = (0..<playerCount).map { index in
            PlayerSetup(name: names[index], token: tokens[index])
        }
        startGame(setups)
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.black))
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .background(configuration.isPressed ? RestaurantTheme.coral : RestaurantTheme.tomato)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(RestaurantTheme.ink, lineWidth: 1.5)
            }
            .shadow(
                color: RestaurantTheme.ink.opacity(configuration.isPressed ? 0 : 0.22),
                radius: 3,
                y: configuration.isPressed ? 0 : 3
            )
            .offset(y: configuration.isPressed ? 2 : 0)
    }
}
