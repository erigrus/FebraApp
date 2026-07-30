//
//  MedicationDose.swift
//  Febra
//

import Foundation

/// A logged medication dose, independent of temperature readings
/// (docs/family-fever-tracker-requirements.md §2.6).
struct MedicationDose: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var memberID: UUID
    var name: String
    /// Free-text dosage, e.g. "5 ml" or "250 mg".
    var dosage: String
    var timestamp: Date
    var note: String?

    init(
        id: UUID = UUID(),
        memberID: UUID,
        name: String,
        dosage: String,
        timestamp: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.memberID = memberID
        self.name = name
        self.dosage = dosage
        self.timestamp = timestamp
        self.note = note
    }
}
