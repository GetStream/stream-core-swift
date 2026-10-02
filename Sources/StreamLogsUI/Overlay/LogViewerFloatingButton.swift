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
    // The icon is drawn by masking a gradient with the symbol.
    private let iconGradientView = GradientView()
    private let iconView = UIImageView(image: UIImage(systemName: "ladybug.fill"))
    private let chevronView = UIImageView()

    // From the accent color to cyan, like the Stream logo.
    private static let iconGradientColors = [LogTokens.UIColors.accentPrimary, UIColor(rgb: 0x00acd4)]

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

        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        iconView.contentMode = .center
        // Spans the icon's bounds only, so the whole ramp is visible.
        iconGradientView.gradientLayer.startPoint = CGPoint(x: 0.3, y: 0.25)
        iconGradientView.gradientLayer.endPoint = CGPoint(x: 0.7, y: 0.75)
        iconGradientView.mask = iconView
        backgroundView.contentView.addSubview(iconGradientView)

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
        iconGradientView.frame = bounds
        iconView.frame = iconGradientView.bounds
        let visibleWidth = LogViewerFloatingButtonLayout.stashedVisibleWidth
        let chevronX = side == .left ? bounds.width - visibleWidth : 0
        chevronView.frame = CGRect(x: chevronX, y: 0, width: visibleWidth, height: bounds.height)
        if !usesGlass {
            backgroundView.layer.cornerRadius = bounds.width / 2
            layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateIconGradientColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateIconGradientColors()
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

    private func updateIconGradientColors() {
        iconGradientView.gradientLayer.colors = Self.iconGradientColors.map { $0.resolvedColor(with: traitCollection).cgColor }
    }

    private func updateStashedAppearance() {
        iconGradientView.alpha = isStashed ? 0 : 1
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

private final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    // swiftlint:disable:next force_cast
    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
}
