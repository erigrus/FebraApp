//
//  AppCopy.swift
//  Febra
//

import Foundation

/// Shared UI copy that appears on more than one screen. Resolved through the
/// string catalog, so every surface shows it in the current app language.
enum AppCopy {
    /// Required in-app disclaimer (spec §3): the app makes no medical claims.
    static var medicalDisclaimer: String {
        String(localized: "Febra is no substitute for medical advice. With a high or persistent fever, please consult a doctor.")
    }

    /// Must accompany every surface that shows the trend extrapolation (§5).
    static var forecastDisclaimer: String {
        String(localized: "The forecast is a rough extrapolation of the most recent readings — not a medical prediction.")
    }
}

extension Double {
    /// Formats a °C value for display in the current locale, e.g. "38.2 °C"
    /// / "38,2 °C".
    var asTemperature: String {
        "\(formatted(.number.precision(.fractionLength(1)))) °C"
    }
}
