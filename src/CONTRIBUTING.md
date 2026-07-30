# Febra development guide

Internal reference for the Febra project. This document captures the conventions
we follow day-to-day so the codebase stays consistent. Febra is a
single-platform **iOS** app and a **local-only** one: no accounts, no backend,
and manual measurement entry as the single input path.

## Prerequisites

- **Xcode 27+**. The app is built against the iOS 27 SDK and runs on iOS 26.0+.
  Install an iOS 26 simulator runtime (Xcode → Settings → Components) to verify
  the minimum-supported OS.
- macOS 15+ (Apple Silicon recommended).
- Nothing else — the project has no dependencies, no service configuration and
  no secrets to obtain.

## Getting the source

```sh
git clone https://github.com/erigrus/FebraApp.git
cd FebraApp
open src/Febra.xcodeproj
```

Xcode's synchronized folder groups auto-pick up new files from `src/Febra/`, so
you usually don't have to touch `project.pbxproj`.

## Project structure

```
.
├── src/
│   ├── Febra.xcodeproj/
│   ├── Febra/                  # App sources
│   ├── FebraTests/             # Swift Testing unit tests
│   ├── FebraUITests/           # XCTest UI tests
│   ├── ci_scripts/             # Xcode Cloud hooks (ci_pre_xcodebuild.sh)
│   ├── CHANGELOG.md            # technical changelog (Keep a Changelog)
│   ├── USER_CHANGELOG.md       # curated user-facing "What's new" (English)
│   ├── USER_CHANGELOG.de.md    # its German translation
│   └── version.txt             # current released version
└── docs/
    └── family-fever-tracker-requirements.md   # product spec
```

## Workflow

For any non-trivial change (bug, feature, refactor):

1. **Issue first.** Check for an existing issue; if none matches, open one with
   the problem/intent before writing code. Skip only for true one-liners.
2. **Branch off `main`.** Name it after the issue: `fix/12-chart-range`,
   `feat/8-csv-export`, `refactor/20-extract-store`. Never commit directly to
   `main`.
3. **Open a PR early as draft.** Link the issue with `Closes #NN`. Mark "Ready
   for review" when done.
4. **Update the changelog before merge** (see below).
5. **Squash-merge** through the GitHub UI. Keep history linear.

## Branching and commits

- **`main` is the default branch** and the target for every PR.
- Commits use [**Conventional Commits**](https://www.conventionalcommits.org/):
  `feat:`, `fix:`, `refactor:` / `refactor(ui):`, `docs:`, `chore:`, `test:`.
- Subject under 72 characters; body covers the *why*.
- Don't amend after pushing — create a new commit.

## Pull requests

- Open as **draft** while WIP; title is a Conventional-Commit-style summary.
- Body covers: what changed, why, reviewer notes, and `Closes #NN`.
- If a PR changes behaviour described in
  `docs/family-fever-tracker-requirements.md`, update that doc in the same PR.

## Changelog and versioning

**In your feature/fix PR, do exactly this:**

- Add a bullet under `## [Unreleased]` in `src/CHANGELOG.md` for any change, in
  an `### Added` / `### Changed` / `### Fixed` / `### Removed` subsection. Febra
  is single-platform, so bullets are **not** platform-tagged.
- For any **user-visible** change, also add a friendly, plain-language bullet
  under `## [Unreleased]` in `src/USER_CHANGELOG.md` **and its German
  translation** in `src/USER_CHANGELOG.de.md` — those files are shown in the
  in-app "What's new" screen and reused as App Store release notes.
- Leave `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION` and `src/version.txt`
  alone, and leave the `## [Unreleased]` heading in place.

**Cutting a release** (a separate commit, not part of a feature PR):

1. Promote `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` in both changelogs and
   prepend a fresh empty `## [Unreleased]`.
2. Write the new version to `src/version.txt` and to every `MARKETING_VERSION`
   in `src/Febra.xcodeproj/project.pbxproj`.
3. Tag `vX.Y.Z` and create the GitHub Release, using the matching CHANGELOG
   section as the notes.

`CURRENT_PROJECT_VERSION` is *not* bumped by hand: Xcode Cloud's pre-build hook
stamps `$CI_BUILD_NUMBER` into every target, which guarantees a strictly
increasing build number per upload (App Store Connect rejects duplicates).

## Building & uploading to TestFlight / App Store

The signed build and its upload are produced by an **Xcode Cloud** workflow
configured in App Store Connect (not in this repo): select this repository, the
`Febra` scheme, an "App Store Connect – TestFlight" post-action and a `main`
branch trigger. The pre-build hook `src/ci_scripts/ci_pre_xcodebuild.sh` stamps
the build number.

This app has its **own** App Store Connect record, distinct from the
cloud-synced Febra it descends from:

| | |
|---|---|
| Bundle ID | `com.erigrus.FebraLocal` |
| Display name | Febra |
| Team | `X2QJU2LNJP` |

Since nothing is collected or transmitted, the App Store privacy questionnaire
is answered as **"Data Not Collected"**.

## Localization

The app ships **English (source) and German**. Working rules:

- English literals in code; translations in `src/Febra/Localizable.xcstrings`
  (Xcode's String Catalog editor).
- SwiftUI view initializers take a `LocalizedStringKey` and localize on their
  own. Anywhere else (enum labels, formatters, toast messages) use
  `String(localized:)` — `Text(aString)` renders verbatim.
- Never pin `\.locale`; dates and numbers follow the device.
- Add the `de` value for every new key in the same PR.
- Test both languages in the simulator by switching the scheme's App Language
  (Product → Scheme → Edit Scheme → Options), or per app in iOS Settings.

## Tests

- Unit tests use the **Swift Testing** framework (`import Testing`, `@Test`,
  `#expect`) in `src/FebraTests/`.
- UI tests use **XCTest** (`import XCTest`, `XCUIApplication`) in
  `src/FebraUITests/`.
- Add a test for any non-trivial pure logic (trend/regression math, threshold
  colouring, episode grouping, forecast extrapolation) and for anything touching
  the on-disk format — `LocalPersistenceTests` round-trips the store through a
  temporary file.
- Run with **⌘U** in Xcode or:
  ```sh
  xcodebuild test -project src/Febra.xcodeproj -scheme Febra \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
  ```

## Where things live

| You want to add… | Put it in… |
|---|---|
| App source (views, models, services) | `src/Febra/` |
| A unit test | `src/FebraTests/` |
| A UI test | `src/FebraUITests/` |
| A user-facing string | English in the code, `de` in `src/Febra/Localizable.xcstrings` |
| An Xcode Cloud CI hook | `src/ci_scripts/` |
| A product/design doc | `docs/` |

## Issue tracking

- **Bugs:** include device, iOS version, Xcode version, repro steps, and
  expected vs. actual.
- Triage labels: `bug`, `enhancement`, `refactor`, `chore`, `docs`.
