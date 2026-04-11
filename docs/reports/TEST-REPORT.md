# Breath Test Report – 2026-04-11

## Shrnutí

| Oblast | Stav | Detail |
|---|---|---|
| Build (xcodebuild) | OK | `** BUILD SUCCEEDED **` (projekt i testovací targety se zkompilují) |
| Unit testy (`BreathTests`) | SELHÁNÍ | 42 testů, 41 passed, **1 failed** |
| UI testy (`BreathUITests`) | OK | 7 testů, 7 passed |
| SwiftLint | N/A | CLI `swiftlint` není nainstalován (`which swiftlint` -> not found), krok přeskočen |
| Swift 6 warnings | WARNING | 6+ varování v testech ohledně `Sendable` / `@MainActor` izolace |

**Celkový stav: SELHÁNÍ (1 unit test)** — selhání je detekovatelné pouze v nové variantě testu (viz níže), funkčnost aplikace tím není přímo narušena, ale test regresse musí být opraven.

Prostředí: Xcode 26.4 (17E192), iPhone 17 Pro simulator (iOS 17+), `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Příkaz:

```
xcodebuild test -project Breath.xcodeproj -scheme Breath \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Celkový čas testů: ~102 s.

---

## Detail selhání

### testBreathingSoundsArePlayedWhenEnabled — FAILED

- **Soubor:** `BreathTests/SessionViewModelTests.swift:96`
- **Severity:** WARNING (nikoli CRITICAL — aplikace funguje, ale test nedrží krok s aktuální logikou `SessionViewModel`)
- **Chyba:**
  ```
  XCTAssertTrue failed
  ```
  Očekává `audio.calls.contains(.playBreathingIn("male"))` / `.playBreathingOut("male")`, ale volání v `calls` nejsou přítomna.

- **Příčina (analýza kódu):**
  `SessionViewModel.runBreathingLoop()` (`Breath/ViewModels/SessionViewModel.swift:112-133`) používá podmínku
  ```swift
  let isWarning = remainingBreaths <= 5
  if isWarning { audio.playWarning() }
  else { audio.playBreathingIn(voice: configuration.breathingSoundsVoice) }
  ```
  Test volá `fastConfig(breaths: 1)`, tedy `remainingBreaths == 1`, což spadá do `isWarning` větve. Na nádech se místo `playBreathingIn` volá `playWarning` a test selže. Pro výdech se `playBreathingOut` naopak volá bez ohledu na warning — test selže na první asserci.

- **Doporučení:**
  Upravit test na `fastConfig(breaths: 6)` a ponechat čekací dobu dostatečnou, aby doběhl minimálně jeden non-warning nádech+výdech. Alternativně přidat parametr `warningThreshold` do `SessionConfiguration` a pro testy ho posunout na 0.

### Swift 6 warnings (non-blocking, ale rostoucí dluh)

1. `BreathTests/Mocks/MockAudioService.swift:26` — `stored property 'calls' of 'Sendable'-conforming class 'MockAudioService' is mutable; this is an error in the Swift 6 language mode`. V Swift 6 režimu se toto stane chybou. Mock by měl být označen `@unchecked Sendable` nebo přepnut na `@MainActor` izolaci.
2. `BreathTests/ConfigurationViewModelTests.swift:13, 17, 18` — `main actor-isolated property 'defaults' can not be mutated/referenced from a nonisolated context`. `setUp()` / `tearDown()` běží mimo main actor, ale třída je `@MainActor`. Doporučení: použít `override func setUp() async throws` (main-actor-isolated) nebo udělat `defaults` `nonisolated(unsafe)`.

### Runtime varování simulátoru

`xcrun: error: unable to find utility "simctl"` — nastává protože `xcrun` z command line tools neumí najít simctl; naše obcházení přes `DEVELOPER_DIR` pro xcodebuild funguje, ale interní diagnostika xcodebuildu volá `xcrun` bez env. Nezpůsobuje selhání testů, jen se logují "Failure collecting diagnostics from simulator". Doporučení pro CI: `sudo xcode-select -s /Applications/Xcode.app`.

---

## Pokrytí — nedávné featury bez testů

Prohlídka zdrojů potvrdila, že následující featury přidané s konfigurovatelným audiem **nemají přímé pokrytí**:

### 1. `AudioService.speakRetentionTime(seconds:)` — žádné testy
- Soubor: `Breath/Services/AudioService.swift:186-202`
- Používá `AVSpeechSynthesizer` přímo, větvení podle jazyka (cs/en), formátuje text `"<n> sekund" / "<n> seconds"`.
- Mock `MockAudioService.speakRetentionTime(seconds:)` existuje, ale žádný test nevolá `SessionViewModel` s `retentionAnnounceInterval > 0`, takže ani ticker volání tohoto API neverifikuje.

### 2. `AudioService.playBreathingIn/Out(voice:)` — female varianta bez testu
- Soubor: `Breath/Services/AudioService.swift:238-258`
- Fallback logika: zkusí `breathing_in_female.m4a`, jinak `breathing_in.m4a`. Tato cesta není pokryta žádným unit testem.
- Jediný existující test (`testBreathingSoundsArePlayedWhenEnabled`) používá pouze `"male"` a aktuálně selhává.

### 3. `SessionViewModel.runRetentionTicker()` — retention announcement ticker bez testu
- Soubor: `Breath/ViewModels/SessionViewModel.swift:161-177`
- Logika: každých `retentionAnnounceInterval` sekund volá `audio.speakRetentionTime(seconds: tick * interval)`.
- Žádný test nenastavuje `retentionAnnounceInterval > 0`, `fastConfig` má `retentionAnnounceInterval: 0`.
- Okrajové případy: tick hranice (např. interval=15, retention 40 s → očekávaná volání na 15 a 30), `interval == 0` (nic se nevolá), cancel během ticku.

### 4. `ConfigurationViewModel` nové @Published props
- Soubor: `Breath/ViewModels/ConfigurationViewModel.swift:61-82`
- Props bez pokrytí:
  - `guidanceVolume` (persistence + side-effect `AudioService.setGuidanceVolume`)
  - `retentionAnnounceInterval` (persistence, default value)
  - `breathingSoundsVoice` (persistence, default = "male")
  - `breathingSoundsVolume` (persistence + side-effect `AudioService.setBreathingVolume`)
- Stávající `ConfigurationViewModelTests` ověřuje pouze `rounds`, `hapticFeedback`, `speed`, `breathsBeforeRetention`, `pingAndGong`.

---

## Navrhované nové testy (pouze specifikace — neimplementováno)

### A. `SessionViewModelTests` — fix existujícího + nové

1. **Fix `testBreathingSoundsArePlayedWhenEnabled`**
   Použít `fastConfig(breaths: 6)`, rozšířit timeout na ~18 s a ověřit, že při prvním (non-warning) cyklu proběhne `playBreathingIn("male")` i `playBreathingOut("male")`.

2. **`testBreathingSoundsFemaleVoiceFallback`**
   Config s `breathingSoundsVoice: "female"`, ověřit, že `MockAudioService.calls` obsahuje `.playBreathingIn("female")` a `.playBreathingOut("female")`.

3. **`testWarningSoundPlaysOnLastFiveBreaths`**
   Config `breaths: 6`, počkat do momentu, kdy `remainingBreaths <= 5`, ověřit, že `calls` obsahuje `.playWarning` alespoň jednou a že tam jsou i `.playBreathingIn` z prvního (non-warning) nádechu.

4. **`testRetentionTickerAnnouncesAtInterval`**
   Config `retentionAnnounceInterval: 1`, `breaths: 1` (fast), po `start()` počkat na retention fázi (~5 s), poté 2.5 s v retention a zavolat `cancel()`. Ověřit, že `calls` obsahuje `.speakRetentionTime(1)` a `.speakRetentionTime(2)` (nebo `(0)` podle implementace první hranice).

5. **`testRetentionTickerIsSilentWhenIntervalZero`**
   Config `retentionAnnounceInterval: 0`. Po startu a retention fázi ověřit, že `calls` **neobsahuje žádné** `.speakRetentionTime(_)`.

6. **`testRetentionTickerStopsOnCancel`**
   Config `retentionAnnounceInterval: 1`, počkat na 1.5 s v retention → cancel → počkat 2 s → ověřit že žádné další `.speakRetentionTime` nepřibyly mezi snapshoty před a po cancelu.

7. **`testGuidanceVolumeIsAppliedAtStart`**
   Config s `guidanceVolume: 0.25`, ověřit, že v `calls` je `.setGuidanceVolume(0.25)` volané v `beginBreathingPhase`.

8. **`testBreathingVolumeIsAppliedAtStart`**
   Config s `breathingSoundsVolume: 0.4`, ověřit `.setBreathingVolume(0.4)`.

### B. `ConfigurationViewModelTests` — nové

9. **`testGuidanceVolumePersistsAndAppliesToAudio`**
   Nastavit `vm.guidanceVolume = 0.3`, vytvořit druhý VM nad stejným `UserDefaults` suite, ověřit že `vm2.guidanceVolume == 0.3`. (Side-effect na `AudioService.shared` nelze ověřit bez abstrakce — viz bod D.)

10. **`testBreathingSoundsVoiceDefaultsAndPersists`**
    Ověřit default `"male"`, změnit na `"female"`, re-instance, ověřit persistenci.

11. **`testBreathingSoundsVolumePersists`**
    Stejný pattern jako guidance volume.

12. **`testRetentionAnnounceIntervalDefaultAndPersists`**
    Default dle `SessionConfiguration.default`, změna + re-load.

13. **`testMakeSessionConfigurationIncludesNewAudioProps`**
    Rozšířit existující `testMakeSessionConfigurationReflectsCurrentState` o nastavení všech 4 nových polí a ověření, že `makeSessionConfiguration()` je propaguje.

### C. `AudioServiceTests` — zcela nový soubor

14. **`testSpeakRetentionTimeDoesNotCrashForZero`** / `...ForLargeValue` — smoke testy volající reálnou `AudioService.shared.speakRetentionTime(seconds:)` s různými vstupy (0, 15, 3600). Nezavolá `AVAudioPlayer`, jen `AVSpeechSynthesizer` v fallback režimu — lze spouštět i bez bundle zvuků.

15. **`testPlayBreathingInFemaleFallsBackToMale`** — test na úrovni file lookupu, vyžaduje buď přidání testovacího bundle, nebo injektovatelný `Bundle` (viz doporučení D).

### D. Architekturní doporučení pro testovatelnost (mimo scope "napiš testy")

- `AudioService` je nyní singleton s přímým přístupem k `Bundle.main`. Doporučuji přidat init `init(bundle: Bundle = .main)` a `static let shared`, aby test mohl injektovat vlastní bundle s fixture `.m4a`.
- `ConfigurationViewModel` volá `AudioService.shared` přímo v `didSet` — blokuje čistý unit test bez side-effektů. Doporučuji injektovat `AudioServiceProtocol` do init (default `AudioService.shared`).

---

## Následné kroky (priority)

1. **P1 — Opravit `testBreathingSoundsArePlayedWhenEnabled`** (`breaths: 6` + delší čekání). Jediný red test, blokuje CI.
2. **P1 — Doinstalovat SwiftLint** (`brew install swiftlint`) nebo dokumentovat v CI, že krok lint je přeskočený.
3. **P2 — Přidat testy na `runRetentionTicker` + `speakRetentionTime`** (body 4, 5, 6, 14). Nová logika je kritická pro "retention announce" feature a má nulové pokrytí.
4. **P2 — Rozšířit `ConfigurationViewModelTests`** o čtyři nová pole (body 9–13). Bez toho není persistence konfigurace regresně chráněna.
5. **P3 — Vyčistit Swift 6 warnings v testech** (`MockAudioService.calls`, `ConfigurationViewModelTests.defaults`). S přechodem na Swift 6 to jinak bude build error.
6. **P3 — Refaktor pro testovatelnost audia** (bod D) — otevírá cestu k reálnému testu female/male fallback logiky.
