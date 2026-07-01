#!/usr/bin/env bash
# Updates the pinned Claude Code version and hash in default.nix.
# Usage: ./update.sh [VERSION]   (defaults to the latest release)
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_file="$dir/default.nix"
platform="linux-x64"

version="${1:-$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)}"

current="$(sed -n 's/.*version = "\(.*\)";/\1/p' "$nix_file")"
if [ "$version" = "$current" ]; then
  echo "Already up to date at $version"
  exit 0
fi

echo "Updating claude-code: $current -> $version"
url="https://downloads.claude.ai/claude-code-releases/${version}/${platform}/claude"
hash="$(nix-prefetch-url "$url")"

sed -i \
  -e "s|version = \".*\";|version = \"${version}\";|" \
  -e "s|hash = \".*\";|hash = \"${hash}\";|" \
  "$nix_file"

echo "Done: version=${version} hash=${hash}"
