import SwiftUI

struct GameSetupView: View {
    @State private var playerCount = 2
    @State private var names = ["Maya", "Theo", "Jordan", "Casey"]
    @State private var tokens = PlayerToken.allCases
    let startGame: ([PlayerSetup]) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                title
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
        .background(RestaurantTheme.canvas)
        .navigationBarHidden(true)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(RestaurantTheme.tomato)
            Text("Restaurant Magnate")
                .font(.largeTitle.bold())
                .foregroundStyle(RestaurantTheme.ink)
                .accessibilityIdentifier("game-title")
            Text("LOCAL PASS & PLAY")
                .font(.caption.weight(.bold))
                .foregroundStyle(RestaurantTheme.secondaryInk)
        }
    }

    private var playerCountPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Players")
                .font(.headline)
            Picker("Player count", selection: $playerCount) {
                ForEach(2...4, id: \.self) { count in
                    Text("\(count)").tag(count)
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
                    Image(systemName: tokens[index].symbolName)
                        .font(.title3)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(RestaurantTheme.color(for: tokens[index]))

                    TextField("Player \(index + 1)", text: $names[index])
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .accessibilityIdentifier("player-name-\(index)")

                    Picker("Token", selection: $tokens[index]) {
                        ForEach(PlayerToken.allCases, id: \.self) { token in
                            Label(token.displayName, systemImage: token.symbolName)
                                .tag(token)
                        }
                    }
                    .labelsHidden()
                    .tint(RestaurantTheme.ink)
                }
                .padding(.vertical, 14)

                if index < playerCount - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 14)
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
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? RestaurantTheme.ink.opacity(0.8) : RestaurantTheme.ink)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
