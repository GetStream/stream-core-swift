//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ObjectiveC
import SwiftUI
import UIKit

/// Presents ``LogListView`` as a sheet on top of the app.
///
/// Requires iOS 16 or later; on earlier versions presenting does nothing.
@MainActor
public enum LogViewer {
    /// Whether shaking the device presents the log viewer. Defaults to `false`.
    ///
    /// Shake detection works by swizzling `UIWindow.motionEnded(_:with:)`, so only enable it in debug builds.
    public static var presentsOnShake = false {
        didSet {
            if presentsOnShake {
                UIWindow.swizzleMotionEndedIfNeeded()
            }
        }
    }

    /// Presents the entries of the given store from the top-most view controller of the key window.
    public static func present(store: InMemoryLogStore = .shared) {
        guard #available(iOS 16.0, *), let presenter = topViewController(), !(presenter is LogViewerHostingController) else {
            return
        }
        let viewController = LogViewerHostingController(rootView: AnyView(LogListView(store: store)))
        viewController.modalPresentationStyle = .pageSheet
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        presenter.present(viewController, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var topViewController = keyWindow?.rootViewController
        while let presented = topViewController?.presentedViewController, !presented.isBeingDismissed {
            topViewController = presented
        }
        return topViewController
    }
}

private final class LogViewerHostingController: UIHostingController<AnyView> {}

extension UIWindow {
    private typealias MotionEnded = @convention(c) (UIWindow, Selector, UIEvent.EventSubtype, UIEvent?) -> Void

    private static var isMotionEndedSwizzled = false

    fileprivate static func swizzleMotionEndedIfNeeded() {
        guard !isMotionEndedSwizzled else { return }
        isMotionEndedSwizzled = true

        let selector = #selector(motionEnded(_:with:))
        guard let method = class_getInstanceMethod(UIWindow.self, selector) else { return }

        // UIResponder forwards motion events to the next responder using `_cmd`,
        // so the original implementation must always be called with the original selector.
        let original = unsafeBitCast(method_getImplementation(method), to: MotionEnded.self)
        let block: @convention(block) (UIWindow, UIEvent.EventSubtype, UIEvent?) -> Void = { window, motion, event in
            if motion == .motionShake {
                MainActor.assumeIsolated {
                    if LogViewer.presentsOnShake {
                        LogViewer.present()
                    }
                }
            }
            original(window, selector, motion, event)
        }
        let implementation = imp_implementationWithBlock(block)

        // UIWindow inherits `motionEnded` from UIResponder; adding it to UIWindow avoids affecting every responder.
        if !class_addMethod(UIWindow.self, selector, implementation, method_getTypeEncoding(method)) {
            method_setImplementation(method, implementation)
        }
    }
}
