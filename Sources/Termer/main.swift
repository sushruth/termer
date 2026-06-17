import AppKit
import Foundation

struct TuiApp: Codable {
    var name: String
    var command: String
    var args: String
    var cwd: String
    var terminal: String
    var dynamicCwd: Bool?
    var icon: String?
    var builtBy: String?  // Termer version that generated this bundle; triggers regen on update
}

final class Store {
    // The running manager's version (set by package.sh); "dev" under `swift run`.
    static let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "dev"

    let root = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications/Termer Apps", isDirectory: true)

    var configs: URL { root.appendingPathComponent(".configs", isDirectory: true) }

    func thumbURL(_ app: TuiApp) -> URL {
        root.appendingPathComponent(".thumbs/\(slug(app.name)).png")
    }

    func load() -> [TuiApp] {
        (try? FileManager.default.contentsOfDirectory(at: configs, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "json" }
            .compactMap { try? JSONDecoder().decode(TuiApp.self, from: Data(contentsOf: $0)) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } ?? []
    }

    func save(_ app: TuiApp) throws {
        var app = app
        app.builtBy = Self.version
        try FileManager.default.createDirectory(at: configs, withIntermediateDirectories: true)
        try makeBundle(app)
        let data = try JSONEncoder().encode(app)
        try data.write(to: configs.appendingPathComponent(slug(app.name) + ".json"))
    }

    // Regenerate bundles built by an older Termer (stale runner/icon/thumbnail code).
    func migrate() {
        for app in load() where app.builtBy != Self.version {
            try? save(app)
        }
    }

    func remove(_ app: TuiApp) throws {
        try? FileManager.default.removeItem(at: bundleURL(app))
        try? FileManager.default.removeItem(at: configs.appendingPathComponent(slug(app.name) + ".json"))
        try? FileManager.default.removeItem(at: thumbURL(app))
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
        let resources = contents.appendingPathComponent("Resources", isDirectory: true)
        try? FileManager.default.removeItem(at: bundle)
        try FileManager.default.createDirectory(at: macOS, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

        try FileManager.default.copyItem(at: runnerURL(), to: macOS.appendingPathComponent("TermerRunner"))
        if let icon = Bundle.module.url(forResource: "AppIcon", withExtension: "icns") {
            try FileManager.default.copyItem(at: icon, to: resources.appendingPathComponent("AppIcon.icns"))
        }
        try JSONEncoder().encode(app).write(to: resources.appendingPathComponent("config.json"))
        try plist(app).write(to: contents.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
        _ = run("/usr/bin/codesign", ["--force", "--sign", "-", bundle.path])
        // ponytail: glyph icons via Finder custom icon (xattr); fine for locally generated apps,
        // switch to generated .icns if these ever get distributed.
        if let glyph = app.icon?.trimmingCharacters(in: .whitespaces), !glyph.isEmpty {
            NSWorkspace.shared.setIcon(iconImage(glyph, size: 512), forFile: bundle.path, options: [])
        }
    }

    private func runnerURL() -> URL {
        Bundle.main.executableURL!.deletingLastPathComponent().appendingPathComponent("TermerRunner")
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
          <key>CFBundleExecutable</key><string>TermerRunner</string>
          <key>CFBundleIdentifier</key><string>local.termer.\(slug(app.name))</string>
          <key>CFBundleName</key><string>\(xml(app.name))</string>
          <key>CFBundleDisplayName</key><string>\(xml(app.name))</string>
          <key>CFBundleIconFile</key><string>AppIcon</string>
          <key>CFBundlePackageType</key><string>APPL</string>
          <key>LSMinimumSystemVersion</key><string>14.0</string>
        </dict></plist>
        """
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSToolbarDelegate, NSTextFieldDelegate, NSComboBoxDelegate {
    // macOS HIG spacing: 8pt between related controls, 20pt window margins.
    let labelWidth: CGFloat = 70
    let fieldWidth: CGFloat = 310
    let rowGap: CGFloat = 8
    let store = Store()
    var apps: [TuiApp] = []
    let table = NSTableView()
    let name = NSTextField()
    let icon = NSComboBox()
    let command = NSTextField()
    let args = NSTextField()
    let cwd = NSTextField()
    let dynamicCwd = NSButton(checkboxWithTitle: "Ask", target: nil, action: nil)
    let terminal = NSPopUpButton()
    let appPicker = NSPopUpButton()
    let tiles = NSStackView()
    let form = NSStackView()
    var saveButton: NSButton?
    var savedState = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 252),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "Termer"
        window.titleVisibility = .hidden
        window.toolbarStyle = .unifiedCompact
        window.toolbar = toolbar()
        window.minSize = NSSize(width: 460, height: 252)
        app.mainMenu = makeMenu()

        let glass = NSVisualEffectView()
        glass.material = .underWindowBackground
        glass.blendingMode = .behindWindow
        glass.state = .active
        window.contentView = glass

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .centerX
        root.spacing = 0
        root.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        root.translatesAutoresizingMaskIntoConstraints = false
        glass.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: glass.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: glass.trailingAnchor),
            root.topAnchor.constraint(equalTo: glass.topAnchor),
            root.bottomAnchor.constraint(equalTo: glass.bottomAnchor),
        ])

        table.addTableColumn(NSTableColumn(identifier: .init("name")))
        table.headerView = nil
        table.dataSource = self
        table.delegate = self

        tiles.orientation = .vertical
        tiles.alignment = .centerX
        tiles.spacing = 12
        root.addArrangedSubview(tiles)

        form.orientation = .vertical
        form.spacing = 8
        form.alignment = .leading
        root.addArrangedSubview(form)

        let back = NSButton(title: "‹ All Apps", target: self, action: #selector(showTiles))
        back.bezelStyle = .accessoryBar
        back.controlSize = .large
        form.addArrangedSubview(back)

        appPicker.target = self
        appPicker.action = #selector(pickApp)
        addRow("Saved", appPicker, form)
        addRow("Name", name, form)
        icon.placeholderString = "emoji or character"
        icon.completes = true
        icon.delegate = self
        icon.addItems(withObjectValues: ["❯", "⌘", "⚙", "⎈", "◆", "●", "▲", "⬢", "✦", "❖", "⌂", "⚑", "⌬", "λ", "∑", "⏻", "⌗", "⊞"])
        addRow("Icon", icon, form)
        for field in [name, command, args, cwd] { field.delegate = self }
        addRow("Command", command, form)
        addRow("Args", args, form)
        addFolderRow(form)
        terminal.addItems(withTitles: ["Embedded"])
        terminal.isEnabled = false
        addRow("Mode", terminal, form)

        let buttons = NSStackView()
        buttons.spacing = 10
        for (title, action) in [("Save", #selector(save)), ("Launch", #selector(launch)), ("Remove", #selector(remove)), ("Reveal", #selector(reveal))] {
            let button = NSButton(title: title, target: self, action: action)
            button.bezelStyle = .rounded
            button.controlSize = .large
            button.widthAnchor.constraint(equalToConstant: 70).isActive = true
            if title == "Save" { button.keyEquivalent = "\r"; saveButton = button }
            buttons.addArrangedSubview(button)
        }
        addButtonRow(buttons, form)

        cwd.stringValue = FileManager.default.homeDirectoryForCurrentUser.path
        store.migrate()
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

    @objc func pickApp() {
        guard appPicker.indexOfSelectedItem > 0 else { return showTiles() }
        show(apps[appPicker.indexOfSelectedItem - 1])
        showForm()
    }

    @objc func pickTile(_ sender: NSButton) {
        show(apps[sender.tag])
        appPicker.selectItem(at: sender.tag + 1)
        showForm()
    }

    @objc func newApp() {
        appPicker.selectItem(at: 0)
        name.stringValue = ""
        icon.stringValue = ""
        command.stringValue = ""
        args.stringValue = ""
        cwd.stringValue = FileManager.default.homeDirectoryForCurrentUser.path
        dynamicCwd.state = .off
        terminal.selectItem(withTitle: "Embedded")
        updateFolderEnabled()
        snapshot()
        showForm()
    }

    @objc func save() {
        guard !name.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return alert("Name is required.") }
        guard !command.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return alert("Command is required.") }
        let app = TuiApp(name: name.stringValue, command: command.stringValue, args: args.stringValue, cwd: cwd.stringValue, terminal: terminal.titleOfSelectedItem ?? "Embedded", dynamicCwd: dynamicCwd.state == .on, icon: icon.stringValue)
        do { try store.save(app); reload(selecting: app.name) } catch { alert(error.localizedDescription) }
    }

    @objc func launch() { selected.map(store.launch) }
    @objc func reveal() { selected.map(store.reveal) }
    @objc func remove() {
        guard let app = selected else { return }
        do { try store.remove(app); reload() } catch { alert(error.localizedDescription) }
    }

    var selected: TuiApp? {
        let i = appPicker.indexOfSelectedItem - 1
        return i >= 0 && i < apps.count ? apps[i] : nil
    }

    func reload(selecting selectedName: String? = nil) {
        apps = store.load()
        table.reloadData()
        rebuildTiles()
        appPicker.removeAllItems()
        appPicker.addItem(withTitle: "All Apps")
        appPicker.addItems(withTitles: apps.map(\.name))
        if let selectedName, let row = apps.firstIndex(where: { $0.name == selectedName }) {
            table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            appPicker.selectItem(at: row + 1)
            snapshot()
            showForm()
        } else {
            showTiles()
        }
    }

    @objc func showTiles() {
        rebuildTiles()  // pick up any newly captured thumbnails
        tiles.isHidden = false
        form.isHidden = true
    }

    func showForm() {
        tiles.isHidden = true
        form.isHidden = false
    }

    func rebuildTiles() {
        tiles.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var row = tileRow()
        for (i, app) in (apps + [TuiApp(name: "+", command: "", args: "", cwd: "", terminal: "Embedded", dynamicCwd: false, icon: nil)]).enumerated() {
            if row.arrangedSubviews.count == 3 {
                tiles.addArrangedSubview(row)
                row = tileRow()
            }
            row.addArrangedSubview(i == apps.count ? plusTile() : appTile(app, i))
        }
        tiles.addArrangedSubview(row)
    }

    func tileRow() -> NSStackView {
        let row = NSStackView()
        row.spacing = 12
        row.alignment = .top
        return row
    }

    func appTile(_ app: TuiApp, _ index: Int) -> NSView {
        let glyph = app.icon?.trimmingCharacters(in: .whitespaces) ?? ""
        let caption = glyph.isEmpty ? app.name : "\(glyph)  \(app.name)"
        if let thumb = thumbImage(app) {
            return tile(thumb, fills: true, caption, #selector(pickTile), index)
        }
        return tile(iconImage(app.icon, size: 44) ?? termerIcon(), fills: false, caption, #selector(pickTile), index)
    }

    func plusTile() -> NSView {
        tile(iconImage("+", size: 44), fills: false, "", #selector(newApp), -1)
    }

    func thumbImage(_ app: TuiApp) -> NSImage? {
        let url = store.thumbURL(app)
        return FileManager.default.fileExists(atPath: url.path) ? NSImage(contentsOf: url) : nil
    }

    // A landscape card (~16:10, the terminal's ratio): terminal screenshot filling it, or a centered glyph.
    func tile(_ image: NSImage?, fills: Bool, _ caption: String, _ action: Selector, _ tag: Int) -> NSView {
        let card = TileButton(title: "", target: self, action: action)
        card.tag = tag
        card.isBordered = false
        card.bezelStyle = .regularSquare
        card.imagePosition = .imageOnly
        card.image = image
        card.imageScaling = fills ? .scaleAxesIndependently : .scaleProportionallyDown
        card.wantsLayer = true
        card.layer?.cornerRadius = 12
        card.layer?.masksToBounds = true
        card.layer?.borderWidth = 1
        card.layer?.borderColor = NSColor.separatorColor.cgColor
        card.baseBackground = fills ? .clear : NSColor.quaternaryLabelColor.withAlphaComponent(0.2)
        card.widthAnchor.constraint(equalToConstant: 132).isActive = true
        card.heightAnchor.constraint(equalToConstant: 82).isActive = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 5
        stack.addArrangedSubview(card)
        if !caption.isEmpty {
            let label = NSTextField(labelWithString: caption)
            label.textColor = .secondaryLabelColor
            label.font = .systemFont(ofSize: 12)
            label.alignment = .center
            label.lineBreakMode = .byTruncatingTail
            label.maximumNumberOfLines = 1
            label.widthAnchor.constraint(lessThanOrEqualToConstant: 132).isActive = true
            stack.addArrangedSubview(label)
        }
        return stack
    }

    func show(_ app: TuiApp) {
        name.stringValue = app.name
        icon.stringValue = app.icon ?? ""
        command.stringValue = app.command
        args.stringValue = app.args
        cwd.stringValue = app.cwd
        dynamicCwd.state = app.dynamicCwd == true ? .on : .off
        updateFolderEnabled()
        terminal.selectItem(withTitle: app.terminal)
        snapshot()
    }

    // Save is enabled only when the form differs from the last loaded/saved state.
    func currentState() -> String {
        [name.stringValue, icon.stringValue, command.stringValue, args.stringValue, cwd.stringValue,
         dynamicCwd.state == .on ? "1" : "0", terminal.titleOfSelectedItem ?? ""].joined(separator: "\u{1f}")
    }

    func snapshot() { savedState = currentState(); updateDirty() }

    func updateDirty() { saveButton?.isEnabled = currentState() != savedState }

    func controlTextDidChange(_ obj: Notification) { updateDirty() }
    func comboBoxSelectionDidChange(_ notification: Notification) {
        DispatchQueue.main.async { self.updateDirty() }
    }

    func toolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "TermerToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        return toolbar
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .init("brand")]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .init("brand")]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier id: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard id.rawValue == "brand" else { return nil }
        let item = NSToolbarItem(itemIdentifier: id)
        item.view = brandView()
        item.isBordered = false
        return item
    }

    func brandView() -> NSView {
        let row = NSStackView()
        row.spacing = 5
        row.alignment = .centerY

        let image = termerIcon() ?? NSImage()
        let icon = NSImageView(image: image)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let title = NSTextField(labelWithString: "Termer")
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = .secondaryLabelColor

        row.addArrangedSubview(title)
        row.addArrangedSubview(icon)
        let pad = NSView()
        pad.widthAnchor.constraint(equalToConstant: 6).isActive = true
        row.addArrangedSubview(pad)
        return row
    }

    func addRow(_ label: String, _ field: NSView, _ stack: NSStackView) {
        let row = NSStackView()
        row.spacing = rowGap
        row.alignment = .centerY
        let l = NSTextField(labelWithString: label)
        l.alignment = .right
        l.textColor = .secondaryLabelColor
        l.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        field.widthAnchor.constraint(equalToConstant: fieldWidth).isActive = true
        if let control = field as? NSControl { control.controlSize = .large }
        row.addArrangedSubview(l)
        row.addArrangedSubview(field)
        stack.addArrangedSubview(row)
    }

    func addButtonRow(_ buttons: NSView, _ stack: NSStackView) {
        let row = NSStackView()
        row.spacing = rowGap
        let spacer = NSView()
        spacer.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(buttons)
        stack.addArrangedSubview(row)
    }

    func addFolderRow(_ stack: NSStackView) {
        let row = NSStackView()
        row.spacing = rowGap
        row.alignment = .centerY
        let l = NSTextField(labelWithString: "Folder")
        l.alignment = .right
        l.textColor = .secondaryLabelColor
        l.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        let fields = NSStackView()
        fields.spacing = 10
        fields.alignment = .centerY
        fields.widthAnchor.constraint(equalToConstant: fieldWidth).isActive = true
        let choose = NSButton(title: "Choose...", target: self, action: #selector(chooseFolder))
        choose.bezelStyle = .rounded
        choose.controlSize = .large
        choose.widthAnchor.constraint(equalToConstant: 96).isActive = true
        dynamicCwd.target = self
        dynamicCwd.action = #selector(toggleDynamicCwd)
        dynamicCwd.controlSize = .large
        dynamicCwd.widthAnchor.constraint(equalToConstant: 52).isActive = true
        cwd.controlSize = .large
        cwd.widthAnchor.constraint(equalToConstant: 142).isActive = true
        row.addArrangedSubview(l)
        fields.addArrangedSubview(cwd)
        fields.addArrangedSubview(choose)
        fields.addArrangedSubview(dynamicCwd)
        row.addArrangedSubview(fields)
        stack.addArrangedSubview(row)
    }

    @objc func toggleDynamicCwd() {
        updateFolderEnabled()
        updateDirty()
    }

    func updateFolderEnabled() {
        cwd.isEnabled = dynamicCwd.state != .on
    }

    @objc func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            cwd.stringValue = url.path
            updateDirty()
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

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        menu.addItem(editMenuItem)
        return menu
    }
}

// Bundled Termer icon; works under `swift run` and in the packaged app. Falls back to the app icon.
@MainActor
func termerIcon() -> NSImage? {
    if let url = Bundle.module.url(forResource: "AppIcon", withExtension: "icns") {
        return NSImage(contentsOf: url)
    }
    return NSApp.applicationIconImage
}

// Renders a glyph as a monochrome (label-colored) image. Empty glyph -> nil (caller falls back).
func iconImage(_ glyph: String?, size: CGFloat) -> NSImage? {
    let g = (glyph ?? "").trimmingCharacters(in: .whitespaces)
    guard !g.isEmpty else { return nil }
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    let para = NSMutableParagraphStyle(); para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size * 0.8), .paragraphStyle: para]
    let s = g as NSString
    let h = s.boundingRect(with: NSSize(width: size, height: size), options: .usesLineFragmentOrigin, attributes: attrs).height
    s.draw(in: NSRect(x: 0, y: (size - h) / 2, width: size, height: h), withAttributes: attrs)
    // Tint every drawn pixel to labelColor via its alpha → monochrome silhouette (kills emoji color).
    NSColor.labelColor.set()
    NSRect(x: 0, y: 0, width: size, height: size).fill(using: .sourceAtop)
    img.unlockFocus()
    img.isTemplate = true
    return img
}

// Tile that brightens on hover (Tahoe-style highlight).
final class TileButton: NSButton {
    var baseBackground: NSColor = .clear { didSet { layer?.backgroundColor = baseBackground.cgColor } }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.22).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = baseBackground.cgColor
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
