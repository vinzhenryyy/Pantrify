//
//  AddRecipesView.swift
//  Pantrify
//
//  Created by STUDENT on 8/28/25.
//

import Foundation
import SwiftUI
import SwiftData

struct AddRecipesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let user: User
    @State private var query = ""
    @State private var results: [WebRecipe] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var autoFilterToPantry = true
    @Query private var allIngredients: [Ingredient]
    init(user: User) { self.user = user }
    
    private var pantry: [Ingredient] {
        allIngredients.filter { $0.owner?.username == user.username }
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    TextField("Search online recipes (e.g., pancakes, pasta)", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { search() }
                    Button { search() } label: { Image(systemName: "magnifyingglass") }
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                Toggle("Prioritize matches to my pantry", isOn: $autoFilterToPantry)
                    .padding(.horizontal)

                if isLoading { ProgressView("Searching…").padding() }
                if let error { Text(error).foregroundStyle(.red).padding(.horizontal) }

                List(results) { wr in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(wr.title).font(.headline)
                            Spacer()
                            let ready = wr.missingCount(pantry: pantry.map { $0.normalized }) == 0
                            TagChip(text: wr.matchBadge(pantry: pantry.map { $0.normalized }),
                                    systemImage: ready ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                                    tint: ready ? .pantrifyMint : .orange)
                        }
                        Text(wr.missingSummary(pantry: pantry.map{ $0.normalized }))
                            .font(.footnote).foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack { ForEach(wr.tags.prefix(5), id: \.self) { TagChip(text: $0, systemImage: nil) } }
                        }
                        HStack {
                            Button("Add to My Recipes") {
                                let r = Recipe(
                                    title: wr.title,
                                    ingredients: wr.ingredients,
                                    instructions: wr.instructions,
                                    tags: wr.tags,
                                    sourceURL: wr.sourceURL,
                                    addedBy: user
                                )
                                context.insert(r); try? context.save()
                            }
                            .buttonStyle(.borderedProminent).tint(.pantrifyMint)
                            Spacer()
                            if let url = wr.sourceURL, let u = URL(string: url) {
                                Link("Open", destination: u).font(.footnote)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Recipes")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private func search() {
        Task {
            isLoading = true; error = nil
            do {
                let raw = try await MealDB.searchMeals(query: query)
                let expanded = try await MealDB.expandMeals(raw)
                let pantryKeys = Set(pantry.map { $0.normalized })
                var mapped = expanded.map { WebRecipe(meal: $0) }
                if autoFilterToPantry {
                    mapped.sort { lhs, rhs in
                        let a = lhs.matchScore(pantry: pantryKeys)
                        let b = rhs.matchScore(pantry: pantryKeys)
                        if a.ready != b.ready { return a.ready && !b.ready }
                        return a.have > b.have
                    }
                }
                results = mapped
            } catch {
                self.error = "Couldn't fetch recipes. Please try again."
            }
            isLoading = false
        }
    }
}

struct WebRecipe: Identifiable {
    let id: String
    let title: String
    let ingredients: [String]
    let instructions: [String]
    let tags: [String]
    let sourceURL: String?
    init(meal: MealDB.Meal) {
        id = meal.idMeal
        title = meal.strMeal
        ingredients = meal.ingredients
        instructions = meal.instructionsArray
        tags = meal.tags
        sourceURL = meal.strSource ?? meal.strYoutube
    }
    func missingCount(pantry: [String]) -> Int {
        let keys = ingredients.map { IngredientName.normalize($0).key }
        let pset = Set(pantry)
        return keys.filter { !pset.contains($0) }.count
    }
    func matchScore(pantry: Set<String>) -> (ready: Bool, have: Int) {
        let keys = ingredients.map { IngredientName.normalize($0).key }
        let have = keys.filter { pantry.contains($0) }.count
        return (have == keys.count, have)
    }
    func matchBadge(pantry: [String]) -> String {
        let missing = missingCount(pantry: pantry)
        return missing == 0 ? "Ready to Cook" : "Missing \(missing)"
    }
    func missingSummary(pantry: [String]) -> String {
        let pset = Set(pantry)
        let miss = ingredients.filter { !pset.contains(IngredientName.normalize($0).key) }
        guard !miss.isEmpty else { return "All ingredients available." }
        return "Missing \(miss.prefix(6).map { IngredientName.normalize($0).display }.localizedJoin)\(miss.count > 6 ? " …" : "")"
    }
}

// Minimal TheMealDB client (HTTPS)
enum MealDB {
    struct SearchResponse: Decodable { let meals: [Meal]? }
    struct Meal: Decodable, Identifiable {
        var id: String { idMeal }
        let idMeal: String
        let strMeal: String
        let strInstructions: String?
        let strSource: String?
        let strYoutube: String?
        let strTags: String?
        // ingredients 1...20
        let strIngredient1: String?;  let strIngredient2: String?;  let strIngredient3: String?
        let strIngredient4: String?;  let strIngredient5: String?;  let strIngredient6: String?
        let strIngredient7: String?;  let strIngredient8: String?;  let strIngredient9: String?
        let strIngredient10: String?; let strIngredient11: String?; let strIngredient12: String?
        let strIngredient13: String?; let strIngredient14: String?; let strIngredient15: String?
        let strIngredient16: String?; let strIngredient17: String?; let strIngredient18: String?
        let strIngredient19: String?; let strIngredient20: String?

        var ingredients: [String] {
            [
                strIngredient1, strIngredient2, strIngredient3, strIngredient4, strIngredient5,
                strIngredient6, strIngredient7, strIngredient8, strIngredient9, strIngredient10,
                strIngredient11, strIngredient12, strIngredient13, strIngredient14, strIngredient15,
                strIngredient16, strIngredient17, strIngredient18, strIngredient19, strIngredient20
            ]
                .compactMap { $0 }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        var instructionsArray: [String] {
            (strInstructions ?? "")
                .replacingOccurrences(of: "\r", with: "")
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        var tags: [String] {
            (strTags ?? "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
    }

    static func searchMeals(query: String) async throws -> [Meal] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlStr: String = q.isEmpty
        ? "https://www.themealdb.com/api/json/v1/1/search.php?s=a"
        : "https://www.themealdb.com/api/json/v1/1/search.php?s=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)"
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlStr)!)
        let resp = try JSONDecoder().decode(SearchResponse.self, from: data)
        return resp.meals ?? []
    }

    static func expandMeals(_ meals: [Meal]) async throws -> [Meal] { meals }
}

