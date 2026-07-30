# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## What Febra is

A **local-only** fever tracker for iOS. Two constraints define the app and both
are load-bearing — do not erode them without an explicit decision from the owner:

1. **No network.** No accounts, no backend, no analytics, no third-party SDKs.
   All data lives in one JSON file on the device (`FamilyStore`).
2. **Manual entry only.** A measurement enters the app exactly one way: the user
   types it in. No Bluetooth thermometers, no HealthKit import, no background
   capture.

The product spec lives in `docs/family-fever-tracker-requirements.md`.

## Layout

Febra is a single-platform **iOS** app. The Xcode project is rooted at `src/`
(`src/Febra.xcodeproj`) — all paths and commands below are relative to the repo
root unless noted. There is no Android port and no app-extension target.

## Build & test

**Xcode 27+** is required to build (the app is built against the iOS 27 SDK),
but it **runs on iOS 26.0+** (`IPHONEOS_DEPLOYMENT_TARGET = 26.0` on every
target).

```sh
# Open in Xcode (⌘R to run, ⌘U to test)
open src/Febra.xcodeproj

# Full test suite from CLI
xcodebuild test -project src/Febra.xcodeproj -scheme Febra \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Single test (Swift Testing) — filter by symbol
xcodebuild test -project src/Febra.xcodeproj -scheme Febra \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FebraTests/SomeTests
```

The project uses Xcode's **synchronized folder groups** — adding files under
`src/Febra/` is auto-picked up; you do not need to edit `project.pbxproj`.

## Architecture

- `Models/` — value types (`FamilyMember`, `TemperatureReading`,
  `MedicationDose`, `MedicationType`, `FeverLevel`, `Changelog`), all `Codable`.
- `Services/FamilyStore.swift` — the single `@MainActor @Observable` store,
  injected via `.environment(...)`. It owns the in-memory arrays *and* the JSON
  file; every mutation rewrites the snapshot. `FamilyStore()` (no arguments) is
  **memory mode** for previews and tests; `FamilyStore(fileURL:)` is the live
  store.
- `Services/` also holds pure derivations — `TemperatureTrend`, `FeverEpisode`,
  `HistoryExport` — which take values in and return values out, so they are
  testable without a store.
- `Views/` — SwiftUI only. Views read the store from the environment; they never
  touch the file system. `SettingsView` is the home for anything that isn't a
  per-member action (medication list, language, what's new, about).
- `Localizable.xcstrings` — the string catalog (source language English).

## Code conventions

- **Deployment target iOS 26.0, built with the iOS 27 SDK.** Everything should
  use iOS 26-era API. If an iOS 27-only API is genuinely needed, guard it behind
  `if #available(iOS 27, *)` with a graceful iOS 26 fallback — don't raise the
  deployment target.
- Use **Observation** macros (`@Observable`, `@Environment(SomeState.self)`) —
  not `ObservableObject` / `@StateObject`.
- `@MainActor` for anything that mutates UI state.
- Keep views small (extract sub-views past ~150 lines).
- Use **system semantic colours** (`.primary`, `.secondary`, `.red`, `.tint`) —
  no hardcoded hex. Use **SF Symbols** for icons.
- Prefer native idioms (`Label`, `ContentUnavailableView`, `.searchable`,
  Swift Charts) over reinvented chrome.
- **No new dependencies.** The project has zero Swift Package dependencies; keep
  it that way unless the owner asks otherwise.
- Tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`) for unit
  tests and **XCTest** (`XCUIApplication`) for UI tests.
- Commits follow **Conventional Commits** (`feat:`, `fix:`, `refactor:`,
  `chore:`, `test:`, `docs:`).

## Localization (English + German)

English is the **development language and the source of every string**; German
is a full translation (spec §3). Rules:

- Never write a German literal in code. UI copy is English in the source and
  translated in `src/Febra/Localizable.xcstrings`.
- A string inside a SwiftUI view initializer (`Text("Next dose")`,
  `Button("Save")`, `.navigationTitle(…)`) is a `LocalizedStringKey` and needs
  nothing extra.
- A string built anywhere else — an enum's `label`, a formatter, a `Toast`
  message — must be wrapped in `String(localized:)`, because `Text(someString)`
  renders a plain `String` **verbatim**.
- Do not pin `\.locale`: dates and numbers follow the device.
- Every new key needs a `de` entry in the catalog. `LocalizationTests` fails if
  the German catalog stops compiling into the bundle.
- Release notes are prose, not UI strings: `USER_CHANGELOG.md` is the English
  source and `USER_CHANGELOG.de.md` its translation. Both are bundled;
  `Changelog.loadFromBundle` picks by app language and falls back to English.
  `CHANGELOG.md` (technical) stays English only.

## Secrets

There are none — no service config plists, no API keys. Signing assets
(`*.p12`, `*.mobileprovision`, `*.cer`) and `.env*` files stay git-ignored.

## When changing behaviour

If a PR changes behaviour described in
`docs/family-fever-tracker-requirements.md`, update that doc in the same PR —
it's versioned product spec, not background reading.

## Branching and releases

- **`main`** is the default branch; feature/fix PRs target `main`.
- Version bumps are **manual** here (there is no release workflow yet):
  a release commit promotes `## [Unreleased]` to a dated heading in
  `src/CHANGELOG.md`, `src/USER_CHANGELOG.md` and `src/USER_CHANGELOG.de.md`,
  and sets `src/version.txt`
  plus every `MARKETING_VERSION` in `src/Febra.xcodeproj/project.pbxproj`.
- `CURRENT_PROJECT_VERSION` (the App Store build number) is stamped by
  `src/ci_scripts/ci_pre_xcodebuild.sh` from Xcode Cloud's `$CI_BUILD_NUMBER` on
  every build, so it is strictly increasing without hand-editing.

## App Store Connect identity

This app ships as its **own** App Store Connect record, separate from the
cloud-synced Febra it descends from:

| | |
|---|---|
| Bundle ID | `com.erigrus.FebraLocal` |
| Display name | Febra |
| Team | `X2QJU2LNJP` |

Do not reuse the old `com.egru.Febra` identifier — that is a different app.
