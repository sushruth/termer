# AGENTS.md

- Keep this repo small. Native Swift/AppKit first, no dependencies unless needed.
- Build locally with `Scripts/package.sh`.
- Release with `TERMER_SIGN_IDENTITY="Developer ID Application: Sushruth Sastry (5G2TDMV275)" TERMER_NOTARY_PROFILE="termer" Scripts/release.sh vX.Y.Z`.
- Deploy site/installer changes with `wrangler deploy`.
- The installer URL is `https://termer.sushruth.dev/install`; it redirects to the latest GitHub release asset.
