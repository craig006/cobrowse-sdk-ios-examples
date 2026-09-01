//
//  JourneyAView.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI

/// One of a pair of plain pushed screens, so a push can move between an
/// approved and an unapproved screen with nothing else differing.
struct JourneyAView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Journey A")
                .font(.largeTitle).bold()

            Text("The first journey in the flow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Journey A")
    }
}

struct ApprovedJourneyView: View {
    @State var isPresented: Bool = false
    var body: some View {
        ZStack {
            VStack(spacing: 16) {


                Text("Approved view")
                    .font(.largeTitle).bold()

                Text("The first view in the flow.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isPresented.toggle()
                    }

                } label: {
                    Text("Add credit card")
                }

                VStack(spacing: 5) {
                    Text("An unapproved view.")
                    WrappedViewControllerView()
                }

                VStack(spacing: 5) {
                    Text("An unapproved view.")
                    UnapprovedJourneyView()
                }


            }
            .padding()
            .navigationTitle("Approved view")
            .printAncestry()

            if isPresented {
                AddCreditCardView()
                    .backgroundStyle(.background)
                    .transition(.move(edge: .bottom))
                    .zIndex(1) // Ensures the view stays on top layer during transition
            }
        }.cobrowseApprovedScreen()
    }
}

struct WrappedViewControllerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    func makeUIViewController(context: Context) -> UIViewController {
        UIHostingController(rootView: UnapprovedJourneyView())
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {

    }
}

struct AddCreditCardView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Capsule()
                    .frame(width: 40, height: 6)
                    .foregroundColor(.secondary)

                Text("Contains sensitive credit card details")
                    .font(.title2)
                    .bold()

                Text("This view is not approved, and has just been added by a USAA developer as a sliding up panel in SwiftUI based on a feature request to allow quickly adding a card in the middle of a flow.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 500)
            .background(Color(.systemBackground))
            .cornerRadius(25)
            .shadow(radius: 10)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct ApprovedJourneyView1: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Approved view")
                .font(.largeTitle).bold()

            Text("The first view in the flow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Approved view")
    }
}

struct UnapprovedJourneyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Unapproved view")
                .font(.largeTitle).bold()

            Text("The first view in the flow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
//            ApprovedJourneyView1()
        }
        .padding()
        .navigationTitle("Unapproved view")
        .border(Color.red)

    }
}

struct UnapprovedJourneyView1: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Unapproved view")
                .font(.largeTitle).bold()

            Text("The first view in the flow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Unapproved view")
    }
}

struct ComplianceView: View {
    var body: some View {
        Text("You need to comply")
    }
}

struct InformationBanner: View {
    var body: some View {
        Text("Information banner")
    }
}
