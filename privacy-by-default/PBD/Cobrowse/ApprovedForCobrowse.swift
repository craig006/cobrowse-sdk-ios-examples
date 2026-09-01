import SwiftUI
import UIKit

/// Conform a view or a view controller to reveal it to the agent.
///
/// Empty on purpose: the conformance *is* the statement, and it can be written
/// in `Approvals.swift` without touching the type it approves — so nothing in
/// the app has to know this policy exists.
protocol ApprovedForCobrowse {}

/// Asks the allowlist about a type.
///
/// Takes `Any.Type` rather than a generic, because the caller has a type it
/// recovered at runtime and cannot name.
enum CobrowseApproval {

    static func approves(_ type: Any.Type) -> Bool {
        type is any ApprovedForCobrowse.Type
    }
}

extension View {

    var isApproved: Bool {
        CobrowseApproval.approves(type(of: self))
    }
}

extension UIViewController {

    var isApproved: Bool {
        CobrowseApproval.approves(type(of: self))
    }
}
