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
    private let gradientLayer = CAGradientLayer()
    private let glossLayer = CAGradientLayer()
    private let iconView = UIImageView(image: UIImage(systemName: "ladybug.fill"))
    private let chevronView = UIImageView()

    // The Stream brand ramp, around the `accentPrimary` token.
    private static let accentLight = UIColor(rgb: 0x4586ff)
    private static let accent = UIColor(rgb: 0x005fff)
    private static let accentDark = UIColor(rgb: 0x0042b4)

    private static var backgroundEffect: UIVisualEffect {
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            effect.tintColor = accent.withAlphaComponent(0.7)
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

        // On glass, a translucent gradient keeps the refraction visible through the accent color.
        gradientLayer.colors = [Self.accentLight, Self.accent, Self.accentDark].map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        gradientLayer.opacity = usesGlass ? 0.6 : 1
        gradientLayer.masksToBounds = true
        gradientLayer.borderWidth = 1
        gradientLayer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        backgroundView.contentView.layer.addSublayer(gradientLayer)

        glossLayer.colors = [UIColor.white.withAlphaComponent(0.45), UIColor.white.withAlphaComponent(0)].map(\.cgColor)
        glossLayer.startPoint = CGPoint(x: 0.5, y: 0)
        glossLayer.endPoint = CGPoint(x: 0.5, y: 1)
        glossLayer.locations = [0, 0.55]
        glossLayer.masksToBounds = true
        backgroundView.contentView.layer.addSublayer(glossLayer)

        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iconView.tintColor = .white
        iconView.contentMode = .center
        iconView.layer.shadowColor = Self.accentDark.cgColor
        iconView.layer.shadowOpacity = 0.5
        iconView.layer.shadowRadius = 2
        iconView.layer.shadowOffset = CGSize(width: 0, height: 1)
        backgroundView.contentView.addSubview(iconView)

        chevronView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        chevronView.tintColor = .white
        chevronView.contentMode = .center
        backgroundView.contentView.addSubview(chevronView)

        layer.shadowColor = Self.accent.cgColor
        layer.shadowOpacity = usesGlass ? 0.3 : 0.45
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

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
        let radius = bounds.height / 2

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = radius
        glossLayer.frame = bounds
        glossLayer.cornerRadius = radius
        CATransaction.commit()

        if !usesGlass {
            backgroundView.layer.cornerRadius = radius
        }
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
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
