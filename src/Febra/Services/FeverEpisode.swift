//
//  FeverEpisode.swift
//  Febra
//

import Foundation

/// A single bout of illness: a contiguous stretch of a member's readings at or
/// above the elevated threshold, with a gap tolerance (§2.5). Peak, start,
/// duration and dose count are aggregated from data already in `FamilyStore` —
/// nothing new is stored (#49).
struct FeverEpisode: Identifiable, Sendable {
    /// Stable within a member's episode list: the peak reading's id.
    let id: UUID
    /// Readings that make up the episode, ascending by time.
    let readings: [TemperatureReading]
    /// The highest reading in the episode.
    let peak: TemperatureReading
    /// Medication doses logged while the episode was running.
    let doseCount: Int

    var start: Date { readings.first!.timestamp }
    var end: Date { readings.last!.timestamp }
    var duration: TimeInterval { end.timeIntervalSince(start) }

    /// Two consecutive elevated readings farther apart than this start separate
    /// episodes — a longer silence is treated as the fever having resolved and
    /// later returned rather than one continuous bout.
    static let defaultGapTolerance: TimeInterval = 12 * 3600

    /// Groups a member's readings into fever episodes, newest first.
    ///
    /// A run is any sequence of readings ≥ the elevated threshold with no gap
    /// longer than `gapTolerance`; a run is surfaced as an episode only once its
    /// peak reached the fever threshold, so a lone "erhöht" blip is ignored. The
    /// elevated shoulders are kept in the run so `start`/`duration` cover the
    /// full ramp-up and cool-down.
    static func episodes(
        from readings: [TemperatureReading],
        doses: [MedicationDose] = [],
        thresholds: FeverLevel.Thresholds,
        gapTolerance: TimeInterval = defaultGapTolerance
    ) -> [FeverEpisode] {
        let ascending = readings.sorted { $0.timestamp < $1.timestamp }

        var runs: [[TemperatureReading]] = []
        var current: [TemperatureReading] = []
        func flush() {
            if !current.isEmpty { runs.append(current) }
            current = []
        }

        for reading in ascending {
            let level = FeverLevel(celsius: reading.value, thresholds: thresholds)
            guard level != .normal else { flush(); continue }
            if let last = current.last,
               reading.timestamp.timeIntervalSince(last.timestamp) > gapTolerance {
                flush()
            }
            current.append(reading)
        }
        flush()

        let episodes = runs.compactMap { run -> FeverEpisode? in
            guard let peak = run.max(by: { $0.value < $1.value }),
                  FeverLevel(celsius: peak.value, thresholds: thresholds) == .fever
            else { return nil }
            let window = run.first!.timestamp...run.last!.timestamp
            let doseCount = doses.filter { window.contains($0.timestamp) }.count
            return FeverEpisode(id: peak.id, readings: run, peak: peak, doseCount: doseCount)
        }

        return episodes.sorted { $0.start > $1.start }
    }

    /// Locale-aware span, e.g. "18 Std." or "1 T 4 Std."; `nil` for a
    /// single-reading episode where the duration is zero.
    var durationText: String? {
        guard duration >= 60 else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = duration >= 3600 ? [.day, .hour] : [.hour, .minute]
        formatter.maximumUnitCount = 2
        return formatter.string(from: duration)
    }
}
