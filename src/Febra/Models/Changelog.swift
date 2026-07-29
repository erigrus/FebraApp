//
//  Changelog.swift
//  Febra
//

import Foundation

/// The user-facing changelog, parsed from the bundled `USER_CHANGELOG.md`.
///
/// `USER_CHANGELOG.md` is the single source of truth for release notes (it is
/// also reused verbatim as App Store "What's New" copy) and is maintained by
/// the release workflow. We parse it into releases so the in-app "What's New"
/// screen can render each category with its own badge. The `[Unreleased]`
/// section is intentionally dropped — every build a user runs is a released
/// build, so it would never contain anything they haven't already got.
struct Changelog: Equatable {
    let releases: [Release]

    struct Release: Identifiable, Equatable {
        let version: String
        let date: Date?
        let sections: [Section]
        var id: String { version }
    }

    struct Section: Identifiable, Equatable {
        let category: Category
        let entries: [String]
        var id: String { category.rawValue }
    }

    /// A "Keep a Changelog" category. Unknown headings are ignored.
    enum Category: String, CaseIterable {
        case added = "Added"
        case changed = "Changed"
        case fixed = "Fixed"
        case removed = "Removed"

        /// German label shown on the in-app badge.
        var label: String {
            switch self {
            case .added: "Neu"
            case .changed: "Geändert"
            case .fixed: "Behoben"
            case .removed: "Entfernt"
            }
        }
    }
}

extension Changelog {
    /// Loads and parses `USER_CHANGELOG.md` from the app bundle. Returns an
    /// empty changelog if the resource is missing or unreadable.
    static func loadFromBundle(_ bundle: Bundle = .main) -> Changelog {
        guard let url = bundle.url(forResource: "USER_CHANGELOG", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return Changelog(releases: [])
        }
        return parse(text)
    }

    /// Parses "Keep a Changelog"-style markdown into released versions, newest
    /// first (the source file is already ordered that way). Bullets that wrap
    /// across several indented lines are re-joined into one entry.
    static func parse(_ markdown: String) -> Changelog {
        var releases: [Release] = []
        var version: String?
        var date: Date?
        var sections: [Section] = []
        var category: Category?
        var entries: [String] = []

        func flushSection() {
            if let category, !entries.isEmpty {
                sections.append(Section(category: category, entries: entries))
            }
            category = nil
            entries = []
        }
        func flushRelease() {
            flushSection()
            if let version, !sections.isEmpty {
                releases.append(Release(version: version, date: date, sections: sections))
            }
            sections = []
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") {
                flushRelease()
                (version, date) = parseReleaseHeader(String(line.dropFirst(3)))
            } else if line.hasPrefix("### ") {
                flushSection()
                category = Category(rawValue: String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces))
            } else if line.hasPrefix("- ") {
                entries.append(String(line.dropFirst(2)))
            } else if !line.isEmpty, !entries.isEmpty {
                // A wrapped continuation of the current bullet.
                entries[entries.count - 1] += " " + line
            }
        }
        flushRelease()

        return Changelog(releases: releases.filter { $0.version.caseInsensitiveCompare("Unreleased") != .orderedSame })
    }

    /// Splits a heading body like `[1.3.0] - 2026-07-03` (or `[Unreleased]`)
    /// into its version and optional date.
    private static func parseReleaseHeader(_ header: String) -> (String, Date?) {
        var version = header
        var date: Date?
        if let separator = header.range(of: " - ") {
            version = String(header[..<separator.lowerBound])
            let dateText = String(header[separator.upperBound...]).trimmingCharacters(in: .whitespaces)
            date = dateFormatter.date(from: dateText)
        }
        version = version.trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
        return (version, date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
