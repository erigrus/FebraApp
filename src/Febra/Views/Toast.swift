//
//  Toast.swift
//  Febra
//

import SwiftUI

/// A transient status banner shown over a screen — e.g. the "Reading deleted"
/// confirmation with its undo action (#45). `message` and the action title are
/// plain `String`s: callers pass already-localized text (`String(localized:)`).
struct Toast: Equatable, Identifiable {
    enum Style: Equatable {
        case progress   // an ongoing operation (shows a spinner)
        case success
        case error

        var symbol: String {
            switch self {
            case .progress: "antenna.radiowaves.left.and.right"
            case .success: "checkmark.circle.fill"
            case .error: "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .progress: .secondary
            case .success: .green
            case .error: .red
            }
        }
    }

    /// An optional trailing button — e.g. "Undo" to revert a deletion (#45).
    struct Action {
        let title: String
        let handler: () -> Void
    }

    let id = UUID()
    let message: String
    var style: Style = .progress
    var action: Action?

    // The `handler` closure isn't `Equatable`; identity is enough here since every
    // toast gets a fresh `id`, so two distinct toasts are never equal anyway.
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

extension View {
    /// Presents `toast` as an auto-dismissing banner at the bottom of the screen
    /// and clears the binding after a few seconds. A new toast replaces the
    /// current one and restarts the timer.
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast {
                    ToastBanner(toast: toast) {
                        withAnimation { self.toast = nil }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: toast.id) {
                        // Progress toasts get replaced by the next state; the
                        // fallback keeps a stuck one from lingering forever.
                        let seconds: Double = toast.style == .progress ? 8 : 3
                        try? await Task.sleep(for: .seconds(seconds))
                        withAnimation { self.toast = nil }
                    }
                }
            }
            .animation(.spring(duration: 0.35), value: toast)
    }
}

private struct ToastBanner: View {
    let toast: Toast
    /// Dismisses the banner; also invoked after the action button fires.
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if toast.style == .progress {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: toast.style.symbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(toast.style.tint)
            }
            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            if let action = toast.action {
                Spacer(minLength: 8)
                Button(action.title) {
                    action.handler()
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.quaternary))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .frame(maxWidth: .infinity)
    }
}
