// THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
// Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.

§PONYTAIL
Minimal, native, boring code wins. !abstractions, !deps, !frameworks, !bg services, !release infra unless demonstrable need.

§PRODUCT
Termer → native macOS app wraps terminal UI commands as standalone .app bundles.
⚡ requirement: process ownership → Activity Monitor CPU/GPU/Energy credited to app, not external terminal.
External launchers ≠ primary path. Embedded terminal → canonical.

§ARCHITECTURE
▸ SwiftPM managed
▸ Termer → manager GUI
▸ TermerRunner → copied into generated apps, owns embedded terminal window
▸ SwiftTerm → terminal renderer + PTY runner
▸ Generated apps @ ~/Applications/Termer\ Apps/
▸ Config @ generated bundle Contents/Resources/config.json
Keep architecture small. macOS gives PTYs, !/embeddable Terminal.app. !/reskin external terminals.

§BUILD+RELEASE
Release binary before curl test.
Build: Scripts/package.sh
Release: TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z
Sign nested binaries first; outer app last (else notary fails).
TERMER_VERSION → CFBundleShortVersionString, read by manager → builtBy stamp on generated apps. Build !TERMER_VERSION → "dev".
Install: curl -fsSL https://termer.frustrated.dev/install | zsh
Deploy Cloudflare: only when @Cloudflare/install-worker.js or wrangler.toml change → wrangler deploy

§SIGNING+NOTARIZATION
Use Developer ID (public dist). Apple Development !/acceptable.
Identity: Developer ID Application: Sushruth Sastry (5G2TDMV275)
Profile: termer
Notary fails? xcrun notarytool log <submission-id> --keychain-profile termer
Common fault: TermerRunner !signed with Developer ID, !timestamp, !hardened runtime.

§GENERATED-APPS
Real .app bundles: own name, bundle ID, icon, config, embedded TermerRunner.
Icons: Icon field → emoji/Unicode glyph. Render monochrome onto rounded-rect. Empty → Termer icon. Custom image files !/yet. Ceiling: setIcon works locally, !/distribution → switch .icns if ever distributed.
builtBy tracks Termer version. On launch, manager regenerates if builtBy ≠ current. !/manual re-save after update.
Screenshots: in-process cacheDisplay (no screen-recording perm) → @~/.thumbs/<slug>.png on first open + quit. Manager reads → previews; deletes on Remove.
Commands (fresh, k9s, lazygit) must work from GUI. GUI !/PATH → launch via login shell → resolve Homebrew/mise/asdf/aliases.
Shell: getpwuid login shell (prefer over $SHELL, fallback /bin/zsh). POSIX → -lic "exec <cmd>"; fish → -l -c "exec <cmd>". !/hardcode /bin/zsh.
Environment: inherited + TERM=xterm-256color + backfill USER/LOGNAME/HOME/SHELL from getpwuid. GUI !/USER/LOGNAME → login(1) handles in terminal, login shell !/set. !/bare TERM (wipes user expectations).
Keep shell launch unless measured problem. Direct exec cleaner but breaks user envs.

§FOLDER+ARGS
Ask OFF → start in saved folder.
Ask ON → folder picker → chosen folder → cwd.
Args: {pwd}→cwd, {cwd}→cwd, {name}→app name.
Whitespace-split ⏹. Add shellword parsing when quoted args actually matter.

§UI
Minimal, native. Small utility, !/dashboard.
Background: Liquid Glass (NSVisualEffectView, .underWindowBackground, behind blend). Tahoe native, !custom chrome.
Tile screen (primary):
▸ Landscape cards (~16:10 aspect, terminal-like)
▸ Live screenshot if exists; else monochrome glyph; else Termer icon
▸ Caption below
▸ Hover brightens (TileButton)
▸ Same-size + card → new app
▸ Click card → edit form
Form (edit/create):
▸ ‹ All Apps (back button)
▸ Name | Icon (editable combo, any emoji/char, rendered monochrome) | Command | Args | Folder + Ask | Save/Launch/Remove/Reveal
!/Saved picker (tiles navigate). !/Mode control (Embedded only). TuiApp.terminal="Embedded" for config compat; launcher() vestigial.
Save enabled !form≠loaded state; greys out on ✓ save.
Titlebar: text first, app icon last, right-aligned toolbar. Keep Termer icon (SwiftPM resource @Sources/Termer/AppIcon.icns via Bundle.module). package.sh copies Termer_Termer.bundle or Bundle.module fatalError.
!large blank windows, !sidebars, !marketing, !decoration. Liquid Glass + thumbnails + hover → native+informative, !gradients/illustrations. Tiles → primary launcher, !/dashboard. AppKit unless native !/suffice.
Cmd-Q → Termer + generated apps. Real app menu w/ Quit.
Manager !/auto-update (bundles self-regenerate). Check for Updates → Store.version vs latest GitHub tag → if newer curl install → relaunch (quit + detached open + sleep). On-demand only.
Closing last generated app window → normal term, !crash, !dead process.

§TERMINAL-THEME
Follow macOS appearance, update on light/dark switch.
Semantic colors (!hardcoded palettes):
▸ bg: NSColor.textBackgroundColor
▸ fg: NSColor.labelColor
!Deprecation warnings. Clean before moving on.

§INSTALLER+SITE
Installer: curl -fsSL https://termer.frustrated.dev/install | zsh
Site: https://termer.frustrated.dev
Cloudflare Worker owns site + /install. GitHub Releases owns binaries. !/move binaries unless Releases becomes problem.
/install → latest; avoid stale; redirect to concrete versioned asset.

§DOCS+COMMITS
Update docs in behavior-change commits.
Concise messages.
Push after release commits.
!/docs-only releases unless binary changed.

§CEILINGS
▸ Args whitespace-split only
▸ Icons emoji/Unicode via setIcon (!custom images, !.icns unless distribution)
▸ Shell startup for PATH resolution
▸ Theme semantic only (!full ANSI palette from macOS)
▸ SwiftTerm → !non-stdlib dep (macOS gives PTYs, !/embeddable terminal UI)
▸ Thumbnails cacheDisplay (!permission; if Metal renders blank → CGWindowListCreateImage)
!Fix speculatively. Fix first user hit.
