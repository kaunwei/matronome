import SwiftUI
import AppKit
import MetronomeCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure macOS recognizes the app as a foreground GUI application
        NSApp.setActivationPolicy(.regular)
        
        // Dynamically assign custom Metronome AppIcon to Dock
        setApplicationDockIcon()
        
        let contentView = MainMetronomeView()
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Metronome"
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        self.window = window
        
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setApplicationDockIcon() {
        if let iconUrl = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") ??
                         Bundle.main.url(forResource: "AppIcon_1024", withExtension: "png") {
            if let image = NSImage(contentsOf: iconUrl) {
                NSApp.applicationIconImage = image
                return
            }
        }
        
        // Fallback check in build folder if running via swift run from project root
        let currentDir = FileManager.default.currentDirectoryPath
        let candidates = [
            "\(currentDir)/build/AppIcon.icns",
            "\(currentDir)/build/AppIcon_1024.png",
            "\(currentDir)/build/Metronome.app/Contents/Resources/AppIcon.icns"
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path),
               let image = NSImage(contentsOfFile: path) {
                NSApp.applicationIconImage = image
                break
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
