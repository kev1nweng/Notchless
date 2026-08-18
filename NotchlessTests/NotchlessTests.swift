import AppKit
import Foundation
import Testing
@testable import Notchless

struct NotchlessTests {
    @Test @MainActor
    func overlayPanelsJoinEverySpace() {
        let behavior = MenuBarOverlayController.panelCollectionBehavior
        #expect(behavior.contains(.canJoinAllSpaces))
        #expect(behavior.contains(.stationary))
    }

    @Test @MainActor
    func modelDefaultsToEnabled() {
        UserDefaults.standard.removeObject(forKey: "isEnabled")
        UserDefaults.standard.removeObject(forKey: "automaticallyHidesOnLock")
        let model = NotchlessModel()
        #expect(model.isEnabled)
        #expect(model.automaticallyHidesOnLock)
    }

    @Test @MainActor
    func lockScreenPreferencePersists() {
        UserDefaults.standard.set(false, forKey: "automaticallyHidesOnLock")
        let model = NotchlessModel()
        #expect(!model.automaticallyHidesOnLock)

        model.automaticallyHidesOnLock = true
        #expect(UserDefaults.standard.bool(forKey: "automaticallyHidesOnLock"))
    }
}
