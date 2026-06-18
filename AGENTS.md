// THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
// Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.

§PONYTAIL
Ponytail active for this repo. Minimal, native, boring code wins. ⊖ abstractions, dependencies, frameworks, background services, release infrastructure unless feature demonstrably needs them.

§PRODUCT
Termer: native macOS app wrapping terminal UI commands as .app bundles.

▸ Critical: generated apps own terminal window/renderer → Activity Monitor CPU/GPU/Energy → app name, not iTerm/Terminal/Ghostty/Warp/etc.
▸ External-terminal launchers ≠ primary path. Embedded terminal → canonical.

§ARCHITECTURE
SwiftPM structure:
▸ `Termer` = manager GUI
▸ `TermerRunner` = copied into generated apps, owns embedded terminal window
▸ SwiftTerm = terminal renderer + PTY
▸ Generated apps → ~/Applications/Termer Apps/
▸ Generated app config → Contents/Resources/config.json

Keep small. OS provides PTYs, not embeddable Terminal.app. ⊖ cloning Terminal/iTerm/Ghostty/Rio/Warp appearance.

§BUILD & RELEASE
Local build: `Scripts/package.sh`

Release (CI): push `vX.Y.Z` tag → `.github/workflows/release.yml` (runner `macos-26`, needs macOS 26 SDK for `NSGlassEffectView`): import Developer ID cert from secrets → temp keychain, `package.sh`, notarize (Apple ID + app pwd), staple, `gh release create`. `workflow_dispatch` = full build/sign/notarize but skips publish (guard `GITHUB_REF_TYPE=tag`) → pipeline test w/o tag.
```bash
git tag vX.Y.Z && git push origin vX.Y.Z
```
Secrets (`gh secret set` once): `MACOS_CERTIFICATE` (base64 `.p12`), `MACOS_CERTIFICATE_PWD`, `APPLE_ID`, `APPLE_APP_PASSWORD`, `APPLE_TEAM_ID`. Identity name hardcoded in workflow env, must match `security find-identity`.

Local fallback:
```bash
TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z
```

Signs nested binaries first → outer app. New executables in bundle → sign before outer sign or notary fails.

`release.sh` → `package.sh` w/ `TERMER_VERSION` → `CFBundleShortVersionString`. Manager reads version → stamps generated apps' `builtBy`. No `TERMER_VERSION` = `dev` stamp.

Install/test:
```bash
curl -fsSL https://termer.frustrated.dev/install | zsh
```

Installer resolves latest GitHub release → concrete versioned asset. Normal releases ≠ Cloudflare deploy needed.

Cloudflare deploy ONLY on `Cloudflare/install-worker.js` or `wrangler.toml` changes:
```bash
wrangler deploy
```

§RELEASE CHECKLIST
Per release, in order:
1. Commit work. Update docs w/ behavior. Edit `AGENTS.source.md` (never `AGENTS.md`), regen:
   ```bash
   claude -p "Read AGENTS.source.md, apply REGEN compression rules (exclude REGEN), write AGENTS.md. Prepend two-line disclaimer." --allowedTools 'Read,Edit,Write' --max-turns 10
   ```
2. Pick version: `gh release list`, bump vX.Y.Z (patch: fixes/tweaks, minor: features). Repo = `usually-frustrated/termer`.
3. Push: `git push`
4. Tag → release: `git tag vX.Y.Z && git push origin vX.Y.Z`. CI (`release.yml`, `macos-26`) builds, signs, notarizes, staples, `gh release create` (zip + install.sh). Build = `package.sh` (swift build release, copy TermerRunner/AppIcon.icns/bundle, Info.plist w/ TERMER_VERSION, sign nested→outer). Watch: `gh run watch`. Notary fail → read log. Dry-run w/o publish = `workflow_dispatch`. Local fallback: `Scripts/release.sh vX.Y.Z`.
5. Cloudflare: only if install-worker.js or wrangler.toml changed, run `wrangler deploy`. (Route deletion = dashboard only.)
6. Site screenshot: UI changed? Recapture `docs/screenshot.png` (active window), `git push`. Raw GitHub serves, no redeploy.
7. Reach: New version reaches users two ways — generated app bundles auto-regenerate on next launch via `builtBy`; manager app updates on toolbar **Update** pill click / Check for Updates (or curl reinstall).

§SIGNING & NOTARIZATION
Developer ID for public distribution. Apple Development = local/dev only, ≠ acceptable public releases.

Identity: `Developer ID Application: Sushruth Sastry (5G2TDMV275)`
Notary profile: `termer`

Notary fail → read log:
```bash
xcrun notarytool log <submission-id> --keychain-profile termer
```

Known: nested `TermerRunner` ≠ Developer ID signed, lacked timestamp, lacked hardened runtime → notary fail.

§GENERATED APPS
Real .app bundles w/ own name, bundle ID, icon, config, embedded TermerRunner.

Icons: form has Icon field → single emoji/Unicode char. Glyph → native rounded-rect (squircle) in manager tiles + generated app Finder icon via `NSWorkspace.setIcon` (xattr). Empty → Termer icon fallback. Custom images = future, not yet built. ⊖ `setIcon` custom icons for distributed apps — use .icns in Resources instead.

Config records `builtBy` = Termer version (CFBundleShortVersionString, injected by package.sh; "dev" under `swift run`). On launch, manager regenerates bundles where `builtBy` ≠ current version. Stale runners/icons/thumbnails auto-rewrite. No manual re-save post-update.

Screenshots: each generated app captures its terminal window in-process (`cacheDisplay`, no screen-recording permission) → ~/Applications/Termer Apps/.thumbs/<slug>.png. Once on first open (if none exists), again on quit (freshest). Manager reads for card previews, deletes on Remove.

Bare commands (`fresh`, `k9s`, `lazygit`) must work from GUI launch. GUI ≠ terminal PATH, so TermerRunner → user login shell to resolve Homebrew/mise/asdf/aliases/PATH.

Shell = user configured login shell — `getpwuid(getuid()).pw_shell` (Directory Services), prefer over `$SHELL`, fallback `/bin/zsh`. See `userShell()`. POSIX shells (zsh/bash): `-lic "exec <cmd>"` (login+interactive, ~/.zprofile/~/.zshrc / ~/.bash_profile/~/.bashrc load); fish: `-l -c "exec <cmd>"` (no `-i`). ⊖ hardcode `/bin/zsh` — bash/fish user needs their shell + profile.

Runner passes inherited process environment (SSH_AUTH_SOCK etc.) w/ `TERM=xterm-256color`, AND backfills identity vars GUI/launchd missing — USER, LOGNAME, HOME, SHELL — from password DB (getpwuid). See `inheritedEnvironment()`. Matters: GUI launch environment lacks USER/LOGNAME (terminal gets from login(1), login shell ≠ set itself), commands reading process.env.USER break without backfill. ⊖ bare `["TERM=..."]` env (wipes command + ~/.zshrc expectations).

Keep shell launch unless measured problem arises. Direct exec cleaner but breaks common user environments.

§DYNAMIC FOLDER & ARGS
Manager: Folder field + Ask checkbox.

Ask off → generated app starts in saved folder.
Ask on → generated app shows folder picker before launch. Chosen folder = process working directory.

Args: simple token replacement:
▸ {pwd} → chosen/current working directory
▸ {cwd} → chosen/current working directory
▸ {name} → generated app name

Currently whitespace-split. Known ceiling. Add shellword parsing when quoted args matter.

§UI
Keep minimal, native. Small utility, not dashboard.

Window background: Liquid Glass material (NSVisualEffectView, .underWindowBackground, behind-window blend) — Tahoe native look, not custom chrome.

Manager tile screen:
▸ One landscape card (~16:10, terminal aspect) per saved app
▸ Card shows live screenshot of app's terminal (if exists) else monochrome glyph (else Termer icon) + caption
▸ Cards brighten on hover (TileButton)
▸ Same-size + card = new app
▸ Click card = open edit form
▸ Primary surface = tile screen; form = edit/create. Return rebuilds cards for fresh thumbnails.

Form surface:
▸ ‹ All Apps back button → tile screen
▸ Name
▸ Icon: editable combo of monochrome Unicode presets; any char/emoji can type/paste (rendered monochrome)
▸ Command
▸ Args
▸ Folder + Ask checkbox
▸ Save, Launch, Remove, Reveal

No Saved picker (tiles = nav), no Mode control (Embedded only; field disabled). Edited app tracked by `editing` → Launch/Remove/Reveal. TuiApp.terminal stays in struct (always "Embedded") for config compat; external-terminal launcher() = vestigial.

Save enabled only when form ≠ last loaded/saved; greys out after successful save (success signal).

Titlebar: text first, app icon last, right-aligned in native toolbar w/ padding ≈ window controls. Keep real Termer icon; ⊖ generic SF Symbol. Icon = SwiftPM resource (Sources/Termer/AppIcon.icns), loaded via Bundle.module, shows under `swift run` + packaged app; package.sh must copy Termer_Termer.bundle into app or Bundle.module fatalError.

▸ ⊖ large blank windows, sidebars w/ empty state, marketing copy, decorative visuals
▸ Liquid Glass, terminal thumbnails, hover highlights allowed (native materials + functional previews)
▸ Keep new visuals native+informative, ⊖ gradients/illustrations for their own sake
▸ Tiles = primary launcher; ⊖ turn app into dashboard
▸ Use AppKit unless native control can't do job

Cmd-Q works in Termer + generated apps. AppKit needs real app menu w/ Quit.

Manager ≠ auto-update (only generated bundles self-regenerate via `builtBy`). Update flow:
▸ On launch: silent check, Store.version vs latest GitHub release tag_name. If newer → primary accent **Update** pill (layer-backed controlAccentColor, white text, not bezelColor which desaturates inactive) in toolbar brand, left of Termer name.
▸ Click pill → one-item menu "Update to vX.Y.Z"; click → install.
▸ App menu: **Check for Updates…** item (loud check — alerts when current).
▸ Install → canonical installer (curl … /install | zsh, replaces ~/Applications/Termer.app) → relaunch: quit first, detached `open` after short sleep (else `open` same bundle ID just reactivates old instance).

⊖ background polling — launch check only.

Closing last generated app window → terminate normally, ⊖ crash/dead process.

§TERMINAL THEME
Colors follow macOS appearance, update on light/dark switch.

Use macOS semantic colors, ⊖ hardcoded aesthetic palettes:
▸ background: NSColor.textBackgroundColor
▸ foreground: NSColor.labelColor

Appearance resolution deprecation warnings → clean before moving on. ⊖ warning debt when fix local.

§INSTALLER & SITE
Primary installer:
```bash
curl -fsSL https://termer.frustrated.dev/install | zsh
```

Site: https://termer.frustrated.dev

Cloudflare Worker = site + install route. GitHub Releases = binary hosting. ⊖ move binaries to Cloudflare unless GitHub Releases becomes real problem.

`/install` = latest. Should avoid stale latest resolution while redirecting to concrete versioned GitHub release asset (asset itself can cache normally).

§DOCS & COMMITS
Update docs in same commit as behavior changes.
Use concise commit messages.
Push after release commits.
⊖ release docs-only changes unless app binary changed.

§KNOWN CEILINGS
▸ Args parsing = whitespace only
▸ Per-app icons = emoji/Unicode via NSWorkspace.setIcon (xattr); ⊖ custom images, ⊖ .icns generation (won't survive distribution)
▸ Shell startup = PATH correctness
▸ Terminal theme = semantic foreground/background only, not full ANSI palette from macOS
▸ SwiftTerm = only non-stdlib dependency (OS provides PTYs, ⊖ embeddable terminal UI)
▸ Terminal thumbnails = in-process cacheDisplay (no permission); if SwiftTerm Metal-renders + shots blank → switch CGWindowListCreateImage

⊖ fix speculatively. Fix first one user hits.
