//
//  FamilyStoreTests.swift
//  FebraTests
//

import Foundation
import Testing
@testable import Febra

/// All tests use the store's memory mode — nothing is written to disk.
@MainActor
struct FamilyStoreTests {
    private func makeStore() -> FamilyStore {
        FamilyStore()
    }

    @Test func memoryInitSeedsData() {
        let member = FamilyMember(name: "Emma")
        let store = FamilyStore(
            members: [member],
            readings: [TemperatureReading(memberID: member.id, value: 37.2)]
        )
        #expect(store.members.count == 1)
        #expect(store.readings.count == 1)
    }

    @Test func removingMemberCascadesToReadingsAndMedications() {
        let store = makeStore()
        let emma = FamilyMember(name: "Emma")
        let ben = FamilyMember(name: "Ben")
        store.addMember(emma)
        store.addMember(ben)
        store.addReading(TemperatureReading(memberID: emma.id, value: 38.2))
        store.addReading(TemperatureReading(memberID: ben.id, value: 36.9))
        store.addMedication(MedicationDose(memberID: emma.id, name: "Paracetamol", dosage: "250 mg"))

        store.removeMember(emma.id)

        #expect(store.members.map(\.id) == [ben.id])
        #expect(store.readings.map(\.memberID) == [ben.id])
        #expect(store.medications.isEmpty)
    }

    @Test func readingsForMemberAreNewestFirst() {
        let store = makeStore()
        let member = FamilyMember(name: "Emma")
        store.addMember(member)
        let older = TemperatureReading(memberID: member.id, value: 37.0, timestamp: .now.addingTimeInterval(-3600))
        let newer = TemperatureReading(memberID: member.id, value: 38.0, timestamp: .now)
        store.addReading(older)
        store.addReading(newer)

        #expect(store.readings(for: member.id).map(\.id) == [newer.id, older.id])
        #expect(store.latestReading(for: member.id)?.id == newer.id)
    }

    @Test func updateMemberReplacesExistingEntry() {
        let store = makeStore()
        var member = FamilyMember(name: "Emma")
        store.addMember(member)

        member.name = "Emma Marie"
        member.colorTag = .purple
        store.updateMember(member)

        #expect(store.members.count == 1)
        #expect(store.member(with: member.id)?.name == "Emma Marie")
        #expect(store.member(with: member.id)?.colorTag == .purple)
    }

    @Test func recentMedicationNamesAreDedupedNewestFirst() {
        let store = makeStore()
        let member = FamilyMember(name: "Emma")
        store.addMember(member)
        let now = Date.now
        store.addMedication(MedicationDose(
            memberID: member.id, name: "Paracetamol", dosage: "250 mg",
            timestamp: now.addingTimeInterval(-7200)
        ))
        store.addMedication(MedicationDose(
            memberID: member.id, name: "Ibuprofen", dosage: "5 ml",
            timestamp: now.addingTimeInterval(-3600)
        ))
        store.addMedication(MedicationDose(
            memberID: member.id, name: "paracetamol", dosage: "500 mg",
            timestamp: now
        ))

        #expect(store.recentMedicationNames == ["paracetamol", "Ibuprofen"])
    }

    @Test func isPlausibleGatesManualEntry() {
        #expect(TemperatureReading.isPlausible(34.0))
        #expect(TemperatureReading.isPlausible(37.2))
        #expect(TemperatureReading.isPlausible(43.0))
        #expect(!TemperatureReading.isPlausible(33.9))
        #expect(!TemperatureReading.isPlausible(43.1))
        #expect(!TemperatureReading.isPlausible(.nan))
        #expect(!TemperatureReading.isPlausible(.infinity))
    }

    // MARK: - Medication catalog (#41)

    @Test func medicationTypeCRUDAndSort() {
        let store = makeStore()
        var ibu = MedicationType(name: "Ibuprofen", intervalHours: 8)
        let para = MedicationType(name: "Paracetamol", intervalHours: 6, defaultDosage: "250 mg")
        store.addMedicationType(ibu)
        store.addMedicationType(para)

        // Sorted by name, case-insensitively.
        #expect(store.sortedMedicationTypes.map(\.name) == ["Ibuprofen", "Paracetamol"])

        ibu.intervalHours = 6
        store.updateMedicationType(ibu)
        #expect(store.medicationType(named: "ibuprofen")?.intervalHours == 6)

        store.removeMedicationType(para.id)
        #expect(store.sortedMedicationTypes.map(\.name) == ["Ibuprofen"])
    }

    @Test func doseGuidanceUsesLatestDoseAndCatalogInterval() throws {
        let store = makeStore()
        let emma = FamilyMember(name: "Emma")
        store.addMember(emma)
        store.addMedicationType(MedicationType(name: "Paracetamol", intervalHours: 6))
        // A catalogued medication with no interval yields no guidance.
        store.addMedicationType(MedicationType(name: "Vitamin D", intervalHours: nil))

        let now = Date.now
        store.addMedication(MedicationDose(
            memberID: emma.id, name: "Paracetamol", dosage: "250 mg",
            timestamp: now.addingTimeInterval(-8 * 3600)
        ))
        // Newer dose (case-insensitive match) is the one guidance builds on.
        store.addMedication(MedicationDose(
            memberID: emma.id, name: "paracetamol", dosage: "250 mg",
            timestamp: now.addingTimeInterval(-2 * 3600)
        ))
        // A dose with no catalogued interval is ignored.
        store.addMedication(MedicationDose(
            memberID: emma.id, name: "Vitamin D", dosage: "1 Tropfen",
            timestamp: now
        ))

        let guidance = store.doseGuidance(for: emma.id)
        #expect(guidance.count == 1)
        let para = try #require(guidance.first)
        #expect(para.name == "Paracetamol")
        // Last dose 2 h ago + 6 h interval → due in ~4 h, not yet ready.
        #expect(!para.isReady(asOf: now))
        #expect(abs(para.nextDoseDate.timeIntervalSince(now.addingTimeInterval(4 * 3600))) < 1)
    }

    @Test func doseGuidanceReadyWhenIntervalElapsed() {
        let store = makeStore()
        let emma = FamilyMember(name: "Emma")
        store.addMember(emma)
        store.addMedicationType(MedicationType(name: "Ibuprofen", intervalHours: 8))
        let now = Date.now
        store.addMedication(MedicationDose(
            memberID: emma.id, name: "Ibuprofen", dosage: "5 ml",
            timestamp: now.addingTimeInterval(-9 * 3600)
        ))

        let guidance = store.doseGuidance(for: emma.id)
        #expect(guidance.first?.isReady(asOf: now) == true)
    }

    @Test func removeReadingAndMedicationByID() {
        let store = makeStore()
        let member = FamilyMember(name: "Emma")
        store.addMember(member)
        let reading = TemperatureReading(memberID: member.id, value: 37.5)
        let dose = MedicationDose(memberID: member.id, name: "Paracetamol", dosage: "250 mg")
        store.addReading(reading)
        store.addMedication(dose)

        store.removeReading(reading.id)
        store.removeMedication(dose.id)

        #expect(store.readings.isEmpty)
        #expect(store.medications.isEmpty)
    }
}
