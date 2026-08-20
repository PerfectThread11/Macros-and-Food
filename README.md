# Macros & Food

Track what you eat, your macros, and what you need to buy each week — on your iPhone, for free.

This repo contains **two versions of the same app**:

- **`docs/` — the web app (recommended).** Runs in Safari, installs to your home screen like a real app, works offline, costs nothing, and needs no Mac. This is the one to use.
- **`MacrosAndFood/` — a native iOS (SwiftUI) version.** Identical features, but requires a Mac with Xcode to install, and free Apple IDs must re-install it every 7 days.

## What the app does

**Log tab** — Pick any day and record what you ate, either from your saved foods (two taps) or with "Quick Add" where you type the macros directly. The day's totals show as progress bars against your daily goals: calories, protein, carbs, fat, plus fiber and sugar.

**Stats tab** — Switch between Week, Month, and Year. Shows period totals for every macro, your daily average compared to your goals, and a calories-per-day chart for the week. Arrows let you look back at past periods. Also home to your daily goals and data backup (export/import).

**Foods tab** — Your personal food library. Save the foods you eat regularly with macros per serving so logging is fast.

**Shopping tab** — One shopping order per week, and you can switch between weeks. Start a new order empty or copy last week's — copying re-checks your pantry and automatically marks anything you still have enough of as "skip." Items are grouped into **To buy**, **Still have enough — skip**, and **Purchased**. After shopping, one tap stocks everything you bought into your pantry.

**Pantry tab** — The foods you have at home, each marked "Enough" or "Low." Anything marked "Enough" is skipped automatically when it appears on a shopping order; anything "Low" can be added to the week's order with one tap.

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
