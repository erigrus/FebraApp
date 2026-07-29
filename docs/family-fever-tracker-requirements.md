# Family Fever Tracker (local) – Requirements & Project Plan

## 1. Project Overview
iOS app for recording, storing and analyzing body-temperature measurements for
the people in one household. Measurements are **entered by hand**, assigned to a
family member, stored **only on the device**, and displayed in a clear history
graph with fever thresholds, trend and short-term forecast.

Main use case: parents track fever for their children (and themselves) on one
phone, without an account, without a server and without any device pairing.

**Design constraints that define this app:**
- **Local-only.** No account, no cloud, no network access at all. The data lives
  in one JSON file in the app's Application Support directory and never leaves
  the device (beyond the user's own encrypted device/iCloud backup).
- **Manual entry only.** There is exactly one way a measurement enters the app:
  the user types it in. No Bluetooth thermometer, no import, no unattributed
  inbox to triage.

### Implementation status
Implemented: member profiles (§2.1), manual temperature entry with assignment,
correctable timestamp and note (§2.2/§2.3), local persistence (§2.4), the
dashboard and history graph with age-dependent fever thresholds, trend and a
labeled forecast (§2.5, §5), fever-episode summaries (§2.5), medication logging
with timeline markers plus the medication list and "next dose" guidance (§2.6),
PDF export for doctor visits (§6.10) and the in-app "Was ist neu" screen.

---

## 2. Functional Requirements

### 2.1 Member Management
- No sign-in, no accounts, no family/invite concept — the app opens straight
  onto the dashboard.
- Create member profiles: name, optional birthdate, avatar color.
- A "member" is simply a person measurements are assigned to (e.g. a toddler);
  there is no notion of an app user.
- Deleting a member removes their readings and doses with them.

### 2.2 Measurement Entry
- **Manual entry is the only input path.** Temperature in °C, member, timestamp
  (prefilled with now, correctable, never in the future) and an optional note.
- Values are validated against the possible range of a human body temperature
  (34.0–43.0 °C); anything outside it is rejected as a typo.
- Existing readings can be corrected in place or deleted (with undo).
- Explicitly **not** in scope: Bluetooth/BLE thermometers, HealthKit import,
  file import, background capture.

### 2.3 Reading Assignment
Because there is no shared measuring device, every reading is assigned to its
member at entry time. There is no unassigned inbox and nothing to triage.

### 2.4 Data Storage
- One JSON file in `Application Support/Febra/data.json`, written atomically
  after every change with `.completeFileProtection` (unreadable while the device
  is locked).
- Loaded synchronously at launch; the volumes involved (a few hundred entries)
  make anything more elaborate unnecessary.
- A corrupt file is moved aside (`data.json.corrupt`) instead of being
  overwritten, and the app starts empty rather than refusing to launch.
- No sync, no conflict resolution, no offline mode — being offline is the only
  mode.

### 2.5 History View & Analysis
- Graph per member (Swift Charts), selectable time range (24h/7 days/30 days/all).
- Color-coded fever thresholds, **age-dependent** (age computed from the member's
  birthdate at the reading's timestamp; core-equivalent/rectal measurement
  assumed; members without a birthdate use the adult bounds):

  | Age at reading | Normal (green) | Elevated (yellow) | Fever (red) |
  |---|---|---|---|
  | < 3 months | < 37.6 °C | 37.6–37.9 °C | ≥ 38.0 °C |
  | 3 months – < 12 years | < 37.6 °C | 37.6–38.4 °C | ≥ 38.5 °C |
  | ≥ 12 years | < 37.5 °C | 37.5–38.0 °C | ≥ 38.1 °C |

  - Infants < 3 months with fever additionally get a prominent "Sofort ärztlich
    abklären" warning (standard pediatric red flag).
- Fever-episode summary: readings are grouped into bouts of illness (contiguous
  readings at/above the elevated threshold with a gap tolerance; surfaced once
  the peak reaches the fever threshold). Each episode aggregates peak, start,
  duration and medication-dose count from existing data (no new storage). The
  member detail screen lists episodes; tapping one opens its summary card.
- Trend calculation: linear regression over the last n readings.
- Short-term forecast (next few hours' extrapolation) – **clearly labeled as
  "not a medical prediction/forecast"**.
- Dashboard/overview: current temperature per member, last measurement time,
  trend direction.

### 2.6 Medication Entries
- Log medication doses independently of temperature readings (separate entry
  flow, no reading required).
- Assignment to a member, timestamp (automatic, correctable).
- Fields: medication name (free text, picker from recently used, or picked from
  the medication list), dosage (e.g. "5 ml", "250 mg"), optional note.
- Displayed in the history graph as markers on the timeline, so the correlation
  between a dose and the temperature curve is visible at a glance.

**Medication list & dosing-interval guidance (#41).** The app keeps a local
catalog of medications, each with an optional default dosage and a **minimum
dosing interval**. Managed from the dashboard "Mehr" menu
("Medikamentenliste"); a new medication can also be added inline while logging a
dose. Picking a medication prefills its name and dosage. From the interval, the
member detail screen shows a live "Nächste Gabe" card — "in 2 Std. 10 Min." /
"Jetzt möglich" — derived from the most recent dose of that medication (no
per-dose storage; editing the interval re-derives the guidance). **Not medical
advice:** the interval is a user-configurable reminder, not a dosing
recommendation; the in-app disclaimer stays.

### 2.7 Notifications
Out of scope. There is no server to evaluate readings and no second device to
notify. Local reminders may be reconsidered later, but only as an on-device
feature.

---

## 3. Non-Functional Requirements
- **App language: German.** The app UI is German-only (no localization layer);
  this affects UI copy, date/number formatting (German locale) and terminology.
- Platform: iOS (Swift/SwiftUI). **Minimum supported OS: iOS 26**
  (`IPHONEOS_DEPLOYMENT_TARGET = 26.0`), built against the iOS 27 SDK with
  Xcode 27+.
- Privacy: children's health data is especially sensitive (GDPR Art. 9). Keeping
  everything on-device is the privacy design — no data collection, no analytics,
  no third-party SDKs, nothing to disclose beyond "Data Not Collected" in App
  Store Connect's privacy questionnaire.
- Performance: smooth graph rendering with several hundred data points.
- No claim of medical accuracy/diagnosis — the app does not replace seeing a
  doctor (disclaimer required in-app and in the store description).

---

## 4. Technical Architecture

### 4.1 App Layer
- SwiftUI + Swift Charts, iOS 26+.
- **No third-party dependencies.** No Swift Package dependencies at all.
- State lives in one `@MainActor @Observable` container (`FamilyStore`) injected
  via `.environment(...)`; persistence stays out of the views.

### 4.2 Persistence
A single Codable snapshot encoded as JSON (ISO-8601 dates), rewritten on every
mutation. No database engine, no migrations, no schema versioning until the
model actually needs it.

### 4.3 Data Model
```
data.json
  members: [
    { id, name, birthdate?, colorTag }
  ]
  readings: [
    { id, memberID, value: Double (°C), timestamp, note? }
  ]
  medications: [
    { id, memberID, name, dosage, timestamp, note? }
  ]
  medicationTypes: [                      // #41 medication list
    { id, name, intervalHours?, defaultDosage? }
  ]
```

### 4.4 Security
The file is protected by `.completeFileProtection` and the app sandbox. There is
no network surface to secure.

---

## 5. Trend/Forecast – Implementation Approach
- Simple linear regression over the last x readings of a member, client-side.
- Communicate the forecast only as a rough extrapolation, never as a "prediction"
  in a medical sense.

---

## 6. Phased Plan

**1.0**
1. Member profiles.
2. Manual entry + assignment.
3. History graph (Swift Charts) with age-dependent thresholds.
4. Trend line + labeled forecast.
5. Fever episodes.
6. Medication logging + timeline markers.
7. Medication list + "next dose" guidance.
8. Local persistence.
9. In-app "Was ist neu".
10. **Export** — PDF for doctor visits (#42): native `ImageRenderer` renders the
    history chart plus a readings/medications table (member, scope, thresholds
    legend, medical disclaimer) and `ShareLink` exports it, both for the selected
    chart range and for a single fever episode.

**Later (optional)**
- CSV export.
- Local reminders ("nächste Gabe möglich").
- HealthKit read/write, if it can be done without weakening the local-only
  promise.

---

## 7. Open Questions
- Should a manual backup/restore (export & import of `data.json`) be offered, so
  a user switching phones without an iCloud backup doesn't lose their history?
- Is HealthKit integration desired, or is a deliberately standalone solution the
  point?
