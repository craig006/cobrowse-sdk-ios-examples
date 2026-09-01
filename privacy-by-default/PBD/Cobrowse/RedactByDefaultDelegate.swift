import UIKit
import SwiftUI
import CobrowseSDK

/// Hides every screen from the agent, then reveals the ones `Approvals.swift`
/// names.
final class RedactByDefaultDelegate: NSObject, CobrowseIODelegate {
    
    /// Guarantees every screen on screen is covered, in whatever window it lives
    /// — an alert's included.
    ///
    /// A screen written next year is covered the first time it appears, with
    /// nobody having remembered anything — approval is not consulted here, so
    /// there is no decision to get wrong. What this promises is only that
    /// something is *covered*: what comes back is decided in
    /// `cobrowseUnredactedViews(for:)`.
    ///
    /// It also guarantees a cover never lands on a view that contains other
    /// screens, because a container contributes its bars rather than its view.
    func cobrowseRedactedViews(for viewController: UIViewController) -> [UIView] {
        
        HostDump.noteAsked(viewController)
        HostDump.printChanges()
        
        // A controller with no loaded view has nothing on screen, so there is
        // nothing of it to cover. `viewIfLoaded` rather than `view`, so asking
        // never forces one to load on the frame loop.
        guard let view = viewController.viewIfLoaded
            else { return [] }

        // Only the app's own window is ours to speak for. Covering a view in a
        // system window blacks out whatever that window is drawing — the keyboard
        // and its editing overlay live there, and the SDK already redacts the
        // keyboard itself.
        guard view.window?.windowLevel == .normal
            else { return [] }

        // A container covers its bars and not its own view: that view contains
        // its children's, so covering it would cover them too — including any
        // screen that is approved, and anything a transition moves through it.
        guard viewController.children.isEmpty
            else { return chrome(of: viewController) }
        
        // Every other screen covers itself, approved or not. Nothing is decided
        // here — the unredact side is what brings a screen back.
        return [viewController.view]
    }
    
    /// Guarantees nothing is revealed but a screen `Approvals.swift` names, and
    /// of that screen only its own view.
    ///
    /// A screen never reveals its neighbours, its chrome, or anything presented
    /// over it — each controller answers for itself and the SDK moves the cover
    /// down onto the rest. Returning nothing leaves the cover from
    /// `cobrowseRedactedViews(for:)` standing, so silence is always safe.
    func cobrowseUnredactedViews(for viewController: UIViewController) -> [UIView] {
        // Not approved: nothing comes back, so the cover from above stands and the
        // agent sees a black screen.
        guard isApproved(viewController)
            else { return [] }
        
        // Approved: this screen's own view is revealed, and the SDK moves the cover
        // down onto whatever sits beside it rather than dropping it.
        var unredacted: [UIView] = [viewController.view]

        // Chrome stays hidden unless one of these is uncommented. Each reveals that
        // bar on every screen that has one — chrome is denied by default because a
        // title can name a screen the agent is not meant to know about.

        // Uncomment if we should see the navigation bar
//        if let navigation = viewController.navigationController,
//           navigation.topViewController === viewController {
//            unredacted.append(navigation.navigationBar)
//        }

        // Uncomment if we should see the tab bar
//        if let tabs = viewController.tabBarController {
//            unredacted.append(tabs.tabBar)
//        }

        // Anything not named here stays covered — a screen reveals itself, never
        // its neighbours.
        return unredacted
    }
    
    /// What to cover of a controller that has children.
    ///
    /// The cases are the containers whose children are separate screens: their
    /// content area belongs to those children, so only the bars are ours to
    /// cover. Everything else is one screen that happens to have children — an
    /// alert and its text fields — and covers itself.
    ///
    /// The default covers rather than skips, so a container nobody anticipated is
    /// hidden rather than shown. Over-covering is visible and fixable; the other
    /// way round is a leak nobody sees.
    ///
    /// Covering the bars rather than the container's view is also what keeps a
    /// transition clean. A push puts views on screen that belong to no view
    /// controller — the container it animates through, and a snapshot of the
    /// outgoing screen — and nothing reveals those. Cover anything above them and
    /// they inherit it, so moving between two approved screens flickers black.
    private func chrome(of container: UIViewController) -> [UIView] {
        
        switch container {
            
            // The pushed screen fills this controller's view, so covering it
            // would cover the screen. The bars are all that is ours, and they
            // are covered because a title can name a screen the agent is not
            // meant to know about.
            case let navigation as UINavigationController: [
                navigation.navigationBar,
                navigation.toolbar
            ]

            // As above: the selected tab fills the view, and the bar names every
            // tab whether or not the agent may see them.
            case let tabs as UITabBarController: [
                tabs.tabBar
            ]

            // SwiftUI's own containers — a hosting controller holding a tab bar
            // or a navigation stack it made. Their children are the screens, and
            // they have no bars of their own to cover.
            //
            // Covering this view was measured (2026-09-01) and rejected: it
            // brought the transition flicker back and did NOT cover the screen's
            // own content, because SwiftUI draws that into the view rather than
            // into a subview a cover can sit above. Content drawn around a
            // container cannot be covered at view level at all.
            case is AnyHostingController: []

            // One screen that happens to have children — an alert and its text
            // fields. Nothing else is going to cover it, so it covers itself.
            //
            // Covering rather than skipping is the point: a container nobody
            // anticipated is hidden rather than shown. Over-covering is visible
            // and fixable; the other way round is a leak nobody sees.
            default: [container.view]
        }
    }

    private func isApproved(_ viewController: UIViewController) -> Bool {
        
        // A container is not a screen — its children answer for themselves.
        guard viewController.children.isEmpty
            else { return false }

        if let found = viewController.foundViewType {
            return CobrowseApproval.approves(found)
        }

        return viewController is ApprovedForCobrowse
    }

    func cobrowseSessionDidUpdate(_ session: CBIOSession) {}
    func cobrowseSessionDidEnd(_ session: CBIOSession) {}
}
