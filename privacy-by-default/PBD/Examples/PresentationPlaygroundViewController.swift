//
//  PresentationPlaygroundViewController.swift
//  PBD
//

import UIKit

// The UIKit twins. Same shape as the SwiftUI playground: two types with
// identical bodies, one approved and one not, each able to present either at
// the next depth as a sheet, a cover or a popover.

final class ApprovedPresentationViewController: PresentationPlaygroundViewController {

    init(depth: Int) {
        super.init(depth: depth, approved: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class UnapprovedPresentationViewController: PresentationPlaygroundViewController {

    init(depth: Int) {
        super.init(depth: depth, approved: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PresentationPlaygroundViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    private let depth: Int
    private let approved: Bool

    init(depth: Int, approved: Bool) {
        self.depth = depth
        self.approved = approved
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        addFrameworkPill()

        let title = UILabel()
        title.text = "\(approved ? "Approved" : "Unapproved") · depth \(depth)"
        title.font = .preferredFont(forTextStyle: .title2)
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = approved ? "In Approvals.swift" : "Deliberately not approved"
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center

        let rows = [UIModalPresentationStyle.pageSheet, .overFullScreen, .popover].map { style in
            let row = UIStackView(arrangedSubviews: [
                button(style, approved: true), button(style, approved: false)
            ])
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            return row
        }

        let column = UIStackView(arrangedSubviews: [title, subtitle] + rows)
        column.axis = .vertical
        column.spacing = 12
        column.setCustomSpacing(24, after: subtitle)
        column.translatesAutoresizingMaskIntoConstraints = false

        if depth > 0 {
            let dismissButton = UIButton(configuration: .plain())
            dismissButton.setTitle("Dismiss", for: .normal)
            dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
            column.addArrangedSubview(dismissButton)
        }

        view.addSubview(column)

        NSLayoutConstraint.activate([
            column.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            column.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func button(_ style: UIModalPresentationStyle, approved: Bool) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.title = "\(name(for: style)) · \(approved ? "approved" : "unapproved")"
        configuration.baseForegroundColor = approved ? .systemGreen : .systemRed
        configuration.titleTextAttributesTransformer = .init { attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .footnote)
            return attributes
        }

        let button = UIButton(configuration: configuration)
        button.tag = style.rawValue * 2 + (approved ? 1 : 0)
        button.addTarget(self, action: #selector(presentTapped), for: .touchUpInside)
        return button
    }

    private func name(for style: UIModalPresentationStyle) -> String {
        switch style {
        case .overFullScreen: "Cover"
        case .popover: "Popover"
        default: "Sheet"
        }
    }

    @objc private func presentTapped(_ sender: UIButton) {
        let style = UIModalPresentationStyle(rawValue: sender.tag / 2) ?? .pageSheet
        let approved = sender.tag % 2 == 1

        let next: UIViewController = approved
            ? ApprovedPresentationViewController(depth: depth + 1)
            : UnapprovedPresentationViewController(depth: depth + 1)

        next.modalPresentationStyle = style

        if style == .popover {
            next.preferredContentSize = CGSize(width: 320, height: 380)
            next.popoverPresentationController?.sourceView = sender
            next.popoverPresentationController?.sourceRect = sender.bounds
            next.popoverPresentationController?.delegate = self
        }

        present(next, animated: true)
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    /// Keeps a popover a popover on iPhone, rather than adapting to a sheet.
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        .none
    }
}
