{ pkgs, ... }:
let
  gcloud = pkgs.google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
    gke-gcloud-auth-plugin
    bigtable
    cbt
    pubsub-emulator
  ]);
in
{
  home.packages = [
    gcloud
    pkgs.jre
  ];
}
