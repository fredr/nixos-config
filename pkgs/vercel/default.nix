{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
}:

let
  version = "59.7.0";
in
buildNpmPackage {
  pname = "vercel";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/vercel/-/vercel-${version}.tgz";
    hash = "sha256-ZzfDDwDX/YvTr853ps6Y2MFQmt+zSJg05d9yJF5nvGI=";
  };

  npmDepsHash = "sha256-eTbopOXEmvl2BWlkXx7+4Ce8Sbli+5mrIHyXi5qoMO8=";

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
