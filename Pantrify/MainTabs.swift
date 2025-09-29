//
//  MainTabs.swift
//  Pantrify
//
//  Created by STUDENT on 9/23/25.
//

import Foundation
import SwiftUI
import SwiftData

struct MainTabs: View {
    let user: User
    let onLogout: () -> Void
    var body: some View {
        TabView {
            PantryView(user: user).tabItem { Label("Pantry", systemImage: "basket") }
            RecipesView(user: user).tabItem { Label("Recipes", systemImage: "book") }
            ProfileView(user: user, onLogout: onLogout)
                            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

