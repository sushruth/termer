import AppKit
import Foundation
import SwiftTerm

struct Config: Codable {
    var name: String
    var command: String
    var args: String
    var cwd: String
    var dynamicCwd: Bool?
}

@MainActor
final class Runner: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    var terminal: LocalProcessTerminalView?
    var appName = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = loadConfig()
        appName = config.name
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 560),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = config.name
        window.delegate = self
        app.mainMenu = makeMenu(config.name)

        let terminal = ThemedTerminalView(frame: window.contentView?.bounds ?? .zero)
        terminal.autoresizingMask = [.width, .height]
        terminal.applySystemTheme()
        window.contentView = terminal
        self.window = window
        self.terminal = terminal

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        let cwd = config.dynamicCwd == true ? chooseFolder(fallback: config.cwd) : expandHome(config.cwd)
        let args = render(config.args, name: config.name, cwd: cwd)
        let commandLine = ([config.command] + splitArgs(args)).map(sh).joined(separator: " ")

        // Use the user's configured login shell so their real profile/rc loads and resolves
        // PATH/mise/asdf/homebrew/aliases. fish takes a different flag set than POSIX shells.
        let shell = userShell()
        let isFish = (shell as NSString).lastPathComponent == "fish"
        let shellArgs = isFish ? ["-l", "-c", "exec \(commandLine)"] : ["-lic", "exec \(commandLine)"]
        terminal.startProcess(
            executable: shell,
            args: shellArgs,
            environment: inheritedEnvironment(),
            execName: config.name,
            currentDirectory: cwd
        )

        // Seed a thumbnail on first open (when none exists yet); quit refreshes it.
        if !FileManager.default.fileExists(atPath: thumbURL(appName).path) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in self?.captureThumbnail() }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func windowWillClose(_ notification: Notification) {
        captureThumbnail()
        NSApp.terminate(nil)
    }

    // ponytail: in-process cacheDisplay snapshot (no screen-recording permission). If SwiftTerm
    // ever renders via Metal and this comes out blank, switch to CGWindowListCreateImage.
    func captureThumbnail() {
        guard let view = window?.contentView, view.bounds.width > 1,
              let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let png = rep.representation(using: .png, properties: [:]) else { return }
        let url = thumbURL(appName)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? png.write(to: url)
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

    func chooseFolder(fallback: String) -> String {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: expandHome(fallback), isDirectory: true)
        return panel.runModal() == .OK ? panel.url!.path : expandHome(fallback)
    }

}

final class ThemedTerminalView: LocalProcessTerminalView {
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applySystemTheme()
    }

    func applySystemTheme() {
        let old = NSAppearance.current
        NSAppearance.current = effectiveAppearance
        nativeBackgroundColor = NSColor.textBackgroundColor
        nativeForegroundColor = NSColor.labelColor
        NSAppearance.current = old
        layer?.backgroundColor = nativeBackgroundColor.cgColor
        needsDisplay = true
    }
}

// Shared with the manager: ~/Applications/Termer Apps/.thumbs/<slug>.png
func thumbURL(_ name: String) -> URL {
    FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications/Termer Apps/.thumbs", isDirectory: true)
        .appendingPathComponent(slug(name) + ".png")
}

func slug(_ s: String) -> String {
    s.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
}

// The user's configured login shell (Directory Services pw_shell), preferred over $SHELL,
// falling back to zsh. So a bash/fish user gets their own shell + profile, not a hardcoded zsh.
func userShell() -> String {
    if let pw = getpwuid(getuid()), let cString = pw.pointee.pw_shell {
        let path = String(cString: cString)
        if !path.isEmpty { return path }
    }
    let envShell = ProcessInfo.processInfo.environment["SHELL"] ?? ""
    return envShell.isEmpty ? "/bin/zsh" : envShell
}

// Inherit the GUI launch environment (USER, HOME, LOGNAME, SSH_AUTH_SOCK, …) so commands that
// need them work; the login+interactive shell then layers on the user's profile/rc.
func inheritedEnvironment() -> [String] {
    var env = ProcessInfo.processInfo.environment
    env["TERM"] = "xterm-256color"
    return env.map { "\($0)=\($1)" }
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

func render(_ s: String, name: String, cwd: String) -> String {
    s.replacingOccurrences(of: "{name}", with: name)
     .replacingOccurrences(of: "{pwd}", with: cwd)
     .replacingOccurrences(of: "{cwd}", with: cwd)
}

let app = NSApplication.shared
let delegate = Runner()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
