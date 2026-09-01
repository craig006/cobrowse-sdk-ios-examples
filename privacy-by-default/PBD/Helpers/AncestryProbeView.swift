//


import SwiftUI
import UIKit

/// A zero-size, non-interactive probe that logs its ancestor chain
/// once it has been inserted into a window.
final class AncestryProbeView: UIView {

    var label: String = "AncestryProbe"

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override var intrinsicContentSize: CGSize { .zero }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        // The hierarchy is still being assembled inside didMoveToWindow.
        // One runloop hop later the ancestors are all attached.
        DispatchQueue.main.async { [weak self] in
            self?.printAncestry()
        }
    }

    func printAncestry() {
        print("── \(label): superview chain ──")
        var view: UIView? = superview
        var depth = 0
        while let current = view {
            let indent = String(repeating: "  ", count: depth)
            let name = String(describing: type(of: current))
            let pointer = String(describing: ObjectIdentifier(current).debugDescription)
            print("\(indent)\(depth). \(name) (\(pointer)")
            view = current.superview
            depth += 1
        }

        print("── \(label): controller chain ──")
        var responder: UIResponder? = next
        var index = 0
        while let current = responder {
            if let controller = current as? UIViewController {
                print("\(index). \(String(reflecting: type(of: controller)))")
                index += 1
            }
            responder = current.next
        }
    }
}

struct AncestryProbe: UIViewRepresentable {

    var label: String = "AncestryProbe"

    func makeUIView(context: Context) -> AncestryProbeView {
        let view = AncestryProbeView(frame: .zero)
        view.label = label
        return view
    }

    func updateUIView(_ uiView: AncestryProbeView, context: Context) {
        uiView.label = label
    }

    /// Stops the probe from claiming any space in the SwiftUI layout.
    @available(iOS 16.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: AncestryProbeView,
        context: Context
    ) -> CGSize? {
        .zero
    }
}

extension View {
    /// Attaches a probe behind the view and logs the UIKit ancestors it lands next to.
    func printAncestry(_ label: String = "AncestryProbe") -> some View {
        background(
            AncestryProbe(label: label)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        )
    }
}

