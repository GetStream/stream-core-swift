//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

// Hosts the floating button and the log viewer sheet in a window above the app,
// so the app keeps receiving touches outside of them and can present its own view controllers.
@available(iOS 16.0, *)
@MainActor
final class LogViewerOverlay {
    static let shared = LogViewerOverlay()

    var showsFloatingButton = false {
        didSet { update() }
    }

    var isPresentingViewer: Bool {
        window?.rootViewController?.presentedViewController != nil
    }

    private var window: LogViewerWindow?
    private var sceneActivationObserver: NSObjectProtocol?

    private var overlayViewController: LogViewerOverlayViewController? {
        window?.rootViewController as? LogViewerOverlayViewController
    }

    func present(_ viewController: UIViewController) {
        guard let window = installWindowIfNeeded(), let rootViewController = window.rootViewController,
              rootViewController.presentedViewController == nil else {
            return
        }
        window.isHidden = false
        overlayViewController?.setFloatingButtonHidden(true, animated: true)
        rootViewController.present(viewController, animated: true)
    }

    func dismissViewer() {
        window?.rootViewController?.dismiss(animated: true)
    }

    func viewerDidDismiss() {
        if let window, window.isKeyWindow {
            appWindow(in: window.windowScene)?.makeKey()
        }
        update(isPresentingViewer: false)
    }

    private func update() {
        update(isPresentingViewer: isPresentingViewer)
    }

    private func update(isPresentingViewer: Bool) {
        guard showsFloatingButton || isPresentingViewer else {
            window?.isHidden = true
            return
        }
        guard let window = installWindowIfNeeded() else { return }
        window.isHidden = false
        overlayViewController?.setFloatingButtonHidden(!showsFloatingButton || isPresentingViewer, animated: true)
    }

    private func installWindowIfNeeded() -> LogViewerWindow? {
        if let window {
            return window
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            observeSceneActivation()
            return nil
        }

        let window = LogViewerWindow(windowScene: scene)
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 1)
        window.backgroundColor = .clear
        let overlayViewController = LogViewerOverlayViewController()
        overlayViewController.onOpenViewer = { LogViewer.present() }
        window.rootViewController = overlayViewController
        window.isHidden = false
        self.window = window
        return window
    }

    private func observeSceneActivation() {
        guard sceneActivationObserver == nil else { return }
        sceneActivationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.sceneDidActivate()
            }
        }
    }

    private func sceneDidActivate() {
        if let sceneActivationObserver {
            NotificationCenter.default.removeObserver(sceneActivationObserver)
            self.sceneActivationObserver = nil
        }
        update()
    }

    fileprivate func appWindow(in scene: UIWindowScene?) -> UIWindow? {
        scene?.windows.first { !($0 is LogViewerWindow) && $0.windowLevel == .normal && !$0.isHidden }
    }
}

@available(iOS 16.0, *)
final class LogViewerWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event), view !== self, view !== rootViewController?.view else {
            return nil
        }
        // Containers around a sheet that doesn't dim the app are hit outside of the sheet,
        // and those touches belong to the app.
        var presentedViewController = rootViewController?.presentedViewController
        while let viewController = presentedViewController {
            if let presentedView = viewController.presentationController?.presentedView,
               presentedView !== view, presentedView.isDescendant(of: view) {
                return nil
            }
            presentedViewController = viewController.presentedViewController
        }
        return view
    }
}

@available(iOS 16.0, *)
final class LogViewerOverlayViewController: UIViewController {
    var onOpenViewer: (() -> Void)?

    private let floatingButton = LogViewerFloatingButton()
    private var layout = LogViewerFloatingButtonLayout()
    private var isDragging = false
    private var dragStartCenter = CGPoint.zero

    private var appViewController: UIViewController? {
        LogViewerOverlay.shared.appWindow(in: view.window?.windowScene)?.rootViewController
    }

    override var childForStatusBarStyle: UIViewController? { appViewController }
    override var childForStatusBarHidden: UIViewController? { appViewController }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        appViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let size = LogViewerFloatingButtonLayout.size
        floatingButton.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        floatingButton.isHidden = true
        floatingButton.alpha = 0
        floatingButton.onActivate = { [weak self] in self?.onOpenViewer?() }
        floatingButton.onStash = { [weak self] in self?.setStashed(true) }
        floatingButton.onUnstash = { [weak self] in self?.setStashed(false) }
        floatingButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        floatingButton.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        view.addSubview(floatingButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isDragging {
            floatingButton.center = layout.center(in: view.bounds, safeAreaInsets: view.safeAreaInsets)
        }
    }

    func setFloatingButtonHidden(_ isHidden: Bool, animated: Bool) {
        loadViewIfNeeded()
        if !isHidden {
            floatingButton.isHidden = false
        }
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.floatingButton.alpha = isHidden ? 0 : 1
        } completion: { _ in
            if self.floatingButton.alpha == 0 {
                self.floatingButton.isHidden = true
            }
        }
    }

    @objc private func handleTap() {
        if layout.isStashed {
            setStashed(false)
        } else {
            onOpenViewer?()
        }
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            isDragging = true
            dragStartCenter = floatingButton.center
        case .changed:
            let translation = recognizer.translation(in: view)
            floatingButton.center = CGPoint(x: dragStartCenter.x + translation.x, y: dragStartCenter.y + translation.y)
        case .ended, .cancelled, .failed:
            isDragging = false
            let newLayout = LogViewerFloatingButtonLayout.released(
                at: floatingButton.center,
                velocity: recognizer.velocity(in: view),
                in: view.bounds,
                safeAreaInsets: view.safeAreaInsets
            )
            move(to: newLayout)
        default:
            break
        }
    }

    private func setStashed(_ isStashed: Bool) {
        var newLayout = layout
        newLayout.isStashed = isStashed
        move(to: newLayout)
    }

    private func move(to newLayout: LogViewerFloatingButtonLayout) {
        layout = newLayout
        floatingButton.side = newLayout.side
        floatingButton.isStashed = newLayout.isStashed
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.floatingButton.center = newLayout.center(in: self.view.bounds, safeAreaInsets: self.view.safeAreaInsets)
        }
        UIAccessibility.post(notification: .layoutChanged, argument: floatingButton)
    }
}
