//
//  LocalizationTests.swift
//  FebraTests
//

import Foundation
import Testing
@testable import Febra

/// Guards the two halves of the localization: the string catalog (UI copy) and
/// the per-language changelog files (release-notes prose). Both are easy to
/// break by adding a string in one language only.
@MainActor
struct LocalizationTests {
    @Test func appShipsEnglishAndGerman() {
        #expect(Set(Bundle.main.localizations).isSuperset(of: ["en", "de"]))
    }

    @Test func germanCatalogIsCompiledIntoTheBundle() throws {
        let path = try #require(Bundle.main.path(forResource: "de", ofType: "lproj"))
        let german = try #require(Bundle(path: path))
        // A key with a genuinely different German string: if the catalog failed
        // to compile, the lookup falls back to the key itself.
        #expect(german.localizedString(forKey: "Overview", value: nil, table: nil) == "Übersicht")
        #expect(german.localizedString(forKey: "Next dose", value: nil, table: nil) == "Nächste Gabe")
    }

    @Test func changelogIsBundledForBothLanguages() {
        for language in ["en", "de"] {
            let changelog = Changelog.loadFromBundle(.main, language: language)
            #expect(!changelog.releases.isEmpty, "no releases parsed for \(language)")
        }
    }

    @Test func unknownLanguageFallsBackToEnglish() {
        let fallback = Changelog.loadFromBundle(.main, language: "fr")
        let english = Changelog.loadFromBundle(.main, language: "en")
        #expect(fallback == english)
    }
}
