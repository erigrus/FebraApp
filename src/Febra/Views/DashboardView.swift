//
//  DashboardView.swift
//  Febra
//

import SwiftUI

/// Household overview: one Liquid Glass card per member with the latest
/// temperature, its fever level and the short-term trend direction
/// (spec §2.5 "Dashboard").
struct DashboardView: View {
    @Environment(FamilyStore.self) private var store

    @State private var showsAddMember = false
    @State private var showsAddReading = false
    @State private var showsAddMedication = false
    @State private var showsSettings = false

    var body: some View {
        Group {
            if store.members.isEmpty {
                emptyState
            } else {
                memberCards
            }
        }
        .navigationTitle("Overview")
        .background {
            AppBackground(tint: store.members.first?.colorTag.color ?? .blue)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showsSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsAddMember = true
                } label: {
                    Label("Add member", systemImage: "person.badge.plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !store.members.isEmpty {
                captureBar
            }
        }
        .sheet(isPresented: $showsAddMember) {
            MemberFormView()
        }
        .sheet(isPresented: $showsAddReading) {
            AddReadingView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showsAddMedication) {
            AddMedicationView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No family members", systemImage: "person.2")
        } description: {
            Text("Add a family member first to start recording temperatures.")
        } actions: {
            Button("Add member") {
                showsAddMember = true
            }
            .buttonStyle(.glassProminent)
        }
    }

    private var memberCards: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(store.members) { member in
                    NavigationLink(value: member.id) {
                        MemberOverviewCard(member: member)
                    }
                    .buttonStyle(.plain)
                }

                Text(AppCopy.medicalDisclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    /// Floating glass bar with the two capture actions.
    private var captureBar: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    showsAddReading = true
                } label: {
                    Label("Temperature", systemImage: "medical.thermometer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)

                Button {
                    showsAddMedication = true
                } label: {
                    Label("Medication", systemImage: "pills")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }
            .controlSize(.large)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

/// One dashboard card: avatar, name, last measurement and trend arrow.
private struct MemberOverviewCard: View {
    @Environment(FamilyStore.self) private var store
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 14) {
            MemberAvatarView(member: member, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.headline)
                if let latest {
                    Text(latest.timestamp, format: .relative(presentation: .named))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No readings yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let latest {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        if let trend {
                            Image(systemName: trendSymbol(for: trend.direction))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel(trendLabel(for: trend.direction))
                        }
                        Text(latest.value.asTemperature)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(level(for: latest).color)
                    }
                    if FeverLevel.needsDoctorWarning(celsius: latest.value, ageInMonths: member.ageInMonths(on: latest.timestamp)) {
                        Text("Seek medical advice now")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    } else {
                        Text(level(for: latest).label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 26))
    }

    private var latest: TemperatureReading? {
        store.latestReading(for: member.id)
    }

    private func level(for reading: TemperatureReading) -> FeverLevel {
        FeverLevel(celsius: reading.value, thresholds: member.feverThresholds(on: reading.timestamp))
    }

    private var trend: TemperatureTrend? {
        TemperatureTrend.compute(from: store.readings(for: member.id))
    }

    private func trendSymbol(for direction: TemperatureTrend.Direction) -> String {
        switch direction {
        case .rising: "arrow.up.right"
        case .falling: "arrow.down.right"
        case .steady: "arrow.right"
        }
    }

    private func trendLabel(for direction: TemperatureTrend.Direction) -> String {
        switch direction {
        case .rising: String(localized: "Rising")
        case .falling: String(localized: "Falling")
        case .steady: String(localized: "Steady")
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(FamilyStore.preview)
}
