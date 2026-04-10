# Breath — Architektura

Dokument popisuje strukturu aplikace, data flow a klíčová designová rozhodnutí. Pro pravidla vývoje viz [CLAUDE.md](../CLAUDE.md).

## Přehled

Breath je iOS 17+ aplikace pro řízené dýchání (Wim Hof metoda) postavená na SwiftUI + SwiftData + MVVM. Vše běží offline, premium funkce přes StoreKit 2.

```
┌─────────────────────────────────────────────────────────┐
│                      BreathApp                          │
│  (scene root, modelContainer, onboarding gate)          │
└───────────────┬─────────────────────────────────────────┘
                │
        ┌───────┴────────┐
        │                │
  OnboardingView   ConfigurationView ──► SessionView ──► SessionResultsView
                        │                    │
                        ├─► StatsView        │
                        ├─► SettingsView     │
                        └─► PaywallView      │
                                             ▼
                                       SwiftData save
                                             │
                                             ▼
                                     WidgetDataService
                                             │
                                             ▼
                                   App Group UserDefaults
                                             │
                                             ▼
                                       BreathWidget
```

## Vrstvy

### Models (`Breath/Models/`)
Doménové typy a SwiftData entity.

- **`Session`** — `@Model` class, perzistovaná session. Rounds jsou uloženy jako JSON blob (`Data`), přístup přes computed property `rounds: [RoundResult]`. Derived properties: `bestRetention`, `averageRetention`.
- **`RoundResult`** — `Codable struct`, jedno kolo (retention + recovery hold).
- **`BreathingSpeed`** — enum (`slow`/`standard`/`fast`) s `inhaleDuration`, `exhaleDuration`, `isPremium`, `localizedTitle`.
- **`UserSettings`** — obsahuje pouze `SettingsKey` enum (string klíče pro `@AppStorage`) a `SessionConfiguration` struct (immutable snapshot předávaný do ViewModelů).

### ViewModels (`Breath/ViewModels/`)
`@MainActor final class ObservableObject`. Obchodní logika, žádný import SwiftUI mimo `@Published`.

- **`ConfigurationViewModel`** — čte/píše do `UserDefaults` přes `@Published` properties s `didSet`. `makeSessionConfiguration()` vytvoří immutable snapshot. `setSpeed(_:isPremium:)` vrací `false` když uživatel nemá premium → View ukáže paywall.
- **`SessionViewModel`** — state machine cvičení (viz níže). Injectable `AudioServiceProtocol` + `HapticServiceProtocol` kvůli testovatelnosti. Všechny timery jsou `Task`-based (async/await), nikdy `Timer.scheduledTimer`.

### Views (`Breath/Views/{Feature}/`)
Jedna obrazovka = jeden soubor. Sdílené komponenty (např. `BreathCircleView`) jsou v adresáři feature kde se primárně používají.

Features:
- **Configuration** — hlavní obrazovka, selektory (speed/rounds/breaths), music/guidance/extra sections, sticky Start button
- **Session** — state machine UI; samostatné views pro `BreathingPhase`, `RetentionPhase`, `RecoveryPhase`, `RoundResult`
- **Results** — `SessionResultsView` (po dokončení)
- **Stats** — `StatsView` s Swift Charts
- **Settings** — hub `SettingsView` + `NotificationSettingsView`
- **Onboarding** — 3-page flow při prvním spuštění
- **Paywall** — `PaywallView` napojený na `StoreService`

### Services (`Breath/Services/`)
Singletony (`shared`) s protokolem pro testovatelnost. Ne-UI stavová logika.

- **`AudioService`** — AVAudioPlayer pro music/guidance/SFX, `AVSpeechSynthesizer` fallback pro chybějící audio soubory. Pozoruje `AVAudioSession.interruptionNotification` a `routeChangeNotification` — při hovoru pauzuje, po skončení resumuje, při odpojení sluchátek pauzuje.
- **`HapticService`** — `UIImpactFeedbackGenerator` wrapper.
- **`StreakService`** — **pure enum**, `compute(from:calendar:referenceDate:)` vrací `StreakInfo`. Injectable `calendar` + `referenceDate` pro deterministické testy.
- **`NotificationService`** — `scheduleDailyReminder(hour:minute:)` a `scheduleStreakWarning(streakCount:lastSessionDate:)` (fires v 20:00 pokud dnes necvičil a má streak ≥ 2).
- **`StoreService`** — StoreKit 2: `loadProducts`, `purchase`, `restore`, `Transaction.updates` listener. `isPremium: Bool` je `@Published`.
- **`WidgetDataService`** — po dokončení session sestaví `WidgetSnapshot` a zapíše JSON do App Group UserDefaults + `WidgetCenter.reloadAllTimelines()`.

### Shared (`Shared/`)
Kód sdílený mezi app a widget targetem (přes XcodeGen multi-source config).

- **`WidgetSnapshot`** — `Codable struct` (currentStreak, bestStreak, lastSessionDate, recentRetentions: [TimeInterval]). App Group identifier: `group.cz.martinkoci.breath`.

### Widget (`BreathWidget/`)
WidgetKit extension. Dva varianty (`.systemSmall`, `.systemMedium`) přes `@Environment(\.widgetFamily)`. Mini chart v medium variantě přes Swift Charts (`LineMark` + `AreaMark`).

## Session state machine

`SessionViewModel.Phase`:

```
idle → breathing → retention → recoveryIn → recoveryHold → roundResult
                                                              │
                                                   ┌──────────┴──────────┐
                                                   ↓                     ↓
                                               breathing             completed
                                              (next round)          (last round)

Kdykoliv: → cancelled
```

### Přechody
- **`start()`** — `idle → breathing`. Spustí `breathingLoop()` task.
- **`breathingLoop()`** — N × (inhale + exhale) podle `speed` + `breathsBeforeRetention`. Na konci → `retention`.
- **`retention`** — stopwatch běží, čeká na tap. `tapToBreathe()` → `recoveryIn`.
- **`recoveryIn`** — hluboký nádech (4s) → `recoveryHold`.
- **`recoveryHold`** — krátký hold (15s) → `roundResult`, uloží `RoundResult`.
- **`roundResult`** — čeká na tap. `advanceFromRoundResult()` → buď `breathing` (další kolo) nebo `completed`.
- **`cancel()`** — `.cancelled`, všechny tasky se zruší, audio se stopne.

### Ukončení
- **`completed`** → `SessionView` persistuje do SwiftData (`modelContext.insert`), pak volá `WidgetDataService.update(with:)` a `NotificationService.scheduleStreakWarning(...)`.
- **`cancelled`** → nic se neperzistuje, audio stop.

## Data flow — session lifecycle

```
User tap Start
      │
      ▼
ConfigurationView.startSession()
      │
      ├─► ConfigurationViewModel.makeSessionConfiguration()  [SessionConfiguration snapshot]
      │
      ▼
SessionViewModel(configuration:) ──► fullScreenCover → SessionView
      │
      ▼
viewModel.start()  →  state machine runs  →  phase == .completed
      │
      ▼
SessionView.persistSession()
      │
      ├─► modelContext.insert(Session)
      ├─► FetchDescriptor<Session> → WidgetDataService.update(with:)
      │      │
      │      └─► App Group UserDefaults ← JSON(WidgetSnapshot)
      │             │
      │             └─► WidgetCenter.reloadAllTimelines()
      │
      └─► NotificationService.scheduleStreakWarning(...)
```

## Perzistence

### SwiftData
- Container registrován v `BreathApp` přes `.modelContainer(for: Session.self)`
- `@Environment(\.modelContext)` ve Views pro insert/fetch
- Rounds v `Session` jsou `Data` blob (JSON) — SwiftData zatím neumí arrays nested structs elegantně

### UserDefaults (`@AppStorage`)
- Všechna konfigurace uživatele (speed, rounds, music, guidance, haptic…)
- Klíče v `SettingsKey` enum
- `hasSeenOnboarding` flag pro first-launch gate

### App Group UserDefaults (`group.cz.martinkoci.breath`)
- `WidgetSnapshot` JSON pod klíčem `widget.snapshot`
- Čteno widgetem přes `UserDefaults(suiteName:)`

## Freemium gating

Premium gates jsou na několika místech:

| Místo | Gate |
|---|---|
| `ConfigurationViewModel.setSpeed` | `.slow`/`.fast` jsou premium |
| `MusicSettingsSection` | tracks mimo `sweet_and_spicy` jsou premium |
| `GuidanceSettingsSection` | styly mimo `classic` jsou premium |
| `StatsView` | období > 7 dní jsou premium |
| `SessionResultsView` | sdílení je premium |

Všechny gates čtou `StoreService.shared.isPremium`. Při pokusu o zamčenou volbu se otevře `PaywallView` sheet.

## Testování (`BreathTests/`)

- **`StreakServiceTests`** — pure function, deterministicky s `Calendar(identifier: .gregorian)` + injected `referenceDate`
- **`TimeFormatterTests`** — formátování času
- **`ConfigurationViewModelTests`** — defaults, perzistence, premium blocking
- **`SessionViewModelTests`** — state machine přechody, async timing (s `waitUntil` helper), `MockAudioService` + `MockHapticService` pro ověření volání
- **`SessionModelTests`** — SwiftData model, rounds encode/decode, computed properties
- **`WidgetDataServiceTests`** — snapshot building, best-per-day aggregation, Codable roundtrip

Patterns:
- `@MainActor final class ... XCTestCase` pro async tests
- Mock protokoly (`AudioServiceProtocol`, `HapticServiceProtocol`) místo stub implementací
- Injekce `Calendar` + `referenceDate` pro čas-závislou logiku

## Build & projekt

- **XcodeGen** — `project.yml` je zdroj pravdy, `.xcodeproj` není verzovaný
- `xcodegen generate` po každé změně souborové struktury
- Targets: `Breath` (app), `BreathTests`, `BreathWidget`
- `Shared/` je v sources obou produkčních targetů
- **CI**: `.github/workflows/ci.yml` — macos-14 runner, `xcodebuild build` + `test` s `CODE_SIGNING_ALLOWED=NO`

## Lokalizace

- String Catalog: `Breath/Resources/Localizable/Localizable.xcstrings`
- Primární jazyk: **čeština** (`CFBundleDevelopmentRegion = "cs"`)
- V kódu vždy `String(localized: "key")`, nikdy literal
- Klíče jsou namespaced: `config.*`, `session.*`, `stats.*`, `settings.*`, `onboarding.*`, `notifications.*`, `paywall.*`

## Barvy (`Constants.Palette`)

| Token | Hex | Použití |
|---|---|---|
| `primaryTeal` | `#0d4f52` | primary (tlačítka, nav) |
| `tealLight` | `#0d7377` | breathing kruh |
| `accentOrange` | `#d4782a` | retention kruh |
| `accentGreen` | `#3aab6a` | recovery kruh |
| `textSecondary` | — | labels, sekundární text |
