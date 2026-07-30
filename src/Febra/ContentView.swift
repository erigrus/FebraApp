//
//  ContentView.swift
//  Febra
//

import SwiftUI

/// Root navigation: dashboard as the start screen, member detail pushed by ID.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            DashboardView()
                .navigationDestination(for: UUID.self) { memberID in
                    MemberDetailView(memberID: memberID)
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(FamilyStore.preview)
}
