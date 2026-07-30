//
//  MedicationCatalogView.swift
//  Febra
//

import SwiftUI

/// The medication list (#41): medications and their dosing intervals are
/// maintained here once, then picked from when logging a dose.
struct MedicationCatalogView: View {
    @Environment(FamilyStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showsNewType = false
    @State private var editingType: MedicationType?

    var body: some View {
        NavigationStack {
            Group {
                if store.sortedMedicationTypes.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showsNewType = true
                    } label: {
                        Label("Add medication", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showsNewType) {
                MedicationTypeFormView()
            }
            .sheet(item: $editingType) { type in
                MedicationTypeFormView(medicationType: type)
            }
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(store.sortedMedicationTypes) { type in
                    Button {
                        editingType = type
                    } label: {
                        MedicationTypeRow(type: type)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: delete)
            } footer: {
                Text("The minimum interval is a reminder you set yourself for the “next dose” — not a medical dosing recommendation.")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No medications", systemImage: "pills")
        } description: {
            Text("Add the medications you use often, together with their minimum interval. You can then pick them directly when logging a dose.")
        } actions: {
            Button("Add medication") {
                showsNewType = true
            }
            .buttonStyle(.glassProminent)

            Menu("Use a suggestion") {
                ForEach(MedicationType.suggestions) { suggestion in
                    Button {
                        store.addMedicationType(MedicationType(
                            name: suggestion.name,
                            intervalHours: suggestion.intervalHours
                        ))
                    } label: {
                        Text("\(suggestion.name) · \(MedicationType.intervalText(suggestion.intervalHours ?? 0))")
                    }
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let types = store.sortedMedicationTypes
        for index in offsets {
            store.removeMedicationType(types[index].id)
        }
    }
}

/// One catalog row: name plus a compact interval / dosage summary.
struct MedicationTypeRow: View {
    let type: MedicationType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills.fill")
                .foregroundStyle(.indigo)
            VStack(alignment: .leading, spacing: 2) {
                Text(type.name)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(.rect)
    }

    private var subtitle: String? {
        var parts: [String] = []
        if let hours = type.intervalHours {
            parts.append(MedicationType.intervalText(hours))
        } else {
            parts.append(String(localized: "no minimum interval"))
        }
        if let dosage = type.defaultDosage, !dosage.isEmpty {
            parts.append(dosage)
        }
        return parts.joined(separator: " · ")
    }
}

#Preview {
    MedicationCatalogView()
        .environment(FamilyStore.preview)
}
