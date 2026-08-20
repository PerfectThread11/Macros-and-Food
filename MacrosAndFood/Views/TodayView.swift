import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: DataStore
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false

    private var dayEntries: [LogEntry] {
        store.entries(on: selectedDate)
    }

    private var dayTotals: Macros {
        store.totals(for: dayEntries)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    dateNavigator
                    DayTotalsCard(totals: dayTotals, goals: store.goals)
                }

                Section("Eaten") {
                    if dayEntries.isEmpty {
                        Text("Nothing logged yet. Tap + to add what you ate.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(dayEntries) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(entry.foodName)
                                    Spacer()
                                    if entry.servings != 1 {
                                        Text("×\(entry.servings.neatString)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                MacroSummaryLine(macros: entry.totalMacros)
                            }
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { dayEntries[$0].id }
                            store.deleteEntries(ids: ids)
                        }
                    }
                }
            }
            .navigationTitle("Food Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEntrySheet(date: selectedDate)
            }
        }
    }

    private var dateNavigator: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)

            Spacer()
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Day totals vs. goals

struct DayTotalsCard: View {
    let totals: Macros
    let goals: MacroGoals

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            goalRow(label: "Calories", value: totals.calories, goal: goals.calories, unit: "cal", tint: .orange)
            goalRow(label: "Protein", value: totals.protein, goal: goals.protein, unit: "g", tint: .red)
            goalRow(label: "Carbs", value: totals.carbs, goal: goals.carbs, unit: "g", tint: .blue)
            goalRow(label: "Fat", value: totals.fat, goal: goals.fat, unit: "g", tint: .yellow)
            HStack {
                Text("Fiber \(totals.fiber.neatString)g")
                Spacer()
                Text("Sugar \(totals.sugar.neatString)g")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func goalRow(label: String, value: Double, goal: Double, unit: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text("\(value.wholeString) / \(goal.wholeString) \(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(value, goal), total: max(goal, 1))
                .tint(tint)
        }
    }
}

// MARK: - Add entry sheet

struct AddEntrySheet: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @State private var mode = 0 // 0 = from library, 1 = quick add
    @State private var searchText = ""
    @State private var selectedFood: FoodItem?
    @State private var servings = 1.0

    @State private var quickName = ""
    @State private var quickMacros = Macros()

    private var filteredFoods: [FoodItem] {
        if searchText.isEmpty { return store.foods }
        return store.foods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Mode", selection: $mode) {
                    Text("My Foods").tag(0)
                    Text("Quick Add").tag(1)
                }
                .pickerStyle(.segmented)

                if mode == 0 {
                    Section("Choose a food") {
                        TextField("Search", text: $searchText)
                        ForEach(filteredFoods) { food in
                            Button {
                                selectedFood = food
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(food.name).foregroundStyle(.primary)
                                        Text(food.servingDescription)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedFood?.id == food.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                    }
                    Section("Servings") {
                        servingsRow
                    }
                } else {
                    Section("What did you eat?") {
                        TextField("Name (e.g. Turkey sandwich)", text: $quickName)
                    }
                    Section("Macros") {
                        MacroFields(macros: $quickMacros)
                    }
                    Section("Servings") {
                        servingsRow
                    }
                }
            }
            .navigationTitle("Add to Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEntry() }
                        .disabled(!canAdd)
                }
            }
        }
    }

    private var servingsRow: some View {
        HStack {
            Text("Servings")
            Spacer()
            TextField("1", value: $servings, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Stepper("Servings", value: $servings, in: 0.25...20, step: 0.25)
                .labelsHidden()
        }
    }

    private var canAdd: Bool {
        if mode == 0 { return selectedFood != nil }
        return !quickName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func addEntry() {
        var entry: LogEntry
        if mode == 0, let food = selectedFood {
            entry = LogEntry(foodName: food.name, servings: servings, macrosPerServing: food.macros)
        } else {
            entry = LogEntry(foodName: quickName.trimmingCharacters(in: .whitespaces),
                             servings: servings,
                             macrosPerServing: quickMacros)
        }
        // Log against the day being viewed, at the current time of day.
        let cal = Calendar.current
        let time = cal.dateComponents([.hour, .minute, .second], from: Date())
        entry.date = cal.date(bySettingHour: time.hour ?? 12,
                              minute: time.minute ?? 0,
                              second: time.second ?? 0,
                              of: date) ?? date
        store.addEntry(entry)
        dismiss()
    }
}

// MARK: - Reusable macro input fields

struct MacroFields: View {
    @Binding var macros: Macros

    var body: some View {
        numberRow("Calories", value: $macros.calories, unit: "cal")
        numberRow("Protein", value: $macros.protein, unit: "g")
        numberRow("Carbs", value: $macros.carbs, unit: "g")
        numberRow("Fat", value: $macros.fat, unit: "g")
        numberRow("Fiber", value: $macros.fiber, unit: "g")
        numberRow("Sugar", value: $macros.sugar, unit: "g")
    }

    private func numberRow(_ label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text(unit).foregroundStyle(.secondary)
        }
    }
}
