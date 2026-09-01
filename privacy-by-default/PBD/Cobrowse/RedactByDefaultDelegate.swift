import UIKit
import SwiftUI
import CobrowseSDK

final class RedactByDefaultDelegate: NSObject, CobrowseIODelegate {
    
    func cobrowseRedactedViews(for viewController: UIViewController) -> [UIView] {
        
        HostDump.printChanges()
        
        guard let view = viewController.viewIfLoaded,
              view.window?.windowLevel == .normal
        else { return [] }

        guard viewController.children.isEmpty
            else { return chrome(of: viewController) }
        
        return [viewController.view]
    }

    private func chrome(of container: UIViewController) -> [UIView] {
        
        switch container {
            case let navigation as UINavigationController: [
                navigation.navigationBar,
                navigation.toolbar
            ]

            case let tabs as UITabBarController: [
                tabs.tabBar
            ]

            default: []
        }
    }

    func cobrowseUnredactedViews(for viewController: UIViewController) -> [UIView] {
        guard isApproved(viewController)
            else { return [] }
        
        var unredacted: [UIView] = [viewController.view]

        // Uncomment if we should see the navigation bar
//        if let navigation = viewController.navigationController,
//           navigation.topViewController === viewController {
//            unredacted.append(navigation.navigationBar)
//        }

        // Uncomment if we should see the tab bar
//        if let tabs = viewController.tabBarController {
//            unredacted.append(tabs.tabBar)
//        }

        return unredacted
    }

    private func isApproved(_ viewController: UIViewController) -> Bool {
        
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
