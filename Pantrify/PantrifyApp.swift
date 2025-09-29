//
//  PantrifyApp.swift
//  Pantrify
//
//  Created by STUDENT on 8/28/25.
//

import SwiftUI
import SwiftData

@main
struct PantrifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.pantrifyMint)
        }
        .modelContainer(for: [User.self, Ingredient.self, Recipe.self])
    }
}
