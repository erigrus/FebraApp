//
//  MemberFormView.swift
//  Febra
//

import SwiftUI

/// Create or edit a family member: name, optional birthdate, avatar color
/// (spec §2.1). Pass `member` to edit, omit it to create.
struct MemberFormView: View {
    @Environment(FamilyStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var member: FamilyMember?

    @State private var name = ""
    @State private var hasBirthdate = false
    @State private var birthdate = Date.now
    @State private var colorTag: MemberColor = .blue
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)

                    Toggle("Set date of birth", isOn: $hasBirthdate.animation())
                    if hasBirthdate {
                        DatePicker(
                            "Date of birth",
                            selection: $birthdate,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                    }
                }

                Section("Color") {
                    colorPicker
                }
            }
            .navigationTitle(member == nil ? "Add member" : "Edit member")
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
            .onAppear(perform: loadExistingMember)
        }
    }

    private var colorPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
            ForEach(MemberColor.allCases, id: \.self) { option in
                Button {
                    colorTag = option
                } label: {
                    Circle()
                        .fill(option.color.gradient)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if option == colorTag {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.rawValue)
                .accessibilityAddTraits(option == colorTag ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func loadExistingMember() {
        guard !didLoad, let member else { return }
        didLoad = true
        name = member.name
        colorTag = member.colorTag
        if let existingBirthdate = member.birthdate {
            hasBirthdate = true
            birthdate = existingBirthdate
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if var member {
            member.name = trimmedName
            member.birthdate = hasBirthdate ? birthdate : nil
            member.colorTag = colorTag
            store.updateMember(member)
        } else {
            store.addMember(FamilyMember(
                name: trimmedName,
                birthdate: hasBirthdate ? birthdate : nil,
                colorTag: colorTag
            ))
        }
        dismiss()
    }
}

#Preview("New") {
    MemberFormView()
        .environment(FamilyStore.preview)
}

#Preview("Edit") {
    let store = FamilyStore.preview
    return MemberFormView(member: store.members.first!)
        .environment(store)
}
