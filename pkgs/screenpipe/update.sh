#!/usr/bin/env bash
# Updates the pinned screenpipe version and hash in default.nix.
# Usage: ./update.sh [VERSION]   (defaults to the latest release on npm)
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_file="$dir/default.nix"

version="${1:-$(curl -fsSL https://registry.npmjs.org/screenpipe/latest | jq -r .version)}"

current="$(sed -n 's/^ *version = "\(.*\)";/\1/p' "$nix_file" | head -1)"
if [ "$version" = "$current" ]; then
  echo "Already up to date at $version"
  exit 0
fi

echo "Updating screenpipe: $current -> $version"
url="https://registry.npmjs.org/@screenpipe/cli-linux-x64/-/cli-linux-x64-${version}.tgz"
hash="$(nix store prefetch-file --json "$url" | jq -r .hash)"

sed -i \
  -e "s|^\( *\)version = \".*\";|\1version = \"${version}\";|" \
  -e "s|^\( *\)hash = \".*\";|\1hash = \"${hash}\";|" \
  "$nix_file"

echo "Done: version=${version} hash=${hash}"
