import HyperCapsLockCore
import SwiftUI

struct ShortcutAppPicker: View {
    var appState: AppState
    let slot: Int
    @Binding var target: AppTarget

    var body: some View {
        HStack(spacing: 10) {
            KeyComboView(trigger: appState.config.triggerMode, key: String(slot))

            Image(nsImage: appState.appIcon(for: target))
                .resizable()
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)

            Picker("数字キー \(slot) で開くアプリ", selection: Binding(
                get: { target.bundleIdentifier },
                set: { id in
                    if let app = appState.installedApps.first(where: { $0.bundleIdentifier == id }) {
                        target = app
                    }
                }
            )) {
                if !appState.installedApps.contains(where: { $0.bundleIdentifier == target.bundleIdentifier }) {
                    Text(target.name).tag(target.bundleIdentifier)
                }
                ForEach(appState.installedApps, id: \.bundleIdentifier) { app in
                    Text(app.name).tag(app.bundleIdentifier)
                }
            }
            .labelsHidden()
        }
    }
}
