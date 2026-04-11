# Breath — Release Checklist

Master checklist pro první submission do App Store. Odškrtávej postupně.

## 1. Právní dokumenty (hostování)

- [ ] Publikovat `docs/legal/privacy-policy.md` na veřejné URL
  - Doporučení: GitHub Pages (`martin-cookie.github.io/breath-legal/privacy`) nebo vlastní doména (`breath.martinkoci.cz/privacy`)
- [ ] Publikovat `docs/legal/terms-of-service.md` na veřejné URL
- [ ] Aktualizovat URL v `Breath/Views/Settings/SettingsView.swift:63-70` (odstranit TODO komentáře)
- [ ] Nastavit reálný support email v `SettingsView.swift:72` (teď: `support@martinkoci.cz`)

## 2. Apple Developer účet

- [ ] Apple Developer Program členství aktivní (99 USD/rok)
- [ ] App ID zaregistrovaný: `cz.martinkoci.breath`
- [ ] App Group zaregistrovaný: `group.cz.martinkoci.breath` (pro Widget)
- [ ] Capabilities: App Groups povolené pro obě App ID
- [ ] Signing certificate (Distribution) a Provisioning Profile vygenerované

## 3. Xcode projekt

- [ ] `project.yml` → `DEVELOPMENT_TEAM: "XXXXXXXXXX"` (tvoje Team ID)
- [ ] Spustit `xcodegen generate`
- [ ] Otevřít v Xcode, v Signing & Capabilities vybrat „Automatically manage signing"
- [ ] Ověřit, že jak Breath, tak BreathWidget target mají App Group `group.cz.martinkoci.breath`
- [ ] Bumpnout `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` podle potřeby

## 4. StoreKit — IAP

- [ ] V App Store Connect vytvořit non-consumable IAP: `cz.martinkoci.breath.pro`
- [ ] Nastavit cenu (doporučeno Tier odpovídající 99 Kč / 3,99 USD / 3,99 EUR)
- [ ] Vyplnit lokalizace (cs + en) — název, popis
- [ ] Nahrát review screenshot IAP (vyžadováno Applem)
- [ ] Ověřit, že `Constants.Freemium.premiumProductID` v kódu odpovídá ID v App Store Connect

## 5. App Store Connect — App záznam

- [ ] Vytvořit nový app záznam (Primary language: Czech)
- [ ] Vyplnit metadata z `docs/release/app-store-metadata.md`:
  - [ ] Název, podtitul
  - [ ] Description (cs + en)
  - [ ] Keywords (cs + en)
  - [ ] Promotional text
  - [ ] What's New (pro první release: „Initial release")
  - [ ] Category: Health & Fitness (primary), Lifestyle (secondary)
  - [ ] Age rating: 4+
- [ ] Nahrát screenshoty (viz bod 6)
- [ ] Privacy URL, Support URL, Marketing URL
- [ ] App Privacy questionnaire — viz níže

### App Privacy questionnaire

Breath nesbírá žádná data. Odpovědi:

- **Data Used to Track You:** None
- **Data Linked to You:** None
- **Data Not Linked to You:** None

Výsledek: „Data Not Collected". Transparentní a snadné.

## 6. Screenshoty

- [ ] Spustit `scripts/generate-screenshots.sh`
- [ ] Ověřit výstup v `build/screenshots/`
- [ ] Nahrát 6.7" (iPhone 17 Pro Max) a 6.5" screenshoty do App Store Connect
- [ ] Minimálně 3 screenshoty (doporučeno 5–7): Configuration, Session breathing, Session retention, Stats, Paywall

## 7. Test na reálném zařízení

- [ ] Archive → iOS Device → Validate
- [ ] Spustit přes TestFlight Internal (bez Review)
- [ ] Projít celý flow na skutečném iPhonu:
  - [ ] Onboarding (3 strany, skip, next)
  - [ ] Cvičení: breathing → retention → recovery → další round
  - [ ] Ukládání do SwiftData, Stats history
  - [ ] Paywall otevře se na zamčenou feature, fallback cena
  - [ ] Purchase (sandbox account)
  - [ ] Restore purchase
  - [ ] Widget na home screen
  - [ ] Notifications permission + doručení připomínky
  - [ ] Share results
  - [ ] Reset statistik
  - [ ] Smazání všech dat

## 8. TestFlight

- [ ] Archive pro Release konfiguraci
- [ ] Upload do App Store Connect (Xcode → Distribute App → App Store Connect)
- [ ] Počkat na „Processing" (10–30 min)
- [ ] Přidat Internal testery, případně External
- [ ] Sbírat feedback minimálně 3 dny před submission

## 9. Submission

- [ ] Finální review metadat a screenshotů
- [ ] Submit for Review
- [ ] Pokud Rejected: přečíst důvod, opravit, resubmit
- [ ] Pokud Approved: Release (manual nebo automatic)

## 10. Po releasu

- [ ] Oznámit release (social, email, web)
- [ ] Sledovat crash reporty v Xcode Organizer
- [ ] Sledovat ratings & reviews v App Store Connect
- [ ] Plán na v1.0.1 (bug fixes) a v1.1.0 (první feature iterace)

---

## Odkazy

- App Store metadata: [app-store-metadata.md](app-store-metadata.md)
- Privacy Policy: [../legal/privacy-policy.md](../legal/privacy-policy.md)
- Terms of Service: [../legal/terms-of-service.md](../legal/terms-of-service.md)
- Screenshot skript: [../../scripts/generate-screenshots.sh](../../scripts/generate-screenshots.sh)
