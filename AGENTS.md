// THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
// Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.

Ponytail active: minimal, native, boring. !abstractions, !dependencies, !frameworks, !infra unless feature demands.

§PRODUCT
Termer: native macOS app → standalone `.app` wrappers for terminal UI cmds.
▸ Critical: process ownership → Activity Monitor shows generated app name, !iTerm/Terminal/Ghostty/Warp.
▸ Embedded terminal mode canonical path. External launchers vestigial (convenience only, !resource attribution).

§ARCHITECTURE
SwiftPM repo:
▸ Termer = manager GUI
▸ TermerRunner = copied into generated apps, owns embedded terminal window
▸ SwiftTerm = renderer + PTY runner
▸ Generated apps → @~/Applications/Termer\ Apps/
▸ Config → inside bundle @Contents/Resources/config.json
!Terminal.app/iTerm/Ghostty/Rio/Warp clones. Process accounting still charges external terminal.

§BUILD+RELEASE
Local: `Scripts/package.sh`

Release:
```
TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" \
TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z
```
▸ Signs nested binaries first, then outer app. New executable in bundle → sign before outer app or notarize fails.
▸ release.sh → package.sh w/ TERMER_VERSION → CFBundleShortVersionString.
▸ Manager reads version, stamps generated apps' builtBy (dev if !TERMER_VERSION).

Install/test:
```
curl -fsSL https://termer.frustrated.dev/install | zsh
```
▸ Installer → resolves latest GitHub release, redirects to concrete versioned asset (normal cache).
▸ !Cloudflare deploy needed for app releases.

Cloudflare deploy (only for Cloudflare/install-worker.js or wrangler.toml changes):
```
wrangler deploy
```

§SIGNING+NOTARIZATION
Developer ID: `Developer ID Application: Sushruth Sastry (5G2TDMV275)`
Profile: `termer`

Notary fail → check log:
```
xcrun notarytool log <submission-id> --keychain-profile termer
```
Known fail: nested TermerRunner !signed w/ Developer ID, !timestamp, !hardened runtime.

§GENERATED-APPS
Real `.app` bundles: own name, bundle ID, icon, config, embedded TermerRunner.

Icons:
▸ Form Icon field → single emoji or Unicode character → rendered monochrome on squircle (grid + Finder xattr).
▸ Empty → Termer icon. Custom images: future ceiling.
▸ Known ceiling: xattr custom icons fine locally, !survive distribution → switch to `.icns` in Resources if distributed.

Per-app config records builtBy (Termer version, injected by package.sh; "dev" under swift run).
Manager regenerates bundles where builtBy ≠ current version → transparent runner/icon/thumbnail rewrites. !Manual re-save after update.

Screenshots:
▸ Generated app captures own terminal (in-process cacheDisplay, !screen-recording permission).
▸ Writes to @~/Applications/Termer\ Apps/.thumbs/<slug>.png
▸ Once on first open if none exists, again on quit (freshest).
▸ Manager reads for card previews, deletes on Remove.

Shell launch:
▸ Bare cmds (fresh, k9s, lazygit) must work from GUI.
▸ GUI !inherit terminal PATH → launch through user's login shell (Homebrew, mise, asdf, aliases, PATH resolved).
▸ Login shell: getpwuid(getuid()).pw_shell (Directory Services), prefer over $SHELL, fallback /bin/zsh.
▸ POSIX shells (zsh/bash): -lic "exec <cmd>" (login + interactive → ~/.zprofile/~/.zshrc / ~/.bash_profile/~/.bashrc load).
▸ fish: -l -c "exec <cmd>" (!-i flag). !Hardcode /bin/zsh — bash/fish user must get own shell+profile.

Environment:
▸ Inherited process env w/ TERM=xterm-256color, PLUS backfilled identity vars GUI/launchd missing:
▸ USER, LOGNAME, HOME, SHELL ← getpwuid. Matters: GUI launch lacks USER/LOGNAME (login(1) sets them, login shell doesn't).
▸ !Bare ["TERM=..."] env; wipes everything cmd + ~/.zshrc expect.
Keep shell launch unless measured problem. Direct exec cleaner but breaks user envs.

§DYNAMIC-FOLDER-ARGS
Manager: Folder field + Ask checkbox.
▸ Ask OFF → app starts in saved folder.
▸ Ask ON → folder picker before launch, chosen → process cwd.

Token replacement (whitespace-split, known ceiling):
▸ {pwd} → chosen/current cwd
▸ {cwd} → chosen/current cwd
▸ {name} → app name
!Quoted args yet. Add shellword parsing when they matter.

§UI
Minimal, native. Small utility, !dashboard.

Background: Liquid Glass (NSVisualEffectView, .underWindowBackground, behind-window) — Tahoe native look.

Manager tile screen:
▸ One landscape card (~16:10, terminal aspect) per saved app.
▸ Card shows live screenshot if exists, else monochrome glyph (else Termer icon) + caption.
▸ Cards brighten on hover (TileButton).
▸ Same-size + card creates new app.
▸ Click card → form for that app.
▸ Tile screen primary; form is edit/create. Return rebuilds, freshly captured thumbnails appear.

Form surface:
▸ ‹ All Apps back button (→ tile screen)
▸ Name, Icon (editable combo: monochrome Unicode presets, any char/emoji typed/pasted, rendered monochrome).
▸ Command, Args, Folder + Ask.
▸ Save, Launch, Remove, Reveal.
!Saved picker (tiles navigate), !Mode control (Embedded only; field always disabled). App tracked by editing (drives Launch/Remove/Reveal). TuiApp.terminal stays "Embedded" for config compat; external launcher() vestigial.

Save enabled only when form ≠ last loaded/saved state; greys out after successful save (success signal).

Titlebar: text first, Termer icon last, right-aligned in native toolbar w/ padding like window controls. Keep Termer icon (SwiftPM resource @Sources/Termer/AppIcon.icns, Bundle.module); package.sh must copy Termer_Termer.bundle or Bundle.module fatalError.

Visuals:
▸ !Large blank windows, !sidebars w/ empty state, !marketing copy, !purely decorative.
▸ Liquid Glass, terminal thumbnails, hover highlights allowed (native materials + functional previews).
▸ New visuals: native + informative spirit. !Gradients/illustrations for own sake.
▸ Tiles primary launcher surface; !Turn into dashboard. AppKit controls unless native can't.

Cmd-Q both Termer + generated apps. AppKit needs real app menu w/ Quit item.
Closing last generated app window → terminate normally, !crash, !dead process.

§TERMINAL-THEME
Colors follow macOS appearance, update on light/dark switch.
Semantic colors, !hardcoded palettes:
▸ background: NSColor.textBackgroundColor
▸ foreground: NSColor.labelColor
Appearance resolution deprecations → clean before moving on. !Warning debt when fix is local.

§INSTALLER-SITE
Primary installer:
```
curl -fsSL https://termer.frustrated.dev/install | zsh
```
Site: https://termer.frustrated.dev

Cloudflare Worker owns site + install route. GitHub Releases own binaries. !Move binaries to Cloudflare unless GitHub Releases becomes real problem.
/install = latest. Avoid stale resolution; redirect to concrete versioned asset (asset caches normally).

§DOCS-COMMITS
Update docs same commit as behavior changes. Concise messages. Push after release commits.
!Release docs-only unless app binary changed.

§KNOWN-CEILINGS
▸ Args: whitespace-only parsing.
▸ Icons: emoji/Unicode glyphs via xattr (NSWorkspace.setIcon); !custom images, !.icns generation (!survive distribution).
▸ Shell startup for PATH correctness.
▸ Terminal theme: semantic foreground/background only, !full ANSI palette from macOS.
▸ SwiftTerm: only non-stdlib dep (macOS gives PTYs, !embeddable UI).
▸ Thumbnails: in-process cacheDisplay (!permission); if SwiftTerm → Metal + shots blank, switch CGWindowListCreateImage.
!Fix speculatively. Fix first one user actually hits.
