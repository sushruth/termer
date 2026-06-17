// THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
// Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.

§PONYTAIL
⊖ abstractions, deps, frameworks, background services, release infra unless demonstrated needed.

§PRODUCT
Termer: native macOS `.app` wrappers for terminal UI commands.
✓ requirement: process ownership → CPU/GPU/Energy attribution under generated app, not iTerm/Terminal/Ghostty/Warp.
! external-terminal launchers (primary path no longer). Embedded terminal mode: canonical.

§ARCHITECTURE
← SwiftPM.
▸ `Termer` → manager GUI
▸ `TermerRunner` → copied into generated apps, owns embedded terminal window
▸ SwiftTerm → renderer + PTY runner
▸ generated apps @ `~/Applications/Termer Apps/`
▸ config @ `Contents/Resources/config.json`
! attempt Terminal.app/iTerm/Ghostty/Rio/Warp reskin; macOS still charges external terminal.

§BUILD-RELEASE
▸ local build: `Scripts/package.sh`
▸ release: `TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z`
▸ nested binaries → sign before outer app or notarization fails
▸ `TERMER_VERSION` → flows to `CFBundleShortVersionString`, `builtBy` stamp (default: `"dev"`)
▸ install/test: `curl -fsSL https://termer.frustrated.dev/install | zsh`
▸ installer endpoint → resolves latest GitHub release, redirects to versioned asset
! normal releases require Cloudflare deploy
▸ Cloudflare deploy: only on `Cloudflare/install-worker.js` or `wrangler.toml` changes: `wrangler deploy`

§SIGNING-NOTARIZATION
▸ Developer ID: public distribution (Apple Development = local/dev only, ! public)
▸ current identity: `Developer ID Application: Sushruth Sastry (5G2TDMV275)`
▸ current profile: `termer`
▸ notarization fails? → read notary log: `xcrun notarytool log <submission-id> --keychain-profile termer`
▸ known failure: nested `TermerRunner` ! signed with Developer ID, ! timestamp, ! hardened runtime

§GENERATED-APPS
▸ real `.app` bundles: own name, bundle ID, icon, config, embedded `TermerRunner`
▸ per-app icons: form Icon field → emoji/Unicode character → rendered on native rounded-rect squircle
▸ empty Icon → fallback: Termer app icon
▸ ⏹ custom image files (possible future, not yet built)
▸ ceiling: `setIcon` xattr custom icons OK locally, ! survive distribution → switch to generated `.icns` in Resources if distributed
▸ `builtBy` → Termer version (CFBundleShortVersionString, injected by `package.sh`; `"dev"` under `swift run`)
▸ on launch: manager regenerates bundles where `builtBy` ≠ current version → transparent rewrite of stale runners/icons/thumbnails
▸ per-app screenshots: in-process `cacheDisplay` (no screen-recording permission) → `~/.thumbs/<slug>.png`
  ▸ timing: first open if none exists, again on quit
  ▸ manager: reads for card previews, deletes on Remove
▸ bare commands (fresh, k9s, lazygit) must work from GUI launch → `/bin/zsh -lic` for PATH/Homebrew/mise/asdf/aliases/user setup
▸ inherited process env (USER, HOME, LOGNAME, SSH_AUTH_SOCK, etc.) + `TERM=xterm-256color` via `inheritedEnvironment()`
▸ ! bare `["TERM=..."]` env (wipes command/user expectations)
▸ shell launch: keep unless measured problem (direct exec cleaner but breaks common environments)

§FOLDER-ARGS
▸ Folder field + Ask checkbox
  ▸ Ask=off → starts in saved folder
  ▸ Ask=on → folder picker before launch
▸ token replacement: `{pwd}`, `{cwd}`, `{name}`
▸ whitespace-split args (ceiling)
▸ shellword parsing: add when quoted args matter

§UI
▸ minimal native (small utility, not dashboard)
▸ background: Liquid Glass material (NSVisualEffectView, .underWindowBackground, behind-window blend) — Tahoe native look
▸ tile screen:
  ▸ landscape cards (~16:10 aspect, terminal shape) per saved app
  ▸ card shows: live screenshot (if exists) or monochrome glyph (or Termer icon) + caption
  ▸ hover: brighten (TileButton)
  ▸ `+` card: new app
  ▸ card click: form for that app
  ▸ tile screen: primary surface; form: edit/create
▸ form surface:
  ▸ `‹ All Apps` back button
  ▸ Name
  ▸ Icon: combo box of monochrome presets; any char/emoji typeable/pasteable (rendered monochrome)
  ▸ Command, Args
  ▸ Folder + Ask checkbox
  ▸ Save, Launch, Remove, Reveal
▸ ! "Saved" picker (tiles navigate), ! "Mode" control (Embedded only; external-terminal launcher vestigial)
▸ `editing` tracks app being edited → drives Launch/Remove/Reveal
▸ `TuiApp.terminal` stays = "Embedded" (config compat)
▸ Save: enabled only when form ≠ last saved state
▸ titlebar: text first, app icon last, right-aligned in native toolbar, padding comparable to window controls
  ▸ keep Termer app icon (! generic SF Symbol)
  ▸ icon: SwiftPM resource (@Sources/Termer/AppIcon.icns) via Bundle.module (works under `swift run` + packaged)
  ▸ `package.sh`: must copy Termer_Termer.bundle or Bundle.module fatalError
▸ avoid: large blank windows, empty sidebars, marketing copy, decorative visuals
▸ allowed: Liquid Glass, thumbnails, hover highlights (native + functional)
▸ AppKit controls: default; native controls only if AppKit insufficient
▸ Cmd-Q: works in Termer + generated apps (real app menu + Quit)
▸ closing last generated app window: terminate normally (! crash, ! dead process)

§TERMINAL-THEME
▸ colors: follow macOS appearance, update on light/dark switch
▸ semantic colors (! hardcoded aesthetic palettes):
  ▸ background: NSColor.textBackgroundColor
  ▸ foreground: NSColor.labelColor
▸ appearance resolution deprecations: clean before moving on (! leave warning debt if fix local)

§INSTALLER-SITE
▸ installer: `curl -fsSL https://termer.frustrated.dev/install | zsh`
▸ site: https://termer.frustrated.dev
▸ Cloudflare Worker: owns site + install route
▸ GitHub Releases: owns binary hosting
▸ ! move binaries to Cloudflare unless GitHub Releases becomes problem
▸ `/install` → latest (avoid stale resolution, redirect to concrete versioned asset for normal caching)

§DOCS-COMMITS
▸ update docs in same commit as behavior changes
▸ concise commit messages
▸ push after release commits
▸ ! release docs-only unless app binary changed

§KNOWN-CEILINGS
▸ Args: whitespace-only parsing
▸ Icons: emoji/Unicode glyphs via NSWorkspace.setIcon (xattr); ! custom images, ! .icns generation (! survive distribution)
▸ shell startup: used for PATH correctness
▸ theme: semantic foreground/background only (! full ANSI palette from macOS)
▸ SwiftTerm: only non-stdlib dep (macOS provides PTYs, ! embeddable terminal UI)
▸ screenshots: in-process cacheDisplay (! permission); if SwiftTerm → Metal + blank shots → switch CGWindowListCreateImage
▸ fix speculatively: no. Fix when user hits it first.
