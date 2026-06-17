import AppKit
import Foundation

struct TuiApp: Codable {
    var name: String
    var command: String
    var args: String
    var cwd: String
    var terminal: String
}

final class Store {
    let root = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications/Termer Apps", isDirectory: true)

    var configs: URL { root.appendingPathComponent(".configs", isDirectory: true) }

    func load() -> [TuiApp] {
        (try? FileManager.default.contentsOfDirectory(at: configs, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "json" }
            .compactMap { try? JSONDecoder().decode(TuiApp.self, from: Data(contentsOf: $0)) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } ?? []
    }

    func save(_ app: TuiApp) throws {
        try FileManager.default.createDirectory(at: configs, withIntermediateDirectories: true)
        try makeBundle(app)
        let data = try JSONEncoder().encode(app)
        try data.write(to: configs.appendingPathComponent(slug(app.name) + ".json"))
    }

    func remove(_ app: TuiApp) throws {
        try? FileManager.default.removeItem(at: bundleURL(app))
        try? FileManager.default.removeItem(at: configs.appendingPathComponent(slug(app.name) + ".json"))
    }

    func launch(_ app: TuiApp) {
        NSWorkspace.shared.openApplication(at: bundleURL(app), configuration: .init())
    }

    func reveal(_ app: TuiApp) {
        NSWorkspace.shared.activateFileViewerSelecting([bundleURL(app)])
    }

    private func bundleURL(_ app: TuiApp) -> URL {
        root.appendingPathComponent(app.name + ".app", isDirectory: true)
    }

    private func makeBundle(_ app: TuiApp) throws {
        let bundle = bundleURL(app)
        let contents = bundle.appendingPathComponent("Contents", isDirectory: true)
        let macOS = contents.appendingPathComponent("MacOS", isDirectory: true)
        try? FileManager.default.removeItem(at: bundle)
        try FileManager.default.createDirectory(at: macOS, withIntermediateDirectories: true)

        let exe = macOS.appendingPathComponent("launcher")
        try launcher(app).write(to: exe, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: exe.path)
        try plist(app).write(to: contents.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
        _ = run("/usr/bin/codesign", ["--force", "--sign", "-", bundle.path])
    }

    private func launcher(_ app: TuiApp) -> String {
        let commandLine = ([app.command] + splitArgs(app.args)).map(sh).joined(separator: " ")
        let script = "cd \(sh(expandHome(app.cwd))) && exec \(commandLine)"
        switch app.terminal {
        case "Terminal":
            return """
            #!/bin/zsh
            /usr/bin/osascript -e \(sh("tell application \"Terminal\" to do script " + quotedApple(script)))
            """
        case "iTerm2":
            return """
            #!/bin/zsh
            /usr/bin/osascript <<'APPLESCRIPT'
            tell application "iTerm2"
              create window with default profile
              tell current session of current window
                write text \(quotedApple(script))
                set name to \(quotedApple(app.name))
              end tell
            end tell
            APPLESCRIPT
            """
        default:
            return """
            #!/bin/zsh
            open -a \(sh(app.terminal)) --args --working-directory=\(sh(expandHome(app.cwd))) -e \(commandLine)
            """
        }
    }

    private func plist(_ app: TuiApp) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
          <key>CFBundleExecutable</key><string>launcher</string>
          <key>CFBundleIdentifier</key><string>local.termer.\(slug(app.name))</string>
          <key>CFBundleName</key><string>\(xml(app.name))</string>
          <key>CFBundleDisplayName</key><string>\(xml(app.name))</string>
          <key>CFBundlePackageType</key><string>APPL</string>
          <key>LSMinimumSystemVersion</key><string>14.0</string>
        </dict></plist>
        """
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {
    let store = Store()
    var apps: [TuiApp] = []
    let table = NSTableView()
    let name = NSTextField()
    let command = NSTextField()
    let args = NSTextField()
    let cwd = NSTextField()
    let terminal = NSPopUpButton()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 280),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "Termer"
        window.minSize = NSSize(width: 500, height: 260)
        app.mainMenu = makeMenu()

        let root = NSStackView()
        root.orientation = .horizontal
        root.alignment = .top
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        window.contentView = root

        table.addTableColumn(NSTableColumn(identifier: .init("name")))
        table.headerView = nil
        table.dataSource = self
        table.delegate = self
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.widthAnchor.constraint(equalToConstant: 130).isActive = true
        root.addArrangedSubview(scroll)

        let form = NSStackView()
        form.orientation = .vertical
        form.spacing = 8
        form.alignment = .leading
        root.addArrangedSubview(form)

        addRow("Name", name, form)
        addRow("Command", command, form)
        addRow("Args", args, form)
        addFolderRow(form)
        terminal.addItems(withTitles: ["Ghostty", "Terminal", "iTerm2"])
        addRow("Terminal", terminal, form)

        let buttons = NSStackView()
        buttons.spacing = 6
        for (title, action) in [("Save", #selector(save)), ("Launch", #selector(launch)), ("Remove", #selector(remove)), ("Reveal", #selector(reveal))] {
            let button = NSButton(title: title, target: self, action: action)
            button.bezelStyle = .rounded
            buttons.addArrangedSubview(button)
        }
        form.addArrangedSubview(buttons)

        cwd.stringValue = FileManager.default.homeDirectoryForCurrentUser.path
        reload()
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func numberOfRows(in tableView: NSTableView) -> Int { apps.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTextField(labelWithString: apps[row].name)
        cell.lineBreakMode = .byTruncatingTail
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard table.selectedRow >= 0 else { return }
        show(apps[table.selectedRow])
    }

    @objc func save() {
        guard !name.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return alert("Name is required.") }
        guard !command.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return alert("Command is required.") }
        let app = TuiApp(name: name.stringValue, command: command.stringValue, args: args.stringValue, cwd: cwd.stringValue, terminal: terminal.titleOfSelectedItem ?? "Ghostty")
        do { try store.save(app); reload(selecting: app.name) } catch { alert(error.localizedDescription) }
    }

    @objc func launch() { selected.map(store.launch) }
    @objc func reveal() { selected.map(store.reveal) }
    @objc func remove() {
        guard let app = selected else { return }
        do { try store.remove(app); reload() } catch { alert(error.localizedDescription) }
    }

    var selected: TuiApp? {
        table.selectedRow >= 0 && table.selectedRow < apps.count ? apps[table.selectedRow] : nil
    }

    func reload(selecting selectedName: String? = nil) {
        apps = store.load()
        table.reloadData()
        if let selectedName, let row = apps.firstIndex(where: { $0.name == selectedName }) {
            table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    func show(_ app: TuiApp) {
        name.stringValue = app.name
        command.stringValue = app.command
        args.stringValue = app.args
        cwd.stringValue = app.cwd
        terminal.selectItem(withTitle: app.terminal)
    }

    func addRow(_ label: String, _ field: NSView, _ stack: NSStackView) {
        let row = NSStackView()
        row.spacing = 8
        row.alignment = .centerY
        let l = NSTextField(labelWithString: label)
        l.alignment = .right
        l.textColor = .secondaryLabelColor
        l.widthAnchor.constraint(equalToConstant: 68).isActive = true
        field.widthAnchor.constraint(equalToConstant: 250).isActive = true
        row.addArrangedSubview(l)
        row.addArrangedSubview(field)
        stack.addArrangedSubview(row)
    }

    func addFolderRow(_ stack: NSStackView) {
        let row = NSStackView()
        row.spacing = 8
        row.alignment = .centerY
        let l = NSTextField(labelWithString: "Folder")
        l.alignment = .right
        l.textColor = .secondaryLabelColor
        l.widthAnchor.constraint(equalToConstant: 68).isActive = true
        let choose = NSButton(title: "Choose...", target: self, action: #selector(chooseFolder))
        choose.bezelStyle = .rounded
        cwd.widthAnchor.constraint(equalToConstant: 160).isActive = true
        row.addArrangedSubview(l)
        row.addArrangedSubview(cwd)
        row.addArrangedSubview(choose)
        stack.addArrangedSubview(row)
    }

    @objc func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            cwd.stringValue = url.path
        }
    }

    func alert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Termer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        menu.addItem(appMenuItem)
        return menu
    }
}

func splitArgs(_ s: String) -> [String] {
    // ponytail: whitespace split; replace with shellwords when quoted args matter.
    s.split(separator: " ").map(String.init)
}

func expandHome(_ s: String) -> String {
    s.hasPrefix("~/") ? FileManager.default.homeDirectoryForCurrentUser.path + String(s.dropFirst()) : s
}

func slug(_ s: String) -> String {
    s.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
}

func sh(_ s: String) -> String {
    "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

func xml(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
     .replacingOccurrences(of: "<", with: "&lt;")
     .replacingOccurrences(of: ">", with: "&gt;")
}

func quotedApple(_ s: String) -> String {
    "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}

func run(_ path: String, _ args: [String]) -> Bool {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    return (try? p.run()).map { p.waitUntilExit(); return p.terminationStatus == 0 } ?? false
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
