import UIKit
import SwiftUI
import CobrowseSDK

/// Hides every screen from the agent, then reveals the ones `Approvals.swift`
/// names.
final class RedactByDefaultDelegate: NSObject, CobrowseIODelegate {

    func cobrowseRedactedViews(for viewController: UIViewController) -> [UIView] {
        // Redact all windows
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
    }

    func cobrowseUnredactedViews(for viewController: UIViewController) -> [UIView] {
        // The `.cobrowseApprovedScreen` modifier adds the first HostView of the SwiftUI view that
        // it's applied to to the UnredactionRegistry
        return UnredactionRegistry.shared.all
    }

    func cobrowseSessionDidUpdate(_ session: CBIOSession) {}
    func cobrowseSessionDidEnd(_ session: CBIOSession) {}
}
