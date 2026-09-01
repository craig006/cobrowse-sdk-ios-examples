import SwiftUI

struct TabsDemoView: View {

    var body: some View {
        tabs
    }

    private var tabs: some View {
        TabView {
            ApprovedTabView()
                .tabItem { Label("Approved", systemImage: "checkmark.circle") }

            UnapprovedTabView()
                .tabItem { Label("Unapproved", systemImage: "eye.slash") }

            MakePaymentView()
                .tabItem { Label("Payment", systemImage: "creditcard") }
        }
    }
}

struct ApprovedTabView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Tabs (SwiftUI)")
                .navigationBarTitleDisplayMode(.inline)
                .closable()
                .viewDetails(isApproved: isApproved)
        }
        .closesModal()
    }

    private var content: some View {
        VStack(spacing: 16) {
            Text("Approved tab")
                .font(.largeTitle).bold()

            Text(approvalDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("£1,240.55")
                .font(.title).monospacedDigit()
        }
        .padding()
    }
}

struct UnapprovedTabView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Tabs (SwiftUI)")
                .navigationBarTitleDisplayMode(.inline)
                .closable()
                .viewDetails(isApproved: isApproved)
        }
        .closesModal()
    }

    private var content: some View {
        VStack(spacing: 16) {
            Text("Unapproved tab")
                .font(.largeTitle).bold()

            Text(approvalDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Sort code 04-00-04 · Account 12345678")
                .font(.callout).monospacedDigit()
        }
        .padding()
    }
}


