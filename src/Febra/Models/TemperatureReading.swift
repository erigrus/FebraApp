//
//  TemperatureReading.swift
//  Febra
//

import Foundation

/// A single body-temperature measurement in °C, assigned to a family member.
struct TemperatureReading: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var memberID: UUID
    /// Body temperature in degrees Celsius.
    var value: Double
    var timestamp: Date
    var note: String?

    init(
        id: UUID = UUID(),
        memberID: UUID,
        value: Double,
        timestamp: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.memberID = memberID
        self.value = value
        self.timestamp = timestamp
        self.note = note
    }

    /// The range a real human body temperature can fall in — from severe
    /// hypothermia to extreme hyperthermia. Anything outside it is not a
    /// possible measurement, only a mistyped entry. The single validity gate for
    /// the manual entry form.
    static let plausibleRange: ClosedRange<Double> = 34.0...43.0

    /// Whether `celsius` is a possible human body temperature. `ClosedRange`
    /// membership also rejects `NaN`/±infinity.
    static func isPlausible(_ celsius: Double) -> Bool {
        plausibleRange.contains(celsius)
    }
}
