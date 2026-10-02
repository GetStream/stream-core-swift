//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ObjectiveC
import SwiftUI
import UIKit

/// Presents ``LogListView`` as a sheet above the app.
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

    /// The filter applied when the viewer is presented, unless another one is passed to ``present(recorder:settings:appearance:filter:)``.
    ///
    /// Also used when the viewer is presented by shaking the device. Defaults to showing every entry.
    public static var defaultFilter = LogFilter()

    /// Whether a floating button that opens the log viewer is shown above the app. Defaults to `false`.
    ///
    /// The button can be dragged to any side of the screen, and flung past an edge to tuck it away.
    public static var showsFloatingButton = false {
        didSet {
            if #available(iOS 16.0, *) {
                LogViewerOverlay.shared.showsFloatingButton = showsFloatingButton
            }
        }
    }

    /// Whether the log viewer is currently presented.
    public static var isPresented: Bool {
        if #available(iOS 16.0, *) {
            return LogViewerOverlay.shared.isPresentingViewer
        }
        return false
    }

    /// Presents the entries of the given recorder in a sheet above the app.
    ///
    /// The sheet can be resized to small, medium and large heights. At the small and medium heights,
    /// the app behind it stays interactive. Does nothing if the viewer is already presented.
    ///
    /// - Parameter filter: The filter applied when the viewer appears. Defaults to ``defaultFilter``.
    public static func present(
        recorder: any LogRecorder = InMemoryLogRecorder.shared,
        settings: LogSettings = .shared,
        appearance: LogViewerAppearance = LogViewerAppearance(),
        filter: LogFilter = defaultFilter
    ) {
        guard #available(iOS 16.0, *), !isPresented else { return }
        let viewController = LogViewerHostingController(rootView: AnyView(
            NavigationStack {
                LogListView(recorder: recorder, settings: settings, filter: filter)
            }
            // Sheets are translucent below the large detent, which looks washed out in dark mode.
            // The system also lightens their content there, so black ends up close to the large detent's background.
            .background(Color(UIColor { $0.userInterfaceStyle == .dark ? .black : .systemBackground }).ignoresSafeArea())
            .logViewerAppearance(appearance)
        ))
        viewController.modalPresentationStyle = .pageSheet
        if let sheet = viewController.sheetPresentationController {
            let small = UISheetPresentationController.Detent.custom(identifier: .logViewerSmall) { context in
                context.maximumDetentValue * 0.3
            }
            sheet.detents = [small, .medium(), .large()]
            sheet.selectedDetentIdentifier = .medium
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
        }
        LogViewerOverlay.shared.present(viewController)
    }

    /// Dismisses the log viewer if it is presented.
    public static func dismiss() {
        if #available(iOS 16.0, *) {
            LogViewerOverlay.shared.dismissViewer()
        }
    }
}

@available(iOS 16.0, *)
private extension UISheetPresentationController.Detent.Identifier {
    static let logViewerSmall = Self("io.getstream.logs-ui.small")
}

@available(iOS 16.0, *)
private final class LogViewerHostingController: UIHostingController<AnyView> {
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed {
            LogViewerOverlay.shared.viewerDidDismiss()
        }
    }
}

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
