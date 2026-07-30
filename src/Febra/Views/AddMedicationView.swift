//
//  AddMedicationView.swift
//  Febra
//

import SwiftUI

/// Standalone medication logging — no temperature reading required (spec §2.6).
/// The name can be picked straight from the medication list
/// (#41), which also prefills the dosage and drives the "next safe dose"
/// countdown; a new medication can be added to that list inline.
struct AddMedicationView: View {
    @Environment(FamilyStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var preselectedMemberID: UUID?

    @State private var memberID: UUID?
    @State private var name = ""
    @State private var dosage = ""
    @State private var timestamp = Date.now
    @State private var note = ""
    @State private var showsNewType = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Member", selection: $memberID) {
                        ForEach(store.members) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }

                    HStack {
                        TextField("Medication", text: $name)
                        medicationMenu
                    }

                    TextField("Dosage", text: $dosage)

                    DatePicker("Time", selection: $timestamp, in: ...Date.now)
                } footer: {
                    Text(footerText)
                }

                Section {
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle("Log medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showsNewType) {
                MedicationTypeFormView { created in
                    apply(created)
                }
            }
            .onAppear {
                if memberID == nil {
                    memberID = preselectedMemberID ?? store.members.first?.id
                }
            }
        }
    }

    /// Pick from the shared list, from recently used names, or add a new
    /// medication to the list on the spot.
    private var medicationMenu: some View {
        Menu {
            if !store.sortedMedicationTypes.isEmpty {
                Section("From list") {
                    ForEach(store.sortedMedicationTypes) { type in
                        Button {
                            apply(type)
                        } label: {
                            Text(menuLabel(for: type))
                        }
                    }
                }
            }
            let recents = store.recentMedicationNames.prefix(5)
            if !recents.isEmpty {
                Section("Recently used") {
                    ForEach(recents, id: \.self) { recent in
                        Button(recent) { name = recent }
                    }
                }
            }
            Button {
                showsNewType = true
            } label: {
                Label("New medication…", systemImage: "plus")
            }
        } label: {
            Label("Choose", systemImage: "list.bullet")
                .labelStyle(.iconOnly)
        }
    }

    private func menuLabel(for type: MedicationType) -> String {
        guard let hours = type.intervalHours else { return type.name }
        return "\(type.name) · \(MedicationType.intervalText(hours))"
    }

    /// The interval note shown once the typed name matches a catalogued medication.
    private var footerText: String {
        if let hours = store.medicationType(named: name)?.intervalHours {
            return String(localized: "Minimum interval \(Int(hours)) hr — “next dose” is shown on the member screen. Dosage e.g. “5 ml”.")
        }
        return String(localized: "Dosage e.g. “5 ml” or “250 mg”")
    }

    private func apply(_ type: MedicationType) {
        name = type.name
        if let defaultDosage = type.defaultDosage, !defaultDosage.isEmpty {
            dosage = defaultDosage
        }
    }

    private var isValid: Bool {
        memberID != nil
            && !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !dosage.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        guard let memberID else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addMedication(MedicationDose(
            memberID: memberID,
            name: name.trimmingCharacters(in: .whitespaces),
            dosage: dosage.trimmingCharacters(in: .whitespaces),
            timestamp: timestamp,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        ))
        dismiss()
    }
}

#Preview {
    AddMedicationView()
        .environment(FamilyStore.preview)
}
