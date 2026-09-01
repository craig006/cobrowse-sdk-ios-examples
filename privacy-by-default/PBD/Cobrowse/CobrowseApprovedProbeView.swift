//

import UIKit
import SwiftUI
import CobrowseSDK

// MARK: - Usage

class CobrowseApprovedProbeView: UIView {
    override func didMoveToWindow() {
        guard window != nil else { return }
        var parent = self.superview

        while let current = parent {
            let name = String(describing: type(of: current))

            // Might be a better way to type check this.
            if name == "HostingView" || name.starts(with: "_UIHostingView") {
                print("Found view, unredacting...")
                // This must go into a registry so that we can remove. Or the sdk must allow removing.
                current.cobrowseUnredacted()
                return
            }
            parent = current.superview
        }
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
