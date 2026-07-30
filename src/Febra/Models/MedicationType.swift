//
//  MedicationType.swift
//  Febra
//

import Foundation

/// A reusable medication the household maintains in a list (#41): a name, an
/// optional default dosage and — the point of the feature — a minimum dosing
/// interval used to compute the "next safe dose" countdown. Stored locally
/// alongside readings and doses.
///
/// Not medical advice: the interval is a user-configurable reminder, not a
/// dosing recommendation (spec §3).
struct MedicationType: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    /// Minimum hours between two doses; `nil` means "as needed" (no countdown).
    var intervalHours: Double?
    /// Prefilled into the dose form when this medication is picked, e.g. "250 mg".
    var defaultDosage: String?

    init(
        id: UUID = UUID(),
        name: String,
        intervalHours: Double? = nil,
        defaultDosage: String? = nil
    ) {
        self.id = id
        self.name = name
        self.intervalHours = intervalHours
        self.defaultDosage = defaultDosage
    }

    /// "every 6 hr" — the interval phrasing shared by the catalog rows, the
    /// dose-form picker and the suggestion menu.
    static func intervalText(_ hours: Double) -> String {
        String(localized: "every \(Int(hours)) hr")
    }

    /// Common starting points offered when the list is still empty. Intervals are
    /// widely-cited minimums for children's antipyretics — still user-editable and
    /// explicitly not a dosing recommendation.
    static let suggestions: [MedicationType] = [
        MedicationType(name: "Paracetamol", intervalHours: 6),
        MedicationType(name: "Ibuprofen", intervalHours: 8),
    ]
}
