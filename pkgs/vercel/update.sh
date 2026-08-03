#!/usr/bin/env bash
# Updates the pinned vercel version, source hash, npm dependency hash and the
# vendored lockfile in this directory.
# Usage: ./update.sh [VERSION]   (defaults to the latest release on npm)
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_file="$dir/default.nix"
lock_file="$dir/package-lock.json"

version="${1:-$(curl -fsSL https://registry.npmjs.org/vercel/latest | jq -r .version)}"

current="$(sed -n 's/^ *version = "\(.*\)";/\1/p' "$nix_file" | head -1)"
if [ "$version" = "$current" ]; then
  echo "Already up to date at $version"
  exit 0
fi

echo "Updating vercel: $current -> $version"
url="https://registry.npmjs.org/vercel/-/vercel-${version}.tgz"

src_hash="$(nix store prefetch-file --json "$url" | jq -r .hash)"

# Resolve a production-only lockfile from the tarball's own package.json. The
# published devDependencies reference unpublished @vercel-internals/* packages,
# so a full resolve would 404.
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
curl -fsSL "$url" | tar -xz -C "$work" package/package.json
jq 'del(.devDependencies, .scripts)' "$work/package/package.json" >"$work/package.json"
(cd "$work" && npm install --package-lock-only --omit=dev --ignore-scripts --no-audit --no-fund >/dev/null)
cp "$work/package-lock.json" "$lock_file"

npm_hash="$(prefetch-npm-deps "$lock_file")"

sed -i \
  -e "s|^\( *\)version = \".*\";|\1version = \"${version}\";|" \
  -e "s|^\( *\)hash = \".*\";|\1hash = \"${src_hash}\";|" \
  -e "s|^\( *\)npmDepsHash = \".*\";|\1npmDepsHash = \"${npm_hash}\";|" \
  "$nix_file"

echo "Done: version=${version} src=${src_hash} npmDeps=${npm_hash}"
