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
            .navigationTitle("Medikamentenliste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showsNewType = true
                    } label: {
                        Label("Medikament hinzufügen", systemImage: "plus")
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
                Text("Der Mindestabstand ist ein einstellbarer Richtwert für die „nächste Gabe“ – keine ärztliche Dosierempfehlung.")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Keine Medikamente", systemImage: "pills")
        } description: {
            Text("Lege häufig genutzte Medikamente mit ihrem Mindestabstand an. Beim Erfassen einer Gabe kannst du sie dann direkt auswählen.")
        } actions: {
            Button("Medikament hinzufügen") {
                showsNewType = true
            }
            .buttonStyle(.glassProminent)

            Menu("Vorschlag übernehmen") {
                ForEach(MedicationType.suggestions) { suggestion in
                    Button {
                        store.addMedicationType(MedicationType(
                            name: suggestion.name,
                            intervalHours: suggestion.intervalHours
                        ))
                    } label: {
                        Text("\(suggestion.name) · alle \(Int(suggestion.intervalHours ?? 0)) Std.")
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
            parts.append("alle \(Int(hours)) Std.")
        } else {
            parts.append("kein Mindestabstand")
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
