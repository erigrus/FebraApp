# What's new

User-facing release notes in plain language. These entries are shown on the
in-app "What's new" screen and reused verbatim as the App Store "What's New"
text — keep them friendly and free of internal jargon, but still grouped under
`### Added` / `### Changed` / `### Fixed` so each category can render its own
badge.

This file is the **English** source; `USER_CHANGELOG.de.md` holds the German
translation and must be updated in the same PR. The headings
(`## [X.Y.Z] - YYYY-MM-DD`, `### Added` …) are parsed, not displayed, so they
stay English in every language file.

Add entries under `## [Unreleased]` while developing. Every build a user runs is
a released build, so `## [Unreleased]` is never shown in the app.

## [Unreleased]

## [1.0.0] - 2026-07-29

### Added
- Febra is here: track fever for everyone in the family — with a history chart,
  age-dependent fever thresholds and a trend.
- All data stays on your device. No account, no sign-in, no cloud — Febra
  doesn't even need an internet connection.
- You enter measurements yourself: temperature, person, time and an optional
  note. Entries can be corrected or deleted afterwards.
- Log medications: name, dose and time appear right in the chart, so you can see
  how the fever behaves afterwards.
- Medication list with a minimum interval: Febra shows you when the next dose is
  possible. That's a reminder, not a medical dosing recommendation.
- Fever episodes are summarised automatically — with the peak, the duration and
  the number of doses.
- Export a history as a PDF, for example for a doctor's visit.
- English and German: the app follows your device language and can be switched
  per app in iOS Settings.
- A settings screen behind the gear icon, with the medication list, the language
  setting, "What's new" and the app version.
