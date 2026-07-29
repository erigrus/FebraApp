//
//  AddReadingView.swift
//  Febra
//

import SwiftUI

/// Manual temperature entry with member assignment, correctable timestamp and
/// optional note (spec §2.2) — the app's only way in for a measurement. Doubles
/// as the editor for an existing reading when `editing` is set (#47).
struct AddReadingView: View {
    @Environment(FamilyStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var preselectedMemberID: UUID?
    /// When set, the form corrects this reading instead of creating a new one.
    var editing: TemperatureReading?

    @State private var memberID: UUID?
    @State private var value: Double?
    @State private var timestamp = Date.now
    @State private var note = ""
    @State private var didPrefill = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mitglied", selection: $memberID) {
                        ForEach(store.members) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }

                    LabeledContent("Temperatur") {
                        HStack(spacing: 4) {
                            TextField("38,0", value: $value, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 80)
                            Text("°C")
                                .foregroundStyle(.secondary)
                        }
                    }

                    DatePicker("Zeitpunkt", selection: $timestamp, in: ...Date.now)
                } footer: {
                    validationFooter
                }

                Section {
                    TextField("Notiz (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                } footer: {
                    Text("z. B. „nach Paracetamol“ oder „linkes Ohr“")
                }
            }
            .navigationTitle(editing == nil ? "Temperatur erfassen" : "Temperatur bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern", action: save)
                        .disabled(!isValid)
                }
            }
            .onAppear {
                guard !didPrefill else { return }
                didPrefill = true
                if let editing {
                    memberID = editing.memberID
                    value = editing.value
                    timestamp = editing.timestamp
                    note = editing.note ?? ""
                } else {
                    memberID = preselectedMemberID ?? store.members.first?.id
                }
            }
        }
    }

    @ViewBuilder
    private var validationFooter: some View {
        if let value {
            if TemperatureReading.isPlausible(value) {
                let level = FeverLevel(
                    celsius: value,
                    thresholds: selectedMember?.feverThresholds(on: timestamp) ?? .adult
                )
                if FeverLevel.needsDoctorWarning(celsius: value, ageInMonths: selectedMember?.ageInMonths(on: timestamp)) {
                    Label("Fieber — bei Säuglingen unter 3 Monaten sofort ärztlich abklären.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    Label(level.label, systemImage: "thermometer.medium")
                        .foregroundStyle(level.color)
                }
            } else {
                Text("Bitte einen Wert zwischen 34,0 °C und 43,0 °C eingeben.")
                    .foregroundStyle(.red)
            }
        }
    }

    private var selectedMember: FamilyMember? {
        memberID.flatMap { store.member(with: $0) }
    }

    private var isValid: Bool {
        guard let value, memberID != nil else { return false }
        return TemperatureReading.isPlausible(value)
    }

    private func save() {
        guard let memberID, let value else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = trimmedNote.isEmpty ? nil : trimmedNote
        if let editing {
            // Preserve identity; only the user-editable fields change.
            store.updateReading(TemperatureReading(
                id: editing.id,
                memberID: memberID,
                value: value,
                timestamp: timestamp,
                note: note
            ))
        } else {
            store.addReading(TemperatureReading(
                memberID: memberID,
                value: value,
                timestamp: timestamp,
                note: note
            ))
        }
        dismiss()
    }
}

#Preview {
    AddReadingView()
        .environment(FamilyStore.preview)
}
