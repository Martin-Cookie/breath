# Breath — pravidla pro vývoj

iOS aplikace pro řízené dýchání (SwiftUI, SwiftData, iOS 17+, MVVM).

## Technologie

- **SwiftUI** (deklarativní UI)
- **SwiftData** (persistence, offline-first)
- **AVFoundation** (audio)
- **Swift Charts** (grafy)
- **WidgetKit** (widget na home screen, App Group container `group.cz.martinkoci.breath`)
- **StoreKit 2** (freemium IAP)
- **UserNotifications** (denní připomínky)
- **String Catalogs** — `Breath/Resources/Localizable/Localizable.xcstrings` (CZ + EN)

## Architektura

MVVM:
- **Models** — `Breath/Models/` — doménové typy a SwiftData `@Model` třídy
- **ViewModels** — `Breath/ViewModels/` — obchodní logika (např. `SessionViewModel` se state machine)
- **Views** — `Breath/Views/` — SwiftUI obrazovky, rozdělené podle feature (Configuration, Session, Results, Stats, Settings, Paywall)
- **Services** — `Breath/Services/` — Audio, Haptic, Streak, Notification, Store

## Session state machine

`SessionViewModel` je centrální state machine cvičení:

```
idle → breathing → retention → recoveryIn → recoveryHold → roundResult
                                                              ↓
                                                 ┌────────────┴────────────┐
                                                 ↓                         ↓
                                             breathing                 completed
                                             (next round)             (last round)
```

- Timery jsou `Task`-based (async/await), nikdy `Timer.scheduledTimer`
- Ukončit lze kdykoliv přes `.cancelled` — všechny tasky se zruší a audio se stopne
- Po `.completed` se session uloží do SwiftData přes `modelContext.insert(...)`

## Konvence

### Struktura složek
- Jedna obrazovka = jeden soubor v `Views/{Feature}/`
- Sdílené komponenty (např. `BreathCircleView`) jsou v `Views/{Feature}/` podle hlavního použití
- Služby v `Services/` jsou singletony (`.shared`) s protokolem pro testovatelnost

### Nastavení
- Všechna konfigurace je v `@AppStorage` přes klíče v `SettingsKey` (viz `Models/UserSettings.swift`)
- Snapshot pro předání do ViewModelu je `SessionConfiguration` (struct)

### Audio
- `AudioService.playGuidance(key:style:)` nejprve zkusí najít `.m4a` v bundle, jinak použije `AVSpeechSynthesizer` fallback
- Pro MVP (dokud nejsou audio soubory dodané) fallback stačí

### Freemium
- Free tier: `Standard` rychlost, `sweet_and_spicy` hudba, `classic` guidance, 7 dní historie
- Premium gates: `Constants.Freemium.*` a `StoreService.shared.isPremium`
- Paywall se otevírá přes `sheet` na pokus o zamčenou funkci

### Lokalizace
- VŠECHNY UI texty musí být v `Localizable.xcstrings`
- Používat `String(localized: "key")` v Swift kódu
- Primární jazyk: **čeština** (CFBundleDevelopmentRegion = "cs")

### Barvy
- `Constants.Palette.primaryTeal` `#0d4f52` — primary
- `Constants.Palette.tealLight` `#0d7377` — breathing kruh
- `Constants.Palette.accentOrange` `#d4782a` — retention kruh
- `Constants.Palette.accentGreen` `#3aab6a` — recovery kruh

## Xcode projekt

Projekt používá **XcodeGen** — `.xcodeproj` není verzovaný:

```bash
brew install xcodegen
xcodegen generate
open Breath.xcodeproj
```

Konfigurace v `project.yml`. Při přidávání/mazání souborů se struktura automaticky aktualizuje při dalším `xcodegen generate`.

## Workflow

### Denní práce
Zadávej úkoly → postupuj po jasných blocích → commituj často.

### Po bloku změn
1. **Doc Sync** — `Přečti docs/agents/DOC-SYNC.md a proveď synchronizaci dokumentace s aktuálním stavem projektu.`
2. **Code Guardian** — `Přečti docs/agents/CODE-GUARDIAN.md a proveď audit projektu. Výstupem je docs/reports/AUDIT-REPORT.md. Nic neopravuj, pouze reportuj.`
3. **Test Agent** — `Přečti docs/agents/TEST-AGENT.md a proveď kompletní testování projektu. Výstupem je docs/reports/TEST-REPORT.md.`

### Před release
1. Code Guardian
2. Backup Agent
3. Doc Sync
4. Test Agent
5. Release Agent

Seznam agentů: [docs/agents/AGENTS.md](docs/agents/AGENTS.md)

> **Poznámka:** Agenti jsou převzatí z projektu SVJ. Některé jsou psané pro Python/FastAPI stack (SVJ) — pro Breath (SwiftUI/iOS) je potřeba přizpůsobit konkrétní příkazy (např. `pytest` → `xcodebuild test`, `ruff` → SwiftLint). Při prvním použití každého agenta zkontroluj a uprav relevantní kroky.

## Komunikace s uživatelem

- Komunikuj **česky** (jazyk projektu)
- Před většími změnami popiš plán a čekej na schválení
- Po změnách uveď stručný souhrn (1–2 věty, žádné markdown headers)
- Používej `file_path:line_number` formát pro odkazy na kód

## Pravidla pro práci na úkolech

1. **Plán** — u netriviálních úkolů nejdřív popsat postup, nechat schválit
2. **Malé commity** — jeden commit = jedna logická změna
3. **Testuj po sobě** — po každé změně ověř, že projekt buildí a běží
4. **Nepřidávej feature flags** ani backwards-compat shim, pokud o to nikdo neřekne
5. **Nežádat mě o commit** — commituj, až když to explicitně řeknu
