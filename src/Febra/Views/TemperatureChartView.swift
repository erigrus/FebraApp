//
//  TemperatureChartView.swift
//  Febra
//

import Charts
import SwiftUI

/// Selectable time window for the history chart (spec §2.5).
enum ChartRange: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case all

    var id: Self { self }

    var label: String {
        switch self {
        case .day: String(localized: "24 h")
        case .week: String(localized: "7 days")
        case .month: String(localized: "30 days")
        case .all: String(localized: "All")
        }
    }

    /// Start of the window, or `nil` for "All".
    func startDate(relativeTo now: Date = .now) -> Date? {
        switch self {
        case .day: now.addingTimeInterval(-24 * 3600)
        case .week: now.addingTimeInterval(-7 * 24 * 3600)
        case .month: now.addingTimeInterval(-30 * 24 * 3600)
        case .all: nil
        }
    }
}

/// Temperature history for one member: color-coded readings, fever-threshold
/// lines, medication markers on the timeline and an optional dashed forecast.
struct TemperatureChartView: View {
    /// Readings inside the selected range, ascending by time.
    let readings: [TemperatureReading]
    /// Doses inside the selected range.
    let medications: [MedicationDose]
    /// Trend to extrapolate; pass `nil` to hide the forecast.
    let trend: TemperatureTrend?
    /// Age-dependent bounds for the member's current age — threshold lines
    /// and point colors.
    let thresholds: FeverLevel.Thresholds
    let accentColor: Color

    /// Hours the dashed forecast line extends past the newest reading (§2.5:
    /// short-term, 2–4 h).
    static let forecastHours: Double = 3

    /// X position the user is scrubbing to, driving the detail callout (#46).
    @State private var selectedDate: Date?

    var body: some View {
        Chart {
            thresholdMarks
            readingMarks
            forecastMarks
            medicationMarks
            selectionMarks
        }
        .chartXSelection(value: $selectedDate)
        .chartYScale(domain: yDomain)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let celsius = value.as(Double.self) {
                        // Already-formatted text: `Text(String)` renders it
                        // verbatim, so no catalog key is needed for a number.
                        Text(celsius.asTemperature)
                    }
                }
            }
        }
        .frame(height: 260)
    }

    // MARK: - Marks

    @ChartContentBuilder
    private var thresholdMarks: some ChartContent {
        RuleMark(y: .value("Temperature", thresholds.fever))
            .foregroundStyle(.red.opacity(0.4))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .annotation(position: .topTrailing, alignment: .trailing) {
                Text("Fever")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

        RuleMark(y: .value("Temperature", thresholds.elevated))
            .foregroundStyle(.yellow.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .annotation(position: .topTrailing, alignment: .trailing) {
                Text("Elevated")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
    }

    @ChartContentBuilder
    private var readingMarks: some ChartContent {
        ForEach(readings) { reading in
            LineMark(
                x: .value("Time", reading.timestamp),
                y: .value("Temperature", reading.value),
                series: .value("Series", "Readings")
            )
            .foregroundStyle(accentColor.opacity(0.6))
            .interpolationMethod(.monotone)

            PointMark(
                x: .value("Time", reading.timestamp),
                y: .value("Temperature", reading.value)
            )
            .foregroundStyle(FeverLevel(celsius: reading.value, thresholds: thresholds).color)
        }
    }

    @ChartContentBuilder
    private var forecastMarks: some ChartContent {
        if let trend {
            ForEach(trend.forecastPoints(hoursAhead: Self.forecastHours), id: \.date) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Temperature", point.value),
                    series: .value("Series", "Forecast")
                )
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
            }
        }
    }

    @ChartContentBuilder
    private var medicationMarks: some ChartContent {
        ForEach(medications) { dose in
            PointMark(
                x: .value("Time", dose.timestamp),
                y: .value("Temperature", medicationBaseline)
            )
            .symbol {
                Image(systemName: "pills.fill")
                    .font(.caption)
                    .foregroundStyle(.indigo)
            }
        }
    }

    @ChartContentBuilder
    private var selectionMarks: some ChartContent {
        if let reading = selectedReading {
            RuleMark(x: .value("Time", reading.timestamp))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .annotation(
                    position: .top,
                    spacing: 4,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    callout(reading: reading, dose: selectedDose)
                }

            PointMark(
                x: .value("Time", reading.timestamp),
                y: .value("Temperature", reading.value)
            )
            .foregroundStyle(FeverLevel(celsius: reading.value, thresholds: thresholds).color)
            .symbolSize(160)
        }
    }

    /// Tap/scrub detail popover for the nearest reading and, when a dose sits
    /// close to the selection, that dose too (§2.6, #46).
    private func callout(reading: TemperatureReading, dose: MedicationDose?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(reading.value.asTemperature)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FeverLevel(celsius: reading.value, thresholds: thresholds).color)
                Text(reading.timestamp, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let note = reading.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let dose {
                Divider()
                Label("\(dose.name) · \(dose.dosage)", systemImage: "pills.fill")
                    .font(.caption)
                    .foregroundStyle(.indigo)
                Text(dose.timestamp, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: 200, alignment: .leading)
    }

    // MARK: - Selection

    /// Reading closest in time to the scrub position.
    private var selectedReading: TemperatureReading? {
        guard let selectedDate else { return nil }
        return readings.min {
            abs($0.timestamp.timeIntervalSince(selectedDate)) < abs($1.timestamp.timeIntervalSince(selectedDate))
        }
    }

    /// Dose closest to the scrub position, but only within `selectionTolerance`
    /// so an unrelated dose from elsewhere on the timeline isn't surfaced.
    private var selectedDose: MedicationDose? {
        guard let selectedDate else { return nil }
        return medications
            .min { abs($0.timestamp.timeIntervalSince(selectedDate)) < abs($1.timestamp.timeIntervalSince(selectedDate)) }
            .flatMap { abs($0.timestamp.timeIntervalSince(selectedDate)) <= selectionTolerance ? $0 : nil }
    }

    /// How close a dose must be to the scrub position to appear — 5% of the
    /// visible span, floored at 20 minutes for sparse data.
    private var selectionTolerance: TimeInterval {
        let times = readings.map(\.timestamp) + medications.map(\.timestamp)
        guard let first = times.min(), let last = times.max(), last > first else { return 45 * 60 }
        return max(last.timeIntervalSince(first) * 0.05, 20 * 60)
    }

    // MARK: - Scale

    /// Y range padded around the data, always spanning both thresholds.
    private var yDomain: ClosedRange<Double> {
        let values = readings.map(\.value)
        let lower = min((values.min() ?? 36.0) - 0.4, 36.0)
        let upper = max((values.max() ?? thresholds.fever) + 0.4, thresholds.fever + 0.4)
        return lower...upper
    }

    /// Y position for the medication icons, just above the lower edge.
    private var medicationBaseline: Double {
        yDomain.lowerBound + 0.15
    }
}

#Preview {
    let store = FamilyStore.preview
    let member = store.members.first!
    let readings = store.readings(for: member.id).sorted { $0.timestamp < $1.timestamp }
    return TemperatureChartView(
        readings: readings,
        medications: store.medications(for: member.id),
        trend: TemperatureTrend.compute(from: readings),
        thresholds: member.feverThresholds(),
        accentColor: member.colorTag.color
    )
    .padding()
}
