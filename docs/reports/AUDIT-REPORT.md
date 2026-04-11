# Breath — Code Guardian Audit Report — 2026-04-11

> Audit iOS projektu `Breath` (SwiftUI / SwiftData / MVVM). Agent byl adaptován z původního Python/FastAPI stacku SVJ — Python/DB/HTMX sekce byly nahrazeny kontrolami specifickými pro Swift/iOS: SwiftLint, lokalizace přes `Localizable.xcstrings`, konzistence `AudioServiceProtocol`, integrita `SettingsKey`, state machine `SessionViewModel`, freemium gating, Task-based timery a SwiftData model. Nic nebylo opravováno — pouze report.

## Souhrn

- **CRITICAL**: 1
- **HIGH**: 4
- **MEDIUM**: 7
- **LOW**: 6

## Souhrnná tabulka

| # | Oblast | Soubor | Severity | Problém | Čas | Rozhodnutí |
|---|--------|--------|----------|---------|-----|------------|
| 1 | Kód / Audio | Breath/Services/AudioService.swift:169 | CRITICAL | `playGuidance(key:style:)` ignoruje parametr `style` — guidance style picker nemá žádný efekt | ~30 min | ❓ |
| 2 | Lokalizace | Breath/Views/Session/RoundResultView.swift:11,32 | HIGH | Hardcoded anglické stringy `"ROUND X OF Y"`, `"Tap to continue"` — nezachytí český překlad | ~10 min | 🔧 |
| 3 | Lokalizace | Breath/Views/Results/SessionResultsView.swift:41,53 | HIGH | Hardcoded `"X rounds • Y total"` a `"Round X"` — mimo xcstrings | ~10 min | 🔧 |
| 4 | Lokalizace | Breath/Views/Stats/SessionRowView.swift:16 | HIGH | Hardcoded `"X kol • avg Y"` (mix cs/en, nelze přeložit) | ~5 min | 🔧 |
| 5 | Lokalizace | Breath/Resources/Localizable/Localizable.xcstrings | HIGH | 10 klíčů bez `cs` překladu, 6 klíčů bez `en` překladu, 5 klíčů ve stavu `new` místo `translated` | ~15 min | 🔧 |
| 6 | Kód / Audio | Breath/Services/AudioService.swift:186-202 | MEDIUM | `speakRetentionTime` — česká gramatika "1 sekund" / "2 sekund" je negramatická (správně "15 sekund", "30 sekund" — ale při volitelném intervalu 15/30/45/60 funguje náhodou) | ~10 min | ❓ |
| 7 | Kód / Catalog | Breath/Models/GuidanceCatalog.swift:10 | MEDIUM | `GuidanceCatalog.all` obsahuje jediný styl `classic`. Po přidání picker UI nemá uživatel z čeho vybírat — chybějící premium styly (např. `calm`, `energetic`) | ~20 min | ❓ |
| 8 | Kód / Audio | Breath/Services/AudioService.swift:215-228 | MEDIUM | Fallback case `breathe_out` nikdy nenastane — `SessionViewModel` nikde nevolá `playGuidance(key: "breathe_out", …)`. Dead code | ~5 min | 🔧 |
| 9 | MVVM / View | Breath/Views/Configuration/BreathingSoundsPickerView.swift:47,51,75,125,129; GuidanceStylePickerView.swift:37,41,65,123,128 | MEDIUM | Picker views volají přímo `AudioService.shared.*` místo VM — porušení MVVM a znemožnění unit testování | ~30 min | ❓ |
| 10 | Kód / State machine | Breath/ViewModels/SessionViewModel.swift:190-195,232-237 | MEDIUM | Dva „plovoucí" `Task { [weak self] … }` nejsou uloženy do `breathTask`/`tickerTask`, takže `stopAllTasks()` / `cancel()` je nezruší. Chrání je pouze `guard phase == …` — ale `phase = .cancelled` je drží v bezpečí. Přesto je to fragile — stačí jedna změna a vznikne race | ~20 min | 🔧 |
| 11 | Kód / Audio | Breath/Services/AudioService.swift:238-258 | MEDIUM | `sfxPlayer` je sdílený jedním `AVAudioPlayer` pro všechny SFX (breathing in/out, ping, gong, warning) — rychlé překrytí (inhale+exhale v rychlé fázi) může přerušit předchozí zvuk | ~20 min | ❓ |
| 12 | Testy | BreathTests/SessionViewModelTests.swift | MEDIUM | Žádný test nepokrývá nové fce: `speakRetentionTime`, `retentionAnnounceInterval` ticker, `breathingSoundsVoice`, `guidanceVolume` | ~30 min | 🔧 |
| 13 | Lokalizace | Breath/Resources/Localizable/Localizable.xcstrings | LOW | Klíče `"%@"`, `"%@%@"` v catalogu — pravděpodobně artefakty automatického extraktoru Xcode, neobsahují text | ~5 min | 🔧 |
| 14 | Kód / Config | Breath/ViewModels/ConfigurationViewModel.swift:14-88 | LOW | 22× opakovaný `didSet { defaults.set(...) }` — kandidát na zobecnění přes `@AppStorage` property wrapper nebo generic helper | ~45 min | ❓ |
| 15 | Kód / Audio | Breath/Services/AudioService.swift:169-184 | LOW | `playGuidance` nezkouší varianty podle `style` — soubor `classic_breathe_in_cs.m4a` nebo adresář `Guidance/classic/` | ~15 min | ❓ |
| 16 | Přístupnost | Breath/Views/Configuration/BreathingSoundsPickerView.swift:98-112; GuidanceStylePickerView.swift:93-109 | LOW | Play/preview tlačítka bez `.accessibilityLabel` — screen reader řekne pouze ikonu | ~10 min | 🔧 |
| 17 | Přístupnost | Breath/Views/Session/RoundResultView.swift:11-34 | LOW | Bez `.accessibilityElement(children: .combine)` — VoiceOver přečte text nesrozumitelně | ~5 min | 🔧 |
| 18 | UI konzistence | Breath/Views/Configuration/{BreathingSoundsPickerView,GuidanceStylePickerView,MusicPickerView}.swift | LOW | Tři picker views s téměř identickou strukturou — kandidáti na extrakci sdílené komponenty `AudioOptionPickerView<Option>` | ~45 min | ❓ |

Legenda: 🔧 = jen opravit, ❓ = vyžaduje rozhodnutí uživatele (více variant)

---

## Detailní nálezy

### 1. Kódová kvalita

#### #1 CRITICAL — `playGuidance` ignoruje `style` parametr
- **Kde**: `Breath/Services/AudioService.swift:169-184`
- **Co**: `func playGuidance(key: String, style: String)` sestavuje URL jako `"\(key)_\(lang).m4a"` nebo `"\(key).m4a"` — **parametr `style` nikde nepoužije**. `SessionViewModel` posílá `configuration.breathingPhaseGuidanceStyle` a `retentionPhaseGuidanceStyle`, `GuidanceStylePickerView` nabízí výběr stylu → ale výběr **nemá žádný efekt** na přehrávání. Kromě toho `GuidanceCatalog.all` obsahuje pouze jeden styl (`classic`), takže problém není dnes slyšitelný — ale jakmile se přidá druhý styl, picker bude vypadat funkčně a při tom ticho.
- **Řešení (varianty)**:
  1. Naming konvence `"\(style)_\(key)_\(lang).m4a"` → např. `classic_breathe_in_cs.m4a`. Nejmenší změna.
  2. Adresářová struktura `Guidance/\(style)/\(key)_\(lang).m4a` — vyžaduje bundle strukturu; čistší.
  3. `GuidanceCatalog` vracející seznam souborů přímo.
- **Náročnost**: střední, **~30 min** (plus čas na dodání audio souborů pro další styly).
- **Závislosti**: souvisí s #7 (prázdný katalog), #15.
- **Regrese riziko**: nízké — dnes se používá jen `classic`, takže změna resolveru nic neporouchá.
- **Test**: spustit session se `breathingPhaseGuidanceStyle = "classic"` → ověřit stejné chování jako nyní; přepnout na nový styl v pickeru → ověřit, že hraje jiný soubor.

#### #8 MEDIUM — Dead code `breathe_out` fallback
- **Kde**: `Breath/Services/AudioService.swift:218, 223`
- **Co**: Fallback text pro klíč `breathe_out` nebude nikdy zavolán — session používá pouze `breathe_in`, `let_go`, `hold`, `recovery`.
- **Řešení**: Odstranit nepoužívané case z switche.
- **Náročnost**: nízká, **~5 min**, regrese: žádná.

#### #10 MEDIUM — Plovoucí Tasky, které se neřadí do cancellable sady
- **Kde**: `Breath/ViewModels/SessionViewModel.swift:190-195` (recoveryIn → recoveryHold), `232-237` (roundResult → proceedAfterRound)
- **Co**: Oba `Task { [weak self] … }` nejsou uloženy do `breathTask` ani `tickerTask`. `cancel()` → `stopAllTasks()` je nemůže explicitně zrušit; spoléhá se čistě na `guard !Task.isCancelled, self.phase == .<exp>`. Protože `cancel()` nastavuje `.cancelled`, obě taska bezpečně vypadnou přes guard — dnes OK. Ale fragile: jakákoliv budoucí změna `cancel()` nebo pořadí stavů může způsobit race.
- **Řešení**: uložit oba Tasky do nové property (např. `transitionTask`) a rušit je v `stopAllTasks()`.
- **Regrese riziko**: nízké, **~20 min**.

#### #11 MEDIUM — Sdílený `sfxPlayer` pro krátce po sobě jdoucí zvuky
- **Kde**: `Breath/Services/AudioService.swift:29, 238-275`
- **Co**: `sfxPlayer` je jedna reference — `playBreathingIn`, `playBreathingOut`, `playPing`, `playGong`, `playWarning` ji všechny přepisují. Při `fast` rychlosti (1.0s inhale + 1.5s exhale) nemusí stihnout doznít předchozí `breathing_in_female.m4a` (~1.2s) než začne `breathing_out_female.m4a` — druhý volání `AVAudioPlayer(contentsOf:)` vytváří nový player, starý se uvolňuje, ale nestará se o fade-out.
- **Řešení (varianty)**: a) separátní `breathPlayer` a `sfxPlayer`; b) pool N playerů; c) nechat takto (MVP).
- **Náročnost**: střední, **~20 min**, regrese: nízké.

#### #6 MEDIUM — Česká gramatika u `speakRetentionTime`
- **Kde**: `Breath/Services/AudioService.swift:186-202`
- **Co**: Text `"\(seconds) sekund"` je korektní pro 15, 30, 45, 60 (plurál „sekund"), ale nejde o správný plurál přes `String(localized:)` s `.stringsdict`. Při jakékoliv změně intervalu (např. 5 s) bude gramatika špatně (*„5 sekund"* → by mělo být „sekund" ano, *„1 sekund"* → špatně „sekundu"). Navíc text není lokalizovaný přes xcstrings.
- **Řešení**: použít `String(AttributedString(localized: "retention.time_announce \(seconds)"))` s pravidly plurálu v xcstrings.
- **Náročnost**: nízká, **~10 min**.

#### #7 MEDIUM — `GuidanceCatalog` obsahuje pouze jeden styl
- **Kde**: `Breath/Models/GuidanceCatalog.swift:10`
- **Co**: Po přidání picker UI `GuidanceStylePickerView` zobrazí jeden řádek bez možnosti výběru. Freemium koncept v `Constants.Freemium.freeGuidanceStyles` je připraven, ale prakticky nepoužitelný.
- **Řešení**: Rozšířit katalog o premium styly (`calm`, `energetic`, …) nebo dočasně UI picker skrýt dokud nejsou audio soubory.
- **Náročnost**: střední (záleží na dodání audia), **~20 min kód**.

#### #14 LOW — Opakovaný `didSet` v ConfigurationViewModel
- **Kde**: `Breath/ViewModels/ConfigurationViewModel.swift:14-88`
- **Co**: 22× boilerplate `didSet { defaults.set(x, forKey: SettingsKey.x) }`. Kandidát na refaktoring na generic helper nebo přímo `@AppStorage` (pokud typy dovolí). `@AppStorage` nepodporuje vlastní enum, takže by šlo o hybrid.

### 2. Bezpečnost

Žádné kritické bezpečnostní nálezy. StoreKit transakce jsou validované přes `case .verified`, `UserDefaults` pro `isPremium` je přijatelný pro free/premium gating (není to licenční DRM), entitlement refresh běží přes `Transaction.currentEntitlements`.

#### Poznámka (INFO): Audio session konfigurace — OK
- `Breath/Services/AudioService.swift:47-54`: `.playback` + `.mixWithOthers` je správná volba pro mindfulness app (hraje s hudbou z jiných aplikací, pokračuje na pozadí).

### 3. Dokumentace

#### #5 HIGH — Nekompletní `Localizable.xcstrings`
- **Kde**: `Breath/Resources/Localizable/Localizable.xcstrings`
- **Nálezy (parsed programaticky)**:
  - **10 klíčů bez `cs`** lokalizace: `%@`, `%@ kol • avg %@`, `%@ rounds • %@ total`, `%@%@`, `Historie`, `Retention Time`, `Round %@`, `ROUND %@ OF %@`, `Tap to continue`, `Žádná data`
  - **6 klíčů bez `en`** lokalizace: `%@`, `Historie`, `Retention Time`, `Round %@`, `Tap to continue`, `Žádná data`
  - **5 klíčů ve stavu `new`** (ne `translated`): `%@ kol • avg %@`, `%@ rounds • %@ total`, `%@%@`, `ROUND %@ OF %@`
  - Několik klíčů vypadá jako artefakty auto-extraktoru (`%@`, `%@%@`) a pravděpodobně patří smazat.
- **Řešení**: viz nálezy #2–#4 pro doplnění klíčů, pak v xcstrings přidat hodnoty a stav `translated` pro obě jazyky.

#### INFO — CLAUDE.md vs reálný stav projektu
- `CLAUDE.md` popisuje `AudioService.playGuidance(key:style:)` korektně, ale nezmiňuje nové metody `setBreathingVolume/setGuidanceVolume/playBreathingIn(voice:)/playBreathingOut(voice:)/previewBreathing(voice:)/speakRetentionTime`. Pro Doc-Sync agenta je to work item, zde pouze poznámka.

### 4. UI / Views

#### #2 HIGH — Hardcoded stringy v `RoundResultView`
- **Kde**: `Breath/Views/Session/RoundResultView.swift:11` → `Text("ROUND \(roundNumber) OF \(totalRounds)")`, `:32` → `Text("Tap to continue")`
- **Co**: V češtině by mělo být „Kolo X z Y" / „Pokračuj tapnutím" (nebo odpovídající). Dnes se v CZ buildu zobrazí anglicky.
- **Řešení**: klíče `session.round_label` a `session.tap_to_continue` (viz existující `session.round_of` a `session.tap_to_breathe`).

#### #3 HIGH — Hardcoded stringy v `SessionResultsView`
- **Kde**: `Breath/Views/Results/SessionResultsView.swift:41` → `"\(rounds.count) rounds • \(…) total"`, `:53` → `"Round \(round.roundNumber)"`, plus `shareText` (řádky 14-21) má hardcoded „Round X: …", „Best retention: …", „🌬️ Breath — … rounds, total …"
- **Řešení**: všechny texty přes xcstrings; share text může být mimo rozsah lokalizace (pro sociální sítě často zůstává EN).

#### #4 HIGH — Hardcoded mix `SessionRowView`
- **Kde**: `Breath/Views/Stats/SessionRowView.swift:16` → `"\(session.totalRounds) kol • avg \(TimeFormatter.mmss(...))"` — míchá CZ („kol") a EN („avg"). Ani jeden není lokalizovaný.
- **Řešení**: klíč `stats.row_summary` s placeholdery.

#### #9 MEDIUM — MVVM porušení v picker views
- **Kde**: `Breath/Views/Configuration/BreathingSoundsPickerView.swift:47, 51, 75, 125, 129`, `Breath/Views/Configuration/GuidanceStylePickerView.swift:37, 41, 65, 123, 128`
- **Co**: Picker views volají přímo `AudioService.shared.*` (setBreathingVolume, previewBreathing, stopAll, playGuidance). To porušuje MVVM a znemožňuje unit testy pickeru s mock servisem. V kontrastu `ConfigurationView` používá `ConfigurationViewModel`.
- **Řešení**: Zavést `BreathingSoundsPickerViewModel` / `GuidanceStylePickerViewModel` které drží `AudioServiceProtocol`, nebo picker jen mění `@Binding` a audio orchestraci nechat na nadřazeném VM. Pozor: `@StateObject` v sheetu stačí injektovat přes `.environmentObject`.
- **Náročnost**: střední, **~30 min**.

#### #13 LOW — Artefakty v xcstrings
- **Kde**: `Breath/Resources/Localizable/Localizable.xcstrings` klíče `%@`, `%@%@`
- **Co**: Pravděpodobně vytvořeno Xcode auto-extraktorem ze string interpolací (`Text("\(value)")`). Nic neznamenají — vyčistit.

#### #16 LOW — Chybějící accessibility labels na preview tlačítkách
- **Kde**: `BreathingSoundsPickerView.swift:98-112`, `GuidanceStylePickerView.swift:93-109`
- **Co**: VoiceOver uslyší „play circle, male" místo „Preview male voice".
- **Řešení**: `.accessibilityLabel(Text("Preview \(option.title)"))`.

#### #17 LOW — `RoundResultView` není combined
- **Kde**: `RoundResultView.swift:10-35`
- **Co**: VoiceOver přečte tři oddělené elementy (heading, time, hint) — lepší je je sloučit do jednoho elementu s popisnou hláškou.

#### #18 LOW — Duplicitní struktura tří pickerů
- **Kde**: `MusicPickerView.swift`, `BreathingSoundsPickerView.swift`, `GuidanceStylePickerView.swift`
- **Co**: Všechny mají identickou kostru (NavigationStack → ScrollView → ForEach → VStack s Sliderem + Button). Kandidát na `AudioOptionPickerView<Option>` generic komponentu.

### 5. Výkon

- **Retention ticker** (`SessionViewModel.swift:164-177`): polling 100 ms je OK, ale když `interval > 0`, `Int(retentionElapsed) / interval` může vypočíst stejný tick vícekrát během jedné sekundy — chrání `lastAnnouncedTick` (OK, správně).
- **StatsView**: nepročetl jsem detaily, ale `@Query` ve SwiftData řeší i velký počet session (není zjevný N+1 problém na iOS).

### 6. Error Handling

- `AudioService` všude loguje `print("…error: \(error)")` — pro MVP OK, ale v produkci by měl být `os.Logger` se subsystem/category.
- `StoreService.purchasePremium` — `userCancelled` a `pending` jsou tiše spolknuté bez feedbacku uživateli. Volající `PaywallView` by měl dostat signál (např. `throw`).

### 7. Git Hygiene

- `.xcodeproj` není v `.gitignore` kontrolováno, ale projekt deklaruje XcodeGen — `.gitignore` obsahuje `build/`, `DerivedData` (OK).
- `build/` adresář existuje v repozitáři (`/Users/martinkoci/breath/build`) — ověř, že není commitnutý.
- Žádné `.env` ani API klíče v kódu nenalezeny.

### 8. Testy

- **Coverage**: `SessionViewModelTests` (stav, breathing loop, cancel, tap-to-breathe), `ConfigurationViewModelTests`, `SessionModelTests`, `StreakServiceTests`, `WidgetDataServiceTests`, `TimeFormatterTests`.
- **Chybí** (nález #12):
  - Test pro `speakRetentionTime` volané v `runRetentionTicker` když `retentionAnnounceInterval > 0`.
  - Test pro `playBreathingIn(voice: "female")` vs `"male"` — ověřit že se pošle správný parametr.
  - Test pro setGuidanceVolume / setBreathingVolume cestu (že se volá při startu session).
  - Test že `cancel()` během `.recoveryIn` / `.roundResult` opravdu ukončí i „plovoucí" Tasky (nález #10).
- `MockAudioService` je kompletní vůči protokolu — drift nenalezen (dobře).

---

## Doporučené opravy (doporučený postup)

1. **Fáze 1 — okamžitě (CRITICAL + HIGH, ~1h)**
   1. #1 Fix `playGuidance(style:)` resolving — vyber naming konvenci, zdokumentuj do CLAUDE.md.
   2. #5 + #2 + #3 + #4 Doplň chybějící lokalizační klíče do xcstrings pro `cs` i `en`, zamění hardcoded literály za `String(localized:)`.
2. **Fáze 2 — do konce týdne (MEDIUM, ~2.5 h)**
   3. #7 Přidat druhý guidance styl (nebo skrýt picker dokud nejsou audio data).
   4. #9 Extrahovat picker logiku z views do VM (MVVM).
   5. #10 Uložit „plovoucí" transition Tasky do `transitionTask` pro deterministický cancel.
   6. #11 Separovat `sfxPlayer` pro breathing vs SFX.
   7. #12 Doplnit unit testy pro nové features.
   8. #6 Opravit českou gramatiku retention announce (plurál přes stringsdict).
   9. #8 Odstranit dead code `breathe_out` fallback.
3. **Fáze 3 — nice-to-have (LOW, ~2 h)**
   10. #13 Vyčistit xcstrings artefakty.
   11. #14 Refactor `@AppStorage` boilerplate.
   12. #16 + #17 Accessibility labels.
   13. #18 Extrakce sdílené picker komponenty.

> **Poznámka k SwiftLint**: SwiftLint CLI není v tomto prostředí nainstalováno (`which swiftlint` → not found), takže statická analýza přes linter nebyla spuštěna. Konfigurace `.swiftlint.yml` existuje a vypadá rozumně. Doporučuji spouštět `brew install swiftlint && swiftlint --strict` v CI.

> **Poznámka k buildu**: `xcodebuild build` nebyl spuštěn (sandbox / časový rozpočet). Vzhledem k tomu, že nové soubory jsou v `project.yml`-generované struktuře a `CLAUDE.md` výslovně říká že `.xcodeproj` není verzovaný, je vhodné před první pull-request validací spustit `xcodegen generate && xcodebuild -scheme Breath -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`.
