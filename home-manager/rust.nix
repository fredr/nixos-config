{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (fenix.stable.withComponents [
      "cargo"
      "clippy"
      "llvm-tools"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    rust-analyzer
  ];
}
