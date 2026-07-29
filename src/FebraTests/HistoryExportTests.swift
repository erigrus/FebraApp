//
//  HistoryExportTests.swift
//  FebraTests
//

import Foundation
import Testing
@testable import Febra

struct HistoryExportTests {
    private let memberID = UUID()
    private let now = Date(timeIntervalSince1970: 1_780_000_000)
    // 3 months – < 12 years: elevated ≥ 37.6, fever ≥ 38.5.
    private let thresholds = FeverLevel.Thresholds.child

    private func reading(hoursAgo: Double, _ value: Double, note: String? = nil) -> TemperatureReading {
        TemperatureReading(
            memberID: memberID,
            value: value,
            timestamp: now.addingTimeInterval(-hoursAgo * 3600),
            note: note
        )
    }

    private func dose(hoursAgo: Double) -> MedicationDose {
        MedicationDose(
            memberID: memberID,
            name: "Paracetamol",
            dosage: "250 mg",
            timestamp: now.addingTimeInterval(-hoursAgo * 3600)
        )
    }

    private func export(
        readings: [TemperatureReading],
        medications: [MedicationDose] = []
    ) -> HistoryExport {
        HistoryExport(
            memberName: "Emma",
            subtitle: "Verlauf · 24 h",
            thresholds: thresholds,
            accentColor: .pink,
            readings: readings,
            medications: medications,
            generatedAt: now
        )
    }

    @Test func rowsMergeReadingsAndDosesChronologically() {
        let e = export(
            readings: [reading(hoursAgo: 1, 38.0), reading(hoursAgo: 3, 39.0)],
            medications: [dose(hoursAgo: 2)]
        )
        let rows = e.rows
        #expect(rows.count == 3)
        // Oldest first: 3h reading, 2h dose, 1h reading.
        #expect(rows[0].temperature == 39.0)
        #expect(rows[1].medication == "Paracetamol · 250 mg")
        #expect(rows[1].temperature == nil)
        #expect(rows[2].temperature == 38.0)
    }

    @Test func readingRowsCarryFeverLevelAndNote() throws {
        let e = export(readings: [reading(hoursAgo: 1, 39.0, note: "schlapp")])
        let row = try #require(e.rows.first)
        #expect(row.level == .fever)
        #expect(row.note == "schlapp")
        #expect(row.medication == nil)
    }

    @Test func thresholdsLegendSpellsOutBounds() {
        let e = export(readings: [reading(hoursAgo: 1, 38.0)])
        #expect(e.thresholdsLegend == "Erhöht ab 37,6 °C · Fieber ab 38,5 °C")
    }

    @Test func fileNameStampsMemberAndDate() {
        let e = export(readings: [])
        #expect(e.fileName == "Febra-Emma-2026-05-28.pdf")
    }

    @Test func fileNameJoinsMultiWordName() {
        let e = HistoryExport(
            memberName: "Max Mustermann",
            subtitle: "Verlauf · 24 h",
            thresholds: thresholds,
            accentColor: .blue,
            readings: [],
            medications: [],
            generatedAt: now
        )
        #expect(e.fileName == "Febra-Max-Mustermann-2026-05-28.pdf")
    }

    @Test func rangeInitDescribesSelectedRange() {
        let member = FamilyMember(name: "Emma")
        let e = HistoryExport(member: member, range: .week, readings: [], medications: [])
        #expect(e.subtitle == "Verlauf · 7 Tage")
    }

    @Test func episodeInitKeepsOnlyDosesInsideTheWindow() throws {
        let readings = [
            reading(hoursAgo: 18, 38.6),
            reading(hoursAgo: 12, 39.4),
            reading(hoursAgo: 4, 38.0),
        ]
        let doses = [
            dose(hoursAgo: 20), // before the window
            dose(hoursAgo: 14), // inside
            dose(hoursAgo: 1),  // after the window
        ]
        let member = FamilyMember(name: "Emma")
        let episode = try #require(
            FeverEpisode.episodes(from: readings, thresholds: thresholds).first
        )
        let e = HistoryExport(member: member, episode: episode, doses: doses)
        #expect(e.medications.count == 1)
        #expect(e.subtitle.hasPrefix("Fieber-Episode · "))
    }
}
