import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Log", systemImage: "fork.knife") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            FoodLibraryView()
                .tabItem { Label("Foods", systemImage: "carrot.fill") }
            ShoppingView()
                .tabItem { Label("Shopping", systemImage: "cart.fill") }
            PantryView()
                .tabItem { Label("Pantry", systemImage: "cabinet.fill") }
        }
    }
}

// MARK: - Shared formatting helpers

extension Double {
    /// "1,234" for calories-style numbers.
    var wholeString: String {
        self.formatted(.number.precision(.fractionLength(0)))
    }

    /// "12.5" but drops the trailing ".0".
    var neatString: String {
        self.formatted(.number.precision(.fractionLength(0...1)))
    }
}

/// Compact "C  P  C  F" macro summary line used in lists.
struct MacroSummaryLine: View {
    let macros: Macros

    var body: some View {
        Text("\(macros.calories.wholeString) cal · P \(macros.protein.neatString)g · C \(macros.carbs.neatString)g · F \(macros.fat.neatString)g")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
