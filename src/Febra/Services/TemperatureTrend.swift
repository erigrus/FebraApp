//
//  TemperatureTrend.swift
//  Febra
//

import Foundation

/// Linear-regression trend over the most recent readings of one member
/// (docs/family-fever-tracker-requirements.md §5). The extrapolation is a
/// rough hint, never a medical prediction — every UI surface showing it must
/// carry the disclaimer.
struct TemperatureTrend: Sendable {
    /// °C change per hour.
    let slopePerHour: Double
    /// Trend value at `referenceDate`.
    let referenceValue: Double
    let referenceDate: Date

    /// Readings the regression needs at minimum to be meaningful.
    static let minimumReadings = 3
    /// How many of the newest readings enter the regression.
    static let windowSize = 8
    /// Forecast values are clamped to this range so a steep short-term slope
    /// can't extrapolate to absurd temperatures.
    static let clampRange: ClosedRange<Double> = 34.0...43.0

    enum Direction: Sendable {
        case rising
        case falling
        case steady
    }

    /// Direction with a ±0.1 °C/h dead zone so noise doesn't flip the arrow.
    var direction: Direction {
        if slopePerHour > 0.1 { .rising }
        else if slopePerHour < -0.1 { .falling }
        else { .steady }
    }

    /// Least-squares fit over the newest `windowSize` readings. Returns `nil`
    /// with fewer than `minimumReadings` readings or when all timestamps
    /// coincide.
    static func compute(from readings: [TemperatureReading]) -> TemperatureTrend? {
        let window = readings
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(windowSize)
        guard window.count >= minimumReadings else { return nil }

        let reference = window.first!.timestamp
        // Hours before the newest reading (≤ 0) keep the numbers small.
        let points = window.map { reading in
            (x: reading.timestamp.timeIntervalSince(reference) / 3600, y: reading.value)
        }

        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumX2 = points.reduce(0) { $0 + $1.x * $1.x }

        let denominator = n * sumX2 - sumX * sumX
        guard abs(denominator) > .ulpOfOne else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        return TemperatureTrend(
            slopePerHour: slope,
            referenceValue: intercept,
            referenceDate: reference
        )
    }

    /// Trend value at `date`, clamped to `clampRange`.
    func value(at date: Date) -> Double {
        let hours = date.timeIntervalSince(referenceDate) / 3600
        let raw = referenceValue + slopePerHour * hours
        return min(max(raw, Self.clampRange.lowerBound), Self.clampRange.upperBound)
    }

    /// Extrapolated points from `referenceDate` for the dashed forecast line,
    /// one point every `stepMinutes`.
    func forecastPoints(hoursAhead: Double = 3, stepMinutes: Double = 30) -> [(date: Date, value: Double)] {
        guard hoursAhead > 0, stepMinutes > 0 else { return [] }
        let steps = Int((hoursAhead * 60 / stepMinutes).rounded(.down))
        return (0...steps).map { step in
            let date = referenceDate.addingTimeInterval(Double(step) * stepMinutes * 60)
            return (date: date, value: value(at: date))
        }
    }
}
