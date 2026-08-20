import SwiftUI

struct FoodLibraryView: View {
    @EnvironmentObject private var store: DataStore
    @State private var searchText = ""
    @State private var editingFood: FoodItem?
    @State private var showingNewFood = false

    private var filteredFoods: [FoodItem] {
        if searchText.isEmpty { return store.foods }
        return store.foods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                if store.foods.isEmpty {
                    Text("Add the foods you eat often, with their macros per serving. Then logging a meal takes two taps.")
                        .foregroundStyle(.secondary)
                }
                ForEach(filteredFoods) { food in
                    Button {
                        editingFood = food
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(food.name).foregroundStyle(.primary)
                            Text(food.servingDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            MacroSummaryLine(macros: food.macros)
                        }
                    }
                }
                .onDelete { offsets in
                    let ids = offsets.map { filteredFoods[$0].id }
                    store.deleteFoods(ids: ids)
                }
            }
            .searchable(text: $searchText, prompt: "Search foods")
            .navigationTitle("My Foods")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewFood = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewFood) {
                FoodEditorSheet(food: nil)
            }
            .sheet(item: $editingFood) { food in
                FoodEditorSheet(food: food)
            }
        }
    }
}

// MARK: - Add / edit a food

struct FoodEditorSheet: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let food: FoodItem?

    @State private var name = ""
    @State private var servingDescription = ""
    @State private var macros = Macros()

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Name", text: $name)
                    TextField("Serving size (e.g. 1 cup)", text: $servingDescription)
                }
                Section("Macros per serving") {
                    MacroFields(macros: $macros)
                }
            }
            .navigationTitle(food == nil ? "New Food" : "Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveFood() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let food {
                    name = food.name
                    servingDescription = food.servingDescription
                    macros = food.macros
                }
            }
        }
    }

    private func saveFood() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let serving = servingDescription.trimmingCharacters(in: .whitespaces)
        if var existing = food {
            existing.name = trimmedName
            existing.servingDescription = serving.isEmpty ? "1 serving" : serving
            existing.macros = macros
            store.updateFood(existing)
        } else {
            store.addFood(FoodItem(name: trimmedName,
                                   servingDescription: serving.isEmpty ? "1 serving" : serving,
                                   macros: macros))
        }
        dismiss()
    }
}
