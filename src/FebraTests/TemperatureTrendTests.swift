//
//  TemperatureTrendTests.swift
//  FebraTests
//

import Foundation
import Testing
@testable import Febra

struct TemperatureTrendTests {
    private let memberID = UUID()
    private let now = Date(timeIntervalSince1970: 1_780_000_000)

    private func reading(hoursAgo: Double, value: Double) -> TemperatureReading {
        TemperatureReading(
            memberID: memberID,
            value: value,
            timestamp: now.addingTimeInterval(-hoursAgo * 3600)
        )
    }

    @Test func tooFewReadingsYieldNoTrend() {
        let readings = [reading(hoursAgo: 2, value: 37.0), reading(hoursAgo: 1, value: 37.5)]
        #expect(TemperatureTrend.compute(from: readings) == nil)
    }

    @Test func identicalTimestampsYieldNoTrend() {
        let readings = [
            reading(hoursAgo: 1, value: 37.0),
            reading(hoursAgo: 1, value: 37.5),
            reading(hoursAgo: 1, value: 38.0),
        ]
        #expect(TemperatureTrend.compute(from: readings) == nil)
    }

    @Test func perfectlyLinearRiseRecoversSlope() throws {
        // +0.5 °C per hour: 37.0 → 38.0 over two hours.
        let readings = [
            reading(hoursAgo: 2, value: 37.0),
            reading(hoursAgo: 1, value: 37.5),
            reading(hoursAgo: 0, value: 38.0),
        ]
        let trend = try #require(TemperatureTrend.compute(from: readings))
        #expect(abs(trend.slopePerHour - 0.5) < 0.0001)
        #expect(abs(trend.referenceValue - 38.0) < 0.0001)
        #expect(trend.direction == .rising)
    }

    @Test func fallingSeriesIsDetected() throws {
        let readings = [
            reading(hoursAgo: 3, value: 39.5),
            reading(hoursAgo: 2, value: 39.0),
            reading(hoursAgo: 1, value: 38.6),
            reading(hoursAgo: 0, value: 38.1),
        ]
        let trend = try #require(TemperatureTrend.compute(from: readings))
        #expect(trend.direction == .falling)
        #expect(trend.slopePerHour < 0)
    }

    @Test func flatSeriesIsSteady() throws {
        let readings = [
            reading(hoursAgo: 2, value: 36.9),
            reading(hoursAgo: 1, value: 37.0),
            reading(hoursAgo: 0, value: 36.9),
        ]
        let trend = try #require(TemperatureTrend.compute(from: readings))
        #expect(trend.direction == .steady)
    }

    @Test func onlyNewestWindowEntersRegression() throws {
        // Old spike outside the window must not affect the fit of a
        // perfectly flat recent series.
        var readings = (0..<TemperatureTrend.windowSize).map {
            reading(hoursAgo: Double($0), value: 37.0)
        }
        readings.append(reading(hoursAgo: Double(TemperatureTrend.windowSize + 5), value: 41.0))

        let trend = try #require(TemperatureTrend.compute(from: readings))
        #expect(abs(trend.slopePerHour) < 0.0001)
    }

    @Test func forecastIsClampedToPlausibleRange() throws {
        // Implausibly steep rise: +2 °C per hour.
        let readings = [
            reading(hoursAgo: 2, value: 38.0),
            reading(hoursAgo: 1, value: 40.0),
            reading(hoursAgo: 0, value: 42.0),
        ]
        let trend = try #require(TemperatureTrend.compute(from: readings))
        let farFuture = now.addingTimeInterval(10 * 3600)
        #expect(trend.value(at: farFuture) == TemperatureTrend.clampRange.upperBound)
    }

    @Test func forecastPointsStartAtNewestReading() throws {
        let readings = [
            reading(hoursAgo: 2, value: 37.0),
            reading(hoursAgo: 1, value: 37.5),
            reading(hoursAgo: 0, value: 38.0),
        ]
        let trend = try #require(TemperatureTrend.compute(from: readings))
        let points = trend.forecastPoints(hoursAhead: 3, stepMinutes: 30)
        #expect(points.count == 7)
        #expect(points.first?.date == now)
        #expect(points.last?.date == now.addingTimeInterval(3 * 3600))
        // +0.5 °C/h for 3 h from 38.0 → 39.5.
        #expect(abs((points.last?.value ?? 0) - 39.5) < 0.0001)
    }
}
