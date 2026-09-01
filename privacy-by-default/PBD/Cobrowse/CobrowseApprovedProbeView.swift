//

import UIKit
import SwiftUI
import CobrowseSDK

// MARK: - Usage

class CobrowseApprovedProbeView: UIView {
    override func didMoveToWindow() {
        if window == nil {
            removeUnredaction()
        } else {
            addUnredaction()
        }
    }

    private func removeUnredaction() {
        guard let view = findAncestorForUnredaction() else { return }
        UnredactionRegistry.shared.remove(view)
    }

    private func addUnredaction() {
        guard let view = findAncestorForUnredaction() else { return }
        UnredactionRegistry.shared.add(view)
    }

    private func findAncestorForUnredaction() -> UIView? {
        var parent = self.superview
        while let current = parent {
            let name = String(describing: type(of: current))

            // Might be a better way to type check this.
            if name == "HostingView" || name.starts(with: "_UIHostingView") {
                return current
            }
            parent = current.superview
        }
        return nil
    }
}

struct CobrowseApprovedViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> CobrowseApprovedProbeView {
        CobrowseApprovedProbeView()
    }

    func updateUIView(_ uiView: CobrowseApprovedProbeView, context: Context) { }
}

extension View {
    func cobrowseApprovedScreen() -> some View {
        background(
            CobrowseApprovedViewRepresentable()
        )
    }
}

class UnredactionRegistry {
    static let shared = UnredactionRegistry()
    private var unredacted = NSHashTable<UIView>.weakObjects()

    var all: [UIView] {
        unredacted.allObjects
    }

    func add(_ view: UIView) {
        unredacted.add(view)
    }

    func remove(_ view: UIView) {
        unredacted.remove(view)
    }
}
