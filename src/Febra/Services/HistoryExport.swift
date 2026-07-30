//
//  HistoryExport.swift
//  Febra
//

import CoreGraphics
import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A printable snapshot of a member's temperature history for a doctor visit
/// (#42, spec §6.10). The value type keeps the data assembly testable without a
/// UI; `Transferable` lets a `ShareLink` export it straight to PDF via the
/// native `ImageRenderer` — no third-party dependency.
struct HistoryExport: Sendable {
    let memberName: String
    /// Second title line describing the exported scope, e.g. "History · 7 days"
    /// or "Fever episode · yesterday, 2:00 PM – today, 8:00 AM".
    let subtitle: String
    /// Age-dependent bounds — threshold lines in the chart and the legend text.
    let thresholds: FeverLevel.Thresholds
    let accentColor: Color
    /// Readings inside the exported scope, ascending by time.
    let readings: [TemperatureReading]
    /// Doses inside the exported scope.
    let medications: [MedicationDose]
    /// When the export was produced — printed in the footer.
    let generatedAt: Date

    init(
        memberName: String,
        subtitle: String,
        thresholds: FeverLevel.Thresholds,
        accentColor: Color,
        readings: [TemperatureReading],
        medications: [MedicationDose],
        generatedAt: Date = .now
    ) {
        self.memberName = memberName
        self.subtitle = subtitle
        self.thresholds = thresholds
        self.accentColor = accentColor
        self.readings = readings.sorted { $0.timestamp < $1.timestamp }
        self.medications = medications.sorted { $0.timestamp < $1.timestamp }
        self.generatedAt = generatedAt
    }

    /// A4 portrait width in points; the page grows tall to fit its content.
    static let pageWidth: CGFloat = 595

    /// "Elevated from 37.6 °C · Fever from 38.5 °C" — the same thresholds the
    /// chart draws, spelled out for the doctor.
    var thresholdsLegend: String {
        let elevated = String(localized: "Elevated from \(thresholds.elevated.asTemperature)")
        let fever = String(localized: "Fever from \(thresholds.fever.asTemperature)")
        return "\(elevated) · \(fever)"
    }

    /// Suggested share-sheet file name, e.g. "Febra-Emma-2026-07-06.pdf".
    var fileName: String {
        let safeName = memberName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let stamp = generatedAt.formatted(.iso8601.year().month().day())
        let base = safeName.isEmpty ? "Febra" : "Febra-\(safeName)"
        return "\(base)-\(stamp).pdf"
    }

    /// Readings and doses merged into one chronological table, oldest first, so
    /// the table reads left-to-right in step with the chart above it.
    var rows: [Row] {
        let readingRows = readings.map { reading in
            Row(
                id: reading.id,
                timestamp: reading.timestamp,
                temperature: reading.value,
                level: FeverLevel(celsius: reading.value, thresholds: thresholds),
                medication: nil,
                note: reading.note
            )
        }
        let doseRows = medications.map { dose in
            Row(
                id: dose.id,
                timestamp: dose.timestamp,
                temperature: nil,
                level: nil,
                medication: "\(dose.name) · \(dose.dosage)",
                note: dose.note
            )
        }
        return (readingRows + doseRows).sorted { $0.timestamp < $1.timestamp }
    }

    /// One line of the readings/medications table.
    struct Row: Identifiable, Sendable {
        let id: UUID
        let timestamp: Date
        /// °C for a reading row; `nil` for a medication row.
        let temperature: Double?
        /// Fever level for coloring a reading; `nil` for a medication row.
        let level: FeverLevel?
        /// "Paracetamol · 5 ml" for a medication row; `nil` for a reading row.
        let medication: String?
        let note: String?
    }
}

extension HistoryExport {
    /// Export of the member's chart for the currently selected range.
    init(
        member: FamilyMember,
        range: ChartRange,
        readings: [TemperatureReading],
        medications: [MedicationDose],
        generatedAt: Date = .now
    ) {
        self.init(
            memberName: member.name,
            subtitle: String(localized: "History · \(range.label)"),
            thresholds: member.feverThresholds(),
            accentColor: member.colorTag.color,
            readings: readings,
            medications: medications,
            generatedAt: generatedAt
        )
    }

    /// Export of a single fever episode: its readings plus the doses given
    /// while it was running.
    init(
        member: FamilyMember,
        episode: FeverEpisode,
        doses: [MedicationDose],
        generatedAt: Date = .now
    ) {
        let window = episode.start...episode.end
        let span = "\(FeverEpisodeFormat.dayTime(episode.start)) – \(FeverEpisodeFormat.dayTime(episode.end))"
        self.init(
            memberName: member.name,
            subtitle: String(localized: "Fever episode · \(span)"),
            thresholds: member.feverThresholds(),
            accentColor: member.colorTag.color,
            readings: episode.readings,
            medications: doses.filter { window.contains($0.timestamp) },
            generatedAt: generatedAt
        )
    }
}

// MARK: - PDF rendering

extension HistoryExport {
    enum ExportError: Error { case renderingFailed }

    /// Renders the export to a single-page PDF using the native `ImageRenderer`.
    @MainActor
    func pdfData() throws -> Data {
        let renderer = ImageRenderer(content: HistoryExportPage(export: self))
        let data = NSMutableData()
        var rendered = false

        renderer.render { size, renderInContext in
            var mediaBox = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: data as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
            else { return }
            context.beginPDFPage(nil)
            renderInContext(context)
            context.endPDFPage()
            context.closePDF()
            rendered = true
        }

        guard rendered else { throw ExportError.renderingFailed }
        return data as Data
    }
}

extension HistoryExport: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { export in
            try await MainActor.run { try export.pdfData() }
        }
        .suggestedFileName { $0.fileName }
    }
}
