import UIKit
import SwiftUI

/// Prints the view controller tree, and what each controller hosts, whenever it
/// changes.
///
/// This is the world the policy actually sees. A screen is identified by the type
/// its controller hosts — but SwiftUI decides what controllers exist, and it
/// makes several kinds the app never asks for:
///
/// - `NavigationStackHostingController<AnyView>` for a stack's root and each
///   destination
/// - `PresentationHostingController<AnyView>` for a sheet, cover or popover
/// - `TabHostingController`, hosting a SwiftUI-internal `RootView` rather than
///   the tab's own view — which is why a tab has to be named by its container
///
/// `erased` marks a controller whose content is an `AnyView`, and `UNREADABLE`
/// one whose concrete type could not be recovered from it. An unreadable
/// controller is exactly where `foundViewType` searches upward instead.
enum HostDump {

    /// Off by default: this walks the tree on every redaction pass.
    static var isEnabled = false

    /// On every line, so the tree can be filtered out of the frame loop's noise.
    private static let marker = "🌳"

    /// Every controller the SDK has asked about. A controller it never asks
    /// about cannot be covered by any policy, however the policy is written —
    /// which is a different problem from covering it wrongly.
    private static let asked = NSHashTable<UIViewController>.weakObjects()

    static func noteAsked(_ viewController: UIViewController) {
        asked.add(viewController)
    }

    private static var lastPrinted = Date.distantPast
    private static var lastTree = ""

    /// Prints the tree when it changes, at most once a second.
    static func printChanges() {
        
        guard isEnabled, Date().timeIntervalSince(lastPrinted) > 1
            else { return }

        lastPrinted = Date()

        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController
        else {
            return
        }

        let tree = describe(root)

        guard tree != lastTree
            else { return }

        lastTree = tree

        let output = "── controller tree ──\n\(tree)"
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "\(marker) \($0)" }
            .joined(separator: "\n")

        print(output)
    }

    private static func describe(_ viewController: UIViewController, depth: Int = 0) -> String {
        
        let seen = asked.contains(viewController) ? "" : "  ⚠️ NEVER ASKED"

        var line = String(repeating: "    ", count: depth)
            + "\(type(of: viewController))  \(hosted(by: viewController))\(seen)\n"

        for child in viewController.children {
            line += describe(child, depth: depth + 1)
        }
        
        if let presented = viewController.presentedViewController {
            line += describe(presented, depth: depth + 1)
        }

        return line
    }

    /// Both questions side by side: what the type system says this controller
    /// hosts, and what the policy managed to name.
    private static func hosted(by viewController: UIViewController) -> String {
        
        let found = viewController.foundViewType.map { "\($0)" } ?? "UNREADABLE"

        guard let hosting = viewController as? AnyHostingController
            else { return "—  found: \(found)" }

        return "hosts: \(hosting.viewType)  found: \(found)"
    }
}
