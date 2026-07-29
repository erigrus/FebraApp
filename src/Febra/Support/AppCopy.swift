//
//  AppCopy.swift
//  Febra
//

import Foundation

/// Shared German UI copy that appears on more than one screen.
enum AppCopy {
    /// Required in-app disclaimer (spec §3): the app makes no medical claims.
    static let medicalDisclaimer =
        "Febra ersetzt keine ärztliche Beratung. Bei hohem oder anhaltendem Fieber bitte ärztlichen Rat einholen."

    /// Must accompany every surface that shows the trend extrapolation (§5).
    static let forecastDisclaimer =
        "Die Prognose ist eine grobe Hochrechnung der letzten Messungen – keine medizinische Vorhersage."
}

extension Double {
    /// Formats a °C value for display in the device locale, e.g. "38,2 °C".
    var asTemperature: String {
        "\(formatted(.number.precision(.fractionLength(1)))) °C"
    }
}
