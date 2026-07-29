//
//  AppBackground.swift
//  Febra
//

import SwiftUI

/// Soft tinted backdrop the Liquid Glass surfaces float above — glass needs
/// gentle color behind it to refract.
struct AppBackground: View {
    /// Hue of the upper glow, e.g. the member's avatar color.
    var tint: Color = .blue

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)

            Circle()
                .fill(tint.opacity(0.22))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -120, y: -260)

            Circle()
                .fill(.indigo.opacity(0.12))
                .frame(width: 380, height: 380)
                .blur(radius: 100)
                .offset(x: 150, y: 240)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground(tint: .pink)
}
