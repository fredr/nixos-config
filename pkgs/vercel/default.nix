{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
}:

let
  version = "62.4.0";
in
buildNpmPackage {
  pname = "vercel";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/vercel/-/vercel-${version}.tgz";
    hash = "sha256-ypAC78AxWnZcDgugHFK9dOSfZoP/h2PaBlKZdt9SqZI=";
  };

  npmDepsHash = "sha256-UPSkxJmtAm7OX0zEQwnBqy55HGZPD964tpTEnq9cW6E=";

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
