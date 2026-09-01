//
//  RedactedByRegexDelegate.swift
//  PBD
//

import UIKit
import CobrowseSDK

/// One thing worth hiding, and how to recognise it.
///
/// Separate patterns rather than one expression, so each stays simple enough to
/// be sure of.
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
    
    static let all: [RedactionPattern] = [
        .maskedCardNumber,
        .cardNumber,
        .keyword
    ]
}

/// The contrast policy: shows everything, hides what it recognises.
///
/// Reads UIKit text only — SwiftUI does not draw through `UILabel`, which is why
/// the UIKit payment screens exist alongside the SwiftUI ones.
final class RedactedByRegexDelegate: NSObject, CobrowseIODelegate {

    private let patterns: [RedactionPattern]

    init(matching patterns: [RedactionPattern] = .all) {
        self.patterns = patterns
    }

    func cobrowseRedactedViews(for viewController: UIViewController) -> [UIView] {
        
        guard let root = viewController.viewIfLoaded
            else { return [] }
        
        let childRoots = Set(viewController.children.compactMap(\.viewIfLoaded))

        var found: [UIView] = []
        collectMatches(in: root, skipping: childRoots, into: &found)

        return found
    }
    
    private func collectMatches(
        in view: UIView,
        skipping childRoots: Set<UIView>,
        into found: inout [UIView]
    ) {
        
        // Hidden and transparent both apply to everything below, so the whole
        // subtree goes with them.
        guard view.isHidden == false, view.alpha > 0
            else { return }

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
    
    private func firstMatch(in text: String) -> RedactionPattern? {
        
        patterns.first { text.contains($0.regex) }
    }

    func cobrowseSessionDidUpdate(_ session: CBIOSession) {}
    func cobrowseSessionDidEnd(_ session: CBIOSession) {}
}

/// A view that puts text on screen.
///
/// A protocol rather than a `switch` over view types, so a new kind is added by
/// conforming it rather than by editing the walk.
protocol ShowsText {
    
    var shownText: [String] { get }
}

extension ShowsText {
    
    func onScreen(_ candidates: String?...) -> [String] {
        candidates
            .compactMap { $0 }
            .filter { $0.isEmpty == false }
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
