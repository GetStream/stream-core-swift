//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A bag of product-specific configuration attached to ``Appearance``.
///
/// Each SDK defines its own conforming type (call images, chat formatters,
/// and so on) and exposes it through an extension. CoreUI does not know
/// those types.
public protocol AppearanceBag: AnyObject {
    init()
}

/// The visual configuration every Stream SDK draws from.
///
/// This type owns the shared design system: ``colorPalette`` and
/// ``tokens``. Product-specific pieces — images, formatters, localization
/// — are attached by each SDK through ``AppearanceBag``.
///
/// Because every SDK defaults to ``shared``, an app that runs more than
/// one of them reskins them together:
///
/// ```swift
/// Appearance.shared.colorPalette.brand500 = .purple
/// ```
///
/// The default instance is process-wide, so an override made through one
/// SDK is visible to the others. To keep them apart, build a separate
/// instance and hand it to the SDK.
///
/// Tokens derive lazily, so apply overrides before the first read.
public final class Appearance {
    /// The instance every Stream SDK uses unless it is given another one.
    public static let shared = Appearance()

    /// Same instance as ``shared``. Matches the name Chat already uses.
    public static var `default`: Appearance { shared }

    public var colorPalette: ColorPalette
    public var tokens: DesignSystemTokens

    private var bags: [ObjectIdentifier: Any] = [:]

    /// Used by Stream SDKs to attach product configuration.
    public subscript<Bag: AppearanceBag>(_ type: Bag.Type) -> Bag {
        get {
            if let bag = bags[ObjectIdentifier(type)] as? Bag {
                return bag
            }
            let bag = Bag()
            bags[ObjectIdentifier(type)] = bag
            return bag
        }
        set { bags[ObjectIdentifier(type)] = newValue }
    }

    public init(
        colorPalette: ColorPalette = .init(),
        tokens: DesignSystemTokens = .init()
    ) {
        self.colorPalette = colorPalette
        self.tokens = tokens
    }
}
