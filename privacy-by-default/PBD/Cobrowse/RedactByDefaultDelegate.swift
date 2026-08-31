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
/// SwiftUI content SwiftUI hosted itself cannot be named here — it erases the
/// view's type before anything can read it — so `HostingControllerApproval`
/// works out which view a controller is showing, and this file asks the
/// allowlist about the answer.
final class RedactByDefaultDelegate: NSObject, CobrowseIODelegate {

    /// Redact the top of the tree, not individual controllers.
    ///
    /// Windows rather than `vc.view`: a window is above every presentation,
    /// every navigation container and every hosting controller, so there is no
    /// screen that can appear outside it and no ordering question about which
    /// controller the SDK happened to ask about first.
    ///
    /// Every window showing app content — and only those, because a redaction
    /// over one window cannot be lifted by an unredaction in another: the
    /// revealed view is not inside the redacted one, so a blanket over a window
    /// on top blacks out everything beneath it whatever is approved.
    ///
    /// `.normal` is where an app's own content lives. Above it sit windows that
    /// belong to the system and to the SDK, measured while a popover was open:
    ///
    ///     UIWindow                   level 0     the app
    ///     UITextEffectsWindow        level 10    arrives with a popover, never leaves
    ///     CBIOIOSAnnotationsCanvas   level 2001  the SDK's own
    ///     SessionIndicatorOverlay    level 2001  the SDK's own
    ///
    /// All three of those are full-screen. Blanketing the text-effects window
    /// covered the whole screen for the rest of the session, approved or not.
    ///
    /// Hidden and fully transparent windows go too: they display nothing, so
    /// covering them can only hide something else.
    func cobrowseRedactedViews(for viewController: UIViewController) -> [UIView] {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter { $0.windowLevel == .normal && $0.isHidden == false && $0.alpha > 0 }

        #if DEBUG
        noteWindows(windows)
        #endif

        return windows + unapprovedScreen(in: viewController)
    }

    /// A screen this app can name and does not approve, covered in its own
    /// right rather than left to the window blanket.
    ///
    /// The blanket only covers windows at `.normal`, so a popover — which lives
    /// in a window above the app's — has nothing over it. Redacting its own view
    /// covers exactly its bounds and nothing else, leaving the screen behind it
    /// to be judged on its own.
    ///
    /// Only a screen we can positively name. Answering "not approved" for every
    /// unidentifiable controller would redact system ones too, and theirs are
    /// full-screen — which is how blanketing the text-effects window blacked out
    /// everything in the first place.
    private func unapprovedScreen(in viewController: UIViewController) -> [UIView] {
        guard let shown = viewController.shownViewType,
              CobrowseApproval.approves(shown) == false,
              let view = viewController.viewIfLoaded else {
            return []
        }

        return [view]
    }

#if DEBUG
    /// Temporary: which windows are being redacted, logged when the set changes.
    ///
    /// A second full-size window is the suspicion — an unredaction in the window
    /// underneath cannot show through a redaction covering the one on top.
    private func noteWindows(_ windows: [UIWindow]) {
        let line = windows
            .map { window in
                "\(type(of: window))"
                + "[level \(Int(window.windowLevel.rawValue))"
                + " \(Int(window.bounds.width))x\(Int(window.bounds.height))"
                + " hidden=\(window.isHidden)"
                + " alpha=\(String(format: "%.1f", window.alpha))"
                + " root=\(window.rootViewController.map { "\(type(of: $0))" } ?? "none")]"
            }
            .joined(separator: " ")

        guard Self.lastWindows != line else { return }
        Self.lastWindows = line

        NSLog("CBIO-WINDOWS %d: %@", windows.count, line)
    }

    nonisolated(unsafe) private static var lastWindows = ""
#endif

    /// Reveal only what has been approved.
    ///
    /// A screen's own view, and nothing around it. Navigation bars, tab bars and
    /// toolbars belong to their container, not to the screen, so they are not
    /// inside the view returned here and stay hidden — chrome is UIKit, and
    /// UIKit is redacted unless something says otherwise.
    ///
    /// An app that wants the bar visible can return it alongside, for instance
    /// `viewController.navigationController?.navigationBar` while an approved
    /// screen is on top. Deliberately not done here: the default is that
    /// nothing shows, including the parts that look harmless.
    func cobrowseUnredactedViews(for viewController: UIViewController) -> [UIView] {
        guard isApproved(viewController) else { return [] }

        // Uncomment to let the agent see the navigation bar above an approved
        // screen — the title and back button say where the customer is.
        //
        // Only while this screen is the one on top: the bar is shared by the
        // whole stack and describes whatever is showing, so revealing it on
        // behalf of a screen underneath would show the title of the screen
        // above it. And a title is information about its screen, so this is a
        // judgement separate from approving the screen itself.
        //
//         if let navigation = viewController.navigationController,
//            navigation.topViewController === viewController {
//             return [viewController.view, navigation.navigationBar]
//         }

        return [viewController.view]
    }

    private func isApproved(_ viewController: UIViewController) -> Bool {
        #if DEBUG
        defer { note(viewController) }
        #endif


        // A controller with children shows a child's content, not its own, and
        // its view contains theirs — so revealing it would reveal the whole
        // subtree, and the container's own chrome with it. A navigation bar
        // belongs to the navigation controller, which is exactly such a
        // container, so this is what keeps chrome hidden whether the approved
        // screen is the stack's root or something it pushed.
        guard viewController.children.isEmpty else { return false }

        // A hosting controller that still knows its root view's type — one the
        // app made itself, however it made it. The allowlist answers by name.
        if let rootViewType = viewController.rootViewType {
            return CobrowseApproval.approves(rootViewType)
        }

        // A hosting controller SwiftUI made, whose root is erased. Revealed only
        // when it is positively approved — an unapproved one is left for the
        // window to cover, on top of the redaction applied to it in SwiftUI.
        //
        // It used to be revealed when merely redacted, on the reasoning that
        // the SwiftUI redaction was already covering it. That lifted the window
        // off content nothing had approved, leaving one cover where there could
        // be two, and the remaining one is a wrapper SwiftUI is known to drop.
        if let hosting = viewController as? UIHostingController<AnyView> {
            return hosting.showsContent == true
        }

        return viewController is ApprovedForCobrowse
    }

#if DEBUG
    /// Temporary: what each tracked controller is judged to be, logged when the
    /// answer changes — so a dismissal can be read as a sequence.
    private func note(_ viewController: UIViewController) {
        let shown = viewController.shownViewType.map { "\($0)" } ?? "unnamed"
        let verdict = verdictWithoutLogging(viewController)

        let line = "\(type(of: viewController)) shows=\(shown) → \(verdict ? "SHOW" : "hide")"

        let key = ObjectIdentifier(viewController)
        guard Self.lastLine[key] != line else { return }
        Self.lastLine[key] = line

        NSLog("CBIO-VERDICT %@", line)
    }

    private func verdictWithoutLogging(_ viewController: UIViewController) -> Bool {
        guard viewController.children.isEmpty else { return false }
        if let rootViewType = viewController.rootViewType { return CobrowseApproval.approves(rootViewType) }
        if let hosting = viewController as? UIHostingController<AnyView> { return hosting.showsContent == true }
        return viewController is ApprovedForCobrowse
    }

    nonisolated(unsafe) private static var lastLine: [ObjectIdentifier: String] = [:]
#endif

    func cobrowseSessionDidUpdate(_ session: CBIOSession) {}
    func cobrowseSessionDidEnd(_ session: CBIOSession) {}
}
