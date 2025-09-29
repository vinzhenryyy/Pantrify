//
//  PantrifyView.swift
//  Pantrify
//
//  Created by STUDENT on 8/28/25.
//

import SwiftUI
import SwiftData
import GoogleGenerativeAI

struct PantryView: View {
    @Environment(\.modelContext) private var context
    let user: User
    @Query private var allIngredients: [Ingredient]
    
    init(user: User) { self.user = user }
    
    private var items: [Ingredient] {
        allIngredients
            .filter { $0.owner?.id == user.id }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    @State private var showAdd = false
    private var totalCount: Int {
        items.count 
    }

    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                MintCard(
                    title: "Your Pantry",
                    subtitle: items.isEmpty
                        ? "No ingredients yet"
                        : "\(totalCount) ingredient\(totalCount == 1 ? "" : "s")",
                    trailing: AnyView(
                        Button { showAdd = true } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Ingredient")
                            }
                        }
                        .buttonStyle(MintButtonStyle())
                    )
                ) { EmptyView() }
                .padding(.horizontal)

                if items.isEmpty {
                    Spacer(minLength: 20)
                    VStack(spacing: 10) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.secondary)
                        Text("No ingredients yet")
                            .font(.title3.weight(.semibold))
                        Text("Tap + to add your first ingredient.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(items) { ing in
                            DisclosureGroup {
                                HStack(spacing: 16) {
                                    Button("-") {
                                        ing.quantity -= 1
                                        if ing.quantity <= 0 {
                                            context.delete(ing)
                                        }
                                        try? context.save()
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Text("\(ing.quantity, specifier: "%.2f") \(ing.unitType)")
                                    
                                    Button("+") {
                                        ing.quantity += 1
                                        try? context.save()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "leaf").foregroundStyle(.mint)
                                    Text(ing.name)
                                }
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { items[$0] }.forEach(context.delete)
                            try? context.save()
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Pantry")
            .sheet(isPresented: $showAdd) { AddIngredientSheet(user: user) }
        }
    }
}

struct AddIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let user: User
    
    @Query private var allIngredients: [Ingredient]
    
    @State private var name: String = ""
    @State private var detectedUnit: String? = nil
    @State private var selectedSubUnit: String = "pcs"
    @State private var oldSubUnit: String = "pcs"
    @State private var quantity: Double = 0
    @State private var error: String?
    
    // Unit options
    private let unitOptions: [String: [String]] = [
        "grams": ["mg", "g", "kg"],
        "liters": ["ml", "L", "kL"],
        "pieces": ["pcs"]
    ]
    
    // Conversion factors
    private let gramFactors: [String: Double] = ["mg": 0.001, "g": 1, "kg": 1000]
    private let literFactors: [String: Double] = ["ml": 0.001, "L": 1, "kL": 1000]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    TextField("e.g., soy sauce", text: $name)
                        .onSubmit {
                            Task {
                                detectUnitWithOpenAI(for: name) { unit in
                                    DispatchQueue.main.async {
                                        detectedUnit = unit
                                        selectedSubUnit = unitOptions[unit]?.first ?? "pcs"
                                        oldSubUnit = selectedSubUnit
                                    }
                                }
                            }
                        }
                    
                    if let unit = detectedUnit {
                        Picker("Select Unit", selection: $selectedSubUnit) {
                            ForEach(unitOptions[unit] ?? ["pcs"], id: \.self) { u in
                                Text(u).tag(u)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedSubUnit) { newUnit in
                            convertQuantity(from: oldSubUnit, to: newUnit)
                            oldSubUnit = newUnit
                        }
                        
                        if unit == "pieces" {
                            HStack {
                                TextField("Qty", value: $quantity, formatter: NumberFormatter.intFormatter)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                                Text(selectedSubUnit)
                                Stepper("", value: $quantity, in: 0...500, step: 1)
                                    .labelsHidden()
                            }
                        } else {
                            HStack {
                                TextField("Qty", value: $quantity, formatter: NumberFormatter.decimalFormatter)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 80)
                                Text(selectedSubUnit)
                                Stepper("", value: $quantity, in: 0...10_000, step: 1)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    if let error { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Add Ingredient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveIngredient() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || detectedUnit == nil)
                        .tint(.pantrifyMint)
                }
            }
        }
    }
    
    private func convertQuantity(from oldUnit: String, to newUnit: String) {
        if detectedUnit == "grams",
           let oldFactor = gramFactors[oldUnit],
           let newFactor = gramFactors[newUnit] {
            let base = quantity * oldFactor
            quantity = base / newFactor
        }
        if detectedUnit == "liters",
           let oldFactor = literFactors[oldUnit],
           let newFactor = literFactors[newUnit] {
            let base = quantity * oldFactor
            quantity = base / newFactor
        }
    }
    
    private func saveIngredient() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { error = "Please enter a name."; return }
        guard detectedUnit != nil else { error = "Please enter a valid ingredient."; return }
        
        let new = Ingredient(trimmed,
                             unitType: selectedSubUnit,
                             quantity: quantity,
                             owner: user)
        context.insert(new)
        
        do {
            try context.save()
            dismiss()
        } catch {
            print("❌ Save failed: \(error.localizedDescription)")
        }
    }
}

extension NumberFormatter {
    static var decimalFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f
    }
    static var intFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .none
        return f
    }
}
