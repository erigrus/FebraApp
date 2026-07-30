//
//  MedicationTypeFormView.swift
//  Febra
//

import SwiftUI

/// Create or edit one entry in the medication list (#41):
/// name, an optional default dosage and a minimum dosing interval. Pass
/// `medicationType` to edit; omit it to create. `onSave` lets the caller pick
/// the freshly created entry (used when adding inline from the dose form).
struct MedicationTypeFormView: View {
    @Environment(FamilyStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var medicationType: MedicationType?
    var onSave: ((MedicationType) -> Void)?

    @State private var name = ""
    @State private var dosage = ""
    @State private var hasInterval = true
    @State private var intervalHours = 6.0
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Default dosage (optional)", text: $dosage)
                } footer: {
                    Text("Default dosage e.g. “250 mg” or “5 ml” — prefilled when logging a dose.")
                }

                Section {
                    Toggle("Set a minimum interval", isOn: $hasInterval.animation())
                    if hasInterval {
                        Stepper(value: $intervalHours, in: 1...48, step: 1) {
                            Text("Every \(Int(intervalHours)) hr")
                        }
                    }
                } footer: {
                    Text("Minimum interval between two doses. It drives the “next dose possible in…” countdown — a reminder, not a medical dosing recommendation.")
                }
            }
            .navigationTitle(medicationType == nil ? "Add medication" : "Edit medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard !didLoad, let medicationType else { return }
        didLoad = true
        name = medicationType.name
        dosage = medicationType.defaultDosage ?? ""
        if let hours = medicationType.intervalHours {
            hasInterval = true
            intervalHours = hours
        } else {
            hasInterval = false
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDosage = dosage.trimmingCharacters(in: .whitespaces)
        var type = medicationType ?? MedicationType(name: trimmedName)
        type.name = trimmedName
        type.defaultDosage = trimmedDosage.isEmpty ? nil : trimmedDosage
        type.intervalHours = hasInterval ? intervalHours : nil

        if medicationType == nil {
            store.addMedicationType(type)
        } else {
            store.updateMedicationType(type)
        }
        onSave?(type)
        dismiss()
    }
}

#Preview("New") {
    MedicationTypeFormView()
        .environment(FamilyStore.preview)
}

#Preview("Edit") {
    let store = FamilyStore.preview
    return MedicationTypeFormView(medicationType: store.sortedMedicationTypes.first!)
        .environment(store)
}
