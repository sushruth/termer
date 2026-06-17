import AppKit
import Foundation
import SwiftTerm

struct Config: Codable {
    var name: String
    var command: String
    var args: String
    var cwd: String
}

@MainActor
final class Runner: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = loadConfig()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 560),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = config.name

        let terminal = LocalProcessTerminalView(frame: window.contentView?.bounds ?? .zero)
        terminal.autoresizingMask = [.width, .height]
        window.contentView = terminal

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // ponytail: use SwiftTerm's local-process PTY; custom PTY only if this API blocks a needed behavior.
        terminal.startProcess(
            executable: config.command,
            args: splitArgs(config.args),
            environment: ["TERM=xterm-256color"],
            execName: URL(fileURLWithPath: config.command).lastPathComponent,
            currentDirectory: expandHome(config.cwd)
        )
    }

    func loadConfig() -> Config {
        let url = Bundle.main.resourceURL!.appendingPathComponent("config.json")
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(Config.self, from: data)
    }
}

func splitArgs(_ s: String) -> [String] {
    s.split(separator: " ").map(String.init)
}

func expandHome(_ s: String) -> String {
    s.hasPrefix("~/") ? FileManager.default.homeDirectoryForCurrentUser.path + String(s.dropFirst()) : s
}

let app = NSApplication.shared
let delegate = Runner()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
