//
//  ContentView.swift
//  RestaurantMagnate
//
//  Created by ilan on 7/18/26.
//

import SwiftUI

struct ContentView: View {
    @State private var session: GameSession?

    var body: some View {
        NavigationStack {
            if let session {
                GameView(session: session) {
                    self.session = nil
                }
            } else {
                GameSetupView { players in
                    self.session = try? GameSession(players: players)
                }
            }
        }
        .tint(RestaurantTheme.tomato)
    }
}

#Preview {
    ContentView()
}
