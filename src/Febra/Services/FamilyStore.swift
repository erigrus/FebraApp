//
//  FamilyStore.swift
//  Febra
//

import Foundation
import Observation
import os

/// Single source of truth for the household, its members, readings and doses.
///
/// Febra is **local-only**: everything lives in one JSON file in the app's
/// Application Support directory (spec §2.4). There is no account, no server and
/// no network access — the data never leaves the device (beyond the user's own
/// encrypted device/iCloud *backup*, like any other app document). Volumes are
/// tiny (a few hundred entries), so every mutation rewrites the whole file
/// synchronously; there is no partial-write state to reason about.
@MainActor
@Observable
final class FamilyStore {
    private(set) var members: [FamilyMember] = []
    private(set) var readings: [TemperatureReading] = []
    private(set) var medications: [MedicationDose] = []
    /// The household's catalog of medications and their dosing intervals (#41).
    private(set) var medicationTypes: [MedicationType] = []

    /// Where the snapshot is persisted. `nil` puts the store in **memory mode**
    /// (previews, unit tests): mutations only touch the in-memory arrays and no
    /// file is ever written.
    private let fileURL: URL?
    private let logger = Logger(subsystem: "com.erigrus.FebraLocal", category: "FamilyStore")

    /// Live store backed by the on-disk snapshot (`FamilyStore.defaultFileURL`).
    /// Loads it synchronously at launch — the file is small, and having the data
    /// present before the first frame avoids an empty-dashboard flash. The label
    /// is required so the no-argument `FamilyStore()` unambiguously means memory
    /// mode.
    init(fileURL: URL?) {
        self.fileURL = fileURL
        load()
    }

    // ponytail: memory mode keeps previews and unit tests off the file system
    init(
        members: [FamilyMember] = [],
        readings: [TemperatureReading] = [],
        medications: [MedicationDose] = [],
        medicationTypes: [MedicationType] = []
    ) {
        self.fileURL = nil
        self.members = members.sorted(by: Self.byName)
        self.readings = readings
        self.medications = medications
        self.medicationTypes = medicationTypes
    }

    // MARK: - Persistence

    /// `Application Support/Febra/data.json`. `nil` only if the directory can't
    /// be resolved, which puts the store in memory mode rather than crashing.
    static var defaultFileURL: URL? {
        guard let base = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return base.appending(path: "Febra/data.json")
    }

    /// The persisted snapshot. Encoded with ISO-8601 dates so the file stays
    /// readable and stable across OS and locale changes.
    private struct Snapshot: Codable {
        var members: [FamilyMember] = []
        var readings: [TemperatureReading] = []
        var medications: [MedicationDose] = []
        var medicationTypes: [MedicationType] = []
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func load() {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let snapshot = try Self.makeDecoder().decode(Snapshot.self, from: data)
            members = snapshot.members.sorted(by: Self.byName)
            readings = snapshot.readings
            medications = snapshot.medications
            medicationTypes = snapshot.medicationTypes
        } catch {
            // A corrupt file must not brick the app: start empty, but keep the
            // damaged copy aside so nothing is silently destroyed.
            logger.error("Daten konnten nicht gelesen werden: \(error.localizedDescription)")
            try? FileManager.default.moveItem(at: fileURL, to: fileURL.appendingPathExtension("corrupt"))
        }
    }

    /// Rewrites the snapshot. Called after every mutation; a no-op in memory mode.
    private func save() {
        guard let fileURL else { return }
        let snapshot = Snapshot(
            members: members,
            readings: readings,
            medications: medications,
            medicationTypes: medicationTypes
        )
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // Health data: written atomically, and unreadable while the device
            // is locked.
            try Self.makeEncoder().encode(snapshot)
                .write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            logger.error("Daten konnten nicht gesichert werden: \(error.localizedDescription)")
        }
    }

    private static func byName(_ lhs: FamilyMember, _ rhs: FamilyMember) -> Bool {
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    // MARK: - Members

    func addMember(_ member: FamilyMember) {
        members.append(member)
        members.sort(by: Self.byName)
        save()
    }

    func updateMember(_ member: FamilyMember) {
        guard let index = members.firstIndex(where: { $0.id == member.id }) else { return }
        members[index] = member
        members.sort(by: Self.byName)
        save()
    }

    /// Removes the member together with all of their readings and doses.
    func removeMember(_ memberID: UUID) {
        members.removeAll { $0.id == memberID }
        readings.removeAll { $0.memberID == memberID }
        medications.removeAll { $0.memberID == memberID }
        save()
    }

    func member(with id: UUID) -> FamilyMember? {
        members.first { $0.id == id }
    }

    // MARK: - Readings

    func addReading(_ reading: TemperatureReading) {
        readings.append(reading)
        save()
    }

    /// Corrects an existing reading in place (value / time / note), keyed by its
    /// `id` so the timeline entry is edited rather than duplicated (#47).
    func updateReading(_ reading: TemperatureReading) {
        guard let index = readings.firstIndex(where: { $0.id == reading.id }) else { return }
        readings[index] = reading
        save()
    }

    func removeReading(_ readingID: UUID) {
        readings.removeAll { $0.id == readingID }
        save()
    }

    /// All readings of a member, newest first.
    func readings(for memberID: UUID) -> [TemperatureReading] {
        readings
            .filter { $0.memberID == memberID }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func latestReading(for memberID: UUID) -> TemperatureReading? {
        readings(for: memberID).first
    }

    // MARK: - Medications

    func addMedication(_ dose: MedicationDose) {
        medications.append(dose)
        save()
    }

    func removeMedication(_ doseID: UUID) {
        medications.removeAll { $0.id == doseID }
        save()
    }

    /// All doses of a member, newest first.
    func medications(for memberID: UUID) -> [MedicationDose] {
        medications
            .filter { $0.memberID == memberID }
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// Distinct medication names, most recently used first — feeds the
    /// "recently used" picker in the dose form (§2.6).
    var recentMedicationNames: [String] {
        var seen = Set<String>()
        return medications
            .sorted { $0.timestamp > $1.timestamp }
            .compactMap { dose in
                let name = dose.name.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty, seen.insert(name.lowercased()).inserted else { return nil }
                return name
            }
    }

    // MARK: - Medication catalog (#41)

    /// The catalog, sorted by name for the management screen and pickers.
    var sortedMedicationTypes: [MedicationType] {
        medicationTypes.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func addMedicationType(_ type: MedicationType) {
        medicationTypes.append(type)
        save()
    }

    func updateMedicationType(_ type: MedicationType) {
        if let index = medicationTypes.firstIndex(where: { $0.id == type.id }) {
            medicationTypes[index] = type
        } else {
            medicationTypes.append(type)
        }
        save()
    }

    func removeMedicationType(_ typeID: UUID) {
        medicationTypes.removeAll { $0.id == typeID }
        save()
    }

    /// The catalog entry whose name matches `name` (case-insensitive), if any —
    /// how a logged dose is joined back to its dosing interval.
    func medicationType(named name: String) -> MedicationType? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return medicationTypes.first { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    /// "Next safe dose" guidance for a member (#41): for every catalogued
    /// medication that carries a minimum interval and that the member has
    /// actually taken, the most recent dose plus that interval. Ordered by which
    /// dose becomes due first. Editing an interval in the catalog re-derives
    /// this — the interval is not frozen onto past doses.
    func doseGuidance(for memberID: UUID) -> [DoseGuidance] {
        let doses = medications(for: memberID)   // newest first
        return medicationTypes
            .compactMap { type -> DoseGuidance? in
                guard let interval = type.intervalHours, interval > 0 else { return nil }
                guard let last = doses.first(where: {
                    $0.name.caseInsensitiveCompare(type.name) == .orderedSame
                }) else { return nil }
                return DoseGuidance(name: type.name, lastDose: last.timestamp, intervalHours: interval)
            }
            .sorted { $0.nextDoseDate < $1.nextDoseDate }
    }
}

/// One row of "next safe dose" guidance: when a medication was last given and,
/// from its minimum interval, when it may next be given.
struct DoseGuidance: Identifiable {
    let name: String
    let lastDose: Date
    let intervalHours: Double

    var id: String { name.lowercased() }
    var nextDoseDate: Date { lastDose.addingTimeInterval(intervalHours * 3600) }
    /// The interval has elapsed — a next dose is within the reminder window.
    func isReady(asOf now: Date = .now) -> Bool { nextDoseDate <= now }
}
