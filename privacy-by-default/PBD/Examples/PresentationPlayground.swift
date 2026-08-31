//
//  PresentationPlayground.swift
//  PBD
//

import SwiftUI

// Two view types with identical bodies, because approval is per type: one is in
// `Approvals.swift` and the other is not. Each can present either at the next
// depth, in any style, so any stack of approved and unapproved screens can be
// built by tapping.

struct ApprovedPresentationView: View {

    let depth: Int

    var body: some View {
        PresentationPlayground(depth: depth, approved: true)
    }
}

struct UnapprovedPresentationView: View {

    let depth: Int

    var body: some View {
        PresentationPlayground(depth: depth, approved: false)
    }
}

private struct PresentationPlayground: View {

    let depth: Int
    let approved: Bool

    @Environment(\.dismiss) private var dismiss

    // One binding per style *and* per approval, because each presentation
    // closure has to return a single concrete view.
    //
    // A `@ViewBuilder` choosing between the two has the type
    // `_ConditionalContent<ApprovedPresentationView, UnapprovedPresentationView>`,
    // which names both, so nothing can say which is on screen and everything
    // presented that way stays hidden. The same rule as `navigationDestination`:
    // declare one per view type.
    @State private var approvedSheet: Int?
    @State private var unapprovedSheet: Int?
    @State private var approvedCover: Int?
    @State private var unapprovedCover: Int?
    @State private var approvedPopover: Int?
    @State private var unapprovedPopover: Int?

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("\(approved ? "Approved" : "Unapproved") · depth \(depth)")
                    .font(.title2).bold()
                Text(approved ? "In Approvals.swift" : "Deliberately not approved")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            row("Sheet", approved: $approvedSheet, unapproved: $unapprovedSheet)
            row("Cover", approved: $approvedCover, unapproved: $unapprovedCover)
            row("Popover", approved: $approvedPopover, unapproved: $unapprovedPopover)

            if depth > 0 {
                Button("Dismiss") { dismiss() }
                    .padding(.top)
            }

            Spacer()
        }
        .padding()
        .frameworkPill()
        .sheet(item: $approvedSheet) { ApprovedPresentationView(depth: $0) }
        .sheet(item: $unapprovedSheet) { UnapprovedPresentationView(depth: $0) }
        .fullScreenCover(item: $approvedCover) { ApprovedPresentationView(depth: $0) }
        .fullScreenCover(item: $unapprovedCover) { UnapprovedPresentationView(depth: $0) }
        .popover(item: $approvedPopover) {
            ApprovedPresentationView(depth: $0).presentationCompactAdaptation(.popover)
        }
        .popover(item: $unapprovedPopover) {
            UnapprovedPresentationView(depth: $0).presentationCompactAdaptation(.popover)
        }
    }

    private func row(_ title: String, approved: Binding<Int?>, unapproved: Binding<Int?>) -> some View {
        HStack(spacing: 8) {
            button("\(title) · approved", tint: .green, presents: approved)
            button("\(title) · unapproved", tint: .red, presents: unapproved)
        }
    }

    private func button(_ title: String, tint: Color, presents depth: Binding<Int?>) -> some View {
        Button(title) { depth.wrappedValue = self.depth + 1 }
            .buttonStyle(.bordered)
            .tint(tint)
            .font(.footnote)
    }
}

/// So a depth can drive `sheet(item:)` directly.
extension Int: @retroactive Identifiable {

    public var id: Int { self }
}
