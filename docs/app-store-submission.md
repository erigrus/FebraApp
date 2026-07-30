---
title: App Store submission
---

# App Store Connect submission — Febra 1.0.0

Everything needed to fill in the App Store Connect forms for the first
submission. Copy is final and within Apple's character limits (counts noted).
Anything that needs a decision from you is marked **DECIDE**.

Related files: [privacy-policy.md](privacy-policy.md) (English),
[privacy-policy.de.md](privacy-policy.de.md) (German),
[support.md](support.md).

## URLs at a glance

Every URL App Store Connect asks for. All of them are live pages on erigrus.de,
maintained in the [erigrus-website](https://github.com/erigrus/erigrus-website)
repo under `febra/` (German) and `febra/en/` (English).

| Field | German localization (primary) | English (U.S.) localization |
|---|---|---|
| Privacy Policy URL | `https://erigrus.de/febra/privacy/` | `https://erigrus.de/febra/en/privacy/` |
| Support URL | `https://erigrus.de/febra/support/` | `https://erigrus.de/febra/en/support/` |
| Marketing URL | `https://erigrus.de/febra/` | `https://erigrus.de/febra/en/` |

Privacy Choices URL: leave empty (nothing is collected, so there is nothing to
opt out of).

**Contact address.** The erigrus.de pages give `info@erigrus.de`, matching the
rest of that site and its Impressum; the drafts here give
`erik.gruschka@mailbox.org`. Pick one for the public pages if you want them
identical — the store forms themselves don't ask for an address.

---

## 1. App record

| Field | Value |
|---|---|
| Platform | iOS |
| Name | `Febra` |
| Primary language | German (Germany) |
| Bundle ID | `com.erigrus.FebraLocal` |
| SKU | `com.erigrus.FebraLocal` |
| Team | Erik Gruschka — `X2QJU2LNJP` |
| User access | Full Access |

> The name only becomes available once the existing app is renamed to
> *Febra Connect* (App Store Connect → old app → App Information → Name). It has
> never been released, so that edit applies immediately.

## 2. App Information

| Field | Value |
|---|---|
| Primary category | Health & Fitness |
| Secondary category | Medical |
| Content rights | Does not contain, show, or access third-party content |
| Age rating | 4+ — see below |
| Localizations | German (Germany) *primary*, English (U.S.) |

**Category choice.** Health & Fitness as primary keeps the listing out of the
stricter Medical bucket, which is right: Febra records numbers the user types in
and draws a chart. It makes no diagnosis and gives no dosing advice. Medical as
secondary still surfaces it to people searching for fever apps.

**Age rating questionnaire.** Answer **None** to every question, including
*Medical or Treatment Information* — the app provides no medical information,
only the user's own records, and the dosing interval is a reminder the user
configures themselves, labelled as such in-app. Result: **4+**.

**DECIDE:** if you would rather be conservative, answering *Infrequent/Mild* to
*Medical or Treatment Information* yields **12+**. Either is defensible; 4+
matches comparable fever-tracking apps.

## 3. Pricing and availability

| Field | Value |
|---|---|
| Price | Free |
| Availability | All countries and regions |
| Pre-orders | No |
| Distribution | App Store (no Custom App, no Unlisted) |

## 4. App Privacy

Answer the questionnaire: **"Data Not Collected."**

Nothing is collected, transmitted or shared. The app has no network code, no
account, no analytics and no third-party SDKs; all data is written to one file
in the app's own container. Nothing else in the questionnaire applies — no
tracking, no data types, no third-party partners.

| Field | Value |
|---|---|
| Privacy Policy URL (German localization) | `https://erigrus.de/febra/privacy/` |
| Privacy Policy URL (English localization) | `https://erigrus.de/febra/en/privacy/` |
| Privacy Choices URL | *(leave empty)* |

Both URLs are live pages on erigrus.de, mirroring
[privacy-policy.de.md](privacy-policy.de.md) and
[privacy-policy.md](privacy-policy.md). They are maintained in the
[erigrus-website](https://github.com/erigrus/erigrus-website) repo under
`febra/privacy/` and `febra/en/privacy/` — when a policy changes here, update
that repo in the same pass. The `erigrus.github.io/FebraApp/…` Pages copies stay
as the developer-facing drafts; the store listing points at erigrus.de.

## 5. Store listing — German (primary)

**Name** (30 max, 5 used)
```
Febra
```

**Subtitle** (30 max, 28 used)
```
Fieber im Blick, ganz privat
```

**Promotional text** (170 max, 121 used) — editable any time without review
```
Fieber eintragen, Verlauf sehen, Medikamente mitschreiben. Ohne Konto, ohne Cloud – alle Daten bleiben auf deinem iPhone.
```

**Keywords** (100 max, 95 used) — comma-separated, no spaces after commas
```
fieber,thermometer,temperatur,kind,baby,gesundheit,tagebuch,verlauf,medikamente,offline,familie
```

**Description** (4000 max, 1678 used)
```
Febra ist ein Fieber-Tagebuch für die ganze Familie – schlicht, schnell und komplett offline.

Du trägst jede Messung selbst ein: Temperatur, Person, Zeitpunkt, auf Wunsch eine Notiz. Febra macht daraus eine übersichtliche Verlaufskurve mit altersabhängigen Fieber-Grenzen, einem Trend und einer kurzen Hochrechnung der nächsten Stunden.

ALLES BLEIBT AUF DEINEM GERÄT
Kein Konto, keine Anmeldung, keine Cloud, keine Werbung, keine Analyse-Dienste. Febra braucht nicht einmal eine Internetverbindung. Deine Daten liegen ausschließlich in der App und sind nur in deiner eigenen Gerätesicherung enthalten.

FÜR DIE GANZE FAMILIE
Lege für jedes Familienmitglied ein Profil mit Namen, Geburtsdatum und Farbe an. Die Fieber-Grenzen richten sich automatisch nach dem Alter – Säuglinge unter drei Monaten bekommen zusätzlich den deutlichen Hinweis, sofort ärztlichen Rat einzuholen.

MEDIKAMENTE MITSCHREIBEN
Halte Gaben mit Name, Dosis und Zeitpunkt fest. Sie erscheinen direkt in der Kurve, sodass du siehst, wie das Fieber danach verläuft. In der Medikamentenliste hinterlegst du einen Mindestabstand, und Febra zeigt dir, wann die nächste Gabe möglich ist – als Erinnerung, nicht als ärztliche Dosierempfehlung.

FIEBER-EPISODEN UND PDF-EXPORT
Zusammenhängende Fieberphasen fasst Febra automatisch zusammen: Höchstwert, Dauer und Anzahl der Gaben. Für den Arztbesuch exportierst du den Verlauf mit einem Tippen als PDF – mit Kurve, Tabelle und Grenzwerten.

DEUTSCH UND ENGLISCH
Febra folgt der Sprache deines Geräts und lässt sich in den iOS-Einstellungen pro App umstellen.

Febra ersetzt keine ärztliche Beratung. Bei hohem oder anhaltendem Fieber bitte ärztlichen Rat einholen.
```

**What's New** (4000 max) — first version, so this field is unused; from 1.1.0
on, paste the matching section of `src/USER_CHANGELOG.de.md`.

**Support URL:** `https://erigrus.de/febra/support/`
**Marketing URL:** `https://erigrus.de/febra/`
**Copyright:** `2026 Erik Gruschka`

## 6. Store listing — English (U.S.)

**Subtitle** (30 max, 28 used)
```
Fever tracking, kept private
```

**Promotional text** (170 max, 106 used)
```
Log a fever, see the history, note the medication. No account, no cloud — everything stays on your iPhone.
```

**Keywords** (100 max, 95 used)
```
fever,thermometer,temperature,child,baby,health,diary,history,medication,offline,family,tracker
```

**Description** (4000 max, 1548 used)
```
Febra is a fever diary for the whole family — simple, quick and completely offline.

You enter every measurement yourself: temperature, person, time, and a note if you want one. Febra turns that into a clear history chart with age-dependent fever thresholds, a trend, and a short extrapolation of the next few hours.

EVERYTHING STAYS ON YOUR DEVICE
No account, no sign-in, no cloud, no ads, no analytics. Febra does not even need an internet connection. Your data lives in the app alone, and travels only in your own device backup.

FOR THE WHOLE FAMILY
Create a profile for each family member with a name, date of birth and colour. Fever thresholds follow each person's age automatically — and for infants under three months, Febra adds a clear prompt to seek medical advice immediately.

KEEP TRACK OF MEDICATION
Record doses with name, amount and time. They appear right in the chart, so you can see how the fever behaves afterwards. Give a medication a minimum interval in the medication list and Febra shows you when the next dose is possible — a reminder you set yourself, not a medical dosing recommendation.

FEVER EPISODES AND PDF EXPORT
Febra groups a bout of fever automatically and summarises its peak, duration and number of doses. For a doctor's visit, export the history as a PDF in one tap — chart, table and thresholds included.

ENGLISH AND GERMAN
Febra follows your device language and can be switched per app in iOS Settings.

Febra is no substitute for medical advice. With a high or persistent fever, please consult a doctor.
```

**Support URL:** `https://erigrus.de/febra/en/support/`
**Marketing URL:** `https://erigrus.de/febra/en/`
**Copyright:** `2026 Erik Gruschka`

## 7. Screenshots

**DECIDE — iPad.** `TARGETED_DEVICE_FAMILY = "1,2"`, so the app claims iPad
support and App Store Connect will therefore *require* iPad screenshots. Two
ways out:

- **Ship iPad too:** produce the 13" set as well as the iPhone set.
- **iPhone only:** change `TARGETED_DEVICE_FAMILY` to `"1"` and no iPad
  screenshots are needed. One-line project change — say the word.

| Device | Size | Count |
|---|---|---|
| iPhone 6.9" (iPhone 17 Pro Max) | 1320 × 2868 | 3–10, required |
| iPad 13" (iPad Pro M4) | 2064 × 2752 | 3–10, required only while iPad is supported |

Apple scales the 6.9" set down for smaller iPhones, so one iPhone set is enough.

Suggested five, in order, captured in both languages (Scheme → Options → App
Language):

1. **Dashboard with two members**, one showing a fever value in red.
   *DE: „Alle auf einen Blick" · EN: "Everyone at a glance"*
2. **Member detail with the chart**, 24 h range, threshold lines and a
   medication marker visible.
   *DE: „Verlauf mit Fieber-Grenzen" · EN: "History with fever thresholds"*
3. **Add-temperature sheet**, a value typed in, level footer visible.
   *DE: „In Sekunden erfasst" · EN: "Logged in seconds"*
4. **Next-dose card / medication list**, a countdown showing.
   *DE: „Nächste Gabe im Blick" · EN: "Next dose at a glance"*
5. **Settings**, showing "Alle Daten bleiben auf diesem Gerät".
   *DE: „Ohne Konto, ohne Cloud" · EN: "No account, no cloud"*

Seed the simulator with a realistic history first — `FamilyStore.preview` in
`src/Febra/Support/PreviewData.swift` is exactly that data if you want to match
it by hand.

**App icon:** currently the same artwork as Febra Connect
(`src/Febra/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, 1024 × 1024, no
alpha). Fine for review, but consider distinct art so the two apps are
distinguishable on one device.

## 8. Build, export compliance, review

**Build.** Xcode Cloud archives `main` and uploads to TestFlight;
`src/ci_scripts/ci_pre_xcodebuild.sh` stamps `CURRENT_PROJECT_VERSION` from
`$CI_BUILD_NUMBER`. Version string is `1.0.0`.

**Export compliance.** `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` is
already set, so App Store Connect will not ask. Correct: the app performs no
encryption of its own — file protection is the OS's.

**Sign-in required?** No. Leave the demo-account fields empty.

**Notes for the reviewer** (paste as-is):
```
Febra is a fully local fever tracker. There is no account, no sign-in and no server — the app makes no network requests at all, so it can be reviewed in Airplane Mode.

To exercise the app:
1. Tap "Mitglied hinzufügen" (Add member), enter any name, optionally a date of birth, and save.
2. Tap "Temperatur" (Temperature) in the bottom bar, enter e.g. 38.5, and save.
3. Tap the member's card to see the history chart, trend and timeline.
4. Tap "Medikament" (Medication) to log a dose; it appears as a marker in the chart.
5. The gear icon opens Settings (medication list, language, version).

The app displays only data the user has entered. It makes no diagnosis and gives no dosing recommendations. The optional minimum dosing interval is a user-configured reminder, and every screen that shows it carries a disclaimer, as does the dashboard: "Febra ersetzt keine ärztliche Beratung." ("Febra is no substitute for medical advice.")

The app is German-first with a full English localization; switch via Settings → Febra → Language.
```

**Version release:** Manually release this version (so you control the moment it
goes live).

## 9. Pre-submission checklist

- [ ] Old app renamed to *Febra Connect* in App Store Connect
- [ ] New app record created: name `Febra`, bundle ID `com.erigrus.FebraLocal`
- [ ] `erigrus.de/febra/` pages live: app, privacy and support in DE and EN
- [ ] Xcode Cloud workflow green; build 1.0.0 (n) visible in TestFlight
- [ ] Smoke test on a device in both languages
- [ ] iPad decision made (screenshots produced, or device family set to iPhone)
- [ ] Screenshots uploaded for DE and EN
- [ ] German and English listing copy pasted from this document
- [ ] App Privacy: "Data Not Collected"
- [ ] Age rating questionnaire answered
- [ ] Reviewer notes pasted
- [ ] Submit for review
