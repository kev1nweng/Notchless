import AppKit
import Observation
import ServiceManagement

@MainActor
@Observable
final class NotchlessModel {
    private enum Keys {
        static let isEnabled = "isEnabled"
        static let automaticallyHidesOnLock = "automaticallyHidesOnLock"
    }

    private let overlayController = MenuBarOverlayController()
    private var isUpdatingLaunchAtLogin = false

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

    var launchesAtLogin: Bool {
        didSet {
            guard !isUpdatingLaunchAtLogin else { return }
            updateLaunchAtLoginRegistration()
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

        launchesAtLogin = Self.isLaunchAtLoginConfigured

        overlayController.setAutomaticallyHidesOnLock(automaticallyHidesOnLock)
        overlayController.setEnabled(isEnabled)
    }

    func refreshLaunchAtLoginStatus() {
        setLaunchesAtLogin(Self.isLaunchAtLoginConfigured)
    }

    private func updateLaunchAtLoginRegistration() {
        do {
            if launchesAtLogin {
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSSound.beep()
        }

        setLaunchesAtLogin(Self.isLaunchAtLoginConfigured)
    }

    private static var isLaunchAtLoginConfigured: Bool {
        let status = SMAppService.mainApp.status
        return status == .enabled || status == .requiresApproval
    }

    private func setLaunchesAtLogin(_ enabled: Bool) {
        isUpdatingLaunchAtLogin = true
        launchesAtLogin = enabled
        isUpdatingLaunchAtLogin = false
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
