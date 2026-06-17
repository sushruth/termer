# AGENTS.source.md

> ⚠️ **AI AGENTS: DO NOT EDIT `AGENTS.md` DIRECTLY**
> `AGENTS.md` is auto-generated from this source via REGEN compression rules.
> Edit `AGENTS.source.md`, then apply the REGEN rules below to compile `AGENTS.md`.
> Edits to `AGENTS.md` will be overwritten on next regen.

Ponytail stays active for this repo. Minimal, native, boring code wins. Do not add abstractions, dependencies, frameworks, background services, or release infrastructure unless the current feature demonstrably needs them.

## Product Shape

Termer is a native macOS app that creates standalone `.app` wrappers for terminal UI commands.

The important product requirement is process ownership: generated apps must own their terminal window and renderer so Activity Monitor CPU, GPU, and Energy attribution appears under the generated app name, not iTerm, Terminal, Ghostty, Warp, or another external terminal.

External-terminal launchers are not the primary path anymore. They can be useful convenience mode later, but they cannot satisfy resource attribution. Embedded terminal mode is the canonical path.

## Architecture

The repo uses SwiftPM.

- `Termer` is the manager GUI.
- `TermerRunner` is copied into generated apps and owns the embedded terminal window.
- SwiftTerm provides the terminal renderer and PTY process runner.
- Generated apps live in `~/Applications/Termer Apps/`.
- Generated app config lives inside the generated bundle at `Contents/Resources/config.json`.

Keep this architecture small. The OS gives us PTYs, not an embeddable Terminal.app window. Do not try to make Terminal.app, iTerm, Ghostty, Rio, or Warp look like the owning app; macOS process accounting will still charge the external terminal.

## Build and Release

Always release app changes before telling the user to test with curl.

Build locally:

```bash
Scripts/package.sh
```

Release:

```bash
TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z
```

Release signs nested binaries first, then signs/notarizes/staples `Termer.app`. If a new executable is added inside the app bundle, sign it before signing the outer app or notarization will fail.

`release.sh` passes the tag to `package.sh` as `TERMER_VERSION`, which writes it into `CFBundleShortVersionString`. The manager reads that as its version and stamps generated apps' `builtBy`, so the version must flow through on every release — a build without `TERMER_VERSION` is stamped `dev`.

Install/test:

```bash
curl -fsSL https://termer.frustrated.dev/install | zsh
```

The installer endpoint resolves the latest GitHub release and redirects to a concrete versioned release asset. Normal app releases do not require a Cloudflare deploy.

Deploy Cloudflare only when changing `Cloudflare/install-worker.js` or `wrangler.toml`:

```bash
wrangler deploy
```

### Per-release checklist

Do these in order for every release:

1. **Commit the work.** Update docs in the same commit as the behavior change. Edit `AGENTS.source.md` (never `AGENTS.md` by hand), then regenerate `AGENTS.md`:
   ```bash
   claude -p "Read AGENTS.source.md, apply the REGEN compression rules to compress it (exclude REGEN section), write AGENTS.md. Always prepend the two-line auto-generated disclaimer at the very top." --allowedTools 'Read,Edit,Write' --max-turns 10
   ```
2. **Pick the next version.** Check `gh release list` and bump `vX.Y.Z` (patch for fixes/tweaks, minor for features). Repo is `usually-frustrated/termer` (gh auto-detects it from the remote).
3. **Build, sign, notarize, publish** in one shot:
   ```bash
   TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z
   ```
   This runs `package.sh` (`swift build -c release`; copies `TermerRunner`, `AppIcon.icns`, and `Termer_Termer.bundle`; writes `Info.plist` with `TERMER_VERSION`→`CFBundleShortVersionString`; signs nested-then-outer), zips, `notarytool submit --wait`, `stapler staple`, and `gh release create` (uploads the zip + `install.sh`). On notary failure read the log first (see Signing section).
4. **Push commits:** `git push`.
5. **Cloudflare:** only if `Cloudflare/install-worker.js` or `wrangler.toml` changed, run `wrangler deploy`. (Route deletion has no wrangler command — do it in the dashboard.)
6. **Site screenshot:** if the UI changed and you want the site to reflect it, recapture `docs/screenshot.png` (active window — see the screenshot note) and `git push`; raw GitHub serves it, no redeploy needed.
7. **Reach:** the new version reaches users two ways — generated app bundles auto-regenerate on next launch via `builtBy`; the manager app itself only updates when the user clicks the toolbar **Update** pill / Check for Updates (or reinstalls via curl).

## Signing and Notarization

Use Developer ID for public distribution. Apple Development signing is only local/dev signing and is not acceptable for public releases.

Current identity:

```text
Developer ID Application: Sushruth Sastry (5G2TDMV275)
```

Current notary profile:

```text
termer
```

If notarization fails, read the notary log first:

```bash
xcrun notarytool log <submission-id> --keychain-profile termer
```

Common failure already seen: nested `TermerRunner` was not signed with Developer ID, lacked timestamp, and lacked hardened runtime.

## Generated Apps

Generated apps should be real `.app` bundles with their own name, bundle identifier, icon, config, and embedded `TermerRunner`.

Per-app icons: the form has an Icon field accepting a single emoji or Unicode character. The glyph is rendered onto a native rounded-rect (squircle) tile — both in the manager's tile grid and as the generated app's Finder icon via `NSWorkspace.setIcon` (xattr custom icon). Empty Icon falls back to the Termer app icon. Custom image files remain a possible future need, not yet built. Known ceiling: `setIcon` custom icons are fine for locally generated apps but won't survive distribution — switch to a generated `.icns` in Resources if generated apps ever get distributed.

Each generated app's config records `builtBy` — the Termer version (`CFBundleShortVersionString`, injected by `package.sh`; `"dev"` under `swift run`) that generated the bundle. On launch the manager regenerates every bundle whose `builtBy` differs from the current version, so updating Termer transparently rewrites stale runners/icons/thumbnail code in already-installed apps. No manual re-save needed after an update.

Each generated app captures a screenshot of its own terminal window (in-process `cacheDisplay`, no screen-recording permission) and writes it to `~/Applications/Termer Apps/.thumbs/<slug>.png` — once on first open if none exists yet, and again on quit (freshest state). The manager reads these for the card previews and deletes them on Remove.

Bare commands such as `fresh`, `k9s`, or `lazygit` must work from GUI launch. GUI apps do not inherit terminal PATH, so `TermerRunner` launches the command through the user's login shell to resolve Homebrew, mise, asdf, aliases, and user PATH setup.

The shell is the user's configured login shell — `getpwuid(getuid()).pw_shell` (Directory Services), preferring that over `$SHELL`, falling back to `/bin/zsh` — see `userShell()`. POSIX shells (zsh/bash) run `-lic "exec <cmd>"` (login + interactive, so `~/.zprofile`/`~/.zshrc` / `~/.bash_profile`/`~/.bashrc` load); fish runs `-l -c "exec <cmd>"` (no `-i` flag). Do not hardcode `/bin/zsh` — a bash/fish user must get their own shell and profile.

The runner passes the inherited process environment (so `SSH_AUTH_SOCK` etc. carry over) with `TERM=xterm-256color`, AND backfills the identity vars a GUI/launchd process is missing — `USER`, `LOGNAME`, `HOME`, `SHELL` — from the password database (`getpwuid`). See `inheritedEnvironment()`. This matters: a GUI launch's environment lacks `USER`/`LOGNAME` (a terminal gets them from `login(1)`, and a login *shell* does not set them itself), so commands reading `process.env.USER` break without the backfill. Do not pass a bare `["TERM=..."]` env; that wipes everything the command and the user's `~/.zshrc` expect.

Keep shell launch unless it creates a measured problem. Direct exec is cleaner but breaks common user environments.

## Dynamic Folder and Args

The manager has a Folder field and an `Ask` checkbox.

If `Ask` is off, generated app starts in the saved folder.

If `Ask` is on, generated app shows a folder picker before launching. The chosen folder becomes the process working directory.

Args support simple token replacement:

- `{pwd}` → chosen/current working directory
- `{cwd}` → chosen/current working directory
- `{name}` → generated app name

Args are currently whitespace-split. This is a known ceiling. Add shellword parsing only when quoted args actually matter.

## UI

Keep UI minimal and native. This is a small utility, not a dashboard.

The window background is a Liquid Glass material (`NSVisualEffectView`, `.underWindowBackground`, behind-window blend) — the Tahoe-era native look, not custom chrome.

Current manager starts on a centered tile screen:

- One landscape card (~16:10, the terminal's aspect) per saved app.
- Each card shows a live screenshot of that app's terminal when one exists, else the app's monochrome glyph (else the Termer icon), with a caption below.
- Cards brighten on hover (`TileButton`).
- A same-size `+` card creates a new app.
- Clicking a card opens the form for that app.
- The card screen is the primary surface; the form is the edit/create surface. Returning to it rebuilds the cards so freshly captured thumbnails appear.

Current form surface:

- `‹ All Apps` back button (returns to the tile screen)
- Name
- Icon: editable combo box of monochrome Unicode glyph presets; any character/emoji can be typed or pasted (rendered monochrome regardless)
- Command
- Args
- Folder plus `Ask`
- Save, Launch, Remove, Reveal

The form has no "Saved" picker (tiles are the navigation) and no "Mode" control (Embedded is the only mode; the field was always disabled). The app being edited is tracked by `editing`, which drives Launch/Remove/Reveal. `TuiApp.terminal` stays in the struct (always `"Embedded"`) for config compatibility; the external-terminal `launcher()` path is vestigial.

Save is enabled only when the form differs from the last loaded/saved state; it greys out again after a successful save (the success signal).

Titlebar brand is text first, app icon last, right-aligned in the native toolbar with padding comparable to the window controls. Keep the actual Termer app icon there; do not replace it with a generic SF Symbol. The icon is a SwiftPM resource (`Sources/Termer/AppIcon.icns`) loaded via `Bundle.module`, so it shows under `swift run` and in the packaged app; `package.sh` must copy `Termer_Termer.bundle` into the app or `Bundle.module` will `fatalError`.

Avoid large blank windows, sidebars with empty state, marketing copy, and purely decorative visuals. The Liquid Glass background, terminal thumbnails, and hover highlights are allowed because they are native materials and functional previews, not ornamentation — keep new visuals in that spirit (native + informative), not gradients/illustrations for their own sake. Tile cards are the primary launcher surface; do not turn the app into a dashboard. Use AppKit controls unless a native control cannot do the job.

Cmd-Q must work in both Termer and generated apps. AppKit needs a real app menu with a Quit item for this.

The manager app does not auto-update (only generated bundles self-regenerate via `builtBy`). Update flow:
- On launch, a silent check compares `Store.version` to the latest GitHub release `tag_name`. If newer, a primary accent **Update** pill (layer-backed `controlAccentColor`, white text — not `bezelColor`, which desaturates on an inactive window) appears in the toolbar brand area, left of the Termer name.
- Clicking the pill shows a one-item menu "Update to vX.Y.Z"; clicking that installs.
- The app menu also has a **Check for Updates…** item (loud check — alerts when already current).
- Installing drives the canonical installer (`curl … /install | zsh`, which replaces `~/Applications/Termer.app`) then relaunches: it quits first and uses a detached `open` after a short sleep, because `open` on the same bundle id would otherwise just reactivate the still-running old instance.

No background polling — the launch check is the only automatic one.

Closing the last generated app window should terminate normally, not crash or leave a dead process.

## Terminal Theme

Terminal colors should follow macOS appearance and update when the system switches light/dark mode.

Use macOS semantic colors, not hardcoded aesthetic palettes:

- background: `NSColor.textBackgroundColor`
- foreground: `NSColor.labelColor`

If appearance resolution emits deprecation warnings, clean that before moving on. Do not leave warning debt when the fix is local.

## Installer and Site

Primary installer:

```bash
curl -fsSL https://termer.frustrated.dev/install | zsh
```

Site:

```text
https://termer.frustrated.dev
```

Cloudflare Worker owns the site and install route. GitHub Releases own binary hosting. Do not move binaries to Cloudflare unless GitHub Releases becomes a real problem.

`/install` means latest. It should avoid stale latest resolution while redirecting to a concrete versioned GitHub release asset so the asset itself can cache normally.

## Docs and Commits

Update docs in the same commit as behavior changes.

Use concise commit messages.

Push after release commits.

Do not release docs-only changes unless the app binary changed.

## Known Ceilings

- Args parsing is whitespace-only.
- Per-app icons are emoji/Unicode glyphs via `NSWorkspace.setIcon` (xattr); no custom image files, no `.icns` generation (won't survive distribution).
- Shell startup is used for PATH correctness.
- Terminal theme uses semantic foreground/background only, not a full ANSI palette from macOS.
- SwiftTerm is the only non-stdlib dependency and exists because macOS provides PTYs but no embeddable terminal UI.
- Terminal thumbnails use in-process `cacheDisplay` (no permission); if SwiftTerm ever renders via Metal and shots come out blank, switch to `CGWindowListCreateImage`.

Do not fix these speculatively. Fix the first one the user actually hits.

---

## REGEN — Compression Method

### Files

| file | role |
|------|------|
| `AGENTS.source.md` | **EDIT THIS** — human-readable, full English prose |
| `AGENTS.md` | compressed output — symbols only, no sentences |

### Rules

- **AI agents: never edit `AGENTS.md` directly.** It is auto-generated.
- Edit `AGENTS.source.md`, then compile to `AGENTS.md` via the workflow below.
- The REGEN section itself is excluded from the compressed output.
- **Always** prepend this exact two-line disclaimer to the top of the compiled `AGENTS.md` (before any compressed content):

  ```
  // THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
  // Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.
  ```

### Workflow

Edit this file, then ask the agent to run:

```bash
claude -p "Read AGENTS.source.md, apply the REGEN compression rules to compress it (exclude REGEN section), write AGENTS.md" --allowedTools 'Read,Edit,Write' --max-turns 10
```

Compression happens outside session context — costs nothing in tokens.

### Compression Rules

| symbol | meaning |
|--------|---------|
| `§` | section heading prefix |
| `→` | maps to / results in |
| `←` | derived from |
| `▸` | list item |
| `@` | path prefix |
| `!` | don't / negation prefix |
| `?` | condition / query |
| `✓` | correct / yes |
| `❌` | wrong / no / failure |
| `💀` | anti-pattern to avoid |
| `🧠` | thinking / reasoning |
| `🕳️` | rabbithole |
| `⏹` | stop |
| `⚡` | fast / speed up |
| `↘` | slow down |
| `⊖` | suppress / remove |
| `│` | table/data separator |

**Compression approach:**
- Drop all prose filler, keep only directives
- Abbreviate common words (impl, config, utils, conv)
- Symbols replace full phrases
- Inline code blocks over multi-line
- No full English sentences — one line per directive
- Emoji for anti-patterns and concepts where clearer than text
- Namespace paths with `@` instead of backtick-wrapped text
