//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

final class LogViewerFloatingButton: UIView {
    var side: LogViewerFloatingButtonLayout.Side = .right {
        didSet { updateStashedAppearance() }
    }

    var isStashed = false {
        didSet { updateStashedAppearance() }
    }

    var onActivate: (() -> Void)?
    var onStash: (() -> Void)?
    var onUnstash: (() -> Void)?

    private let usesGlass: Bool = if #available(iOS 26.0, *) { true } else { false }
    private let backgroundView = UIVisualEffectView(effect: LogViewerFloatingButton.backgroundEffect)
    private let iconView = UIImageView(image: UIImage(systemName: "ladybug.fill"))
    private let chevronView = UIImageView()

    private static var backgroundEffect: UIVisualEffect {
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            effect.isInteractive = true
            return effect
        }
        return UIBlurEffect(style: .systemThickMaterial)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Interactive glass reacts to touches on itself, so it must receive them.
        backgroundView.isUserInteractionEnabled = usesGlass
        if #available(iOS 26.0, *) {
            backgroundView.cornerConfiguration = .capsule()
        } else {
            backgroundView.clipsToBounds = true
        }
        addSubview(backgroundView)

        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iconView.tintColor = .label
        iconView.contentMode = .center
        backgroundView.contentView.addSubview(iconView)

        chevronView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        chevronView.tintColor = .secondaryLabel
        chevronView.contentMode = .center
        backgroundView.contentView.addSubview(chevronView)

        if !usesGlass {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.25
            layer.shadowRadius = 8
            layer.shadowOffset = CGSize(width: 0, height: 4)
        }

        isAccessibilityElement = true
        accessibilityIdentifier = "LogViewerFloatingButton"
        accessibilityTraits = .button
        updateStashedAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.frame = bounds
        iconView.frame = bounds
        let visibleWidth = LogViewerFloatingButtonLayout.stashedVisibleWidth
        let chevronX = side == .left ? bounds.width - visibleWidth : 0
        chevronView.frame = CGRect(x: chevronX, y: 0, width: visibleWidth, height: bounds.height)
        if !usesGlass {
            backgroundView.layer.cornerRadius = bounds.width / 2
            layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
        }
    }

    override func accessibilityActivate() -> Bool {
        if isStashed {
            onUnstash?()
        } else {
            onActivate?()
        }
        return true
    }

    private func updateStashedAppearance() {
        iconView.alpha = isStashed ? 0 : 1
        chevronView.alpha = isStashed ? 1 : 0
        chevronView.image = UIImage(systemName: side == .left ? "chevron.right" : "chevron.left")
        setNeedsLayout()

        accessibilityLabel = "Logs"
        accessibilityValue = isStashed ? "Hidden" : nil
        accessibilityHint = isStashed ? "Shows the logs button." : "Opens the log viewer."
        accessibilityCustomActions = [
            isStashed
                ? UIAccessibilityCustomAction(name: "Show") { [weak self] _ in
                    self?.onUnstash?()
                    return true
                }
                : UIAccessibilityCustomAction(name: "Hide") { [weak self] _ in
                    self?.onStash?()
                    return true
                }
        ]
    }
}
