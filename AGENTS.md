// THIS FILE IS AUTO-GENERATED FROM AGENTS.source.md — DO NOT EDIT DIRECTLY.
// Edit AGENTS.source.md, then apply REGEN compression rules to regen this file.

§MODE
ponytail always. minimal,native,boring. !deps/fw/infra/abstractions until current feature proves need.

§PRODUCT
Termer→macOS GUI creates standalone `.app` wrappers for TUI cmds.
core req→generated app owns terminal window+renderer→Activity Monitor CPU/GPU/Energy under app name.
external terms(iTerm/Terminal/Ghostty/Warp/Rio)→convenience only; ❌resource attribution.
embedded terminal→canonical.

§ARCH
SwiftPM.
@Sources/Termer→manager GUI.
@Sources/TermerRunner→copied into generated apps; owns embedded terminal window.
SwiftTerm→renderer+PTY.
generated apps→`~/Applications/Termer Apps/`.
config→`Contents/Resources/config.json`.
OS gives PTY, !embeddable Terminal.app. !try make external terminal look owning app.

§BUILD_RELEASE
app change→release before curl test msg.
build→`Scripts/package.sh`.
release→`TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z`.
new nested exe→sign nested first, then outer app. else notarize ❌.
install/test→`curl -fsSL https://termer.sushruth.dev/install | zsh`.
installer→latest GitHub release → concrete versioned asset.
normal app release→!wrangler.
Cloudflare change(@Cloudflare/install-worker.js,@wrangler.toml)→`wrangler deploy`.

§SIGNING
public dist→Developer ID only. Apple Development→local only.
identity→`Developer ID Application: Sushruth Sastry (5G2TDMV275)`.
notary profile→`termer`.
notary fail→`xcrun notarytool log <id> --keychain-profile termer` first.
known fail→nested `TermerRunner` !DeveloperID/!timestamp/!hardened runtime.

§GENERATED_APPS
real `.app` bundles: name,bundle id,icon,config,embedded `TermerRunner`.
icon currently Termer icon. per-app icons later.
bare cmds(`fresh`,`k9s`,`lazygit`) must work from GUI.
GUI !terminal PATH→runner uses `/bin/zsh -lic` for Homebrew/mise/asdf/PATH.
keep shell launch until measured problem. direct exec breaks user env.

§DYNAMIC_FOLDER_ARGS
Folder field + `Ask`.
Ask off→saved cwd.
Ask on→folder picker before launch; chosen dir→process cwd.
args tokens: `{pwd}`/`{cwd}`→chosen cwd; `{name}`→app name.
args split→whitespace only. known ceiling. shellwords only when quoted args matter.

§UI
small native utility. !dashboard.
surface→Saved,Name,Command,Args,Folder+Ask,Mode:Embedded,Save/Launch/Remove/Reveal.
avoid→large blank windows, empty sidebars, cards, marketing copy, decoration, custom styling.
use AppKit controls.
Cmd-Q must work in Termer+generated apps→real app menu Quit item.
last generated window close→normal terminate; !crash/dead proc.

§TERM_THEME
follow macOS appearance; live light/dark switching.
semantic colors only: bg=`NSColor.textBackgroundColor`; fg=`NSColor.labelColor`.
!hardcoded aesthetic palette.
appearance warning→fix before moving on; !warning debt.

§INSTALLER_SITE
primary→`curl -fsSL https://termer.sushruth.dev/install | zsh`.
site→`https://termer.sushruth.dev`.
Cloudflare Worker→site/install route.
GitHub Releases→binary hosting. !move to CF unless real problem.
`/install`→latest resolver; avoid stale latest; redirect to concrete versioned asset for cache.

§DOCS_COMMITS
docs same commit as behavior.
commit msg concise.
push after release commits.
docs-only→!release.

§KNOWN_CEILINGS
▸ args whitespace-only
▸ generated apps use Termer icon
▸ shell startup for PATH correctness
▸ semantic fg/bg only, no full ANSI macOS palette
▸ SwiftTerm only non-stdlib dep; needed because macOS lacks terminal UI widget
!fix speculative. fix first user-hit ceiling.
