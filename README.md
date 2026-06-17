# Termer

GUI app for creating macOS `.app` wrappers around TUI commands.

Install latest release:

```sh
curl -fsSL https://github.com/sushruth/termer/releases/latest/download/install.sh | zsh
```

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
