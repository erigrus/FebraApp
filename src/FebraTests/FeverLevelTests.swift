//
//  FeverLevelTests.swift
//  FebraTests
//

import Foundation
import Testing
@testable import Febra

struct FeverLevelTests {

    // MARK: Adult band (≥ 12 years, and fallback without birthdate)

    @Test(arguments: [36.5, 37.0, 37.4] as [Double])
    func adultBelowElevatedIsNormal(celsius: Double) {
        #expect(FeverLevel(celsius: celsius, thresholds: .adult) == .normal)
    }

    @Test(arguments: [37.5, 37.9, 38.0] as [Double])
    func adultBetweenThresholdsIsElevated(celsius: Double) {
        #expect(FeverLevel(celsius: celsius, thresholds: .adult) == .elevated)
    }

    @Test(arguments: [38.1, 39.0, 40.5] as [Double])
    func adultAtOrAboveFeverThresholdIsFever(celsius: Double) {
        #expect(FeverLevel(celsius: celsius, thresholds: .adult) == .fever)
    }

    // MARK: Child band (3 months – < 12 years)

    @Test func childThresholds() {
        #expect(FeverLevel(celsius: 37.5, thresholds: .child) == .normal)
        #expect(FeverLevel(celsius: 37.6, thresholds: .child) == .elevated)
        #expect(FeverLevel(celsius: 38.4, thresholds: .child) == .elevated)
        #expect(FeverLevel(celsius: 38.5, thresholds: .child) == .fever)
    }

    // MARK: Infant band (< 3 months)

    @Test func infantThresholds() {
        #expect(FeverLevel(celsius: 37.5, thresholds: .infant) == .normal)
        #expect(FeverLevel(celsius: 37.9, thresholds: .infant) == .elevated)
        #expect(FeverLevel(celsius: 38.0, thresholds: .infant) == .fever)
    }

    // MARK: Age banding

    @Test func thresholdsForAgeBands() {
        #expect(FeverLevel.Thresholds.forAge(inMonths: 0) == .infant)
        #expect(FeverLevel.Thresholds.forAge(inMonths: 2) == .infant)
        #expect(FeverLevel.Thresholds.forAge(inMonths: 3) == .child)
        #expect(FeverLevel.Thresholds.forAge(inMonths: 143) == .child)
        #expect(FeverLevel.Thresholds.forAge(inMonths: 144) == .adult)
        #expect(FeverLevel.Thresholds.forAge(inMonths: nil) == .adult)
    }

    // MARK: Infant doctor warning

    @Test func infantFeverNeedsDoctorWarning() {
        #expect(FeverLevel.needsDoctorWarning(celsius: 38.0, ageInMonths: 2))
        #expect(!FeverLevel.needsDoctorWarning(celsius: 37.9, ageInMonths: 2))
        #expect(!FeverLevel.needsDoctorWarning(celsius: 38.0, ageInMonths: 3))
        #expect(!FeverLevel.needsDoctorWarning(celsius: 38.0, ageInMonths: nil))
    }

    // MARK: Member age at reading time

    @Test func memberThresholdsFollowAgeAtReadingTime() {
        let calendar = Calendar.current
        let birthdate = calendar.date(byAdding: .month, value: -2, to: .now)!
        let member = FamilyMember(name: "Baby", birthdate: birthdate)

        #expect(member.feverThresholds(on: .now) == .infant)
        // The same member two years later is in the child band.
        let later = calendar.date(byAdding: .year, value: 2, to: .now)!
        #expect(member.feverThresholds(on: later) == .child)
    }
}
