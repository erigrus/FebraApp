//
//  WhatsNewView.swift
//  Febra
//

import SwiftUI

/// In-app "What's New": renders the bundled user changelog, newest release
/// first, with a coloured badge per category (spec: reuse of `USER_CHANGELOG.md`
/// as an in-app changelog screen). Reached from the dashboard "Mehr" menu.
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private let changelog: Changelog

    init(changelog: Changelog = .loadFromBundle()) {
        self.changelog = changelog
    }

    var body: some View {
        NavigationStack {
            Group {
                if changelog.releases.isEmpty {
                    ContentUnavailableView(
                        "Keine Neuigkeiten",
                        systemImage: "sparkles",
                        description: Text("Es liegen noch keine Versionshinweise vor.")
                    )
                } else {
                    releaseList
                }
            }
            .navigationTitle("Was ist neu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private var releaseList: some View {
        List {
            ForEach(changelog.releases) { release in
                Section {
                    ForEach(release.sections) { section in
                        ChangelogSectionView(section: section)
                    }
                } header: {
                    header(for: release)
                }
            }
        }
    }

    private func header(for release: Changelog.Release) -> some View {
        HStack {
            Text("Version \(release.version)")
            Spacer()
            if let date = release.date {
                Text(date, format: .dateTime.day().month().year())
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(nil)
    }
}

/// One `### Category` block: a badge followed by its bullet entries.
private struct ChangelogSectionView: View {
    let section: Changelog.Section

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CategoryBadge(category: section.category)
            ForEach(Array(section.entries.enumerated()), id: \.offset) { _, entry in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(.tertiary)
                    Text(entry)
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Small coloured capsule naming the change category.
private struct CategoryBadge: View {
    let category: Changelog.Category

    var body: some View {
        Text(category.label)
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch category {
        case .added: .green
        case .changed: .blue
        case .fixed: .orange
        case .removed: .red
        }
    }
}

#Preview {
    WhatsNewView(changelog: Changelog(releases: [
        Changelog.Release(
            version: "1.3.0",
            date: Date(),
            sections: [
                Changelog.Section(category: .changed, entries: [
                    "Fieber-Schwellen passen sich jetzt dem Alter jedes Familienmitglieds an."
                ]),
                Changelog.Section(category: .added, entries: [
                    "Deutliche Warnung, bei Babys unter 3 Monaten mit Fieber sofort ärztlichen Rat einzuholen."
                ])
            ]
        )
    ]))
}
