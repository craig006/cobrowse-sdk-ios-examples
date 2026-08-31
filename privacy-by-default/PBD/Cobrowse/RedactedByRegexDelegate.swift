//
//  RedactedByRegexDelegate.swift
//  PBD
//

import UIKit
import CobrowseSDK

/// One thing worth hiding, and how to recognise it.
///
/// Named and separate so each pattern can stay simple enough to read at a
/// glance. A single expression covering every case would be the shortest thing
/// to write and the hardest to be sure of.
struct RedactionPattern {

    let name: String
    let regex: Regex<Substring>
}

extension RedactionPattern {

    /// A card shown as its last four: `•••• 4242`, `**** 4242`.
    static let maskedCardNumber = RedactionPattern(
        name: "masked card number",
        regex: /[•*]{2,}\s*\d{4}/
    )

    /// A full card number, grouped or not: `4242 4242 4242 4242`.
    static let cardNumber = RedactionPattern(
        name: "card number",
        regex: /\d{4}\s?\d{4}\s?\d{4}\s?\d{4}/
    )

    /// Wording that sits next to something worth hiding — a field's label, its
    /// placeholder, a section heading.
    static let keyword = RedactionPattern(
        name: "keyword",
        regex: /card|cvv/.ignoresCase()
    )
}

extension Array where Element == RedactionPattern {

    /// Everything worth hiding by its content, in the order it is tried.
    static let all: [RedactionPattern] = [.maskedCardNumber, .cardNumber, .keyword]
}

/// Redacts any view whose visible text matches one of a set of patterns.
///
/// An alternative to `RedactByDefaultDelegate`: that policy hides everything
/// and reveals what is named, this one shows everything and hides what it
/// recognises.
///
/// - Important: this reads UIKit views. SwiftUI does not draw text through
///   `UILabel`, so a subview walk over hosted SwiftUI content finds nothing —
///   which is why the UIKit payment screens exist alongside the SwiftUI ones.
final class RedactedByRegexDelegate: NSObject, CobrowseIODelegate {

    private let patterns: [RedactionPattern]

    init(matching patterns: [RedactionPattern] = .all) {
        self.patterns = patterns
    }

    func cobrowseRedactedViews(for viewController: UIViewController) -> [UIView] {
        guard let root = viewController.viewIfLoaded else { return [] }

        // Views belonging to a child view controller are left to that
        // controller: the SDK tracks every controller that has appeared and
        // asks each about its own tree, so walking into a child here would walk
        // the same views again for every ancestor above it.
        //
        // That relies on the child actually being tracked, which it is only if
        // it received `viewWillAppear`. A child added with `addChild` but never
        // given its appearance transitions is visible and untracked, and its
        // content would be skipped here and asked about nowhere — visible to the
        // agent. Containment done properly is fine; containment done halfway is
        // not, and this is where that would show.
        //
        // `viewIfLoaded`, so asking never forces a controller to load a view it
        // has not needed yet.
        let childRoots = Set(viewController.children.compactMap(\.viewIfLoaded))

        var found: [UIView] = []
        collectMatches(in: root, skipping: childRoots, into: &found)

        return found
    }

    /// Walks once, matching as it goes.
    ///
    /// One traversal and one array, rather than collecting every text view and
    /// filtering afterwards: this runs on the main thread on every captured
    /// frame, once per tracked controller.
    private func collectMatches(
        in view: UIView,
        skipping childRoots: Set<UIView>,
        into found: inout [UIView]
    ) {
        // Hidden and transparent both apply to everything below, so the whole
        // subtree goes with them.
        guard view.isHidden == false, view.alpha > 0 else { return }

        if view.bounds.isEmpty == false,
           let textual = view as? ShowsText,
           textual.shownText.contains(where: { firstMatch(in: $0) != nil }) {
            found.append(view)
        }

        // Clips, with no area to clip to: nothing below it can be on screen, so
        // the subviews are never even asked for. The per-child test below would
        // reach the same answer, one allocation and one comparison at a time.
        if view.clipsToBounds, view.bounds.isEmpty {
            return
        }

        for subview in view.subviews where childRoots.contains(subview) == false {
            // A clipping parent hides whatever falls outside its bounds, so the
            // subtree can be dismissed with one test — which is what keeps a
            // long scrolling list cheap, since its offscreen rows are never
            // visited at all.
            //
            // Subview frames are in the superview's *bounds* space, and a scroll
            // view's `bounds.origin` is its content offset, so this is already
            // correct for scrolling without special-casing. Comparing against
            // `frame` instead would look equivalent and quietly not be.
            //
            // Only when the parent clips: an oversized child of a non-clipping
            // parent is genuinely on screen, zero-sized parents included.
            if view.clipsToBounds, subview.frame.intersects(view.bounds) == false {
                continue
            }

            collectMatches(in: subview, skipping: childRoots, into: &found)
        }
    }

    /// The first pattern this text matches, or `nil` for none.
    ///
    /// First, not all: one match is enough to hide the view, so there is
    /// nothing to learn from the rest.
    private func firstMatch(in text: String) -> RedactionPattern? {
        patterns.first { text.contains($0.regex) }
    }

    func cobrowseSessionDidUpdate(_ session: CBIOSession) {}
    func cobrowseSessionDidEnd(_ session: CBIOSession) {}
}

/// A view that puts text on screen.
///
/// A protocol rather than a `switch` over view types: one conformance check per
/// view instead of one per kind, and a new kind is added by conforming it rather
/// than by editing the walk.
protocol ShowsText {

    /// Every piece of text this view shows. More than one, because a text field
    /// shows what has been typed and, when nothing has, its placeholder.
    var shownText: [String] { get }
}

extension ShowsText {

    /// Drops what is absent or empty, so callers can list candidates plainly.
    func onScreen(_ candidates: String?...) -> [String] {
        candidates.compactMap { $0 }.filter { $0.isEmpty == false }
    }
}

extension UILabel: ShowsText {

    var shownText: [String] { onScreen(text) }
}

extension UITextField: ShowsText {

    var shownText: [String] { onScreen(text, placeholder) }
}

extension UITextView: ShowsText {

    var shownText: [String] { onScreen(text) }
}
