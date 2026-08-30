//
//  RedactByDefaultDelegate.swift
//  PBD
//

import UIKit
import SwiftUI
import CobrowseSDK

/// The app's entire redaction policy, in one object.
///
/// Nothing in this app carries a redaction modifier. Redaction is stated once,
/// here, at the top: every attached window is hidden, so an agent joining a
/// session sees black until something has been approved. A screen written next
/// year is private the first time it is shown, with nobody having remembered
/// anything.
///
/// UIKit controllers are revealed by name, from `Approvals.swift`.
///
/// SwiftUI content SwiftUI hosted itself is handled differently, and
/// `HostingRootRedaction` explains why: the window redaction cannot reach it.
/// Such a controller sits inside an approved screen whose view has already been
/// unredacted, and that view is its ancestor — so the window is lifted across
/// the whole subtree whatever this returns. Its content is hidden in SwiftUI
/// instead, which is the only cover available there.
final class RedactByDefaultDelegate: NSObject, CobrowseIODelegate {

    /// Redact the top of the tree, not individual controllers.
    ///
    /// Windows rather than `vc.view`: a window is above every presentation,
    /// every navigation container and every hosting controller, so there is no
    /// screen that can appear outside it and no ordering question about which
    /// controller the SDK happened to ask about first.
    func cobrowseRedactedViews(for viewController: UIViewController) -> [UIView] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
    }

    /// Reveal only what has been approved.
    func cobrowseUnredactedViews(for viewController: UIViewController) -> [UIView] {
        guard isApproved(viewController)
            else { return [] }
        
        return [viewController.view]
    }

    private func isApproved(_ viewController: UIViewController) -> Bool {

        // A hosting controller that still knows its root view's type — one the
        // app made itself, however it made it. The allowlist answers by name.
        if let rootViewType = viewController.rootViewType {
            return CobrowseApproval.approves(rootViewType)
        }

        // A hosting controller SwiftUI made, whose root is erased. Its
        // redaction is decided in SwiftUI — but only once it has been decided.
        // Until then the window keeps covering it, which is why this asks
        // rather than assuming every hosting controller is governed.
        if let hosting = viewController as? UIHostingController<AnyView> {
            return hosting.rootView.carriesRootRedaction || hosting.showsContent == true
        }

        // A UIKit controller with children is a container: its view is an
        // ancestor of its children's, so revealing it would reveal them all
        // whatever the allowlist says about them.
        guard viewController.children.isEmpty else { return false }

        return viewController is ApprovedForCobrowse
    }

    func cobrowseSessionDidUpdate(_ session: CBIOSession) {}
    func cobrowseSessionDidEnd(_ session: CBIOSession) {}
}
