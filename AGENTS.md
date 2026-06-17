// THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
// Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.

§PONYTAIL
Minimal, native, boring code. !abstractions, !deps, !frameworks, !bg services unless demonstrably needed.

§PRODUCT
Native macOS app wraps TUI commands in .app bundles. **Key req:** process ownership — Activity Monitor attributes CPU/GPU/Energy to generated app name, not iTerm/Terminal/Ghostty/Warp. Embedded terminal canonical, !external launchers primary.

§ARCH
▸ Termer → manager GUI
▸ TermerRunner → embedded in generated apps, owns terminal window
▸ SwiftTerm → only non-stdlib dep (OS gives PTYs, !embeddable UI)
▸ Apps @ ~/Applications/Termer\ Apps/
▸ Config @ app bundle Contents/Resources/config.json
Keep small. macOS gives PTYs, !Terminal.app emulation, !reskin external terminals.

§BUILD
Release binary before curl test.

Build: `Scripts/package.sh`
Release: `TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z`
  ▸ Sign nested binaries first, outer app last (else notary fails)
  ▸ TERMER_VERSION → CFBundleShortVersionString → manager → builtBy stamp
  ▸ Build !TERMER_VERSION → "dev"

Install: `curl -fsSL https://termer.frustrated.dev/install | zsh`

Cloudflare (only when @Cloudflare/install-worker.js or wrangler.toml change):
`wrangler deploy`

§SIGNING
Developer ID only (public dist). Apple Development !/acceptable.

Identity: `Developer ID Application: Sushruth Sastry (5G2TDMV275)`
Profile: `termer`

Notary fails? `xcrun notarytool log <id> --keychain-profile termer`
Common fail: TermerRunner !Developer ID signed, !timestamp, !hardened runtime.

§GENERATED_APPS
Real .app bundles with own name, bundle ID, icon, config, embedded TermerRunner.

**Icons:** Icon field → emoji/Unicode glyph, render monochrome on native squircle. Empty → Termer icon. Custom images !yet. Ceiling: setIcon OK local, !distribution → .icns if ever distributed.

**builtBy:** config tracks Termer version generated bundle. On launch, regenerate if builtBy ≠ current. !manual re-save after update.

**Screenshots:** in-process cacheDisplay (!screen-recording perm) → @~/.thumbs/<slug>.png on first open + quit. Manager reads previews, deletes on Remove. If SwiftTerm Metal renders blank → CGWindowListCreateImage.

**Commands:** fresh, k9s, lazygit must work from GUI. GUI !inherit PATH → launch via login shell → resolve Homebrew/mise/asdf/aliases/PATH.

**Shell:** user's login shell from getpwuid (prefer over $SHELL, fallback /bin/zsh). POSIX (zsh/bash) → `-lic "exec <cmd>"` (login+interactive, load profile). Fish → `-l -c "exec <cmd>"` (!-i). !hardcode /bin/zsh.

**Env:** inherit process + TERM=xterm-256color + backfill identity vars (USER/LOGNAME/HOME/SHELL) from getpwuid. GUI !get USER/LOGNAME (login(1) sets in terminal, login shell !set). !bare ["TERM=..."] env (wipes expectations). See inheritedEnvironment().

Keep shell launch unless measured problem. Direct exec cleaner but breaks user envs.

§FOLDER_ARGS
Ask=off → start in saved folder.
Ask=on → folder picker → chosen folder → cwd.

Token replacement: {pwd}/{cwd} → cwd, {name} → app name.
Whitespace-split args (ceiling). Add shellword parsing when quoted args needed.

§UI
Minimal, native. Utility, !dashboard.

Background: Liquid Glass (NSVisualEffectView, .underWindowBackground, behind blend). Tahoe native, !custom chrome.

**Tile screen (primary):**
▸ Landscape cards (~16:10, terminal aspect)
▸ Live screenshot (if exists) | monochrome glyph | Termer icon
▸ Caption below
▸ Hover brightens (TileButton)
▸ Same-size + card creates app
▸ Click card → form

**Form (edit/create):**
▸ ‹ All Apps back button
▸ Name | Icon (editable combo, any char/emoji, render monochrome) | Command | Args | Folder+Ask | Save/Launch/Remove/Reveal

!Saved picker (!tiles are nav). !Mode control (Embedded only). TuiApp.terminal="Embedded" (config compat); launcher() vestigial.

Save enabled !form≠loaded; greys out on save ✓.

**Titlebar:** text first, app icon last, right-aligned toolbar (padding like window controls). Keep real Termer icon (SwiftPM resource @Sources/Termer/AppIcon.icns, Bundle.module). package.sh copies Termer_Termer.bundle or Bundle.module fatalErrors.

!large blank windows, !sidebars, !marketing, !decoration. Liquid Glass+thumbnails+hover native+informative, !gradients/illustrations. Tiles → primary launcher, !dashboard. AppKit unless native !suffice.

Cmd-Q → both Termer + generated apps. Real app menu with Quit.

**Update:** Manager !auto-update (bundles self-regenerate via builtBy).
  ▸ Launch: silent check Store.version vs latest GitHub tag_name
  ▸ If newer → accent **Update** pill (controlAccentColor, white text, !bezelColor) in toolbar left of name
  ▸ Click pill → "Update to vX.Y.Z" menu item → install
  ▸ App menu: **Check for Updates…** (loud check, alert if current)
  ▸ Install: canonical installer (curl…/install | zsh, replaces ~/Applications/Termer.app), relaunch (quit + detached open + sleep, else same bundle ID reactivates old)
  ▸ !background polling — launch check only

Closing last generated app → normal term, !crash, !zombie.

§TERMINAL_THEME
Follow macOS appearance, update on light/dark switch.

Semantic colors (!hardcoded):
▸ bg: NSColor.textBackgroundColor
▸ fg: NSColor.labelColor

!Deprecation warnings (fix local if emitted).

§SITE_INSTALLER
Installer: `curl -fsSL https://termer.frustrated.dev/install | zsh`
Site: `https://termer.frustrated.dev`

Cloudflare Worker owns site + /install. GitHub Releases owns binaries. !move binaries unless Releases becomes problem.

/install → latest; avoid stale latest; redirect to concrete versioned asset (asset caches normally).

§DOCS_COMMITS
Update docs in same commit as behavior changes. Concise messages. Push after release. !docs-only releases unless binary changed.

§CEILINGS
▸ Args whitespace-split only
▸ Icons emoji/Unicode via setIcon (!custom images, !.icns unless distribution)
▸ Shell startup for PATH correctness
▸ Theme semantic only (!full ANSI palette)
▸ SwiftTerm !non-stdlib dep (OS gives PTYs, !embeddable UI)
▸ Screenshots in-process cacheDisplay (!perm)

💀 Speculative fixes. Fix first one user hits.
