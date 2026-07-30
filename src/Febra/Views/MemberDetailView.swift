//
//  MemberDetailView.swift
//  Febra
//

import SwiftUI

/// History screen for one member: Liquid Glass cards for the chart with
/// selectable range, the trend summary and a combined timeline of readings
/// and medication doses.
struct MemberDetailView: View {
    @Environment(FamilyStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let memberID: UUID

    @State private var range: ChartRange = .day
    @State private var showsAddReading = false
    @State private var showsAddMedication = false
    @State private var showsEditMember = false
    @State private var showsDeleteConfirmation = false
    @State private var toast: Toast?

    var body: some View {
        if let member = store.member(with: memberID) {
            content(for: member)
        } else {
            // The member was deleted while this screen was on the stack.
            ContentUnavailableView("Member not found", systemImage: "person.slash")
        }
    }

    private func content(for member: FamilyMember) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Period", selection: $range) {
                    ForEach(ChartRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                chartCard
                trendCard
                NextDoseCard(memberID: memberID)
                EpisodesCard(memberID: memberID)
                TimelineCard(memberID: memberID, toast: $toast)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background {
            AppBackground(tint: member.colorTag.color)
        }
        .toast($toast)
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showsAddReading = true
                    } label: {
                        Label("Add temperature", systemImage: "medical.thermometer")
                    }
                    Button {
                        showsAddMedication = true
                    } label: {
                        Label("Log medication", systemImage: "pills")
                    }
                    if !rangeReadings.isEmpty {
                        Divider()
                        ShareLink(
                            item: HistoryExport(
                                member: member,
                                range: range,
                                readings: rangeReadings,
                                medications: rangeMedications
                            ),
                            preview: SharePreview("History · \(member.name)")
                        ) {
                            Label("Export as PDF", systemImage: "square.and.arrow.up")
                        }
                    }
                    Divider()
                    Button {
                        showsEditMember = true
                    } label: {
                        Label("Edit member", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Label("Delete member", systemImage: "trash")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showsAddReading) {
            AddReadingView(preselectedMemberID: memberID)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showsAddMedication) {
            AddMedicationView(preselectedMemberID: memberID)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showsEditMember) {
            MemberFormView(member: member)
        }
        .confirmationDialog(
            "Delete “\(member.name)” and all of their readings and medications?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                store.removeMember(memberID)
                dismiss()
            }
        }
    }

    // MARK: - Cards

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if rangeReadings.isEmpty {
                ContentUnavailableView {
                    Label("No readings", systemImage: "chart.xyaxis.line")
                } description: {
                    Text("No readings in the selected period.")
                }
            } else {
                TemperatureChartView(
                    readings: rangeReadings,
                    medications: rangeMedications,
                    trend: showsForecast ? trend : nil,
                    thresholds: store.member(with: memberID)?.feverThresholds() ?? .adult,
                    accentColor: memberColor
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
    }

    @ViewBuilder
    private var trendCard: some View {
        if let trend, showsForecast {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(trendDescription(for: trend), systemImage: trendSymbol(for: trend))
                        .font(.headline)
                    Spacer()
                    // Composed String, so `Text` renders it verbatim — a
                    // signed number needs no translation.
                    Text(slopeText(for: trend))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Text(AppCopy.forecastDisclaimer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 26))
        }
    }

    // MARK: - Data

    private var memberColor: Color {
        store.member(with: memberID)?.colorTag.color ?? .accentColor
    }

    /// Readings in the selected range, ascending for the chart.
    private var rangeReadings: [TemperatureReading] {
        let all = store.readings(for: memberID).sorted { $0.timestamp < $1.timestamp }
        guard let start = range.startDate() else { return all }
        return all.filter { $0.timestamp >= start }
    }

    private var rangeMedications: [MedicationDose] {
        let all = store.medications(for: memberID)
        guard let start = range.startDate() else { return all }
        return all.filter { $0.timestamp >= start }
    }

    private var trend: TemperatureTrend? {
        TemperatureTrend.compute(from: rangeReadings)
    }

    /// The short-term extrapolation only makes sense on short windows; on
    /// "30 days"/"All" a 3-hour dashed tail would be invisible anyway.
    private var showsForecast: Bool {
        range == .day || range == .week
    }

    /// "+0.12 °C/h" — sign kept explicit so a rise reads as a rise.
    private func slopeText(for trend: TemperatureTrend) -> String {
        let sign = trend.slopePerHour >= 0 ? "+" : ""
        return "\(sign)\(trend.slopePerHour.formatted(.number.precision(.fractionLength(2)))) °C/h"
    }

    private func trendSymbol(for trend: TemperatureTrend) -> String {
        switch trend.direction {
        case .rising: "arrow.up.right"
        case .falling: "arrow.down.right"
        case .steady: "arrow.right"
        }
    }

    private func trendDescription(for trend: TemperatureTrend) -> String {
        switch trend.direction {
        case .rising: String(localized: "Rising")
        case .falling: String(localized: "Falling")
        case .steady: String(localized: "Steady")
        }
    }
}

/// Glass card showing when each catalogued medication may next be safely given
/// (#41): the last dose plus its minimum interval. Live-updating countdown,
/// hidden entirely until the member has taken a medication that carries an
/// interval. Not medical advice — the interval is a user-set reminder.
private struct NextDoseCard: View {
    @Environment(FamilyStore.self) private var store
    let memberID: UUID

    var body: some View {
        let guidance = store.doseGuidance(for: memberID)
        if !guidance.isEmpty {
            // Refresh the countdown every minute so "in 2 Std. 10 Min." stays honest.
            TimelineView(.periodic(from: .now, by: 60)) { context in
                VStack(alignment: .leading, spacing: 12) {
                    Text("Next dose")
                        .font(.headline)

                    VStack(spacing: 0) {
                        ForEach(guidance) { item in
                            NextDoseRow(guidance: item, now: context.date)
                                .padding(.vertical, 10)
                            if item.id != guidance.last?.id {
                                Divider()
                            }
                        }
                    }

                    Text("The minimum interval is a reminder, not a medical dosing recommendation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: 26))
            }
        }
    }
}

private struct NextDoseRow: View {
    let guidance: DoseGuidance
    let now: Date

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(guidance.name, systemImage: "pills.fill")
                .font(.headline)
                .foregroundStyle(.indigo)
            Spacer()
            if guidance.isReady(asOf: now) {
                Label("Possible now", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("in \(Self.remaining(from: now, to: guidance.nextDoseDate))")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                    Text(guidance.nextDoseDate, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }

    /// "2 hr 10 min" style remaining-time string, minutes rounded up so the
    /// countdown never reads 0 while time is still left.
    private static func remaining(from now: Date, to target: Date) -> String {
        let totalMinutes = max(0, Int((target.timeIntervalSince(now) / 60).rounded(.up)))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 { return String(localized: "\(hours) hr \(minutes) min") }
        if hours > 0 { return String(localized: "\(hours) hr") }
        return String(localized: "\(minutes) min")
    }
}

/// Glass card listing the member's fever episodes, newest first. Tapping a row
/// opens the summary card (#49). Hidden entirely when there are no episodes.
private struct EpisodesCard: View {
    @Environment(FamilyStore.self) private var store
    let memberID: UUID

    @State private var selectedEpisode: FeverEpisode?

    var body: some View {
        if !episodes.isEmpty, let member = store.member(with: memberID) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fever episodes")
                    .font(.headline)

                VStack(spacing: 0) {
                    ForEach(episodes) { episode in
                        Button {
                            selectedEpisode = episode
                        } label: {
                            FeverEpisodeRow(episode: episode, member: member)
                                .padding(.vertical, 10)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        if episode.id != episodes.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 26))
            .sheet(item: $selectedEpisode) { episode in
                FeverEpisodeDetailSheet(episode: episode, member: member)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    /// Episodes over the member's full history — a bout is a historical fact,
    /// independent of the chart's selected range.
    private var episodes: [FeverEpisode] {
        guard let member = store.member(with: memberID) else { return [] }
        return FeverEpisode.episodes(
            from: store.readings(for: memberID),
            doses: store.medications(for: memberID),
            thresholds: member.feverThresholds()
        )
    }
}

/// Glass card listing readings and doses merged, newest first.
private struct TimelineCard: View {
    @Environment(FamilyStore.self) private var store
    let memberID: UUID
    @Binding var toast: Toast?

    @State private var editingReading: TemperatureReading?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Entries")
                .font(.headline)

            if timeline.isEmpty {
                Text("No entries yet.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(timeline) { entry in
                        TimelineEntryRow(entry: entry, member: store.member(with: memberID))
                            .padding(.vertical, 10)
                            .contentShape(.rect)
                            .contextMenu {
                                if case .reading(let reading) = entry {
                                    Button("Edit", systemImage: "pencil") {
                                        editingReading = reading
                                    }
                                }
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    delete(entry)
                                }
                            }
                        if entry.id != timeline.last?.id {
                            Divider()
                        }
                    }
                }

                Text("Press and hold a row to edit or delete an entry.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
        .sheet(item: $editingReading) { reading in
            AddReadingView(editing: reading)
                .presentationDetents([.medium, .large])
        }
    }

    /// Readings and doses merged, newest first.
    private var timeline: [TimelineEntry] {
        let readings = store.readings(for: memberID).map(TimelineEntry.reading)
        let doses = store.medications(for: memberID).map(TimelineEntry.dose)
        return (readings + doses).sorted { $0.timestamp > $1.timestamp }
    }

    /// Deletes an entry but keeps it recoverable via an "undo" toast (#45) —
    /// re-adding uses the original `id`, so the entry comes back unchanged.
    private func delete(_ entry: TimelineEntry) {
        // Bind the store reference locally so the undo closure captures it
        // directly rather than reading `@Environment` after `body` has ended.
        let store = store
        let undo = String(localized: "Undo")
        switch entry {
        case .reading(let reading):
            store.removeReading(reading.id)
            toast = Toast(message: String(localized: "Reading deleted"), style: .success, action: .init(title: undo) {
                store.addReading(reading)
            })
        case .dose(let dose):
            store.removeMedication(dose.id)
            toast = Toast(message: String(localized: "Medication deleted"), style: .success, action: .init(title: undo) {
                store.addMedication(dose)
            })
        }
    }
}

/// One item in the merged history list — either a reading or a dose.
private enum TimelineEntry: Identifiable {
    case reading(TemperatureReading)
    case dose(MedicationDose)

    var id: UUID {
        switch self {
        case .reading(let reading): reading.id
        case .dose(let dose): dose.id
        }
    }

    var timestamp: Date {
        switch self {
        case .reading(let reading): reading.timestamp
        case .dose(let dose): dose.timestamp
        }
    }
}

private struct TimelineEntryRow: View {
    let entry: TimelineEntry
    /// For age-dependent fever coloring; `nil` falls back to adult bounds.
    let member: FamilyMember?

    var body: some View {
        switch entry {
        case .reading(let reading):
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reading.value.asTemperature)
                        .font(.headline)
                        .foregroundStyle(FeverLevel(
                            celsius: reading.value,
                            thresholds: member?.feverThresholds(on: reading.timestamp) ?? .adult
                        ).color)
                    if let note = reading.note, !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(reading.timestamp, format: .dateTime.day().month().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .dose(let dose):
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("\(dose.name) · \(dose.dosage)", systemImage: "pills.fill")
                        .font(.headline)
                        .foregroundStyle(.indigo)
                    if let note = dose.note, !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(dose.timestamp, format: .dateTime.day().month().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let store = FamilyStore.preview
    return NavigationStack {
        MemberDetailView(memberID: store.members.first!.id)
    }
    .environment(store)
}
