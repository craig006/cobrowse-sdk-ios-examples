//
//  FrameworkPill.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI
import UIKit

// Demo chrome: which framework drew this screen. Nothing here knows anything
// about redaction — what the agent can see is the agent's view, not a label
// this app prints about itself.

// MARK: - SwiftUI

extension View {

    func frameworkPill() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                Text("SWIFTUI")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.purple.opacity(0.12), in: Capsule())
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
            }
    }
}

// MARK: - UIKit

extension UIViewController {

    func addFrameworkPill() {
        let label = PaddedLabel()
        label.text = "UIKIT"
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        label.layer.cornerRadius = 9
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }
}

private final class PaddedLabel: UILabel {
    private let insets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
