//
//  SavedCardRow.swift
//  PBD
//

import SwiftUI
import UIKit

import CobrowseSDK

// A saved card, drawn the same way in both worlds: icon, brand, nickname, and
// the digits off on their own.
//
// The separation is the point. `RedactedByRegexDelegate` reads one label at a
// time, so putting the digits in their own label is what lets an agent see
// which card is which while the number itself stays hidden. Written as a single
// "Visa •••• 4242" string, matching it would black out the whole row.

// MARK: - SwiftUI

struct SavedCardRowView: View {

    let card: SavedCard

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: card.symbolName)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.nickname)
                    .font(.body)
                Text(card.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(card.maskedNumber)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .cobrowseRedacted()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - UIKit

final class SavedCardRow: UIControl {

    init(card: SavedCard) {
        super.init(frame: .zero)

        let icon = UIImageView(image: UIImage(systemName: card.symbolName))
        icon.tintColor = .tintColor
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let nicknameLabel = UILabel()
        nicknameLabel.text = card.nickname
        nicknameLabel.font = .preferredFont(forTextStyle: .body)

        let brandLabel = UILabel()
        brandLabel.text = card.brand
        brandLabel.font = .preferredFont(forTextStyle: .caption1)
        brandLabel.textColor = .secondaryLabel

        let names = UIStackView(arrangedSubviews: [nicknameLabel, brandLabel])
        names.axis = .vertical
        names.spacing = 2

        // On its own, so only this is hidden.
        let numberLabel = UILabel()
        numberLabel.text = card.maskedNumber
        numberLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        numberLabel.textColor = .secondaryLabel
        numberLabel.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [icon, names, UIView(), numberLabel])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 32),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }
}
