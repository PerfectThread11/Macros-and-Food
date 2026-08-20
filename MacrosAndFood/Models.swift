import Foundation

// MARK: - Macros

struct Macros: Codable, Hashable {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0
    var sugar: Double = 0

    static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber,
            sugar: lhs.sugar + rhs.sugar
        )
    }

    func scaled(by factor: Double) -> Macros {
        Macros(
            calories: calories * factor,
            protein: protein * factor,
            carbs: carbs * factor,
            fat: fat * factor,
            fiber: fiber * factor,
            sugar: sugar * factor
        )
    }

    static let zero = Macros()
}

// MARK: - Food library

struct FoodItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var servingDescription: String = "1 serving"
    var macros = Macros()
}

// MARK: - Food log

/// One thing eaten on one day. Macros are snapshotted so later edits to the
/// food library never rewrite history.
struct LogEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var date = Date()
    var foodName: String
    var servings: Double = 1
    var macrosPerServing = Macros()

    var totalMacros: Macros { macrosPerServing.scaled(by: max(servings, 0)) }
}

// MARK: - Pantry

/// Something you have at home. `haveEnough` marks foods you do NOT need to
/// re-buy this week.
struct PantryItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var quantity: String = ""
    var haveEnough = true
}

// MARK: - Shopping orders

struct ShoppingItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var quantity: String = ""
    var isPurchased = false
    /// Marked when you realize you still have enough at home, so it stays on
    /// the list but is skipped when shopping.
    var stillHaveEnough = false
}

/// One week's shopping list. You can keep several and switch between them.
struct ShoppingOrder: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var createdAt = Date()
    var items: [ShoppingItem] = []

    var itemsToBuy: [ShoppingItem] { items.filter { !$0.isPurchased && !$0.stillHaveEnough } }
    var itemsSkipped: [ShoppingItem] { items.filter { $0.stillHaveEnough && !$0.isPurchased } }
    var itemsPurchased: [ShoppingItem] { items.filter { $0.isPurchased } }
}

// MARK: - Goals

struct MacroGoals: Codable, Hashable {
    var calories: Double = 2000
    var protein: Double = 100
    var carbs: Double = 250
    var fat: Double = 70
}

// MARK: - Persisted blob

struct AppData: Codable {
    var foods: [FoodItem] = []
    var log: [LogEntry] = []
    var pantry: [PantryItem] = []
    var orders: [ShoppingOrder] = []
    var goals = MacroGoals()
}
