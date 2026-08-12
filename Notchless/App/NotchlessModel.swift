import AppKit
import Observation

@MainActor
@Observable
final class NotchlessModel {
    private enum Keys {
        static let isEnabled = "isEnabled"
        static let automaticallyHidesOnLock = "automaticallyHidesOnLock"
    }

    private let overlayController = MenuBarOverlayController()
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
            overlayController.setEnabled(isEnabled)
        }
    }

    var automaticallyHidesOnLock: Bool {
        didSet {
            UserDefaults.standard.set(automaticallyHidesOnLock, forKey: Keys.automaticallyHidesOnLock)
            overlayController.setAutomaticallyHidesOnLock(automaticallyHidesOnLock)
        }
    }

    init() {
        if UserDefaults.standard.object(forKey: Keys.isEnabled) == nil {
            isEnabled = true
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: Keys.isEnabled)
        }

        if UserDefaults.standard.object(forKey: Keys.automaticallyHidesOnLock) == nil {
            automaticallyHidesOnLock = true
        } else {
            automaticallyHidesOnLock = UserDefaults.standard.bool(forKey: Keys.automaticallyHidesOnLock)
        }

        overlayController.setAutomaticallyHidesOnLock(automaticallyHidesOnLock)
        overlayController.setEnabled(isEnabled)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
