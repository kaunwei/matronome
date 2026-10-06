import SwiftUI
import MetronomeCore

struct MetronomeApp: App {
    var body: some Scene {
        WindowGroup {
            MainMetronomeView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 580, height: 760)
    }
}

MetronomeApp.main()
