//
//  RecipeView.swift
//  Pantrify
//
//  Created by STUDENT on 8/28/25.
//

import Foundation
import SwiftUI
import SwiftData

enum RecipeCategory: String, CaseIterable, Identifiable {
    case all = "All", breakfast = "Breakfast", lunch = "Lunch", dinner = "Dinner", quick = "Quick & Easy"
    var id: String { rawValue }
    var tagKey: String? { self == .all ? nil : rawValue }
}

struct RecipesView: View {
    @Environment(\.modelContext) private var context
    let user: User
    @Query private var allRecipes: [Recipe]
    @Query private var allIngredients: [Ingredient]
    init(user: User) { self.user = user }
    
    @State private var showAdd = false
    @State private var selected: RecipeCategory = .all

    private var recipes: [Recipe] { allRecipes
        .filter { $0.addedBy?.username == user.username}
        .sorted { $0.createdAt > $1.createdAt}
    }
    
    private var pantry: [Ingredient] {
        allIngredients.filter { $0.owner?.username == user.username }
    }
    
    private var pantryKeys: Set<String> { Set(pantry.map { $0.normalized }) }
    private func score(_ r: Recipe) -> (ready: Bool, have: Int, total: Int) {
        let have = r.ingredientNames.filter { pantryKeys.contains($0) }.count
        return (have == r.ingredientNames.count, have, r.ingredientNames.count)
    }
    private var filteredSorted: [Recipe] {
        let base = recipes.filter { r in
            guard let key = selected.tagKey else { return true }
            return r.tags.map { $0.lowercased() }.contains(key.lowercased())
        }
        return base.sorted {
            let a = score($0), b = score($1)
            if a.ready != b.ready { return a.ready && !b.ready }
            if a.have != b.have { return a.have > b.have }
            return $0.title < $1.title
        }
    }
    private var readyCount: Int { recipes.filter { score($0).ready }.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                MintCard(
                    title: "Recipe Collection",
                    subtitle: "\(readyCount) Ready • \(recipes.count) Total",
                    trailing: AnyView(
                        Button {
                            showAdd = true
                        } label: {
                            HStack { Image(systemName: "plus.circle.fill"); Text("Add Recipes") }
                        }.buttonStyle(MintButtonStyle())
                    )
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(RecipeCategory.allCases) { cat in
                                let selectedNow = selected == cat
                                Button { selected = cat } label: { Text(cat.rawValue) }
                                    .buttonStyle(.plain)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Capsule().fill(selectedNow ? Color.pantrifyMint.opacity(0.18) : Color.surface))
                                    .overlay(Capsule().stroke(selectedNow ? Color.pantrifyMint : Color.outline.opacity(0.4), lineWidth: 1))
                                    .foregroundStyle(selectedNow ? Color.mintyDim : .primary)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal)

                if recipes.isEmpty {
                    ContentUnavailableView("No recipes yet", systemImage: "book",
                        description: Text("Tap **Add Recipes** to import from the web."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredSorted) { r in
                            NavigationLink { RecipeDetailView(recipe: r, pantryKeys: pantryKeys) } label: {
                                RecipeRow(recipe: r, pantryKeys: pantryKeys)
                            }
                        }
                        .onDelete { $0.map { filteredSorted[$0] }.forEach(context.delete) }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Recipes")
            .sheet(isPresented: $showAdd) { AddRecipesView(user: user) }
        }
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    let pantryKeys: Set<String>
    var have: Int { recipe.ingredientNames.filter { pantryKeys.contains($0) }.count }
    var missing: Int { recipe.ingredientNames.count - have }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(recipe.title).font(.headline)
                Spacer()
                if missing == 0 { TagChip(text: "Ready", systemImage: "checkmark.seal.fill") }
                else { TagChip(text: "Not Ready", systemImage: "exclamationmark.triangle.fill", tint: .orange) }
            }

            if missing > 0 {
                Text("Missing \(missing) ingredients:").font(.subheadline).foregroundStyle(.secondary)
                let miss = zip(recipe.ingredientNames, recipe.displayIngredients)
                    .filter { !pantryKeys.contains($0.0) }.map { $0.1 }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(miss.prefix(6), id: \.self) {
                            TagChip(text: $0, systemImage: nil, tint: .red, filled: true)
                        }
                    }
                }
            }

            if !recipe.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recipe.tags, id: \.self) { TagChip(text: $0, systemImage: nil, tint: .mintyDim, filled: true) }
                    }
                }.padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}

struct RecipeDetailView: View {
    @Environment(\.openURL) private var openURL
    let recipe: Recipe
    let pantryKeys: Set<String>
    
    private struct Item: Identifiable {
        let id = UUID()
        let key: String
        let display: String
        let available: Bool
    }
    
    private var items: [Item] {
        zip(recipe.ingredientNames, recipe.displayIngredients).map { k, d in Item(key: k, display: d, available: pantryKeys.contains(k)) }
    }
    
    private var missingDisplays: [String]{
        items.filter { !$0.available }.map { $0.display }
    }
    
    private var isReady: Bool {
        missingDisplays.isEmpty
    }
    var body: some View {
           ScrollView {
               VStack(spacing: 16) {
                   header
                   if !recipe.tags.isEmpty { tagsRow }
                   missingSection
                   ingredientsSection
                   instructionsSection
               }
               .padding()
           }
           .navigationBarTitleDisplayMode(.inline)
       }

       // MARK: Header

       @ViewBuilder private var header: some View {
           HStack(alignment: .top) {
               VStack(alignment: .leading, spacing: 6) {
                   Text(recipe.title).font(.title3.weight(.bold))
                   MetaRow(time: recipe.cookTimeMinutes,
                           servings: recipe.servings,
                           difficulty: recipe.difficulty)
               }
               Spacer()
               StatusBadge(ready: isReady)
           }
       }

       // MARK: Tags

       @ViewBuilder private var tagsRow: some View {
           ScrollView(.horizontal, showsIndicators: false) {
               HStack(spacing: 8) {
                   ForEach(recipe.tags, id: \.self) {
                       TagChip(text: $0, systemImage: nil, tint: .mintyDim, filled: true)
                   }
               }
           }
       }

       // MARK: Missing section

       @ViewBuilder private var missingSection: some View {
           GroupBox {
               if isReady {
                   Text("All ingredients available.")
                       .frame(maxWidth: .infinity, alignment: .leading)
               } else {
                   VStack(alignment: .leading, spacing: 8) {
                       Text("Missing \(missingDisplays.count) ingredients").font(.headline)
                       ChipsGrid(labels: missingDisplays)
                   }
               }
           }
       }

       // MARK: Ingredients section

       @ViewBuilder private var ingredientsSection: some View {
           GroupBox {
               VStack(alignment: .leading, spacing: 8) {
                   Text("Ingredients").font(.headline)
                   ForEach(items) { item in
                       HStack {
                           Image(systemName: item.available ? "leaf.fill" : "leaf")
                               .foregroundStyle(item.available ? .mint : .secondary)
                           Text(item.display)
                           Spacer()
                           if item.available {
                               TagChip(text: "Available", systemImage: "checkmark", tint: .pantrifyMint, filled: true)
                           } else {
                               TagChip(text: "Missing", systemImage: "exclamationmark.triangle.fill", tint: .orange, filled: true)
                           }
                       }
                       .padding(.vertical, 2)
                   }
               }
           }
       }

       // MARK: Instructions

       @ViewBuilder private var instructionsSection: some View {
           GroupBox {
               VStack(alignment: .leading, spacing: 12) {
                   Text("Cooking Instructions").font(.headline)
                   // Pre-map to a typed sequence so the type checker doesn't choke
                   ForEach(Array(recipe.instructions.enumerated()).map { (index: $0.offset, text: $0.element) },
                           id: \.index) { step in
                       StepRow(number: step.index + 1, text: step.text)
                   }
                   if let s = recipe.sourceURL, let url = URL(string: s) {
                       Button("View Source") { openURL(url) }
                           .buttonStyle(.bordered)
                   }
               }
           }
       }
   }

   // MARK: - Small, typed subviews

   private struct MetaRow: View {
       var time: Int?
       var servings: Int?
       var difficulty: String?
       var body: some View {
           HStack(spacing: 14) {
               if let time { Label("\(time) min", systemImage: "clock") }
               if let servings { Label("\(servings) servings", systemImage: "person.2") }
               if let difficulty { Label(difficulty, systemImage: "bolt.badge.a") }
           }
           .foregroundStyle(.secondary)
           .font(.footnote)
       }
   }

   private struct StatusBadge: View {
       var ready: Bool
       var body: some View {
           if ready {
               TagChip(text: "Ready to Cook", systemImage: "checkmark.seal.fill")
           } else {
               TagChip(text: "Missing Ingredients", systemImage: "exclamationmark.triangle.fill", tint: .orange)
           }
       }
   }

   private struct StepRow: View {
       let number: Int
       let text: String
       var body: some View {
           HStack(alignment: .top, spacing: 12) {
               ZStack {
                   Circle().fill(Color.pantrifyMint.opacity(0.15)).frame(width: 28, height: 28)
                   Text("\(number)").font(.callout.weight(.bold)).foregroundStyle(.mint)
               }
               Text(text)
           }
       }
   }

   private struct ChipsGrid: View {
       let labels: [String]
       private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]
       var body: some View {
           LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
               ForEach(labels, id: \.self) { label in
                   TagChip(text: label, systemImage: nil, tint: .red, filled: true)
               }
           }
       }
   }
