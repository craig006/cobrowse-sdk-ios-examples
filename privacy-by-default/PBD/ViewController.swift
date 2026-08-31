//
//  ViewController.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {

    private lazy var router: SwiftUIRouter? = {
        guard let navigationController else { return nil }
        return SwiftUIRouter(navigationController: navigationController)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "UIKit"
        view.backgroundColor = .systemGroupedBackground
        addFrameworkPill()

        let titleLabel = UILabel()
        titleLabel.text = "UIKit View Controller"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Pick a destination — journeys push onto the nav stack, payment is presented modally."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let journeyAButton = makeButton(title: "Journey A", style: .filled)
        journeyAButton.addTarget(self, action: #selector(journeyATapped), for: .touchUpInside)

        let journeyBButton = makeButton(title: "Journey B", style: .filled)
        journeyBButton.addTarget(self, action: #selector(journeyBTapped), for: .touchUpInside)

        let paymentButton = makeButton(title: "Make Payment", style: .tinted)
        paymentButton.addTarget(self, action: #selector(paymentTapped), for: .touchUpInside)

        let pathNavButton = makeButton(title: "Make Payment (path)", style: .tinted)
        pathNavButton.addTarget(self, action: #selector(pathNavTapped), for: .touchUpInside)

        let uiKitPaymentButton = makeButton(title: "Make Payment (UIKit)", style: .tinted)
        uiKitPaymentButton.addTarget(self, action: #selector(uiKitPaymentTapped), for: .touchUpInside)

        let playgroundButton = makeButton(title: "Presentations (SwiftUI)", style: .tinted)
        playgroundButton.addTarget(self, action: #selector(playgroundTapped), for: .touchUpInside)

        let uiKitPlaygroundButton = makeButton(title: "Presentations (UIKit)", style: .tinted)
        uiKitPlaygroundButton.addTarget(self, action: #selector(uiKitPlaygroundTapped), for: .touchUpInside)


        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            spacer(height: 8),
            journeyAButton,
            journeyBButton,
            spacer(height: 4),
            paymentButton,
            pathNavButton,
            uiKitPaymentButton,
            spacer(height: 4),
            playgroundButton,
            uiKitPlaygroundButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.setCustomSpacing(24, after: subtitleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func makeButton(title: String, style: UIButton.Configuration.Style) -> UIButton {
        var config: UIButton.Configuration
        switch style {
        case .tinted:
            config = .tinted()
        default:
            config = .filled()
        }
        config.title = title
        config.cornerStyle = .large
        config.buttonSize = .large
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    private func spacer(height: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    @objc private func journeyATapped() {
        router?.show(JourneyAView())
    }

    @objc private func journeyBTapped() {
        router?.show(JourneyBView())
    }

    @objc private func paymentTapped() {
        router?.present(MakePaymentView())
    }

    @objc private func playgroundTapped() {
        router?.present(ApprovedPresentationView(depth: 0))
    }

    @objc private func uiKitPlaygroundTapped() {
        present(ApprovedPresentationViewController(depth: 0), animated: true)
    }

    @objc private func uiKitPaymentTapped() {
        navigationController?.pushViewController(MakePaymentViewController(), animated: true)
    }

    @objc private func pathNavTapped() {
        // Deliberately not routed, as a check that nothing in the redaction
        // policy depends on `SwiftUIRouter`. A hosting controller made by hand
        // keeps its `rootView`'s type, which is all the allowlist needs — so
        // this screen behaves exactly as the routed one beside it.
        present(UIHostingController(rootView: MakePaymentPathView()), animated: true)
    }
}

private extension UIButton.Configuration {
    enum Style {
        case filled
        case tinted
    }
}
