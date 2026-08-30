//
//  MakePaymentView.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI
import CobrowseSDK

/// `NavigationStack` driven by boolean destinations, as a contrast with
/// `MakePaymentPathView`'s typed path.
///
/// Nothing here approves anything. This screen and every destination it pushes
/// are hidden by default and revealed only by `Approvals.swift`.
///
/// The single `cobrowseRedacted()` below goes the other way: it hides the
/// amount field *because* the screen around it is revealed.
struct MakePaymentView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var amount: String = "10.00"
    @State private var showingDetails = false
    @State private var showingExplainMyBill = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("£")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .cobrowseRedacted()
                    }
                }

                Section {
                    Button {
                        showingDetails = true
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Button {
                        showingExplainMyBill = true
                    } label: {
                        Text("Explain My Bill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Make Payment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingDetails) {
                PaymentDetailsView(amount: amount) { dismiss() }
            }
            .navigationDestination(isPresented: $showingExplainMyBill) {
                ExplainMyBillView()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .frameworkPill()
        }
    }
}
