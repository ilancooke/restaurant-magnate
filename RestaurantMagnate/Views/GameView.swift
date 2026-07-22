import SwiftUI

struct GameView: View {
    @Bindable var session: GameSession
    let newGame: () -> Void
    @State private var selectedSpaceID = BoardSpaceID(rawValue: 0)
    @State private var showNewGameConfirmation = false

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > proxy.size.height {
                landscapeLayout(in: proxy.size)
            } else {
                portraitLayout
            }
        }
        .background(RestaurantTheme.canvas)
        .toolbar(.hidden, for: .navigationBar)
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

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 0) {
                gameHeader

                VStack(spacing: 16) {
                    playerStrip
                    TurnControlPanel(session: session)
                    GameBoardView(state: session.state, selectedSpaceID: $selectedSpaceID)
                    selectedSpaceDetail
                    eventFeed
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
            }
        }
    }

    private func landscapeLayout(in size: CGSize) -> some View {
        let boardSide = min(size.height - 20, size.width * 0.52)

        return HStack(alignment: .center, spacing: 12) {
            GameBoardView(state: session.state, selectedSpaceID: $selectedSpaceID)
                .frame(width: boardSide, height: boardSide)

            ScrollView {
                VStack(spacing: 10) {
                    gameHeader
                    playerStrip
                    TurnControlPanel(session: session)
                    selectedSpaceDetail
                    eventFeed
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(10)
    }

    private var gameHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Rectangle()
                    .fill(RestaurantTheme.tomato)
                Image(systemName: "fork.knife")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
            }
            .frame(width: 38, height: 42)

            VStack(alignment: .leading, spacing: 0) {
                Text("RESTAURANT")
                    .foregroundStyle(.white)
                Text("MAGNATE")
                    .foregroundStyle(RestaurantTheme.coral)
            }
            .font(.system(size: 15, weight: .black, design: .rounded))
            .lineLimit(1)

            Spacer(minLength: 4)

            if let player = session.actingPlayer {
                Image(systemName: player.token.symbolName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RestaurantTheme.color(for: player.token))
                    .frame(width: 30, height: 30)
                    .background(.white.opacity(0.1))

                VStack(alignment: .trailing, spacing: 0) {
                    Text(player.name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("$\(player.cash.amount)")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(RestaurantTheme.mustard)
                }
            }

            Button {
                showNewGameConfirmation = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1))
            }
            .accessibilityLabel("Start new game")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(RestaurantTheme.asphalt)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RestaurantTheme.tomato)
                .frame(height: 3)
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
    }

    private var selectedSpaceDetail: some View {
        let space = session.state.board[selectedSpaceID.rawValue]
        return HStack(spacing: 0) {
            Rectangle()
                .fill(space.kind.accentColor)
                .frame(width: 7)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: space.kind.symbolName)
                        .foregroundStyle(space.kind.accentColor)
                    Text(space.name)
                        .font(RestaurantTheme.compactTitle)
                        .lineLimit(2)
                    Spacer()
                    Text("#\(space.position)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(RestaurantTheme.secondaryInk)
                }

                if case let .property(property) = space.kind {
                    HStack(spacing: 12) {
                        Label("$\(property.purchasePrice.amount)", systemImage: "tag.fill")
                        if let owner = session.ownerName(for: property.id) {
                            Label(owner, systemImage: "person.fill")
                            if session.state.propertyStates[property.id]?.isMortgaged == true {
                                Image(systemName: "lock.fill")
                                    .accessibilityLabel("Mortgaged")
                            }
                        } else {
                            Label("Bank", systemImage: "building.columns.fill")
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RestaurantTheme.secondaryInk)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RestaurantTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(RestaurantTheme.line, lineWidth: 1)
        }
    }

    private var eventFeed: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("RECENT ACTIVITY", systemImage: "list.bullet.rectangle")
                    .font(RestaurantTheme.compactTitle)
                Spacer()
                Image(systemName: "receipt")
                    .foregroundStyle(RestaurantTheme.tomato)
            }
            ForEach(Array(session.eventLog.suffix(4).enumerated()), id: \.offset) { _, message in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Circle()
                        .fill(RestaurantTheme.mustard)
                        .frame(width: 5, height: 5)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(RestaurantTheme.secondaryInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RestaurantTheme.paper)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(RestaurantTheme.tomato)
                .frame(width: 3)
        }
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
                .font(.subheadline.weight(.bold))
                .frame(width: 32, height: 32)
                .foregroundStyle(isActing ? .white : RestaurantTheme.color(for: player.token))
                .background(
                    RestaurantTheme.color(for: player.token).opacity(isActing ? 1 : 0.14)
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))

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
                    .foregroundStyle(isActing ? .white.opacity(0.72) : RestaurantTheme.secondaryInk)
                    .lineLimit(1)
                if player.status == .bankrupt {
                    Text("Bankrupt")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestaurantTheme.tomato)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .foregroundStyle(isActing ? .white : RestaurantTheme.ink)
        .background(isActing ? RestaurantTheme.asphalt : RestaurantTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActing ? RestaurantTheme.tomato : RestaurantTheme.line, lineWidth: isActing ? 3 : 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name), $\(player.cash.amount), \(propertyCount) locations")
        .opacity(player.status == .bankrupt ? 0.58 : 1)
    }
}

private struct TurnControlPanel: View {
    @Bindable var session: GameSession
    @State private var showAssetManagement = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(phaseTitle)
                        .font(RestaurantTheme.compactTitle)
                        .textCase(.uppercase)
                    if let actingPlayer = session.actingPlayer {
                        Text(actingPlayer.name)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.68))
                    }
                }
                Spacer()
                if let roll = session.state.latestRoll {
                    Text("\(roll.total)")
                        .font(.headline.bold().monospacedDigit())
                        .foregroundStyle(RestaurantTheme.ink)
                        .frame(width: 36, height: 30)
                        .background(RestaurantTheme.mustard)
                    .accessibilityLabel("Latest roll total \(roll.total)")
                }
            }

            controls

            if showsAssetManagementButton {
                Button {
                    showAssetManagement = true
                } label: {
                    Label("Manage Locations", systemImage: "building.2.crop.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .accessibilityIdentifier("manage-locations")
            }

            if let error = session.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(RestaurantTheme.coral)
            }
        }
        .padding(14)
        .foregroundStyle(.white)
        .background(RestaurantTheme.asphalt)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RestaurantTheme.tomato, lineWidth: 2)
        }
        .accessibilityIdentifier("turn-controls")
        .sheet(isPresented: $showAssetManagement) {
            AssetManagementView(session: session)
        }
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
            VStack(alignment: .leading, spacing: 12) {
                Label(
                    "Payment due: $\(debt.amount.amount)",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(RestaurantTheme.tomato)
                AssetManagementRows(session: session, onDark: true)
                bankruptcyButton
            }

        case .resolvingMortgageTransfer:
            if let property = session.transferredMortgageProperty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(property.name)
                        .font(.subheadline.weight(.semibold))

                    if let cost = session.transferredUnmortgageCost(for: property.id) {
                        actionButton(
                            "Pay $\(cost.amount) & Unmortgage",
                            icon: "lock.open.fill",
                            id: "unmortgage-transfer"
                        ) {
                            session.unmortgageTransferredProperty(property.id)
                        }
                    }
                    if let interest = session.transferredMortgageInterest(for: property.id) {
                        secondaryButton(
                            "Pay $\(interest.amount) Interest",
                            icon: "lock.fill",
                            id: "keep-transfer-mortgage"
                        ) {
                            session.keepTransferredMortgage(property.id)
                        }
                    }
                    AssetManagementRows(session: session, onDark: true)
                    bankruptcyButton
                }
            }

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
        case .resolvingMortgageTransfer: "Transferred Mortgage"
        case .gameOver: "Final Result"
        }
    }

    private var showsAssetManagementButton: Bool {
        guard !session.ownedProperties.isEmpty else {
            return false
        }
        switch session.state.phase {
        case .awaitingRoll, .awaitingPurchase, .awaitingEndTurn:
            return session.legalActions.contains { action in
                switch action {
                case .mortgageProperty, .unmortgageProperty:
                    return true
                default:
                    return false
                }
            }
        default:
            return false
        }
    }

    private var bankruptcyButton: some View {
        Button(role: .destructive) {
            session.declareBankruptcy()
        } label: {
            Label("Declare Bankruptcy", systemImage: "exclamationmark.octagon")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(RestaurantTheme.coral)
        .disabled(!session.canDeclareBankruptcy)
        .accessibilityIdentifier("declare-bankruptcy")
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

private struct AssetManagementView: View {
    @Bindable var session: GameSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if session.ownedProperties.isEmpty {
                    ContentUnavailableView(
                        "No Locations",
                        systemImage: "building.2"
                    )
                } else {
                    AssetManagementRows(session: session)
                }
            }
            .scrollContentBackground(.hidden)
            .background(RestaurantTheme.canvas)
            .navigationTitle("Manage Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct AssetManagementRows: View {
    @Bindable var session: GameSession
    var onDark = false

    var body: some View {
        ForEach(session.ownedProperties, id: \.id) { property in
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(property.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(onDark ? .white : RestaurantTheme.ink)
                    Text(status(for: property))
                        .font(.caption)
                        .foregroundStyle(onDark ? .white.opacity(0.66) : RestaurantTheme.secondaryInk)
                }
                Spacer(minLength: 8)
                if let proceeds = session.mortgageProceeds(for: property.id) {
                    Button("+$\(proceeds.amount)") {
                        session.mortgage(property.id)
                    }
                    .buttonStyle(.bordered)
                    .tint(onDark ? .white : RestaurantTheme.ink)
                    .accessibilityLabel("Mortgage \(property.name) for $\(proceeds.amount)")
                } else if let cost = session.unmortgageCost(for: property.id) {
                    Button("Pay $\(cost.amount)") {
                        session.unmortgage(property.id)
                    }
                    .buttonStyle(.bordered)
                    .tint(onDark ? .white : RestaurantTheme.ink)
                    .accessibilityLabel("Unmortgage \(property.name) for $\(cost.amount)")
                }
            }
            .padding(.vertical, onDark ? 3 : 0)
        }
    }

    private func status(for property: PropertyDefinition) -> String {
        if session.state.propertyStates[property.id]?.isMortgaged == true {
            return "Mortgaged · value $\(property.mortgageValue.amount)"
        }
        return "Mortgage value $\(property.mortgageValue.amount)"
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
                    .foregroundStyle(.white.opacity(0.68))
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
                        .background(RestaurantTheme.surface)
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
