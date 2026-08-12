import AppKit

@MainActor
final class MenuBarOverlayController {
    private var panels: [CGDirectDisplayID: MenuBarOverlayPanel] = [:]
    private var observers: [NSObjectProtocol] = []
    private var distributedObservers: [NSObjectProtocol] = []
    private var restoreTask: Task<Void, Never>?
    private let fadeDuration: TimeInterval = 0.22
    private var isUserSessionActive = true
    private(set) var isEnabled = false
    private(set) var automaticallyHidesOnLock = true

    init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuildPanels() }
        })

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observers.append(workspaceCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                // A stationary panel is not assigned to each individual Space.
                // Re-order it after the transition so WindowServer keeps it
                // immediately behind the newly active menu bar.
                self?.orderPanels()
            }
        })

        for name in [NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.screensDidSleepNotification] {
            observers.append(workspaceCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard self?.automaticallyHidesOnLock == true else { return }
                    self?.suspendForSessionTransition()
                }
            })
        }

        for name in [NSWorkspace.sessionDidBecomeActiveNotification, NSWorkspace.screensDidWakeNotification] {
            observers.append(workspaceCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard self?.automaticallyHidesOnLock == true else { return }
                    self?.restoreAfterSessionTransition()
                }
            })
        }

        // These loginwindow notifications arrive closer to the beginning and
        // end of the lock animation than the workspace session notifications.
        let distributedCenter = DistributedNotificationCenter.default()
        distributedObservers.append(distributedCenter.addObserver(
            forName: Notification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard self?.automaticallyHidesOnLock == true else { return }
                self?.suspendForSessionTransition()
            }
        })
        distributedObservers.append(distributedCenter.addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard self?.automaticallyHidesOnLock == true else { return }
                self?.restoreAfterSessionTransition()
            }
        })
    }

    func setAutomaticallyHidesOnLock(_ enabled: Bool) {
        guard enabled != automaticallyHidesOnLock else { return }
        automaticallyHidesOnLock = enabled

        if !enabled, !isUserSessionActive {
            restoreTask?.cancel()
            restoreTask = nil
            isUserSessionActive = true
            rebuildPanels()
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled

        if enabled {
            rebuildPanels()
        } else {
            fadeOutAndClosePanels()
        }
    }

    private func rebuildPanels() {
        guard isEnabled, isUserSessionActive else { return }
        closePanels()

        for screen in NSScreen.screens {
            let panel = MenuBarOverlayPanel(screen: screen)
            panel.alphaValue = 0
            panels[screen.displayID] = panel
        }

        orderPanels()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = fadeDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panels.values.forEach { $0.animator().alphaValue = 1 }
        }
    }

    private func closePanels() {
        for panel in panels.values {
            panel.close()
        }
        panels.removeAll()
    }

    private func fadeOutAndClosePanels() {
        let closingPanels = Array(panels.values)
        panels.removeAll()
        guard !closingPanels.isEmpty else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = fadeDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            closingPanels.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            closingPanels.forEach { $0.close() }
        }
    }

    private func orderPanels() {
        guard isEnabled, isUserSessionActive else { return }
        panels.values.forEach { $0.orderFrontRegardless() }
    }

    private func suspendForSessionTransition() {
        restoreTask?.cancel()
        restoreTask = nil
        isUserSessionActive = false

        // Fade promptly, then remove the windows so WindowServer does not keep
        // them around after the lock-screen transition completes.
        fadeOutAndClosePanels()
    }

    private func restoreAfterSessionTransition() {
        restoreTask?.cancel()
        restoreTask = Task { [weak self] in
            // Wait until loginwindow's unlock zoom and display relayout settle.
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled, let self else { return }
            isUserSessionActive = true
            rebuildPanels()
        }
    }
}

private final class MenuBarOverlayPanel: NSPanel {
    init(screen: NSScreen) {
        let height = Self.menuBarHeight(for: screen)
        let frame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - height,
            width: screen.frame.width,
            height: height
        )

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) - 1)
        backgroundColor = .black
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.black.cgColor
        isOpaque = true
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        canHide = false
        isMovable = false
        animationBehavior = .none
        isExcludedFromWindowsMenu = true
        // Do not use `.canJoinAllSpaces`: WindowServer creates a Space-bound
        // representation for that mode, which fades with the outgoing desktop.
        // A stationary, non-full-screen panel stays fixed while desktops slide
        // underneath it and is excluded from full-screen Spaces.
        collectionBehavior = [.stationary, .ignoresCycle, .fullScreenNone]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func isAccessibilityElement() -> Bool { false }

    private static func menuBarHeight(for screen: NSScreen) -> CGFloat {
        let visibleFrameHeight = screen.frame.maxY - screen.visibleFrame.maxY
        if visibleFrameHeight > 0 {
            return visibleFrameHeight
        }
        if screen.safeAreaInsets.top > 0 {
            return screen.safeAreaInsets.top
        }
        return NSStatusBar.system.thickness
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
    }
}
