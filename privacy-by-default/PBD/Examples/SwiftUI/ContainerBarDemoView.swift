//
//  ContainerBarDemoView.swift
//  PBD
//

import SwiftUI

/// A persistent bar drawn *around* a `NavigationStack`, the way `.safeAreaInset`
/// is normally used for a now-playing bar or a cart total.
///
/// Deliberately not approved, so the whole screen should be black. The bar is
/// drawn in this screen's own view rather than in the stack's child controllers,
/// which is the shape a view-level policy cannot cover — so whether the balance
/// reaches the agent is the measurement.
struct ContainerBarDemoView: View {

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Inside the stack")
                    .font(.title3)

                Text("This part lives in a child controller.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Container bar")
            .navigationBarTitleDisplayMode(.inline)
            .closable()
        }
        .safeAreaInset(edge: .bottom) {
            Text("Balance £1,240.55")
                .font(.callout.monospacedDigit())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thinMaterial)
        }
    }
}
