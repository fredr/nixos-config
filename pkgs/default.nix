{ pkgs }:
{
  encore = pkgs.callPackage ./encore { };
  mirror = pkgs.callPackage ./mirror { };
}
