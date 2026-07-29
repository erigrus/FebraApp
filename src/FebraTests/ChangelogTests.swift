//
//  ChangelogTests.swift
//  FebraTests
//

import Foundation
import Testing
@testable import Febra

struct ChangelogTests {

    private let sample = """
    # What's New

    Some intro text that should be ignored.

    ## [Unreleased]

    ### Added
    - Something not yet shipped.

    ## [1.3.0] - 2026-07-03

    ### Changed
    - Fever levels now match each family member's age: babies, children, and
      adults each get medically appropriate thresholds.

    ### Added
    - A clear warning to see a doctor right away.

    ## [1.2.0] - 2026-07-02

    ### Added
    - Neues App-Icon.
    """

    @Test
    func dropsUnreleasedSection() {
        let changelog = Changelog.parse(sample)
        #expect(changelog.releases.allSatisfy { $0.version != "Unreleased" })
        #expect(changelog.releases.map(\.version) == ["1.3.0", "1.2.0"])
    }

    @Test
    func parsesCategoriesAndEntries() throws {
        let changelog = Changelog.parse(sample)
        let first = try #require(changelog.releases.first)
        #expect(first.sections.map(\.category) == [.changed, .added])
        #expect(first.sections.first?.entries.count == 1)
        #expect(first.sections.last?.entries == ["A clear warning to see a doctor right away."])
    }

    @Test
    func rejoinsWrappedBullets() {
        let changelog = Changelog.parse(sample)
        let changed = changelog.releases.first?.sections.first
        #expect(changed?.entries.first?.contains("age: babies, children, and adults") == true)
        #expect(changed?.entries.first?.contains("\n") == false)
    }

    @Test
    func parsesReleaseDate() throws {
        let changelog = Changelog.parse(sample)
        let date = try #require(changelog.releases.first?.date)
        let utc = try #require(TimeZone(identifier: "UTC"))
        let components = Calendar(identifier: .gregorian).dateComponents(in: utc, from: date)
        #expect(components.year == 2026)
        #expect(components.month == 7)
        #expect(components.day == 3)
    }

    @Test
    func emptyMarkdownYieldsNoReleases() {
        #expect(Changelog.parse("").releases.isEmpty)
    }
}
