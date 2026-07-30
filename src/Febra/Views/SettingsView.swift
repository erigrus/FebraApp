//
//  SettingsView.swift
//  Febra
//

import SwiftUI
import UIKit

/// The app's settings screen, reached from the dashboard toolbar: the
/// medication list, the language switch, "What's new", and the about block that
/// states the app's privacy position and medical disclaimer.
///
/// Language is deliberately *not* an in-app picker. iOS offers a per-app
/// language setting for every app that ships more than one localization, and
/// that is the switch users already know — so this screen links there instead
/// of maintaining its own override.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showsMedicationCatalog = false
    @State private var showsWhatsNew = false

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Button {
                        showsMedicationCatalog = true
                    } label: {
                        SettingsRow(
                            title: "Medications",
                            systemImage: "list.bullet.clipboard",
                            detail: nil
                        )
                    }
                    .buttonStyle(.plain)

                    languageRow
                }

                Section {
                    Button {
                        showsWhatsNew = true
                    } label: {
                        SettingsRow(title: "What's new", systemImage: "sparkles", detail: nil)
                    }
                    .buttonStyle(.plain)

                    LabeledContent {
                        Text(Self.versionText)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    } label: {
                        Label("Version", systemImage: "app.badge")
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text(AppCopy.medicalDisclaimer)
                }

                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Everything stays on this device")
                                .font(.subheadline.weight(.semibold))
                            Text("Febra has no account and no server, and never sends your data anywhere. It is stored in the app only, and is included in your own device backup.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "lock.iphone")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showsMedicationCatalog) {
                MedicationCatalogView()
            }
            .sheet(isPresented: $showsWhatsNew) {
                WhatsNewView()
            }
        }
    }

    /// Opens iOS Settings for this app, where the per-app language lives.
    @ViewBuilder
    private var languageRow: some View {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Link(destination: url) {
                SettingsRow(
                    title: "Language",
                    systemImage: "globe",
                    detail: Self.currentLanguageName
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// The app's current language, in that language ("Deutsch" / "English").
    private static var currentLanguageName: String {
        let locale = Locale.current
        guard let code = locale.language.languageCode?.identifier else {
            return String(localized: "System")
        }
        return locale.localizedString(forLanguageCode: code)?.capitalized(with: locale)
            ?? code.uppercased()
    }

    /// "1.0.0 (12)" — marketing version plus build number.
    private static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}

/// One tappable settings row: icon + title, an optional trailing detail, and
/// the disclosure chevron.
private struct SettingsRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let detail: String?

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            if let detail {
                Text(detail)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(.rect)
    }
}

#Preview {
    SettingsView()
        .environment(FamilyStore.preview)
}
