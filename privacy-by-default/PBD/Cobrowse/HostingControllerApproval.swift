//
//  HostingControllerApproval.swift
//  PBD
//

import UIKit
import SwiftUI

// Reading a hosting controller: which SwiftUI view is it showing, and may that
// view be seen?
//
// There is no redaction here. Everything is hidden by the window, and
// `RedactByDefaultDelegate` reveals a controller by unredacting its view — so
// deciding what a controller is showing is the whole job.

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
    /// `AnyView` first.
    var rootViewType: Any.Type? {
        guard let hosting = self as? AnyHostingController else { return nil }

        let rootView = type(of: hosting.anyRootView)

        return rootView == AnyView.self ? nil : rootView
    }

    /// The SwiftUI view this controller is showing, however it can be told.
    ///
    /// Either it kept the type — the app hosted it — or the type can be read
    /// back out of the erased root, which is how a controller SwiftUI made
    /// answers for itself.
    var shownViewType: Any.Type? {
        if let concrete = rootViewType { return concrete }

        return (self as? UIHostingController<AnyView>)?.rootView.concreteViewType
    }

    /// What the nearest ancestor is showing.
    ///
    /// For a screen that cannot name itself — a stack's own root — this is how
    /// its content is tied back to a view the allowlist knows.
    var ancestorShownViewType: Any.Type? {
        var candidate = parent

        while let current = candidate {
            if let shown = current.shownViewType { return shown }
            candidate = current.parent
        }

        return nil
    }
}

extension UIHostingController where Content == AnyView {

    /// Whether this controller may show its content — or `nil` when that cannot
    /// be answered, which the delegate treats as "no".
    ///
    /// Nothing is remembered between calls, so an answer that cannot be reached
    /// on one pass can be reached on the next. That matters: a destination's
    /// type is not always readable the instant it appears, and a verdict that
    /// stuck would leave an approved screen black until something disturbed it.
    var showsContent: Bool? {

        // Whatever this controller is showing, judged on its own — a pushed
        // destination, a sheet, a cover, a popover. SwiftUI erased which view it
        // is, but the erased root still names it.
        //
        // Where it came from is deliberately not consulted: approving a view
        // approves it wherever it appears.
        if let shown = rootView.concreteViewType {
            return CobrowseApproval.approves(shown)
        }

        // It cannot name itself, which is true of a stack's own root screen —
        // its erased root holds the content-and-modifiers chain rather than the
        // screen type. It inherits from the nearest ancestor that can be named,
        // reaching across the navigation controller to the view owning the stack.
        if let navigation = navigationController,
           navigation.viewControllers.first === self {
            return ancestorShownViewType.map(CobrowseApproval.approves) ?? false
        }

        // Otherwise nobody can say what this is showing, and nobody answers.
        return nil
    }
}

extension AnyView {

    /// The view this `AnyView` erased.
    ///
    /// `AnyView` keeps it in its single child, so that child is what the type
    /// below is read from; the `AnyView` type itself says nothing.
    var erasedView: Any {
        Mirror(reflecting: self).children.first?.value ?? self
    }

    /// The app-defined view this `AnyView` is hiding, when it can be told.
    ///
    /// SwiftUI hosts a pushed destination with its root erased and builds it
    /// lazily, so there is no view *value* to ask — only its type, which exists
    /// whether or not the view has been constructed. That type is spelled out in
    /// the erased value's own type, and the name resolves back to a real
    /// metatype which is then conformance-tested rather than string-matched.
    ///
    /// `nil` unless exactly one is named. Several means a `navigationDestination`
    /// closure that switches over routes — its static type is
    /// `_ConditionalContent<A, B>`, naming every branch whichever is showing —
    /// and nothing can say which is on screen, so nobody answers.
    ///
    /// The structure also names route types and SwiftUI's own internals, so
    /// candidates are filtered to app-defined `View`s.
    var concreteViewType: Any.Type? {
        let structure = String(reflecting: type(of: erasedView))

        // This app's module, taken from a type of ours rather than written out.
        let module = String(String(reflecting: SavedCard.self).prefix { $0 != "." })

        let named = Set(structure
            .split(whereSeparator: { "<>, ()".contains($0) })
            .map(String.init)
            .filter { $0.hasPrefix(module + ".") })
            .compactMap(Self.resolve)
            .filter { $0 is any View.Type }

        return named.count == 1 ? named.first : nil
    }

    /// Resolves `Module.Name` to the type it names.
    ///
    /// The runtime resolves a *mangled* name, and its own `_mangledTypeName`
    /// only runs the other way — type to name — so the name is built here. Its
    /// last letter is the kind, and all three are tried rather than assumed:
    /// measured, hardcoding `V` resolves a struct and fails an enum or a class
    /// outright, which would read as "unnamed" and hide the view with nothing to
    /// explain it. A wrong kind cannot resolve to the wrong type — name and kind
    /// both have to match — so trying each costs only a lookup.
    private static func resolve(_ qualified: String) -> Any.Type? {
        let parts = qualified.split(separator: ".").map(String.init)

        guard parts.count == 2 else { return nil }

        let name = "\(parts[0].count)\(parts[0])\(parts[1].count)\(parts[1])"

        return ["V", "O", "C"].lazy.compactMap { _typeByName(name + $0) }.first
    }
}
