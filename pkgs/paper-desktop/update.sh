#!/usr/bin/env bash
# Updates the pinned Paper Desktop version and hash in default.nix.
# Usage: ./update.sh   (the download URL only ever serves the latest build)
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_file="$dir/default.nix"
url="https://download.paper.design/linux/appImage/x64"

# content-disposition: attachment; filename="paper-desktop-0.5.18x86_64.AppImage"
version="$(curl -fsSI "$url" | sed -n 's/^content-disposition:.*paper-desktop-\([0-9][0-9.]*[0-9]\).*/\1/Ip')"
if [ -z "$version" ]; then
  echo "error: could not read version from $url" >&2
  exit 1
fi

current="$(sed -n 's/.*version = "\(.*\)";/\1/p' "$nix_file")"
if [ "$version" = "$current" ]; then
  echo "Already up to date at $version"
  exit 0
fi

echo "Updating paper-desktop: $current -> $version"
hash="$(nix-prefetch-url --name "paper-desktop-${version}.AppImage" "$url")"

sed -i \
  -e "s|version = \".*\";|version = \"${version}\";|" \
  -e "s|hash = \".*\";|hash = \"${hash}\";|" \
  "$nix_file"

echo "Done: version=${version} hash=${hash}"
