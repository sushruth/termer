// THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
// Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.

§BREVITY
ponytail active. minimal,native,boring. !abstractions,!deps,!frameworks,!background svcs,!release infra until feature needs it.

§PRODUCT
Termer→native macOS app creates standalone `.app` wrappers for terminal UI cmds.
🎯 core req→generated apps own terminal window+renderer→Activity Monitor CPU/GPU/Energy under app name, !iTerm/Terminal/Ghostty/Warp.
external-term launchers→convenience mode only, !resource attribution.
embedded terminal→canonical path.

§ARCH
SwiftPM-based.
@Sources/Termer→manager GUI.
@Sources/TermerRunner→copied into generated apps; owns embedded terminal window.
SwiftTerm→terminal renderer+PTY runner.
generated apps→@~/Applications/Termer Apps/.
config→app bundle Contents/Resources/config.json.
Keep small. OS gives PTYs, !embeddable Terminal.app window. !try copy Terminal.app/iTerm/Ghostty/Rio/Warp styling; macOS charges external term anyway.

§BUILD_RELEASE
app change→release before curl test.
build: `Scripts/package.sh`.
release: `TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z`.
nested exe→sign nested first, then outer app. new exe inside bundle→sign before outer or notarize ❌.
install/test: `curl -fsSL https://termer.sushruth.dev/install | zsh`.
installer endpoint→resolves latest GitHub release, redirects to concrete versioned asset. normal releases !need Cloudflare deploy.
Cloudflare deploy only: @Cloudflare/install-worker.js or @wrangler.toml changed→`wrangler deploy`.

§SIGNING_NOTARY
Developer ID→public dist only. Apple Development→local/dev only.
identity: `Developer ID Application: Sushruth Sastry (5G2TDMV275)`.
profile: `termer`.
notary fail→read log first: `xcrun notarytool log <id> --keychain-profile termer`.
known fail: nested `TermerRunner` !Developer ID, !timestamp, !hardened runtime.

§GENERATED_APPS
real `.app` bundles: own name,bundle id,icon,config,embedded `TermerRunner`.
per-app icons→form Icon field(1 emoji/Unicode char)→rendered squircle tile in grid+generated app Finder icon via NSWorkspace.setIcon(xattr).empty→Termer icon.custom image files→!built.ceiling:setIcon !survive dist→generated .icns if distributed.
thumbnails→each generated app screenshots own terminal(in-proc cacheDisplay,!screen-rec perm)→`~/Applications/Termer Apps/.thumbs/<slug>.png`,on first open if missing+on quit.manager reads for card previews,deletes on Remove.
bare cmds(`fresh`,`k9s`,`lazygit`)→must work from GUI launch. GUI !inherit PATH.
`TermerRunner`→launches via `/bin/zsh -lic`→resolves Homebrew/mise/asdf/aliases/user PATH.
keep shell launch unless measured problem. direct exec cleaner but breaks common user envs.

§DYNAMIC_FOLDER_ARGS
manager→Folder field+Ask checkbox.
Ask off→app starts in saved folder.
Ask on→folder picker before launch; chosen folder=process working dir.
args token replacement: `{pwd}`/`{cwd}`→working dir, `{name}`→app name.
⚠️ args=whitespace-split only. add shellword parsing when quoted args matter.

§UI
keep minimal,native. small utility, !dashboard.
window bg→Liquid Glass(NSVisualEffectView .underWindowBackground behindWindow)=Tahoe native,!custom chrome.
manager→centered card screen: one landscape card(~16:10 terminal ratio) per saved app→live terminal screenshot if exists else mono glyph else Termer icon+caption.cards brighten on hover(TileButton).`+` card→new app, click card→edit form.card screen=primary surface, form=edit/create.return to it→rebuilds cards(fresh thumbnails).
form: `‹ All Apps` back btn→tiles, saved app picker, Name, Icon(combo box:monochrome Unicode presets;type/paste any char/emoji→rendered mono), Command, Args, Folder+Ask, Mode:Embedded, Save/Launch/Remove/Reveal.
Save enabled only when form≠last loaded/saved state;greys after save=success signal.
titlebar: text first, app icon last, right-aligned in native toolbar. keep real Termer icon, !generic SF Symbol. icon=SwiftPM resource(Sources/Termer/AppIcon.icns)via Bundle.module→works swift run+packaged.package.sh MUST cp Termer_Termer.bundle into app or Bundle.module fatalError.
!large blank windows, !sidebars+empty state, !marketing copy, !purely decorative visuals. glass bg+terminal thumbnails+hover=native materials+functional previews, OK; keep new visuals native+informative,!gradients/illustrations for own sake. !custom control styling beyond that.
tile buttons OK (primary launcher). use AppKit controls unless native control !can do job.
Cmd-Q→must work in Termer+generated apps. AppKit needs real app menu with Quit item.
close last generated window→terminate normally, !crash, !dead proc.

§TERMINAL_THEME
colors→follow macOS appearance, update on light/dark switch.
macOS semantic colors only, !hardcoded palettes: bg=`NSColor.textBackgroundColor`, fg=`NSColor.labelColor`.
appearance deprecation warnings→clean before moving on. !warning debt when fix is local.

§INSTALLER_SITE
primary: `curl -fsSL https://termer.sushruth.dev/install | zsh`.
site: `https://termer.sushruth.dev`.
Cloudflare Worker→site+install route. GitHub Releases→binary hosting. !move binaries to CF unless GH Releases breaks.
`/install`=latest. avoid stale latest; redirect to concrete versioned GH release asset.

§DOCS_COMMITS
update docs in same commit as behavior changes.
commit messages concise.
push after release commits.
!release docs-only unless app binary changed.

§KNOWN_CEILINGS
▸ args parsing: whitespace-only
▸ per-app icons: emoji/Unicode glyph via NSWorkspace.setIcon(xattr); !custom images,!​.icns(​!survive dist)
▸ shell startup: for PATH correctness
▸ terminal theme: semantic fg/bg only, !full ANSI palette
▸ SwiftTerm: only non-stdlib dep (macOS has PTYs, !embeddable terminal UI)
▸ thumbnails: in-proc cacheDisplay(!perm); blank w/ Metal→CGWindowListCreateImage
!fix speculatively. fix first ceiling user hits.
