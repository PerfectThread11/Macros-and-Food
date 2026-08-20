import SwiftUI

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    var calendarComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }
}

struct StatsView: View {
    @EnvironmentObject private var store: DataStore
    @State private var period: StatsPeriod = .week
    @State private var offset = 0
    @State private var showingGoals = false

    private var calendar: Calendar { Calendar.current }

    private var interval: DateInterval {
        let reference = calendar.date(byAdding: period.calendarComponent, value: offset, to: Date()) ?? Date()
        return calendar.dateInterval(of: period.calendarComponent, for: reference)
            ?? DateInterval(start: Date(), duration: 0)
    }

    private var periodEntries: [LogEntry] {
        store.entries(in: interval)
    }

    private var totals: Macros {
        store.totals(for: periodEntries)
    }

    private var loggedDays: Int {
        Set(periodEntries.map { calendar.startOfDay(for: $0.date) }).count
    }

    private var dailyAverage: Macros {
        loggedDays > 0 ? totals.scaled(by: 1.0 / Double(loggedDays)) : .zero
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Period", selection: $period) {
                        ForEach(StatsPeriod.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Button {
                            offset -= 1
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.borderless)

                        Spacer()
                        Text(intervalLabel)
                            .font(.headline)
                        Spacer()

                        Button {
                            offset += 1
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.borderless)
                        .disabled(offset >= 0)
                    }
                }

                Section("Totals") {
                    totalRow("Calories", totals.calories, "cal")
                    totalRow("Protein", totals.protein, "g")
                    totalRow("Carbs", totals.carbs, "g")
                    totalRow("Fat", totals.fat, "g")
                    totalRow("Fiber", totals.fiber, "g")
                    totalRow("Sugar", totals.sugar, "g")
                }

                Section("Daily average (\(loggedDays) logged day\(loggedDays == 1 ? "" : "s"))") {
                    if loggedDays == 0 {
                        Text("No food logged in this period.")
                            .foregroundStyle(.secondary)
                    } else {
                        averageRow("Calories", dailyAverage.calories, goal: store.goals.calories, unit: "cal")
                        averageRow("Protein", dailyAverage.protein, goal: store.goals.protein, unit: "g")
                        averageRow("Carbs", dailyAverage.carbs, goal: store.goals.carbs, unit: "g")
                        averageRow("Fat", dailyAverage.fat, goal: store.goals.fat, unit: "g")
                    }
                }

                if period == .week {
                    Section("Calories by day") {
                        WeekBars(interval: interval)
                    }
                }
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingGoals = true
                    } label: {
                        Image(systemName: "target")
                    }
                }
            }
            .sheet(isPresented: $showingGoals) {
                GoalsSheet()
            }
            .onChange(of: period) {
                offset = 0
            }
        }
    }

    private var intervalLabel: String {
        let formatter = DateFormatter()
        switch period {
        case .week:
            formatter.dateFormat = "MMM d"
            let endDay = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            return "\(formatter.string(from: interval.start)) – \(formatter.string(from: endDay))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: interval.start)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: interval.start)
        }
    }

    private func totalRow(_ label: String, _ value: Double, _ unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value.wholeString) \(unit)")
                .foregroundStyle(.secondary)
        }
    }

    private func averageRow(_ label: String, _ value: Double, goal: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value.wholeString) / \(goal.wholeString) \(unit)/day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(value, goal), total: max(goal, 1))
        }
    }
}

// MARK: - Simple per-day calorie bars for the week

struct WeekBars: View {
    @EnvironmentObject private var store: DataStore
    let interval: DateInterval

    private struct DayCalories: Identifiable {
        let date: Date
        let calories: Double
        var id: Date { date }
    }

    private var days: [DayCalories] {
        let calendar = Calendar.current
        var result: [DayCalories] = []
        var day = interval.start
        while day < interval.end {
            let calories = store.totals(for: store.entries(on: day)).calories
            result.append(DayCalories(date: day, calories: calories))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    var body: some View {
        let maxCalories = max(days.map { $0.calories }.max() ?? 0, 1)
        let formatter = weekdayFormatter
        ForEach(days) { day in
            HStack {
                Text(formatter.string(from: day.date))
                    .font(.caption)
                    .frame(width: 40, alignment: .leading)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                        Capsule()
                            .fill(Color.orange)
                            .frame(width: max(geo.size.width * day.calories / maxCalories, day.calories > 0 ? 4 : 0))
                    }
                }
                .frame(height: 10)
                Text(day.calories.wholeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }

    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
}

// MARK: - Daily goals

struct GoalsSheet: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var goals = MacroGoals()

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily targets") {
                    goalRow("Calories", value: $goals.calories, unit: "cal")
                    goalRow("Protein", value: $goals.protein, unit: "g")
                    goalRow("Carbs", value: $goals.carbs, unit: "g")
                    goalRow("Fat", value: $goals.fat, unit: "g")
                }
                Section {
                    Text("These targets drive the progress bars on the Log tab and the daily averages here in Stats.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("My Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateGoals(goals)
                        dismiss()
                    }
                }
            }
            .onAppear {
                goals = store.goals
            }
        }
    }

    private func goalRow(_ label: String, value: Binding<Double>, unit: String) -> some View {
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
