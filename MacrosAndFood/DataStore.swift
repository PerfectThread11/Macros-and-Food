import Foundation

@MainActor
final class DataStore: ObservableObject {
    @Published var foods: [FoodItem] = []
    @Published var log: [LogEntry] = []
    @Published var pantry: [PantryItem] = []
    @Published var orders: [ShoppingOrder] = []
    @Published var goals = MacroGoals()

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("macros-and-food.json")
    }()

    init() {
        load()
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data) else {
            seedDefaults()
            return
        }
        foods = decoded.foods
        log = decoded.log
        pantry = decoded.pantry
        orders = decoded.orders
        goals = decoded.goals
    }

    func save() {
        let blob = AppData(foods: foods, log: log, pantry: pantry, orders: orders, goals: goals)
        if let data = try? JSONEncoder().encode(blob) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func seedDefaults() {
        foods = [
            FoodItem(name: "Egg", servingDescription: "1 large egg",
                     macros: Macros(calories: 72, protein: 6.3, carbs: 0.4, fat: 4.8, fiber: 0, sugar: 0.2)),
            FoodItem(name: "Chicken Breast", servingDescription: "4 oz cooked",
                     macros: Macros(calories: 187, protein: 35, carbs: 0, fat: 4, fiber: 0, sugar: 0)),
            FoodItem(name: "White Rice", servingDescription: "1 cup cooked",
                     macros: Macros(calories: 205, protein: 4.3, carbs: 44.5, fat: 0.4, fiber: 0.6, sugar: 0.1)),
            FoodItem(name: "Banana", servingDescription: "1 medium",
                     macros: Macros(calories: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3.1, sugar: 14.4)),
            FoodItem(name: "Greek Yogurt", servingDescription: "1 cup plain nonfat",
                     macros: Macros(calories: 130, protein: 23, carbs: 9, fat: 0.5, fiber: 0, sugar: 9))
        ]
        save()
    }

    // MARK: Food library

    func addFood(_ food: FoodItem) {
        foods.append(food)
        foods.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func updateFood(_ food: FoodItem) {
        if let idx = foods.firstIndex(where: { $0.id == food.id }) {
            foods[idx] = food
            save()
        }
    }

    func deleteFoods(ids: [UUID]) {
        foods.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: Log

    func addEntry(_ entry: LogEntry) {
        log.append(entry)
        save()
    }

    func deleteEntries(ids: [UUID]) {
        log.removeAll { ids.contains($0.id) }
        save()
    }

    func entries(on date: Date) -> [LogEntry] {
        log.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }

    func entries(in interval: DateInterval) -> [LogEntry] {
        log.filter { interval.contains($0.date) }
    }

    func totals(for entries: [LogEntry]) -> Macros {
        entries.reduce(Macros.zero) { $0 + $1.totalMacros }
    }

    // MARK: Pantry

    func addPantryItem(_ item: PantryItem) {
        pantry.append(item)
        pantry.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func updatePantryItem(_ item: PantryItem) {
        if let idx = pantry.firstIndex(where: { $0.id == item.id }) {
            pantry[idx] = item
            save()
        }
    }

    func deletePantryItems(ids: [UUID]) {
        pantry.removeAll { ids.contains($0.id) }
        save()
    }

    func togglePantryHaveEnough(id: UUID) {
        if let idx = pantry.firstIndex(where: { $0.id == id }) {
            pantry[idx].haveEnough.toggle()
            save()
        }
    }

    /// True when the pantry says you still have enough of a food with this name.
    func pantryHasEnough(named name: String) -> Bool {
        pantry.contains {
            $0.haveEnough && $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    // MARK: Shopping orders

    @discardableResult
    func addOrder(name: String, copyFrom sourceID: UUID? = nil) -> UUID {
        var order = ShoppingOrder(name: name)
        if let sourceID, let source = orders.first(where: { $0.id == sourceID }) {
            order.items = source.items.map { item in
                var copy = item
                copy.id = UUID()
                copy.isPurchased = false
                copy.stillHaveEnough = pantryHasEnough(named: item.name)
                return copy
            }
        }
        orders.insert(order, at: 0)
        save()
        return order.id
    }

    func renameOrder(id: UUID, to name: String) {
        if let idx = orders.firstIndex(where: { $0.id == id }) {
            orders[idx].name = name
            save()
        }
    }

    func deleteOrders(ids: [UUID]) {
        orders.removeAll { ids.contains($0.id) }
        save()
    }

    func order(id: UUID) -> ShoppingOrder? {
        orders.first { $0.id == id }
    }

    func addShoppingItem(orderID: UUID, name: String, quantity: String) {
        guard let idx = orders.firstIndex(where: { $0.id == orderID }) else { return }
        var item = ShoppingItem(name: name, quantity: quantity)
        item.stillHaveEnough = pantryHasEnough(named: name)
        orders[idx].items.append(item)
        save()
    }

    func removeShoppingItems(orderID: UUID, ids: [UUID]) {
        guard let idx = orders.firstIndex(where: { $0.id == orderID }) else { return }
        orders[idx].items.removeAll { ids.contains($0.id) }
        save()
    }

    func togglePurchased(orderID: UUID, itemID: UUID) {
        guard let oIdx = orders.firstIndex(where: { $0.id == orderID }),
              let iIdx = orders[oIdx].items.firstIndex(where: { $0.id == itemID }) else { return }
        orders[oIdx].items[iIdx].isPurchased.toggle()
        if orders[oIdx].items[iIdx].isPurchased {
            orders[oIdx].items[iIdx].stillHaveEnough = false
        }
        save()
    }

    func toggleStillHaveEnough(orderID: UUID, itemID: UUID) {
        guard let oIdx = orders.firstIndex(where: { $0.id == orderID }),
              let iIdx = orders[oIdx].items.firstIndex(where: { $0.id == itemID }) else { return }
        orders[oIdx].items[iIdx].stillHaveEnough.toggle()
        if orders[oIdx].items[iIdx].stillHaveEnough {
            orders[oIdx].items[iIdx].isPurchased = false
        }
        save()
    }

    /// Everything checked off as purchased gets stocked into the pantry.
    func addPurchasedToPantry(orderID: UUID) {
        guard let order = order(id: orderID) else { return }
        for item in order.itemsPurchased {
            if let idx = pantry.firstIndex(where: {
                $0.name.compare(item.name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }) {
                pantry[idx].haveEnough = true
                if !item.quantity.isEmpty { pantry[idx].quantity = item.quantity }
            } else {
                pantry.append(PantryItem(name: item.name, quantity: item.quantity, haveEnough: true))
            }
        }
        pantry.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    /// Pantry items marked "running low" get added to the given order.
    func addLowStockToOrder(orderID: UUID) {
        guard let idx = orders.firstIndex(where: { $0.id == orderID }) else { return }
        let existingNames = Set(orders[idx].items.map { $0.name.lowercased() })
        for item in pantry where !item.haveEnough {
            if !existingNames.contains(item.name.lowercased()) {
                orders[idx].items.append(ShoppingItem(name: item.name, quantity: item.quantity))
            }
        }
        save()
    }

    // MARK: Goals

    func updateGoals(_ newGoals: MacroGoals) {
        goals = newGoals
        save()
    }
}
