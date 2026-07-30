//
//  FeverLevel.swift
//  Febra
//

import SwiftUI

/// Fever classification with the age-dependent thresholds from
/// docs/family-fever-tracker-requirements.md §2.5.
enum FeverLevel: Sendable, CaseIterable {
    case normal
    case elevated
    case fever

    /// Age-dependent lower bounds (°C), assuming core-equivalent (rectal)
    /// measurement (§2.5).
    struct Thresholds: Equatable, Sendable {
        var elevated: Double
        var fever: Double

        /// Under 3 months.
        static let infant = Thresholds(elevated: 37.6, fever: 38.0)
        /// 3 months to under 12 years.
        static let child = Thresholds(elevated: 37.6, fever: 38.5)
        /// 12 years and older — also the fallback for members without a
        /// birthdate, because its fever bound is the most sensitive outside
        /// the infant band.
        static let adult = Thresholds(elevated: 37.5, fever: 38.1)

        static func forAge(inMonths months: Int?) -> Thresholds {
            switch months {
            case .some(..<3): .infant
            case .some(..<144): .child
            default: .adult
            }
        }
    }

    init(celsius: Double, thresholds: Thresholds) {
        if celsius >= thresholds.fever {
            self = .fever
        } else if celsius >= thresholds.elevated {
            self = .elevated
        } else {
            self = .normal
        }
    }

    /// Any fever in an infant under 3 months warrants immediate medical
    /// attention (§2.5).
    static func needsDoctorWarning(celsius: Double, ageInMonths: Int?) -> Bool {
        guard let months = ageInMonths, months < 3 else { return false }
        return celsius >= Thresholds.infant.fever
    }

    var color: Color {
        switch self {
        case .normal: .green
        case .elevated: .yellow
        case .fever: .red
        }
    }

    var label: String {
        switch self {
        case .normal: String(localized: "Normal")
        case .elevated: String(localized: "Elevated")
        case .fever: String(localized: "Fever")
        }
    }
}
