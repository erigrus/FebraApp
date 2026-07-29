//
//  FeverEpisodeTests.swift
//  FebraTests
//

import Foundation
import Testing
@testable import Febra

struct FeverEpisodeTests {
    private let memberID = UUID()
    private let now = Date(timeIntervalSince1970: 1_780_000_000)
    // 3 months – < 12 years: elevated ≥ 37.6, fever ≥ 38.5.
    private let thresholds = FeverLevel.Thresholds.child

    private func reading(hoursAgo: Double, _ value: Double) -> TemperatureReading {
        TemperatureReading(
            memberID: memberID,
            value: value,
            timestamp: now.addingTimeInterval(-hoursAgo * 3600)
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

    @Test func noReadingsYieldNoEpisodes() {
        #expect(FeverEpisode.episodes(from: [], thresholds: thresholds).isEmpty)
    }

    @Test func onlyNormalReadingsYieldNoEpisodes() {
        let readings = [reading(hoursAgo: 3, 36.8), reading(hoursAgo: 1, 37.2)]
        #expect(FeverEpisode.episodes(from: readings, thresholds: thresholds).isEmpty)
    }

    @Test func elevatedButNeverFeverIsNotAnEpisode() {
        // Stays in the elevated band (37.6–38.4) — never reaches fever (38.5).
        let readings = [reading(hoursAgo: 3, 37.8), reading(hoursAgo: 1, 38.2)]
        #expect(FeverEpisode.episodes(from: readings, thresholds: thresholds).isEmpty)
    }

    @Test func singleBoutAggregatesPeakAndSpan() throws {
        // Elevated shoulders around a fever peak form one episode.
        let readings = [
            reading(hoursAgo: 18, 37.8), // elevated shoulder = start
            reading(hoursAgo: 12, 39.4), // peak
            reading(hoursAgo: 4, 38.0),  // elevated shoulder = end
        ]
        let episodes = FeverEpisode.episodes(from: readings, thresholds: thresholds)
        #expect(episodes.count == 1)
        let episode = try #require(episodes.first)
        #expect(episode.peak.value == 39.4)
        #expect(episode.start == now.addingTimeInterval(-18 * 3600))
        #expect(episode.end == now.addingTimeInterval(-4 * 3600))
        #expect(abs(episode.duration - 14 * 3600) < 0.001)
    }

    @Test func normalReadingBetweenFeversSplitsEpisodes() {
        let readings = [
            reading(hoursAgo: 30, 39.0),
            reading(hoursAgo: 26, 36.7), // recovered
            reading(hoursAgo: 4, 38.8),  // relapse
        ]
        let episodes = FeverEpisode.episodes(from: readings, thresholds: thresholds)
        #expect(episodes.count == 2)
    }

    @Test func largeGapSplitsEpisodesEvenWithoutNormalReading() {
        // Two fever readings farther apart than the gap tolerance, with no
        // reading in between — treated as two separate bouts.
        let readings = [
            reading(hoursAgo: 40, 39.0),
            reading(hoursAgo: 2, 38.9),
        ]
        let episodes = FeverEpisode.episodes(
            from: readings,
            thresholds: thresholds,
            gapTolerance: 12 * 3600
        )
        #expect(episodes.count == 2)
    }

    @Test func episodesAreSortedNewestFirst() throws {
        let readings = [
            reading(hoursAgo: 40, 39.0),
            reading(hoursAgo: 2, 38.9),
        ]
        let episodes = FeverEpisode.episodes(from: readings, thresholds: thresholds)
        #expect(episodes.count == 2)
        #expect(episodes[0].start > episodes[1].start)
    }

    @Test func doseCountOnlyCountsDosesWithinTheEpisode() throws {
        let readings = [
            reading(hoursAgo: 18, 38.6),
            reading(hoursAgo: 12, 39.4),
            reading(hoursAgo: 4, 38.0),
        ]
        let doses = [
            dose(hoursAgo: 20), // before the episode window
            dose(hoursAgo: 14), // inside
            dose(hoursAgo: 6),  // inside
            dose(hoursAgo: 1),  // after the episode window
        ]
        let episodes = FeverEpisode.episodes(from: readings, doses: doses, thresholds: thresholds)
        let episode = try #require(episodes.first)
        #expect(episode.doseCount == 2)
    }

    @Test func singleFeverReadingHasNoDurationText() throws {
        let episodes = FeverEpisode.episodes(from: [reading(hoursAgo: 2, 39.0)], thresholds: thresholds)
        let episode = try #require(episodes.first)
        #expect(episode.duration == 0)
        #expect(episode.durationText == nil)
    }
}
