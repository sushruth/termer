// THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
// Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.

§PONYTAIL
🧠 Ponytail active: minimal, native, boring code. ▸!abstractions ▸!deps ▸!frameworks ▸!services ▸!release infra unless feature needs.

§PRODUCT
Termer→native macOS app, standalone `.app` wrappers for terminal UI commands.
⚠️ **Process ownership critical**: generated apps own terminal window/renderer → Activity Monitor CPU/GPU/Energy under app name, ❌iTerm/Terminal/Ghostty/Warp.
External-terminal launchers ❌. Embedded terminal = canonical path.

§ARCHITECTURE
SwiftPM. @Sources/Termer = manager GUI. @Sources/TermerRunner = copied into apps, owns embedded terminal. SwiftTerm = renderer+PTY.
Generated apps @ @~/Applications/Termer Apps/. Config @ app bundle Contents/Resources/config.json.
Keep small. OS gives PTYs, ❌embeddable Terminal.app window. 💀 Don't wrap Terminal.app/iTerm/Ghostty/Rio/Warp — macOS still charges external terminal.

§BUILD+RELEASE
app change → release before curl test.
Build: `Scripts/package.sh`
Release: `TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z`
Sign nested binaries → sign outer app. New exe inside bundle → sign before outer or notarize ❌.
Install/test: `curl -fsSL https://termer.sushruth.dev/install | zsh`
Installer endpoint: latest GH release → concrete versioned asset. Normal releases ✓ no Cloudflare deploy.
Cloudflare deploy only when @Cloudflare/install-worker.js or @wrangler.toml changed: `wrangler deploy`

§SIGNING+NOTARY
Developer ID = public dist only. Apple Development ❌ (local/dev).
Identity: `Developer ID Application: Sushruth Sastry (5G2TDMV275)`
Profile: `termer`
Notarization fails? Read log: `xcrun notarytool log <submission-id> --keychain-profile termer`
Known fail: nested `TermerRunner` ❌ Developer ID, ❌ timestamp, ❌ hardened runtime.

§GENERATED_APPS
Real `.app` bundles: own name, bundle ID, icon, config, embedded `TermerRunner`.

**Icons**: form Icon field → single emoji/Unicode char → rendered on squircle tile (grid + Finder icon via NSWorkspace.setIcon xattr). Empty → Termer icon default. Custom images: not built. ⏹ Ceiling: xattr OK locally, won't survive distribution → switch to generated .icns in Resources if distributed.

**builtBy**: each app records Termer version (CFBundleShortVersionString). On launch, manager regenerates where builtBy ≠ current version → transparently rewrites stale runners/icons/thumbnails. No manual re-save after update.

**Thumbnails**: in-process cacheDisplay (no permission) → @~/Applications/Termer Apps/.thumbs/<slug>.png. First open (if missing) + on quit (freshest). Manager reads for previews, deletes on Remove.

**Shell launch**: bare commands (`fresh`, `k9s`, `lazygit`) must work from GUI. GUI ❌ inherit PATH → `TermerRunner` launches `/bin/zsh -lic` → resolves Homebrew/mise/asdf/aliases/user PATH. Keep unless measured problem. Direct exec cleaner but breaks common env.

§DYNAMIC_FOLDER+ARGS
Folder field + Ask checkbox.
Ask off → app starts in saved folder.
Ask on → folder picker before launch → chosen folder = process CWD.
Token replacement: `{pwd}`/`{cwd}` → working dir, `{name}` → app name.
⏹ Ceiling: whitespace-split only. Add shellword parsing when quoted args matter.

§UI
Minimal, native. Small utility, ❌ dashboard.
Background: Liquid Glass (NSVisualEffectView, .underWindowBackground, behind-window blend) = Tahoe native, ❌ custom chrome.

**Tile screen** (primary): ~16:10 landscape cards per app → live terminal screenshot or mono glyph or Termer icon + caption. Cards brighten on hover (TileButton). `+` card → new app. Click card → edit form. Returning rebuilds cards (fresh thumbnails visible).

**Form surface**: `‹ All Apps` back btn, saved app picker, Name, Icon (editable combo: monochrome Unicode presets; type/paste any char/emoji → rendered mono), Command, Args, Folder+Ask, Mode:Embedded, Save/Launch/Remove/Reveal.
Save enabled only when form ≠ last state; greys after save = success signal.

**Titlebar brand**: text first, app icon last, right-aligned in native toolbar. Keep real Termer icon (@Sources/Termer/AppIcon.icns, SwiftPM resource, Bundle.module). package.sh must copy Termer_Termer.bundle into app or Bundle.module → fatalError.

❌ Large blank windows. ❌ Sidebars+empty state. ❌ Marketing copy. ❌ Purely decorative visuals. Glass bg + thumbnails + hover = native materials + functional previews (OK). New visuals: native+informative, ❌ gradients/illustrations. Use AppKit controls unless native control can't do job.
Cmd-Q must work (Termer + generated apps). AppKit needs real app menu with Quit item.
Closing last generated window → terminate normally, ❌ crash, ❌ dead process.

§TERMINAL_THEME
Colors follow macOS appearance, update on light/dark switch.
Semantic colors only, ❌ hardcoded palettes: bg = `NSColor.textBackgroundColor`, fg = `NSColor.labelColor`.
Appearance deprecation warnings → fix before moving on. ❌ Warning debt if fix is local.

§INSTALLER+SITE
Primary: `curl -fsSL https://termer.sushruth.dev/install | zsh`
Site: `https://termer.sushruth.dev`
Cloudflare Worker = site+install. GitHub Releases = binaries. ❌ Move binaries to CF unless GH Releases breaks.
`/install` = latest. Avoid stale latest; redirect to concrete versioned GH release asset → asset caches normally.

§DOCS+COMMITS
▸ Update docs in same commit as behavior changes.
▸ Concise commit messages.
▸ Push after release commits.
▸ ❌ Release docs-only unless app binary changed.

§CEILINGS
▸ Args parsing: whitespace-only. Add shellword when quoted args matter.
▸ Per-app icons: emoji/Unicode via NSWorkspace.setIcon xattr; ❌ custom images, ❌ .icns generation (won't survive distribution).
▸ Shell startup for PATH correctness. Direct exec cleaner but breaks user env.
▸ Terminal theme: semantic fg/bg only, ❌ full ANSI palette.
▸ SwiftTerm: only non-stdlib dep (PTYs exist, embeddable UI ❌).
▸ Terminal thumbnails: in-process cacheDisplay (no permission). If SwiftTerm → Metal + blank → switch CGWindowListCreateImage.

💀 Don't fix speculatively. Fix first ceiling user hits.
