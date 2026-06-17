#!/bin/zsh
set -euo pipefail

version="${1:?usage: Scripts/release.sh v0.1.0}"
identity="${TERMER_SIGN_IDENTITY:-Developer ID Application}"
profile="${TERMER_NOTARY_PROFILE:-termer}"

if ! security find-identity -v -p codesigning | grep -q "$identity"; then
  echo "missing signing identity: $identity" >&2
  echo "set TERMER_SIGN_IDENTITY or install a Developer ID Application certificate" >&2
  exit 1
fi

TERMER_SIGN_IDENTITY="$identity" Scripts/package.sh >/dev/null
ditto -c -k --keepParent .build/Termer.app ".build/Termer-$version.zip"

xcrun notarytool submit ".build/Termer-$version.zip" --keychain-profile "$profile" --wait
xcrun stapler staple .build/Termer.app
ditto -c -k --keepParent .build/Termer.app ".build/Termer-$version.zip"

gh release create "$version" ".build/Termer-$version.zip" Scripts/install.sh \
  --title "Termer $version" \
  --notes "Termer $version"
