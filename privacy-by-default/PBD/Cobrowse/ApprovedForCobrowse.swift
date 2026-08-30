//
//  ApprovedForCobrowse.swift
//  PBD
//

import Foundation

/// The whole redaction policy of this app, in one protocol.
///
/// A screen is hidden from the Cobrowse agent unless its type is declared
/// approved. Nothing opts *out* — absence of approval **is** the redaction, so
/// a screen added tomorrow and forgotten today is already private.
///
/// It marks types in both worlds, and `RedactByDefaultDelegate` is the only
/// thing that reads it:
/// - a SwiftUI `View` type, matched against a hosting controller's root view
/// - a `UIViewController` type, matched against the controller itself
///
/// Every conformance lives in `Approvals.swift`. That file is the allowlist.
protocol ApprovedForCobrowse {}

/// Asks the allowlist about a screen type.
enum CobrowseApproval {

    /// Whether the agent may see this type.
    ///
    /// Types that are not approved — and types nobody has classified at all —
    /// both answer `false`. There is deliberately no third answer: the policy
    /// fails closed, so the only way to become visible is to say so.
    static func approves(_ type: Any.Type) -> Bool {
        type is any ApprovedForCobrowse.Type
    }
}
