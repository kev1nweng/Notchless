import SwiftUI

@main
struct NotchlessApp: App {
    @State private var model = NotchlessModel()

    var body: some Scene {
        MenuBarExtra {
            Toggle("Hide Notch", isOn: $model.isEnabled)
            Toggle("Hide on Lock Screen", isOn: $model.automaticallyHidesOnLock)

            Divider()

            Button("Quit Notchless", action: model.quit)
                .keyboardShortcut("q")
        } label: {
            Label("Notchless", systemImage: model.isEnabled ? "rectangle.topthird.inset.filled" : "rectangle.topthird.inset")
        }
        .menuBarExtraStyle(.menu)
    }
}
