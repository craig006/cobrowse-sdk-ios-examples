//

import UIKit
import SwiftUI
import CobrowseSDK

// MARK: - Usage

extension View {
    func cobrowseApprovedScreen() -> some View {
        background(
            ApprovedScreenProbe()
                .printAncestry()
        )
    }
}

/// An invisible probe view that allows automatically unredacting an approved screen's view.
private struct ApprovedScreenProbe: UIViewRepresentable {
    func makeUIView(context: Context) -> ApprovedScreenProbeView { ApprovedScreenProbeView() }
    func updateUIView(_ uiView: ApprovedScreenProbeView, context: Context) { }
}

private class ApprovedScreenProbeView: UIView {
    init() {
        super.init(frame: .zero)
        self.isUserInteractionEnabled = false
        self.alpha = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        // This view only exists on approved screens. When it's added to a window
        // automatically unredact the SwiftUI host UIKit view.
        // When it's removed, remove the unredaction as well.
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





