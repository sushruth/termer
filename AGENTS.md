// THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
// Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.

§PONYTAIL
Minimal, native, boring code. ! abstractions, deps, frameworks, bg services, release infra unless demonstrated needed.

§PRODUCT
Termer: native macOS `.app` wrappers for terminal UI commands.
✓ key: process ownership → CPU/GPU/Energy attrs under generated app, ! iTerm/Terminal/Ghostty/Warp.
! external-terminal launchers (↘ canonical path). Embedded terminal → only valid path for resource attribution.

§ARCH
← SwiftPM. Termer = manager GUI. TermerRunner = embedded terminal owner (copied into generated apps). SwiftTerm = renderer + PTY.
Generated apps @ ~/Applications/Termer Apps/. Config @ bundle Contents/Resources/config.json.
! try wrap Terminal.app/iTerm/Ghostty/Rio/Warp → process acctng still charges external terminal.

§BUILD+RELEASE
⊖ user testing curl before releasing app changes. Always release app 1st.
Build: Scripts/package.sh
Release: TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z
▸ sign nested bins before outer app, else notary fails
▸ release.sh → TERMER_VERSION → package.sh → CFBundleShortVersionString + builtBy (dev if unset)
Install/test: curl -fsSL https://termer.frustrated.dev/install | zsh
▸ endpoint resolves latest GH release → redirects versioned asset
▸ ! Cloudflare deploy for normal app releases
Cloudflare deploy only: Cloudflare/install-worker.js or wrangler.toml changed → wrangler deploy

§SIGNING+NOTARY
Developer ID (public): Developer ID Application: Sushruth Sastry (5G2TDMV275)
Notary profile: termer
❌ known failure: nested TermerRunner ! signed Developer ID, ! timestamp, ! hardened runtime
Notary fails? → xcrun notarytool log <submission-id> --keychain-profile termer

§GENERATED_APPS
Real .app bundles: name, bundle ID, icon, config, embedded TermerRunner.
Icons: emoji/Unicode via Icon field → native squircle (manager + Finder xattr). Empty → Termer icon.
⚠️ ceiling: NSWorkspace.setIcon xattrs ! survive distribution → generate .icns in Resources if apps distributed.
▸ builtBy records Termer version (CFBundleShortVersionString). Manager regenerates where builtBy ≠ current → transparent runner/icon/thumbnail updates, ! manual re-save.

Thumbnails: in-process cacheDisplay (! screen-recording perms) → ~/Applications/Termer Apps/.thumbs/<slug>.png
▸ once 1st open if missing, again on quit (freshest state)
▸ manager reads for card previews, deletes on Remove
⚠️ ceiling: SwiftTerm renders blank w/ Metal? → CGWindowListCreateImage

Shell launch: bare commands (fresh, k9s, lazygit) must work from GUI. ! inherit terminal PATH → launch via login shell.
▸ shell = getpwuid(getuid()).pw_shell (Directory Services), ! $SHELL, ⏹ /bin/zsh fallback
▸ POSIX (zsh/bash): -lic "exec <cmd>" (login + interactive, ~/.zprofile/~/.zshrc/~/.bash_profile/~/.bashrc load)
▸ fish: -l -c "exec <cmd>" (! -i)
▸ ! hardcode /bin/zsh → user gets their shell + profile

Environment: inherit process env (USER, HOME, LOGNAME, SSH_AUTH_SOCK, etc.) + TERM=xterm-256color.
▸ ! bare ["TERM=..."] → wipes expected env
▸ keep shell launch unless ↘ measured problem. Direct exec cleaner but breaks common user envs.

§DYNAMIC_FOLDER+ARGS
Manager: Folder field + Ask checkbox.
Ask=off → app starts in saved folder. Ask=on → folder picker → chosen cwd.
Args: token replacement {pwd}, {cwd}, {name}.
⚠️ ceiling: whitespace-only split. Add shellword parsing when quoted args matter.

§UI
Minimal, native. Small utility, ! dashboard.
Background: Liquid Glass (NSVisualEffectView, .underWindowBackground, behind-window) — Tahoe native.
Manager: centered tiles:
▸ ~16:10 landscape card per saved app
▸ card: live terminal screenshot (if exists) or monochrome glyph or Termer icon + caption
▸ hover → brighten (TileButton)
▸ same-size + card creates new app
▸ click → form for app
▸ tiles = primary; form = edit/create; return rebuilds → fresh thumbnails appear

Form:
▸ ‹ All Apps back, Name, Icon (combo + any char/emoji, rendered monochrome), Command, Args, Folder + Ask
▸ Save, Launch, Remove, Reveal
▸ ! "Saved" picker (tiles = nav), ! "Mode" control (Embedded only, vestigial external launcher)
▸ editing tracks app → Launch/Remove/Reveal
▸ TuiApp.terminal = "Embedded" (config compat)
▸ Save enabled ! form ≠ loaded state; greys out after save (✓ signal)

Titlebar: text 1st, app icon last, right-aligned toolbar w/ native padding. Real Termer icon only.
▸ icon = SwiftPM resource (Sources/Termer/AppIcon.icns, Bundle.module). Shown @ swift run + packaged.
▸ package.sh must copy Termer_Termer.bundle or Bundle.module → fatalError

! large blank windows, empty sidebars, marketing, decorative visuals.
▸ Liquid Glass, thumbnails, hover = native + functional → allowed
▸ keep new visuals native + informative, ! gradients/illustrations
▸ tiles = primary launcher; ! dashboard
▸ AppKit controls unless native control can't do job

Cmd-Q works in Termer + generated apps. AppKit needs real app menu + Quit.
Last generated app window closed → terminate normally, ! crash/dead process.

§THEME
Colors follow macOS appearance, update on light/dark switch.
Semantic (! hardcoded): bg = NSColor.textBackgroundColor, fg = NSColor.labelColor.
⊖ deprecation warnings cleanly before moving on. ! warning debt when fix local.

§INSTALLER+SITE
Primary: curl -fsSL https://termer.frustrated.dev/install | zsh
Site: https://termer.frustrated.dev
Cloudflare Worker = site + install. GitHub Releases = binaries. ! move binaries unless GH Releases becomes problem.
/install = latest, avoid stale resolution, redirect to versioned asset → asset caches normally.

§DOCS+COMMITS
Update docs same commit as behavior changes.
Concise commit messages.
Push after release commits.
! release docs-only unless app binary changed.

§CEILINGS
⚠️ Args: whitespace-only.
⚠️ Icons: emoji/Unicode (NSWorkspace.setIcon xattr), ! custom images, ! .icns gen (! survive dist).
⚠️ Shell: PATH via startup.
⚠️ Theme: semantic fg/bg only, ! full ANSI palette.
⚠️ SwiftTerm: only non-stdlib (macOS gives PTYs, ! embeddable UI).
⚠️ Thumbnails: in-process cacheDisplay (! perms); Metal blank → CGWindowListCreateImage.
! fix speculatively. Fix 1st user-hit ceiling.
