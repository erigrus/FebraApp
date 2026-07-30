# Febra

A local-only fever tracker for iOS, in English and German.

Track body temperature for everyone in the household: enter a measurement by
hand, see the history as a chart with age-dependent fever thresholds and a
trend, log medication doses with their minimum dosing interval, and export a
member's history as a PDF for the doctor.

**Everything stays on the device.** No account, no sign-in, no backend, no
analytics, no third-party SDKs — the app has no network access at all. Data is
stored in a single JSON file in the app's sandbox.

**Manual entry only.** A measurement enters the app exactly one way: you type it
in. There is no Bluetooth thermometer support and no import.

## Requirements

- iOS 26.0 or newer
- Xcode 27+ to build (iOS 27 SDK)

## Getting started

```sh
open src/Febra.xcodeproj   # ⌘R to run, ⌘U to test
```

No configuration, no keys, no packages to resolve.

## Repository layout

| Path | What |
|---|---|
| `src/Febra/` | App sources (SwiftUI) |
| `src/FebraTests/` | Unit tests (Swift Testing) |
| `src/FebraUITests/` | UI tests (XCTest) |
| `src/Febra/Localizable.xcstrings` | String catalog (English source, German translation) |
| `src/CHANGELOG.md` | Technical changelog |
| `src/USER_CHANGELOG.md` | User-facing "What's new" (bundled; `.de.md` is the German one) |
| `docs/` | Product spec |

See [src/CONTRIBUTING.md](src/CONTRIBUTING.md) for the development workflow and
[src/CLAUDE.md](src/CLAUDE.md) for architecture notes.

## Disclaimer

Febra makes no medical claims and does not replace seeing a doctor.

## Licence

[MIT](LICENSE)
