import UIKit
import SwiftUI

/// Finding the type of the view something is showing.
///
/// Two questions, and the names say which is which: `viewType` is a fact read
/// straight off the type system, `foundViewType` is a search that can fail.
/// Whether the view it names is a *screen* is the policy's question, not this
/// file's.

protocol AnyHostingController {

    /// The type this controller hosts. `AnyView` where the view is erased —
    /// which is the truth, not a failure.
    var viewType: Any.Type { get }

    /// The erased view it hosts, where it hosts one.
    var anyView: AnyView? { get }
}

extension UIHostingController: AnyHostingController {

    var viewType: Any.Type { Content.self }

    var anyView: AnyView? { rootView as? AnyView }
}

extension UIViewController {

    /// The type of the screen this controller is showing.
    ///
    /// Its tab's, where it is a tab; otherwise what it hosts; otherwise, for a
    /// navigation root whose erased view could not be read, the screen that
    /// contains it. `nil` where none of those name anything.
    var foundViewType: Any.Type? {
        
        if let tab = tabViewType { return tab }

        if let hosted = hostedViewType { return hosted }

        // A root that shows something we cannot name is the screen containing
        // it. Only the root — anything pushed after it is a screen in its own
        // right and must be named as one.
        guard self is AnyHostingController, isNavigationRoot
            else { return nil }

        return ancestorViewType
    }

    /// What this controller hosts, seeing through erasure.
    ///
    /// Never consults tabs, so the tab lookup can use it without asking itself
    /// the same question again.
    fileprivate var hostedViewType: Any.Type? {
        
        guard let hosting = self as? AnyHostingController
            else { return nil }

        guard hosting.viewType == AnyView.self
            else { return hosting.viewType }

        return hosting.anyView?.foundViewType
    }

    /// The view this tab shows, named by its container's declaration.
    ///
    /// A tab's own controller hosts a SwiftUI-internal `RootView`, so it cannot
    /// say which tab it is — but the container declares them in order, and the
    /// tab knows its index.
    fileprivate var tabViewType: Any.Type? {
        
        guard let tabs = parent as? UITabBarController,
              let index = tabs.viewControllers?.firstIndex(of: self)
        else { return nil }

        guard let container = tabs.containerViewType,
              let body = (container as? any View.Type)?.bodyType
        else { return nil }

        let declared = String(reflecting: body).foundViewTypes

        guard declared.count == tabs.viewControllers?.count,
              declared.indices.contains(index)
        else { return nil }

        return declared[index]
    }

    /// The nearest ancestor that hosts a view.
    ///
    /// Deliberately not `foundViewType`: that would ask about tabs, and a tab
    /// asking its container about tabs would not terminate.
    fileprivate var containerViewType: Any.Type? {
        ancestors.lazy.compactMap(\.hostedViewType).first
    }

    fileprivate var ancestorViewType: Any.Type? {
        ancestors.lazy.compactMap { $0.tabViewType ?? $0.hostedViewType }.first
    }

    fileprivate var ancestors: [UIViewController] {
        parent.map { [$0] + $0.ancestors } ?? []
    }

    fileprivate var isNavigationRoot: Bool {
        navigationController?.viewControllers.first === self
    }
}

extension AnyView {

    /// The view inside the box.
    ///
    /// `AnyView` publishes nothing about what it wraps, but its storage's own
    /// type names it — and reflection is the only way to reach that value.
    /// `nil` where the box names more than one view, and nothing can say which
    /// of them is the screen.
    var foundViewType: Any.Type? {
        
        let storage = Mirror(reflecting: self).children.first?.value ?? self

        var found: Set<String> = []
        let named = String(reflecting: type(of: storage))
            .foundViewTypes
            .filter { found.insert(String(reflecting: $0)).inserted }

        return named.count == 1 ? named.first : nil
    }
}

extension View {

    /// The type of this view's body.
    ///
    /// Here only to open the generic: `Body` cannot be reached through an
    /// `Any.Type`, and a static member on `any View.Type` can.
    static var bodyType: Any.Type { Body.self }
}

extension String {

    /// The view types found in this type structure, in the order they appear.
    ///
    /// Ours only — a structure names SwiftUI's own views alongside the app's.
    /// Whether any of them is a *screen* is the caller's question: a `TabView`
    /// body names one per tab, an erased view names the one it wraps.
    ///
    /// Repeats are kept: a `TabView` with two tabs of the same type names it
    /// twice, and a caller counting tabs against names needs both.
    var foundViewTypes: [Any.Type] {
        
        split(whereSeparator: { "<>, ()".contains($0) })
            .map(String.init)
            .filter(\.isAppTypeName)
            .compactMap { $0.resolvedType }
            .filter { $0 is any View.Type }
    }

    /// Ours, rather than a framework's.
    ///
    /// A type structure names SwiftUI's own views alongside the app's — a tab's
    /// `Text` label is part of the tab's type — and only the module tells them
    /// apart, since `Text` is as much a `View` as a screen is.
    ///
    /// - Note: a screen defined in a third-party UI module reads as a
    ///   framework's here, and so cannot be approved.
    fileprivate var isAppTypeName: Bool {
        moduleName == Self.appModule
    }

    fileprivate var moduleName: Substring {
        prefix { $0 != "." }
    }

    /// Read from a type we know is ours, so there is no list to keep current.
    fileprivate static let appModule = String(reflecting: CobrowseApproval.self)
        .moduleName

    /// The type this name refers to, or `nil` where it names no type at all —
    /// the common case, since splitting a type structure yields plenty of tokens
    /// that are not names.
    fileprivate var resolvedType: Any.Type? {
        
        if let cached = ResolvedTypes.byName[self] { return cached }

        let parts = split(separator: ".").map(String.init)
        let found = parts.count >= 2 ? Self.type(from: parts[...], mangled: "") : nil

        ResolvedTypes.byName[self] = found

        return found
    }

    /// Swift mangles a name as one length-prefixed component per level, each
    /// tagged with its kind — and the name itself gives no way to know which, so
    /// every kind is tried at every level.
    ///
    /// Recursion rather than two components, so a view declared inside a
    /// namespace or another type resolves like any other.
    private static func type(from parts: ArraySlice<String>, mangled: String) -> Any.Type? {
        
        guard let part = parts.first
            else { return _typeByName(mangled) }

        let component = mangled + "\(part.count)\(part)"
        let rest = parts.dropFirst()

        // The module comes first and carries no kind.
        guard mangled.isEmpty == false
            else { return type(from: rest, mangled: component) }

        return ["V", "O", "C"]
            .lazy
            .compactMap { type(from: rest, mangled: component + $0) }
            .first
    }
}

/// Resolving a name always gives the same answer, and this runs for every token
/// of every screen on every captured frame — so each name is looked up once.
/// Misses are kept too: they are the common case and the one worth not repeating.
///
/// Main thread only, which is where the SDK asks about redaction.
private enum ResolvedTypes {

    nonisolated(unsafe) static var byName: [String: Any.Type?] = [:]
}
