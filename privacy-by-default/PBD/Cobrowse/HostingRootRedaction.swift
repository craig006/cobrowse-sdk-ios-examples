//
//  HostingRootRedaction.swift
//  PBD
//

import UIKit
import SwiftUI
import CobrowseSDK

/// Hands SwiftUI content back to SwiftUI's own redaction.
///
/// The delegate hides every window, and reveals a screen by unredacting its
/// controller's view. That cannot govern what SwiftUI hosts inside an approved
/// screen: a destination's controller sits beneath one whose view has already
/// been unredacted, and an unredacted view lifts the window across everything
/// under it. By the time such a destination appears, the window is no longer
/// covering it.
///
/// So SwiftUI content SwiftUI hosted is redacted here instead, at its own root,
/// per controller. For a destination that is not defence in depth — it is the
/// only cover there is, which is why an identification that cannot be made has
/// to redact rather than abstain.
///
/// The hook reaches every controller SwiftUI makes, because SwiftUI erases the
/// root of each one. Measured, across a push, a sheet, a cover and a popover:
///
///     NavigationStackHostingController<AnyView>   ✓
///     PresentationHostingController<AnyView>      ✓
///     TabHostingController                        a container; its children are hosts
///     UIHostingController<MakePaymentView>        made by the app — unreachable
///
/// The last line is not a gap. A controller made by the app keeps its screen's
/// concrete type, and that type is what the allowlist answers by name — it does
/// not need redacting in SwiftUI at all, because if the allowlist declines it
/// the window redaction is simply never lifted. Which is also why it cannot be
/// reached here: generic classes are invariant, so no cast finds it.
enum HostingRootRedaction {

    static func install() {
        _ = installed
    }

    // MARK: - The hook

    /// Layout, not `viewDidLoad`.
    ///
    /// At `viewDidLoad` a controller is not yet in its navigation stack —
    /// measured — so a stack root cannot be told apart from a destination and
    /// would be redacted before anything could distinguish them. By the first
    /// layout pass the stack is in place, and layout runs before anything is
    /// drawn, so nothing is shown unredacted in the meantime.
    private static let installed: Void = {
        let original = #selector(UIViewController.viewWillLayoutSubviews)
        let replacement = #selector(UIViewController.pbd_redactingViewWillLayoutSubviews)

        guard let originalMethod = class_getInstanceMethod(UIViewController.self, original),
              let replacementMethod = class_getInstanceMethod(UIViewController.self, replacement) else {
            return
        }

        method_exchangeImplementations(originalMethod, replacementMethod)
    }()
}

private extension UIViewController {

    @objc func pbd_redactingViewWillLayoutSubviews() {
        // Post-exchange this selector holds the original implementation.
        pbd_redactingViewWillLayoutSubviews()

        // Checked on every layout, not once: SwiftUI reassigns `rootView` on its
        // own updates and discards the wrapper — measured, a destination was
        // recorded as redacted while carrying no redaction at all. Only the
        // check is repeated; a view that is still wrapped returns immediately
        // and nothing is re-derived.
        (self as? UIHostingController<AnyView>)?.redactRootIfNeeded()
    }
}

extension UIHostingController where Content == AnyView {

    /// Whether this controller may show its content — or `nil` when that
    /// cannot be answered, which is treated as "no".
    ///
    /// The two are kept apart because they mean different things to a reader,
    /// not because they lead anywhere different: an unanswerable question about
    /// a privacy control has exactly one safe answer.
    ///
    /// Only ever asked of a controller SwiftUI made — the constraint above says
    /// so — which is why there is no case here for one the app made. Those keep
    /// their `rootViewType` and are answered by the allowlist directly, in
    /// `RedactByDefaultDelegate`.
    var showsContent: Bool? {

        // Belongs to an approved view: the nearest ancestor that still knows
        // its own type, which is the view the app presented.
        guard let rootViewType = ancestorRootViewType,
              CobrowseApproval.approves(rootViewType) else {
            return false
        }

        // The view's own content — first in its navigation controller — rather
        // than a destination it pushed. Nothing more to ask.
        guard let navigation = navigationController,
              navigation.viewControllers.first !== self else {
            return true
        }

        // A destination. SwiftUI erased which one, but the erased root still
        // names it, so the allowlist can answer for it like anything else —
        // and when it names nothing conclusive, nobody answers at all.
        guard let destination = rootView.concreteViewType else { return nil }

        return CobrowseApproval.approves(destination)
    }

    func redactRootIfNeeded() {
        // Already redacted, so there is nothing to decide and nothing to do.
        //
        // Asked first because this runs on every layout pass and a redacted
        // view is the steady state — answering it here skips the ancestor walk
        // and the identification below entirely. It cannot be cached instead:
        // SwiftUI reassigns `rootView` on its own updates and drops the
        // wrapper, and noticing that is the only reason this runs repeatedly.
        guard rootView.carriesRootRedaction == false else { return }

        // Anything but a clear yes is redacted, undecided included.
        //
        // Leaving an undecided controller alone was tried, on the reasoning
        // that the window redaction still covered it. It does not: this
        // controller's approved ancestor has had the window lifted from it, and
        // its view is an ancestor of this one's, so "undecided" showed the
        // view. Undecided has to mean redacted.
        guard showsContent != true else { return }

        rootView = AnyView(rootView.modifier(RootRedaction()))
    }
}

// MARK: - The redaction

/// The redaction this app applies to a hosting controller's root.
///
/// A named type of ours, rather than `cobrowseRedacted()` applied directly, so
/// that `carriesRootRedaction` can recognise it by **type** rather than by
/// matching the name of a type inside the SDK. Getting that wrong would be
/// quiet and expensive: the guard would stop matching and every layout pass
/// would wrap the root again.
struct RootRedaction: ViewModifier {

    func body(content: Content) -> some View {
        content.cobrowseRedacted()
    }
}

extension AnyView {

    /// The view this `AnyView` erased.
    ///
    /// `AnyView` keeps it in its single child, so that child is what the type
    /// checks below actually read; the `AnyView` type itself says nothing.
    private var erasedView: Any {
        Mirror(reflecting: self).children.first?.value ?? self
    }

    /// Whether this root already carries our redaction.
    ///
    /// Read from the view itself rather than from what we remember applying,
    /// because what we applied does not always survive — SwiftUI reassigns
    /// `rootView` on its own updates.
    ///
    /// A search rather than a type check, and it has to be. `AnyView`'s single
    /// child is its storage box — `AnyViewStorage<ModifiedContent<…>>` — not
    /// the view, so `erasedView is ModifiedContent<AnyView, RootRedaction>` is
    /// never true. That was tried: the check never matched, every layout pass
    /// wrapped the root again, and each wrap provoked another layout. The app
    /// hung.
    ///
    /// The name-based reading below survives that indirection because the
    /// storage's own type name spells out what it holds. A type check does not.
    var carriesRootRedaction: Bool {
        Self.contains(RootRedaction.self, in: self)
    }

    /// Searches `AnyView`'s storage and the modifier chain for a value of the
    /// given type. Bounded, because it runs on every layout pass, and it does
    /// not descend into the view's own content — so a `cobrowseRedacted()` on
    /// a field inside cannot be mistaken for this.
    private static func contains<Marker>(_ marker: Marker.Type, in value: Any, depth: Int = 0) -> Bool {
        guard depth < 8 else { return false }

        for child in Mirror(reflecting: value).children {
            if child.value is Marker { return true }

            switch child.label {
            case "storage", "view", "content", "modifier":
                if contains(marker, in: child.value, depth: depth + 1) { return true }
            default:
                continue
            }
        }

        return false
    }

    /// The app-defined view this `AnyView` is hiding, when it can be told.
    ///
    /// SwiftUI hosts a pushed destination with its root erased, so nothing can
    /// be asked of it directly — but the erased value's *type* still names the
    /// view, and that name resolves back to a real metatype which is then
    /// conformance-tested rather than string-matched.
    ///
    /// `nil` when it cannot be told, and that is the answer in two different
    /// situations which are the same answer here: nothing app-defined was
    /// named, or several were. Several happens when a `navigationDestination`
    /// closure switches over routes — its static type is
    /// `_ConditionalContent<A, B>`, naming every branch whichever is showing —
    /// which is why a stack declares one destination per route instead.
    ///
    /// The structure also names route types and SwiftUI's own internals, so
    /// candidates are filtered to app-defined `View`s.
    var concreteViewType: Any.Type? {
        let structure = String(reflecting: type(of: erasedView))

        // This app's module, taken from a type of ours rather than written out.
        let module = String(String(reflecting: RootRedaction.self).prefix { $0 != "." })

        let named = Set(structure
            .split(whereSeparator: { "<>, ()".contains($0) })
            .map(String.init)
            .filter { $0.hasPrefix(module + ".") })
            .compactMap(Self.resolve)
            .filter { $0 is any View.Type }

        // One concrete view named, so its type says which. This is the only
        // answer taken, and a closure that names several — a `switch` over
        // routes has the type `_ConditionalContent<A, B>` — decides nothing.
        //
        // The value graph does know which branch was built, and using it was
        // tried: it retains views from pushes already dismissed, so a stale
        // approved view answered for the card details on screen and revealed
        // them. Ambiguity has to stay unanswerable.
        return named.count == 1 ? named.first : nil
    }

    /// Resolves `Module.Name` to the type it names.
    ///
    /// The runtime resolves a *mangled* name, and its own `_mangledTypeName`
    /// only runs the other way — type to name — so the name has to be built
    /// here. Its last letter is the kind, and all three are tried rather than
    /// assumed: measured, hardcoding `V` resolves a struct and fails an enum or
    /// a class outright, which would read as "unnamed" and black the view with
    /// nothing to explain it. A wrong kind cannot resolve to the wrong type —
    /// name and kind both have to match — so trying each costs only a lookup.
    private static func resolve(_ qualified: String) -> Any.Type? {
        let parts = qualified.split(separator: ".").map(String.init)

        guard parts.count == 2 else { return nil }

        let name = "\(parts[0].count)\(parts[0])\(parts[1].count)\(parts[1])"

        return ["V", "O", "C"].lazy.compactMap { _typeByName(name + $0) }.first
    }
}

// MARK: - Reading a controller

/// Recognises a `UIHostingController` of any root view type.
///
/// `UIHostingController` is generic and Swift's generic classes are invariant,
/// so `vc as? UIHostingController<AnyView>` matches only a controller whose
/// root really is `AnyView`. An existential asks the question that was meant.
protocol AnyHostingController {

    /// The root SwiftUI view, with its concrete type erased.
    var anyRootView: Any { get }
}

extension UIHostingController: AnyHostingController {

    var anyRootView: Any { rootView }
}

extension UIViewController {

    /// The type of the SwiftUI view this controller hosts, when it still knows.
    ///
    /// A hosting controller created with a concrete view keeps that type, and
    /// the type is the whole record — nothing has to be registered as the
    /// controller is made, so one built anywhere, by anyone, answers the same.
    ///
    /// `nil` when SwiftUI made the controller itself: it erases `rootView` to
    /// `AnyView` first, which is why a pushed destination cannot be named by
    /// the allowlist and unredacts itself instead.
    var rootViewType: Any.Type? {
        guard let hosting = self as? AnyHostingController else { return nil }

        let rootView = type(of: hosting.anyRootView)

        return rootView == AnyView.self ? nil : rootView
    }

    /// The `rootViewType` of the nearest ancestor that still knows its own.
    ///
    /// A controller SwiftUI made never knows, so this is how its content is
    /// tied back to the view the app presented, and through that to the
    /// allowlist.
    var ancestorRootViewType: Any.Type? {
        var candidate = parent

        while let current = candidate {
            if let rootViewType = current.rootViewType { return rootViewType }
            candidate = current.parent
        }

        return nil
    }
}
