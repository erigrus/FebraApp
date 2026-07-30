//
//  PreviewData.swift
//  Febra
//

import Foundation

extension FamilyStore {
    /// In-memory store with a small fever episode for previews.
    @MainActor
    static var preview: FamilyStore {
        let emma = FamilyMember(
            name: "Emma",
            birthdate: Calendar.current.date(byAdding: .year, value: -4, to: .now),
            colorTag: .pink
        )
        let ben = FamilyMember(
            name: "Ben",
            birthdate: Calendar.current.date(byAdding: .year, value: -7, to: .now),
            colorTag: .teal
        )

        let now = Date.now
        let emmaValues: [(hoursAgo: Double, value: Double)] = [
            (30, 37.1), (26, 37.6), (22, 38.4), (18, 39.1),
            (14, 38.6), (10, 38.0), (6, 37.9), (2, 37.4),
        ]
        let readings = emmaValues.map { sample in
            TemperatureReading(
                memberID: emma.id,
                value: sample.value,
                timestamp: now.addingTimeInterval(-sample.hoursAgo * 3600)
            )
        } + [
            TemperatureReading(
                memberID: ben.id,
                value: 36.8,
                timestamp: now.addingTimeInterval(-5 * 3600)
            )
        ]

        let medications = [
            MedicationDose(
                memberID: emma.id,
                name: "Paracetamol",
                dosage: "250 mg",
                timestamp: now.addingTimeInterval(-17 * 3600),
                note: "suppository"
            ),
            MedicationDose(
                memberID: emma.id,
                name: "Ibuprofen",
                dosage: "5 ml",
                timestamp: now.addingTimeInterval(-8 * 3600)
            ),
        ]

        let medicationTypes = [
            MedicationType(name: "Paracetamol", intervalHours: 6, defaultDosage: "250 mg"),
            MedicationType(name: "Ibuprofen", intervalHours: 8, defaultDosage: "5 ml"),
        ]

        return FamilyStore(
            members: [emma, ben],
            readings: readings,
            medications: medications,
            medicationTypes: medicationTypes
        )
    }
}
