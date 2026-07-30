//
//  FeverEpisodeCard.swift
//  Febra
//

import SwiftUI

/// The fever-episode summary card (#49): peak, dose count, duration and the
/// span of one bout of illness — e.g. "Höchstwert 39,4 °C · 3 Gaben · über
/// 18 Std. · seit gestern, 14:00". Aggregated from existing readings/doses.
struct FeverEpisodeCard: View {
    let episode: FeverEpisode
    /// For age-dependent fever coloring; `nil` falls back to adult bounds.
    let member: FamilyMember?

    private var peakColor: Color {
        FeverLevel(
            celsius: episode.peak.value,
            thresholds: member?.feverThresholds(on: episode.peak.timestamp) ?? .adult
        ).color
    }

    /// The bout is still considered running if the last reading is no older
    /// than the gap tolerance — then the span reads "seit …".
    private var isOngoing: Bool {
        Date.now.timeIntervalSince(episode.end) <= FeverEpisode.defaultGapTolerance
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Fever episode", systemImage: "thermometer.high")
                .font(.headline)
                .foregroundStyle(peakColor)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Peak")
                        .foregroundStyle(.secondary)
                    Text(episode.peak.value.asTemperature)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(peakColor)
                        .monospacedDigit()
                }

                Label(metricsLine, systemImage: "list.bullet.clipboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label(spanLine, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(AppCopy.medicalDisclaimer)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
    }

    /// "3 doses · over 18 hr" — the duration part is dropped for a
    /// single-reading episode.
    private var metricsLine: String {
        var parts = [FeverEpisodeFormat.doses(episode.doseCount)]
        if let duration = episode.durationText {
            parts.append(String(localized: "over \(duration)"))
        }
        return parts.joined(separator: " · ")
    }

    private var spanLine: String {
        if isOngoing {
            String(localized: "since \(FeverEpisodeFormat.dayTime(episode.start))")
        } else {
            "\(FeverEpisodeFormat.dayTime(episode.start)) – \(FeverEpisodeFormat.dayTime(episode.end))"
        }
    }
}

/// Compact one-line entry for the episode list; tapping it opens the full card.
struct FeverEpisodeRow: View {
    let episode: FeverEpisode
    let member: FamilyMember?

    private var peakColor: Color {
        FeverLevel(
            celsius: episode.peak.value,
            thresholds: member?.feverThresholds(on: episode.peak.timestamp) ?? .adult
        ).color
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.peak.value.asTemperature)
                    .font(.headline)
                    .foregroundStyle(peakColor)
                    .monospacedDigit()
                Text(FeverEpisodeFormat.doses(episode.doseCount)
                    + (episode.durationText.map { " · \($0)" } ?? ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(FeverEpisodeFormat.dayTime(episode.start))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

/// The full-card sheet shown when an episode row is tapped.
struct FeverEpisodeDetailSheet: View {
    @Environment(FamilyStore.self) private var store
    let episode: FeverEpisode
    let member: FamilyMember?
    @Environment(\.dismiss) private var dismiss

    /// Export of just this bout — its readings plus doses given while it ran.
    private var export: HistoryExport? {
        guard let member else { return nil }
        return HistoryExport(
            member: member,
            episode: episode,
            doses: store.medications(for: member.id)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                FeverEpisodeCard(episode: episode, member: member)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .background {
                AppBackground(tint: member?.colorTag.color ?? .accentColor)
            }
            .navigationTitle(member?.name ?? String(localized: "Fever episode"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let export {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(
                            item: export,
                            preview: SharePreview("Fever episode · \(export.memberName)")
                        ) {
                            Label("Export as PDF", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// Shared formatting for the episode surfaces.
enum FeverEpisodeFormat {
    /// "1 dose" / "3 doses". Branching in Swift keeps both languages' one/other
    /// split in plain string keys instead of catalog plural variations.
    static func doses(_ count: Int) -> String {
        count == 1 ? String(localized: "1 dose") : String(localized: "\(count) doses")
    }

    /// Relative day plus time, e.g. "yesterday, 2:00 PM" / "Jul 5, 2:00 PM".
    static func dayTime(_ date: Date, calendar: Calendar = .current) -> String {
        let time = date.formatted(.dateTime.hour().minute())
        if calendar.isDateInToday(date) { return String(localized: "today, \(time)") }
        if calendar.isDateInYesterday(date) { return String(localized: "yesterday, \(time)") }
        return date.formatted(.dateTime.day().month().hour().minute())
    }
}

#Preview {
    let store = FamilyStore.preview
    let member = store.members.first!
    let episode = FeverEpisode.episodes(
        from: store.readings(for: member.id),
        doses: store.medications(for: member.id),
        thresholds: member.feverThresholds()
    ).first!
    return FeverEpisodeDetailSheet(episode: episode, member: member)
        .environment(store)
}
