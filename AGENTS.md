# AGENTS.md

Notes for AI coding agents working in this repo. Febra is a single-platform
**iOS** app; the Xcode project lives at `src/`. Read
[src/CLAUDE.md](src/CLAUDE.md) for architecture, build/test commands and code
conventions, and [src/CONTRIBUTING.md](src/CONTRIBUTING.md) for the human-facing
workflow.

## The two rules that define this app

1. **Local-only.** No accounts, no backend, no network calls, no analytics, no
   third-party SDKs. Everything lives in one JSON file on the device.
2. **Manual entry only.** The user types every measurement in. No Bluetooth
   thermometer, no HealthKit import, no background capture.

A change that breaks either rule is a product decision, not an implementation
detail — ask the owner first.

## Releases

Version bumps are manual in this repo. In an ordinary feature/fix PR:

- Add the changelog bullet under `## [Unreleased]` in `src/CHANGELOG.md` (and,
  when user-facing, a plain-language **German** bullet in
  `src/USER_CHANGELOG.md`) and **stop**.
- Do **not** promote `## [Unreleased]` to a dated `## [X.Y.Z]` heading, bump
  `MARKETING_VERSION` / `src/version.txt`, or create tags — that happens in a
  separate release commit.

`CURRENT_PROJECT_VERSION` (the App Store build number) is stamped from Xcode
Cloud's `$CI_BUILD_NUMBER` by `src/ci_scripts/ci_pre_xcodebuild.sh`, so it is
strictly increasing per upload without anyone editing it.
