//
//  HistoryExportPage.swift
//  Febra
//

import SwiftUI

/// The single-page layout an export renders to PDF (#42): a title block, the
/// history chart, a thresholds legend, a chronological readings/medications
/// table and the medical disclaimer. Pinned to light mode on a white page so it
/// prints legibly regardless of the device theme.
struct HistoryExportPage: View {
    let export: HistoryExport

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            chart
            legend
            table
            footer
        }
        .padding(32)
        .frame(width: HistoryExport.pageWidth, alignment: .leading)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(export.memberName)
                .font(.title.weight(.bold))
            Text(export.subtitle)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var chart: some View {
        if export.readings.isEmpty {
            Text("Im gewählten Zeitraum gibt es keine Messungen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            TemperatureChartView(
                readings: export.readings,
                medications: export.medications,
                trend: nil,
                thresholds: export.thresholds,
                accentColor: export.accentColor
            )
        }
    }

    private var legend: some View {
        Label(export.thresholdsLegend, systemImage: "ruler")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var table: some View {
        let rows = export.rows
        if !rows.isEmpty {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("Zeit")
                    Text("Temperatur")
                    Text("Medikament")
                    Text("Notiz")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                Divider().gridCellColumns(4)

                ForEach(rows) { row in
                    GridRow(alignment: .firstTextBaseline) {
                        Text(row.timestamp, format: .dateTime.day().month().hour().minute())
                            .font(.footnote)
                            .monospacedDigit()

                        if let temperature = row.temperature {
                            Text(temperature.asTemperature)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(row.level?.color ?? .primary)
                                .monospacedDigit()
                        } else {
                            Text("—").font(.footnote).foregroundStyle(.secondary)
                        }

                        Text(row.medication ?? "—")
                            .font(.footnote)
                            .foregroundStyle(row.medication == nil ? .secondary : .primary)

                        Text(row.note ?? "")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Text("Erstellt mit Febra am \(export.generatedAt.formatted(.dateTime.day().month().year().hour().minute()))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(AppCopy.medicalDisclaimer)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let store = FamilyStore.preview
    let member = store.members.first!
    return ScrollView {
        HistoryExportPage(
            export: HistoryExport(
                member: member,
                range: .week,
                readings: store.readings(for: member.id),
                medications: store.medications(for: member.id)
            )
        )
    }
}
