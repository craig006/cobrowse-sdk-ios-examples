import SwiftUI
import UIKit

protocol ApprovedForCobrowse {}

enum CobrowseApproval {

    static func approves(_ type: Any.Type) -> Bool {
        type is any ApprovedForCobrowse.Type
    }

    /// What an example screen says about itself.
    ///
    /// Read from the policy rather than written into the screen, so changing
    /// `Approvals.swift` changes what every example claims — a screen can never
    /// describe itself as approved while the policy denies it.
    static func description(of type: Any.Type) -> String {
        description(isApproved: approves(type))
    }

    static func description(isApproved: Bool) -> String {
        isApproved ? "In Approvals.swift" : "Deliberately not approved"
    }
}

// The same two, once per framework. `type(of: self)` reads the same in both: a
// view's concrete struct type, a controller's actual subclass.

extension View {

    var isApproved: Bool { CobrowseApproval.approves(type(of: self)) }

    var approvalDescription: String { CobrowseApproval.description(of: type(of: self)) }
}

extension UIViewController {

    var isApproved: Bool { CobrowseApproval.approves(type(of: self)) }

    var approvalDescription: String { CobrowseApproval.description(of: type(of: self)) }
}
