//
//  MemberAvatarView.swift
//  Febra
//

import SwiftUI

/// Colored circle with the member's initials.
struct MemberAvatarView: View {
    let member: FamilyMember
    var size: CGFloat = 44

    var body: some View {
        Circle()
            .fill(member.colorTag.color.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(member.initials)
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    MemberAvatarView(member: FamilyMember(name: "Emma Muster", colorTag: .pink))
}
