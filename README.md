# Termer

GUI app for creating macOS `.app` wrappers around TUI commands.

Install latest release:

```sh
curl -fsSL https://termer.frustrated.dev/install | zsh
```

Site: https://termer.frustrated.dev

Build locally:

```sh
Scripts/package.sh
open .build/Termer.app
```

Release:

```sh
xcrun notarytool store-credentials termer
TERMER_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" Scripts/release.sh v0.1.0
```

The installer route is a Cloudflare Worker in `Cloudflare/install-worker.js`.
It redirects to GitHub's `releases/latest/download/install.sh`, so normal app
releases do not require a Cloudflare deploy.

Deploy the site/installer Worker only when `Cloudflare/install-worker.js` or
`wrangler.toml` changes:

```sh
wrangler deploy
```
