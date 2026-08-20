# Macros & Food

An iPhone app (SwiftUI, iOS 17+) that tracks what you eat, your macros, and what you need to buy each week.

## What it does

**Log tab** — Pick any day and log what you ate, either from your saved foods (two taps) or with a one-off "Quick Add" where you type the macros directly. The day's totals show as progress bars against your daily goals: calories, protein, carbs, fat, plus fiber and sugar.

**Stats tab** — Switch between Week, Month, and Year. Shows period totals for every macro, your daily average compared to your goals, and (for weeks) a calories-per-day bar chart. Use the arrows to look back at past weeks/months/years. Tap the target icon to set your daily calorie and macro goals.

**Foods tab** — Your personal food library. Save the foods you eat regularly with their macros per serving, so logging is fast.

**Shopping tab** — One shopping order per week, and you can switch between weeks. Start a new order empty or copy last week's order — when you copy, the app checks your pantry and automatically marks anything you still have enough of as "skip." Items are grouped into **To buy**, **Still have enough — skip** (swipe an item right to toggle this), and **Purchased**. After shopping, one tap stocks everything you bought into your pantry.

**Pantry tab** — Type in the foods you've bought and have at home. Mark each one "Enough" or "Low." Anything marked "Enough" gets skipped automatically when it appears on a shopping order; anything marked "Low" can be added to the current week's order with one tap.

Everything is stored on the phone (a JSON file in the app's documents folder) — no account, no internet needed.

## How to run it on your iPhone

This is an Xcode project, so it needs a Mac to build:

1. On a Mac, install **Xcode** (free, from the Mac App Store — version 16 or newer).
2. Clone or download this repository and open `MacrosAndFood.xcodeproj`.
3. In Xcode, select the **MacrosAndFood** target → **Signing & Capabilities**, check *Automatically manage signing*, and pick your Apple ID as the Team (add it under Xcode → Settings → Accounts if needed). If Xcode complains about the bundle identifier, change `com.perfectthread.MacrosAndFood` to anything unique.
4. Plug in your iPhone (or use Wi-Fi pairing), pick it as the run destination, and press **Run**.
5. On the phone, go to Settings → General → VPN & Device Management and trust your developer certificate the first time.

Notes:
- With a **free** Apple ID the app must be re-installed from Xcode every 7 days. With a paid Apple Developer account ($99/yr) it lasts a year, and you could distribute it via TestFlight or the App Store.
- No Mac? You can run it in the **iOS Simulator** on a borrowed Mac, or use a cloud Mac service (MacStadium, MacinCloud) with Xcode.

## Project layout

```
MacrosAndFood.xcodeproj      Xcode project
MacrosAndFood/
  MacrosAndFoodApp.swift     App entry point
  ContentView.swift          Tab bar + shared helpers
  Models.swift               Foods, log entries, pantry, shopping orders, goals
  DataStore.swift            All app state + JSON persistence
  Views/
    TodayView.swift          Food log + add-entry sheet
    StatsView.swift          Week/month/year totals, averages, goals
    FoodLibraryView.swift    Saved foods with macros
    ShoppingView.swift       Weekly orders + order detail
    PantryView.swift         What you have at home
```
