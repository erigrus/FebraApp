# Changelog

All notable changes to Febra are recorded here. The format is based on
[Keep a Changelog](https://keepachangelog.com/) and this project adheres to
[Semantic Versioning](https://semver.org/).

Febra is a single-platform iOS app, so entries are **not** platform-tagged.
Group each bullet under `### Added` / `### Changed` / `### Fixed` / `### Removed`.

Add your bullet under `## [Unreleased]` while developing. See
`src/CONTRIBUTING.md` → "Changelog and versioning" for how a release promotes it.

## [Unreleased]

## [1.0.0] - 2026-07-29

Initial release of Febra as a **local-only** fever tracker. The app is a
stripped-down descendant of the cloud-synced Febra: same tracking, analysis and
export, none of the backend.

### Added
- Local persistence: members, readings, medication doses and the medication list
  are stored in a single JSON file in Application Support, written atomically
  with `.completeFileProtection` after every change. A corrupt file is moved
  aside instead of overwritten, so the app never refuses to launch.
- Member profiles with name, optional birthdate and avatar color; deleting a
  member cascades to their readings and doses.
- Manual temperature entry with member assignment, correctable timestamp, note
  and validation against the plausible range of a human body temperature
  (34.0–43.0 °C). Readings can be edited in place or deleted with undo.
- History screen per member: Swift Charts graph with selectable range, age-
  dependent fever thresholds, linear-regression trend with a labeled short-term
  forecast, and fever-episode summaries.
- Medication logging with timeline markers, a medication list with minimum
  dosing intervals, and the derived "next dose" countdown.
- PDF export of a member's history (chart + table) for a doctor visit, for both
  the selected range and a single fever episode.
- Settings screen, reached from a gear button in the dashboard toolbar: the
  medication list, a link to iOS's per-app language setting, "What's new", the
  version/build number, the medical disclaimer and a statement that all data
  stays on the device. The dashboard's overflow menu is gone — its two entries
  moved here.
- Full English and German localization. English is the development language and
  the source of every string; German is a complete translation in the
  `Localizable.xcstrings` string catalog. Dates and numbers follow the device
  locale (nothing is pinned to `de_DE` any more), and the app can be switched
  per app in iOS Settings.
- In-app "What's new" screen rendered from the bundled changelog:
  `USER_CHANGELOG.md` (English) and `USER_CHANGELOG.de.md` (German) are both
  bundled, and the one matching the app language is parsed, falling back to
  English.

### Removed
- Firebase Auth, Firestore and Cloud Messaging, along with sign-in, family
  creation, invite codes and realtime sync between devices. There is no account
  and no network access.
- Bluetooth thermometer support (Braun ThermoScan 7+ pairing, the encrypted BLE
  protocol implementation, background sync via CoreBluetooth state restoration)
  and the unassigned-readings inbox it fed. Manual entry is the only input path.
- Fever push notifications and the Cloud Function behind them, plus the push
  diagnostics screen.
