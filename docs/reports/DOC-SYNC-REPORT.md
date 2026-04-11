# Doc Sync Report — 2026-04-11

Synchronizace dokumentace s aktuálním stavem projektu po bloku změn v audio subsystému, picker obrazovkách a konfiguraci session.

## Aktualizované soubory

### `docs/ARCHITECTURE.md`

1. **Models (§ Models)** — přidány záznamy pro:
   - `GuidanceCatalog` (statický katalog hlasových stylů; MVP = pouze `classic`)
   - `MusicCatalog` (statický katalog stop; MVP = `sweet_and_spicy` free, `forest_treasure` premium)
   - Rozšířen popis `SessionConfiguration` o nová pole: `musicVolume`, `guidanceVolume`, `retentionAnnounceInterval`, `breathingSoundsVoice` (`male`/`female`), `breathingSoundsVolume`, rozdělení music/guidance per phase (breathing vs retention) s track/style ID, `hapticFeedback`, `pingAndGong`.

2. **Views → Configuration feature** — doplněn seznam nových picker sheetů:
   - `MusicPickerView`
   - `GuidanceStylePickerView`
   - `BreathingSoundsPickerView` (volba hlasu male/female, slider hlasitosti, preview)
   - Zmínka o slideru retention announce interval (0/15/30/45/60 s) v `GuidanceSettingsSection`.

3. **Services → AudioService** — kompletně přepsán popis API, aby odpovídal rozšířenému `AudioServiceProtocol`:
   - `setGuidanceVolume`, `setBreathingVolume` — nezávislé hlasitosti
   - `playBreathingIn(voice:)` / `playBreathingOut(voice:)` / `previewBreathing(voice:)` s fallbackem male pokud female soubor chybí
   - `speakRetentionTime(seconds:)` pro hlasové oznamování času v retention
   - SFX soubory rozšířeny o `breathing_in_female.m4a` a `breathing_out_female.m4a`

### `README.md`

- Rozšířena struktura složek (zmínka o `GuidanceCatalog`/`MusicCatalog`, SFX audio male+female, lokalizační catalog).
- Přidána nová sekce **Klíčové features** shrnující audio/guidance konfiguraci, picker obrazovky, retention announce a zvuky dýchání ve dvou variantách hlasu.

## Záměrně neupravené

- **`CLAUDE.md`** — po kontrole všech sekcí odpovídá realitě. Poznámka o `AVSpeechSynthesizer` fallbacku se vztahuje primárně na guidance audio soubory, které stále nejsou v bundle, takže je stále platná. Sekce state machine, konvence složek, freemium gates a barvy odpovídají kódu.
- **`docs/agents/`** — agent specs, mimo scope Doc Sync.
- **`docs/reports/`** — historické reporty, nedotýkat.
- **Session state machine diagram** v `ARCHITECTURE.md` — přechody se nezměnily, zůstává beze změny.
- **`RetentionPhaseView`** — zvětšení pulzu je řešeno rozsahem scale 0.95→1.05 na sdíleném `BreathCircleView`; architektonicky se nic nezměnilo, není potřeba doplňovat do docs.

## Drift / upozornění pro uživatele

1. **Lokalizační klíče** — dokumentace zmiňuje namespacing `config.*`, `session.*` atd., ale neobsahuje vyčerpávající seznam. Nové klíče (`config.guidance.retention_announce`, picker tituly, `common.off` apod.) jsou v `Localizable.xcstrings`, ale nejsou explicitně listovány v architektuře. Pokud chceš, může být do ARCHITECTURE přidána tabulka namespace → sekce, ale to je spíše nice-to-have.
2. **`GuidanceCatalog` / `MusicCatalog`** — momentálně tvrdě kódované seznamy. Pokud v budoucnu přejdou na JSON nebo dynamický zdroj, bude potřeba dokumentaci znovu aktualizovat.
3. **Freemium tabulka v ARCHITECTURE** — stále odkazuje na `MusicSettingsSection` a `GuidanceSettingsSection` jako gate pointy. Reálně gate existuje i v nových picker views (`MusicPickerView`, `GuidanceStylePickerView`). Pokud chceš přesnost, gate řádek lze přepsat na „picker views tracků/stylů". Ponecháno, protože sekce logicky stále vlastní gate (pickery jsou jen UI).
4. **BreathingSoundsPickerView** nemá freemium gate — female hlas je zatím pro všechny. Až se přidá premium rozdělení, bude potřeba zmínit v sekci Freemium gating.
