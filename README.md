# Breath

iOS aplikace pro řízené dýchání inspirovaná Wim Hof metodou. SwiftUI + SwiftData, iOS 17+, MVVM, offline-first, freemium.

## Stack

| Vrstva | Technologie |
|--------|-------------|
| UI | SwiftUI |
| Persistence | SwiftData |
| Audio | AVFoundation |
| Grafy | Swift Charts |
| Widget | WidgetKit + App Group |
| IAP | StoreKit 2 |
| Lokalizace | String Catalogs (CZ + EN) |
| Architektura | MVVM |

## Struktura

```
Breath/
├── Models/        # Doménové modely a @Model SwiftData (Session, BreathingSpeed, GuidanceCatalog, MusicCatalog, UserSettings)
├── ViewModels/    # MVVM logika (state machine pro session)
├── Views/         # SwiftUI obrazovky (Configuration, Session, Results, Stats, Settings, Paywall, Onboarding)
├── Services/      # Audio, haptika, notifikace, StoreKit, streak, widget data
├── Utilities/     # Formátování, konstanty
└── Resources/     # Audio (SFX/breathing hlasy male+female, guidance), lokalizace (Localizable.xcstrings)
BreathWidget/      # WidgetKit extension
docs/agents/       # Workflow playbooks (převzato z projektu SVJ)
```

## Klíčové features

- Konfigurovatelné cvičení — rychlost, počet kol, počet dechů před retention
- Hudba na pozadí s nezávislou hlasitostí, výběr stop přes `MusicPickerView`
- Hlasové vedení (`GuidanceStylePickerView`) s nezávislou hlasitostí a volitelným hlasovým oznamováním času v retention (0/15/30/45/60 s)
- Zvuky dýchání ve dvou variantách hlasu (mužský / ženský) — výběr a preview v `BreathingSoundsPickerView`
- Haptická odezva, ping/gong SFX, streak tracking, widget na home screen, freemium přes StoreKit 2

## Generování Xcode projektu

Projekt používá **XcodeGen** — `.xcodeproj` není verzovaný, generuje se z `project.yml`.

```bash
brew install xcodegen
xcodegen generate
open Breath.xcodeproj
```

## Vývoj

- Deployment target: **iOS 17.0**
- Swift: **5.9+**
- Bundle ID: `cz.martinkoci.breath`
- Jazyk aplikace: čeština (výchozí) + angličtina

## Agenti

Workflow agenti jsou v `docs/agents/` — viz [docs/agents/AGENTS.md](docs/agents/AGENTS.md). Klíčoví agenti:

- **Doc Sync** — synchronizace dokumentace po bloku změn
- **Code Guardian** — audit kódu
- **Test Agent** — kompletní testování
- **Release Agent** — příprava release

## Pravidla pro vývoj

Viz [CLAUDE.md](CLAUDE.md) pro konvence a workflow.

## Kompletní zadání

Původní specifikace MVP je v `/Users/martinkoci/Library/CloudStorage/Dropbox/Dokumenty/Projects/Dychani/Breath_zadani_komplet.md`.
