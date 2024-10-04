{ buildGoModule }:

# golang.org/x/tools/cmd/stringer

buildGoModule {
  pname = "stringer";
  version = "d0d0d9";

  src = builtins.fetchGit
    {
      url = "https://go.googlesource.com/tools";
      rev = "d0d0d9ebc2175ffb592761462bd3a5c2ceab354f";
    };

  vendorHash = "sha256-9NSgtranuyRqtBq1oEnHCPIDFOIUJdVh5W/JufqN2Ko=";

  subPackages = [ "cmd/stringer" ];
}
