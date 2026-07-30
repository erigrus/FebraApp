//
//  FamilyMember.swift
//  Febra
//

import SwiftUI

/// A person readings are assigned to (e.g. a child) — distinct from an app
/// user with a login, per docs/family-fever-tracker-requirements.md §2.1.
struct FamilyMember: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var birthdate: Date?
    var colorTag: MemberColor

    init(id: UUID = UUID(), name: String, birthdate: Date? = nil, colorTag: MemberColor = .blue) {
        self.id = id
        self.name = name
        self.birthdate = birthdate
        self.colorTag = colorTag
    }

    /// Up-to-two-letter initials for the avatar circle.
    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }

    /// Whole years since `birthdate`, if set.
    func age(on date: Date = .now, calendar: Calendar = .current) -> Int? {
        guard let birthdate else { return nil }
        return calendar.dateComponents([.year], from: birthdate, to: date).year
    }

    /// Whole months since `birthdate`, if set — fever thresholds are banded
    /// by age in months.
    func ageInMonths(on date: Date = .now, calendar: Calendar = .current) -> Int? {
        guard let birthdate else { return nil }
        return calendar.dateComponents([.month], from: birthdate, to: date).month
    }

    /// Fever thresholds for this member's age at `date`. Pass the reading's
    /// timestamp so historic readings keep the bounds that applied back then.
    func feverThresholds(on date: Date = .now) -> FeverLevel.Thresholds {
        .forAge(inMonths: ageInMonths(on: date))
    }
}

/// Avatar tint chosen when creating a member. Raw values are stable and
/// persisted — do not rename cases.
enum MemberColor: String, Codable, CaseIterable, Sendable {
    case red, orange, yellow, green, teal, blue, indigo, purple, pink

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        }
    }
}
