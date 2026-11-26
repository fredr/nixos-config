#!/usr/bin/env bash
# Updates the pinned herdr-app version and hash in default.nix from the
# release manifest the official installer reads.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_file="$dir/default.nix"
manifest="$(curl -fsSL https://releases.herdr.dev/app/latest.json)"

version="$(jq -r .version <<<"$manifest")"
current="$(sed -n 's/.*version = "\(.*\)";/\1/p' "$nix_file")"
if [ "$version" = "$current" ]; then
  echo "Already up to date at $version"
  exit 0
fi

echo "Updating herdr-app: $current -> $version (needs herdr-core >= $(jq -r .core_min <<<"$manifest"))"
hash="$(nix hash convert --hash-algo sha256 --to sri "$(jq -r '.targets["linux-x86_64"].sha256' <<<"$manifest")")"

sed -i \
  -e "s|version = \".*\";|version = \"${version}\";|" \
  -e "s|hash = \".*\";|hash = \"${hash}\";|" \
  "$nix_file"

echo "Done: version=${version} hash=${hash}"
