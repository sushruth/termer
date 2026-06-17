#!/bin/zsh
set -euo pipefail

repo="${TERMER_REPO:-usually-frustrated/termer}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

url="$(curl -fsSL -H "Cache-Control: no-cache" "https://api.github.com/repos/$repo/releases/latest" \
  | /usr/bin/python3 -c 'import json,sys; print(next(a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if a["name"].endswith(".zip")))')"

curl -fL -H "Cache-Control: no-cache" "$url" -o "$tmp/Termer.zip"
ditto -x -k "$tmp/Termer.zip" "$tmp"
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/Termer.app"
mv "$tmp/Termer.app" "$HOME/Applications/Termer.app"
open "$HOME/Applications/Termer.app"
