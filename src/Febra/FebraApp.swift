//
//  FebraApp.swift
//  Febra
//
//  Created by Erik Gruschka on 02.07.26.
//

import SwiftUI

@main
struct FebraApp: App {
    /// The one app-lifetime store. Local-only: it reads and writes a single JSON
    /// file on this device — there is no sign-in and no sync, so the whole app
    /// can start straight into the dashboard.
    @State private var store = FamilyStore(fileURL: FamilyStore.defaultFileURL)

    var body: some Scene {
        WindowGroup {
            ContentView()
                // The app is German-only (spec §3): force German date/number
                // formatting everywhere so an English device locale can't leak
                // through (e.g. "Jul 5 at 2:00 PM" / "39.4" instead of
                // "5. Juli, 14:00" / "39,4"). Sheets inherit this environment.
                .environment(\.locale, Locale(identifier: "de_DE"))
                .environment(store)
        }
    }
}
