//
//  SwapDemoView.swift
//  PBD
//

import SwiftUI

// Two screens a hosting controller alternates between, to show that approval
// follows the VALUE a controller is showing rather than the controller itself.
// `SwapDemoViewController` hosts them, and the button swaps which one it holds.

struct ApprovedSwapView: View {

    let swap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(isApproved ? "Approved" : "Unapproved")
                .font(.largeTitle).bold()
                .foregroundStyle(isApproved ? .green : .red)

            Text(approvalDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Swap", action: swap)
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .padding()
        .viewDetails(isApproved: isApproved)
    }
}

struct UnapprovedSwapView: View {

    let swap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(isApproved ? "Approved" : "Unapproved")
                .font(.largeTitle).bold()
                .foregroundStyle(isApproved ? .green : .red)

            Text(approvalDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Sort code 04-00-04 · Account 12345678")
                .font(.callout).monospacedDigit()

            Button("Swap", action: swap)
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .padding()
        .viewDetails(isApproved: isApproved)
    }
}
