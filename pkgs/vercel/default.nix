{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
}:

let
  version = "59.1.4";
in
buildNpmPackage {
  pname = "vercel";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/vercel/-/vercel-${version}.tgz";
    hash = "sha256-OOXpqJtotYNaDtzsaWYbfxUAZovlXj6o5h6CmuE7DVo=";
  };

  npmDepsHash = "sha256-PPMHsRIkgMMu1KbHM4NAFng5MuU618Mu92sYqzYKw54=";

  # npm tarballs ship no lockfile, so ./update.sh resolves one and vendors it
  # next to this file. devDependencies have to go: they reference
  # @vercel-internals/* packages that are never published to the registry, so
  # they cannot be resolved at all. Dropping them keeps package.json in sync
  # with the production-only lockfile, which `npm ci` insists on.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    ${jq}/bin/jq 'del(.devDependencies, .scripts)' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';

  npmFlags = [ "--omit=dev" ];

  # dist/ is already an esbuild bundle in the published tarball.
  dontNpmBuild = true;

  meta = {
    description = "Vercel CLI - deploy and manage Vercel projects from the terminal";
    homepage = "https://vercel.com/docs/cli";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    mainProgram = "vercel";
  };
}
