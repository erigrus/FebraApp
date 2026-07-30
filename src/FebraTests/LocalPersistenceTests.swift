//
//  LocalPersistenceTests.swift
//  FebraTests
//

import Foundation
import Testing
@testable import Febra

/// The local JSON file is the app's only storage, so a round trip through it is
/// the closest thing Febra has to an integration test.
@MainActor
struct LocalPersistenceTests {
    /// A unique file in a temporary directory, removed after the test body runs.
    private func withTemporaryFile(_ body: (URL) throws -> Void) rethrows {
        let url = URL.temporaryDirectory
            .appending(path: "FebraTests-\(UUID().uuidString)")
            .appending(path: "data.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try body(url)
    }

    @Test func dataSurvivesRelaunch() {
        withTemporaryFile { url in
            let emma = FamilyMember(name: "Emma", colorTag: .pink)
            let reading = TemperatureReading(memberID: emma.id, value: 38.4, note: "linkes Ohr")
            let dose = MedicationDose(memberID: emma.id, name: "Paracetamol", dosage: "250 mg")

            let first = FamilyStore(fileURL: url)
            first.addMember(emma)
            first.addReading(reading)
            first.addMedication(dose)
            first.addMedicationType(MedicationType(name: "Paracetamol", intervalHours: 6))

            // A fresh launch reads the same file.
            let second = FamilyStore(fileURL: url)
            #expect(second.members.map(\.id) == [emma.id])
            #expect(second.members.first?.colorTag == .pink)
            #expect(second.readings.map(\.id) == [reading.id])
            #expect(second.readings.first?.note == "linkes Ohr")
            #expect(second.medications.map(\.id) == [dose.id])
            #expect(second.sortedMedicationTypes.map(\.name) == ["Paracetamol"])
        }
    }

    @Test func timestampsRoundTripToTheSecond() {
        withTemporaryFile { url in
            // ISO-8601 encoding drops sub-second precision; whole seconds must
            // survive exactly so the timeline order never shifts.
            let timestamp = Date(timeIntervalSince1970: 1_780_000_000)
            let member = FamilyMember(name: "Ben")
            let store = FamilyStore(fileURL: url)
            store.addMember(member)
            store.addReading(TemperatureReading(memberID: member.id, value: 37.2, timestamp: timestamp))

            let reloaded = FamilyStore(fileURL: url)
            #expect(reloaded.readings.first?.timestamp == timestamp)
        }
    }

    @Test func deletionIsPersisted() {
        withTemporaryFile { url in
            let member = FamilyMember(name: "Emma")
            let store = FamilyStore(fileURL: url)
            store.addMember(member)
            store.addReading(TemperatureReading(memberID: member.id, value: 38.0))
            store.removeMember(member.id)

            let reloaded = FamilyStore(fileURL: url)
            #expect(reloaded.members.isEmpty)
            #expect(reloaded.readings.isEmpty)
        }
    }

    @Test func corruptFileStartsEmptyAndIsSetAside() throws {
        try withTemporaryFile { url in
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data("not json".utf8).write(to: url)

            let store = FamilyStore(fileURL: url)

            #expect(store.members.isEmpty)
            // The damaged file is kept next to the original instead of being
            // overwritten silently.
            #expect(FileManager.default.fileExists(atPath: url.appendingPathExtension("corrupt").path))
        }
    }

    @Test func memoryModeNeverWritesAFile() {
        withTemporaryFile { url in
            let store = FamilyStore()   // no file URL
            store.addMember(FamilyMember(name: "Emma"))
            #expect(!FileManager.default.fileExists(atPath: url.path))
        }
    }
}
