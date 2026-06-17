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
final class Runner: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    var terminal: LocalProcessTerminalView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = loadConfig()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 560),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = config.name
        window.delegate = self
        app.mainMenu = makeMenu(config.name)

        let terminal = LocalProcessTerminalView(frame: window.contentView?.bounds ?? .zero)
        terminal.autoresizingMask = [.width, .height]
        window.contentView = terminal
        self.window = window
        self.terminal = terminal

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        let commandLine = ([config.command] + splitArgs(config.args)).map(sh).joined(separator: " ")

        // ponytail: shell resolves PATH/mise/asdf/homebrew. Direct exec later only if shell startup becomes a real problem.
        terminal.startProcess(
            executable: "/bin/zsh",
            args: ["-lic", "exec \(commandLine)"],
            environment: ["TERM=xterm-256color"],
            execName: config.name,
            currentDirectory: expandHome(config.cwd)
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }

    func loadConfig() -> Config {
        let url = Bundle.main.resourceURL!.appendingPathComponent("config.json")
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(Config.self, from: data)
    }

    func makeMenu(_ name: String) -> NSMenu {
        let menu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit \(name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        menu.addItem(appMenuItem)
        return menu
    }
}

func splitArgs(_ s: String) -> [String] {
    s.split(separator: " ").map(String.init)
}

func expandHome(_ s: String) -> String {
    s.hasPrefix("~/") ? FileManager.default.homeDirectoryForCurrentUser.path + String(s.dropFirst()) : s
}

func sh(_ s: String) -> String {
    "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

let app = NSApplication.shared
let delegate = Runner()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
