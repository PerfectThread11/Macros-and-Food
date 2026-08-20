# Macros & Food

Track what you eat, your macros, and what you need to buy each week — on your iPhone, for free.

This repo contains **two versions of the same app**:

- **`docs/` — the web app (recommended).** Runs in Safari, installs to your home screen like a real app, works offline, costs nothing, and needs no Mac. This is the one to use.
- **`MacrosAndFood/` — a native iOS (SwiftUI) version.** Identical features, but requires a Mac with Xcode to install, and free Apple IDs must re-install it every 7 days.

## What the app does

**Log tab** — Pick any day and record what you ate: from your saved foods, from your recipes, or with "Quick Add" where you type the macros directly. Entries are grouped by meal (breakfast/lunch/dinner/snacks) with per-meal calorie subtotals, portions have one-tap ½/1/1½/2 buttons, and "Repeat yesterday's meals" copies a whole day in one tap. The day's totals show as progress bars against your daily goals, and a water card tracks ounces with one-tap +8/+12/+16 oz buttons. Gentle reminders appear right in the app: a Sunday nudge to plan the week and an evening note if nothing's been logged (both dismissible).

**Plan tab** — A weekly meal planner: breakfast, lunch, dinner, and snacks for each day, filled from your recipes and foods. One button turns the whole week's plan into a shopping order — ingredient quantities are added up across all meals, and anything your pantry says you still have enough of arrives pre-marked as "skip." A 🍽️ button on any planned meal logs it to that day's food diary.

**Foods tab** — Your personal food library plus a recipe builder. Recipes are made from your foods (plus plain items like salt), and macros per serving are calculated automatically from the ingredients and how many servings the recipe makes. Star your regulars — favorites float to the top of every picker.

**Shopping tab** — One shopping order per week, and you can switch between weeks. Start a new order empty, copy last week's, or generate one from the meal planner — either way your pantry is re-checked and anything you still have enough of is marked "skip." Items are grouped into **To buy**, **Still have enough — skip**, and **Purchased**. After shopping, one tap stocks everything you bought into your pantry. Note prices on purchased items to see what each order cost and your average grocery spend over recent orders.

**Pantry tab** — The foods you have at home, each marked "Enough" or "Low." Anything marked "Enough" is skipped automatically when it appears on a shopping order; anything "Low" can be added to the week's order with one tap. Items can carry an expiration date — a "Use soon or toss" warning appears when something is within 3 days of expiring or already past it.

**Stats tab** — Nutrition and Body views. Nutrition: switch between Week, Month, and Year for period totals of every macro, daily averages against your goals, water averages, a calories-per-day chart, and a report card (days logged, current streak, protein-goal days, calories-on-target days). Body: log your weight whenever you weigh in and see a trend chart, total change, and a week-by-week pairing of average calorie intake against where your weight ended up. Also home to your daily goals and data backup (export/import).

**Profiles** — The 👤 button in the header switches between profiles, each with fully separate foods, logs, plans, pantry, and goals — all stored on the phone. Add, rename, or delete profiles right in the app; deleting one removes its data from the phone permanently.

All data stays on your phone (browser local storage for the web app; a JSON file for the iOS app). No account, no server, no tracking. Use "Export my data" on the Stats tab for backups.

## Get it on your iPhone (free, no Mac needed)

The web app needs to be hosted somewhere with a URL. GitHub can do this for free with **GitHub Pages**, with one requirement: the repository must be **public** (Pages is a paid feature on private repos). The app contains no personal data — your food log lives only on your phone — so making the code public is safe.

1. **Make the repo public:** on GitHub, go to *Settings → General*, scroll to the bottom (*Danger Zone*) → *Change visibility* → *Make public*.
2. **Turn on Pages:** *Settings → Pages* → under *Build and deployment*, set Source to **Deploy from a branch**, pick your branch (e.g. `main` after merging), folder **`/docs`**, and press *Save*.
3. Wait a minute or two. Your app is now live at:
   **`https://perfectthread11.github.io/Macros-and-Food/`**
4. **On your iPhone:** open that link in **Safari**, tap the **Share** button (square with arrow), then **Add to Home Screen**. Done — it gets its own icon, opens full screen, and works offline.

Prefer to keep the repo private? Host the `docs/` folder anywhere else instead — e.g. drag-and-drop it onto [Netlify Drop](https://app.netlify.com/drop) (free) and add that URL to your home screen the same way.

## The native iOS version

If you ever want the Swift version: open `MacrosAndFood.xcodeproj` in Xcode 16+ on a Mac, enable automatic signing with your Apple ID, plug in your iPhone, and press Run. With a free Apple ID the install expires after 7 days; a paid Apple Developer account ($99/yr) extends that to a year and unlocks TestFlight/App Store distribution.

## Project layout

```
docs/                        The web app (host this folder)
  index.html                 The whole app — HTML, CSS, and JS in one file
  manifest.webmanifest       Home-screen install metadata
  sw.js                      Service worker (offline support)
  icons/                     App icons
MacrosAndFood.xcodeproj      Xcode project for the native version
MacrosAndFood/               SwiftUI source (same features as the web app)
```
