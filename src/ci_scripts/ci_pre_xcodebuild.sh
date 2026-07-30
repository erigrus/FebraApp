#!/bin/sh
# Xcode Cloud pre-build script.
#
# Every Xcode Cloud run is handed a unique, strictly-increasing integer in
# $CI_BUILD_NUMBER. We stamp it into every CURRENT_PROJECT_VERSION in the Xcode
# project so each upload to App Store Connect / TestFlight has a build number
# greater than the last — App Store Connect rejects an upload whose build
# number isn't strictly increasing for the same MARKETING_VERSION.
#
# We rewrite *every* CURRENT_PROJECT_VERSION so all targets in the project keep
# a matching build number.
#
# MARKETING_VERSION is intentionally left untouched — that is the released
# version, bumped in a release commit (see src/CONTRIBUTING.md).
#
# Febra is local-only: there are no secrets, no service config plists and no
# third-party SDKs to fetch, so this is the only CI hook the project needs.
set -eu

PROJECT="$CI_PRIMARY_REPOSITORY_PATH/src/Febra.xcodeproj/project.pbxproj"

# BSD sed (macOS) requires an explicit empty suffix for in-place edits.
sed -i '' -E \
  "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${CI_BUILD_NUMBER};/g" \
  "$PROJECT"

echo "Stamped CURRENT_PROJECT_VERSION = ${CI_BUILD_NUMBER}"
