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
            // The app ships English and German (spec §3). Copy comes from the
            // string catalog and dates/numbers follow the device locale, so
            // nothing is pinned here — iOS's per-app language setting is what
            // switches the app (see SettingsView).
            ContentView()
                .environment(store)
        }
    }
}
