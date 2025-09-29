//
//  File.swift
//  Pantrify
//
//  Created by STUDENT on 8/28/25.
//
import Foundation
import SwiftData

@Model
final class User: Identifiable {
    @Attribute(.unique) var email: String
    @Attribute(.unique) var username: String
    @Attribute(.externalStorage) var profileImageData: Data? = nil
    
    var id: UUID
    var firstName: String
    var lastName: String
    var phoneNumber: String?
    var dateOfBirth: Date?
    var sex: String?
    var password: String
    var createdAt: Date
    var hoursSpent: Double = 0
    
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient]
    @Relationship(deleteRule: .cascade) var recipes: [Recipe]
    
    init(firstName: String, lastName: String, email: String, username: String, phoneNumber: String? = nil, dateOfBirth: Date? = nil, sex: String? = nil, password: String) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.username = username
        self.phoneNumber = phoneNumber
        self.dateOfBirth = dateOfBirth
        self.sex = sex
        self.password = password
        self.createdAt = Date()
        self.ingredients = []
        self.recipes = []
        self.profileImageData = nil
        self.hoursSpent = 0
    }
}

@Model
final class Ingredient: Identifiable {
    var id: UUID
    var name: String
    var normalized: String
    var createdAt: Date
    
    var unitType: String
    var quantity: Double
    
    @Relationship var owner: User?
    
    init(_ rawName: String, unitType: String, quantity: Double, owner: User) {
        let (display, key) = IngredientName.normalize(rawName)
        self.id = UUID()
        self.name = display
        self.normalized = key
        self.createdAt = Date()
        self.unitType = unitType
        self.quantity = quantity
        self.owner = owner
    }
}

@Model
final class Recipe: Identifiable {
    var id: UUID
    var title: String
    var ingredientNames: [String]
    var displayIngredients: [String]
    var instructions: [String]
    var tags: [String]
    var sourceURL: String?
    var createdAt: Date
    // UI meta
    var cookTimeMinutes: Int?
    var servings: Int?
    var difficulty: String?
    var isPlanned: Bool
    var isCooked: Bool = false
    
    @Relationship var addedBy: User?
    init(
        title: String,
        ingredients: [String],
        instructions: [String],
        tags: [String] = [],
        sourceURL: String? = nil,
        addedBy: User? = nil,
        cookTimeMinutes: Int? = nil,
        servings: Int? = nil,
        difficulty: String? = nil,
        isPlanned: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.displayIngredients = ingredients.map { IngredientName.normalize($0).display }
        self.ingredientNames = ingredients.map { IngredientName.normalize($0).key }
        self.instructions = instructions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        self.tags = tags
        self.sourceURL = sourceURL
        self.createdAt = Date()
        self.cookTimeMinutes = cookTimeMinutes
        self.servings = servings
        self.difficulty = difficulty
        self.isPlanned = isPlanned
        self.addedBy = addedBy
        self.isCooked = false
    }
}

enum IngredientName {
    private static let synonyms: [String: String] = [
        "scallion": "green onion",
        "spring onion": "green onion",
        "cilantro": "coriander",
        "caster sugar": "sugar",
        "powdered sugar": "confectioners sugar",
        "icing sugar": "confectioners sugar",
        "all purpose flour": "flour",
        "all-purpose flour": "flour",
        "ap flour": "flour",
        "kosher salt": "salt",
        "sea salt": "salt",
        "soya sauce": "soy sauce",
        "bell pepper": "capsicum",
        "ground beef": "minced beef"
    ]
    static func normalize(_ raw: String) -> (display: String, key: String) {
        let cleaned = raw
            .lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let mapped = synonyms[cleaned] ?? cleaned
        let display = mapped.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
        return (display, mapped)
    }
}

extension Array where Element == String {
    var localizedJoin: String {
        switch count {
        case 0: return ""
        case 1: return self[0]
        case 2: return "\(self[0]) and \(self[1])"
        default: return dropLast().joined(separator: ", ") + ", and " + (last ?? "")
        }
    }
}
