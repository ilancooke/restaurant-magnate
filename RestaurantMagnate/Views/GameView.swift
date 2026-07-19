import SwiftUI

struct GameView: View {
    @Bindable var session: GameSession
    let newGame: () -> Void
    @State private var selectedSpaceID = BoardSpaceID(rawValue: 0)
    @State private var showNewGameConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                playerStrip
                TurnControlPanel(session: session)
                GameBoardView(state: session.state, selectedSpaceID: $selectedSpaceID)
                selectedSpaceDetail
                eventFeed
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 28)
        }
        .background(RestaurantTheme.canvas)
        .navigationTitle("Restaurant Magnate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewGameConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("Start new game")
            }
        }
        .confirmationDialog(
            "Start a new game?",
            isPresented: $showNewGameConfirmation,
            titleVisibility: .visible
        ) {
            Button("New Game", role: .destructive, action: newGame)
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: session.currentPlayer?.position) { _, newPosition in
            if let newPosition {
                selectedSpaceID = newPosition
            }
        }
    }

    private var playerStrip: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(session.state.players, id: \.id) { player in
                PlayerSummaryView(
                    player: player,
                    propertyCount: session.state.propertyStates.values.filter {
                        $0.ownerID == player.id
                    }.count,
                    isActing: session.actingPlayer?.id == player.id
                )
            }
        }
        .padding(.top, 10)
    }

    private var selectedSpaceDetail: some View {
        let space = session.state.board[selectedSpaceID.rawValue]
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: space.kind.symbolName)
                    .foregroundStyle(space.kind.accentColor)
                Text(space.name)
                    .font(.headline)
                Spacer()
                Text("#\(space.position)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(RestaurantTheme.secondaryInk)
            }

            if case let .property(property) = space.kind {
                HStack {
                    Text("Price $\(property.purchasePrice.amount)")
                    if let owner = session.ownerName(for: property.id) {
                        Text("Owned by \(owner)")
                    } else {
                        Text("Bank owned")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(RestaurantTheme.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    private var eventFeed: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recent Activity", systemImage: "list.bullet.rectangle")
                .font(.headline)
            ForEach(Array(session.eventLog.suffix(4).enumerated()), id: \.offset) { _, message in
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(RestaurantTheme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .accessibilityIdentifier("event-feed")
    }
}

private struct PlayerSummaryView: View {
    let player: Player
    let propertyCount: Int
    let isActing: Bool

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: player.token.symbolName)
                .frame(width: 28, height: 28)
                .foregroundStyle(RestaurantTheme.color(for: player.token))
                .background(RestaurantTheme.color(for: player.token).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(player.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if player.detention != nil {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.caption2)
                    }
                }
                Text("$\(player.cash.amount) · \(propertyCount) sites")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(RestaurantTheme.secondaryInk)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .background(RestaurantTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActing ? RestaurantTheme.tomato : RestaurantTheme.line, lineWidth: isActing ? 2 : 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name), $\(player.cash.amount), \(propertyCount) locations")
    }
}

private struct TurnControlPanel: View {
    @Bindable var session: GameSession

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(phaseTitle)
                        .font(.headline)
                    if let actingPlayer = session.actingPlayer {
                        Text(actingPlayer.name)
                            .font(.subheadline)
                            .foregroundStyle(RestaurantTheme.secondaryInk)
                    }
                }
                Spacer()
                if let roll = session.state.latestRoll {
                    Text("\(roll.total)")
                        .font(.title2.bold().monospacedDigit())
                        .accessibilityLabel("Latest roll total \(roll.total)")
                }
            }

            controls

            if let error = session.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(RestaurantTheme.tomato)
            }
        }
        .padding(14)
        .background(RestaurantTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RestaurantTheme.line, lineWidth: 1)
        }
        .accessibilityIdentifier("turn-controls")
    }

    @ViewBuilder
    private var controls: some View {
        switch session.state.phase {
        case .openingRoll, .awaitingRoll:
            HStack(spacing: 10) {
                if session.canRoll {
                    actionButton("Roll Dice", icon: "dice.fill", id: "roll-dice") {
                        session.rollDice()
                    }
                }
                if session.canPayDetentionFee {
                    secondaryButton("Pay $50", icon: "banknote", id: "pay-detention") {
                        session.payDetentionFee()
                    }
                }
            }

        case .awaitingPurchase:
            if let property = session.offeredProperty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(property.name) · $\(property.purchasePrice.amount)")
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 10) {
                        if session.legalActions.contains(.buyProperty(property.id)) {
                            actionButton("Buy", icon: "cart.fill", id: "buy-property") {
                                session.buyOfferedProperty()
                            }
                        }
                        secondaryButton("Auction", icon: "gavel.fill", id: "decline-purchase") {
                            session.declineOfferedProperty()
                        }
                    }
                }
            }

        case .awaitingAuction:
            AuctionControls(session: session)

        case .awaitingEndTurn:
            actionButton("End Turn", icon: "arrow.right.circle.fill", id: "end-turn") {
                session.endTurn()
            }

        case let .resolvingDebt(debt):
            Label(
                "Payment due: $\(debt.amount.amount)",
                systemImage: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(RestaurantTheme.tomato)

        case let .gameOver(winnerID):
            Label("\(session.playerName(winnerID)) wins", systemImage: "trophy.fill")
                .foregroundStyle(RestaurantTheme.mustard)

        case .resolvingLanding:
            ProgressView()
        }
    }

    private var phaseTitle: String {
        switch session.state.phase {
        case .openingRoll: "Opening Roll"
        case .awaitingRoll: session.actingPlayer?.detention == nil ? "Ready to Roll" : "Closed for Renovation"
        case .resolvingLanding: "Resolving Stop"
        case .awaitingPurchase: "Available Location"
        case .awaitingAuction: "Location Auction"
        case .awaitingEndTurn: "Turn Complete"
        case .resolvingDebt: "Outstanding Payment"
        case .gameOver: "Final Result"
        }
    }

    private func actionButton(
        _ title: String,
        icon: String,
        id: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .accessibilityIdentifier(id)
    }

    private func secondaryButton(
        _ title: String,
        icon: String,
        id: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RestaurantTheme.surface)
                .foregroundStyle(RestaurantTheme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RestaurantTheme.ink, lineWidth: 1)
                }
        }
        .accessibilityIdentifier(id)
    }
}

private struct AuctionControls: View {
    @Bindable var session: GameSession
    @State private var bidAmount = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let property = session.auctionProperty {
                Text(property.name)
                    .font(.subheadline.weight(.semibold))
            }
            if let highBid = session.state.auction?.highBid {
                Text("High bid $\(highBid.amount.amount) · \(session.playerName(highBid.bidderID))")
                    .font(.subheadline)
                    .foregroundStyle(RestaurantTheme.secondaryInk)
            }

            if canBid {
                Stepper(value: $bidAmount, in: minimumBid...maximumBid, step: 1) {
                    Text("Bid $\(bidAmount)")
                        .font(.headline.monospacedDigit())
                }
            }

            HStack(spacing: 10) {
                if canBid {
                    Button {
                        session.placeAuctionBid(bidAmount)
                    } label: {
                        Label("Bid", systemImage: "gavel.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .accessibilityIdentifier("auction-bid")
                }

                Button {
                    session.withdrawFromAuction()
                } label: {
                    Label("Withdraw", systemImage: "xmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RestaurantTheme.ink, lineWidth: 1)
                        }
                }
                .foregroundStyle(RestaurantTheme.ink)
                .accessibilityIdentifier("auction-withdraw")
            }
        }
        .onAppear {
            bidAmount = minimumBid
        }
        .onChange(of: minimumBid) { _, newValue in
            bidAmount = newValue
        }
    }

    private var minimumBid: Int {
        session.minimumAuctionBid?.amount ?? 1
    }

    private var maximumBid: Int {
        max(minimumBid, session.actingPlayer?.cash.amount ?? minimumBid)
    }

    private var canBid: Bool {
        session.legalActions.contains { action in
            if case .placeAuctionBid = action {
                return true
            }
            return false
        }
    }
}
