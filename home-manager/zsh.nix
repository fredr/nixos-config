{ config, pkgs, ... }: {
  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
    "$HOME/bin"
  ];

  home.sessionVariables = {
    DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";

    # for cross compilation to windows
    CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS =
      "-L native=${pkgs.pkgsCross.mingwW64.windows.pthreads}/lib "
      + "-L native=${pkgs.pkgsCross.mingwW64.windows.mcfgthreads}/lib "
      + "-C link-arg=-lmcfgthread";

    # napi-build requires a real Windows libnode.dll when cross-compiling napi
    # addons to x86_64-pc-windows-gnu. Official Node.js Windows builds don't
    # ship one, so use a prebuilt shared-library Node from
    # github.com/alshdavid/libnode-prebuilt.
    LIBNODE_PATH = pkgs.fetchzip {
      url = "https://github.com/alshdavid/libnode-prebuilt/releases/download/v22.18.0/libnode-windows-amd64.tar.gz";
      hash = "sha256-ED8F0HIdLAc2fd9l77Ox9D247bRusvs6+XAfXdglWQU=";
      stripRoot = false;
    };

    # for building boring-sys etc
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

    # bindgen needs mingw headers when cross-compiling to windows
    BINDGEN_EXTRA_CLANG_ARGS_x86_64_pc_windows_gnu =
      "-isystem ${pkgs.pkgsCross.mingwW64.stdenv.cc.libc.dev}/include";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;

      plugins = [
        "git-prompt"
      ];
    };

    shellAliases = {
      ll = "ls -l";
      nixrebuild = "sudo nixos-rebuild switch";
      nixrebuild-diff = "tmp=$(mktemp -d); (cd $tmp; nixos-rebuild build && ${pkgs.nvd}/bin/nvd diff /run/current-system result); rm -r $tmp";
      nix-diff-latest = "${pkgs.nvd}/bin/nvd diff $(ls -d /nix/var/nix/profiles/system-*-link | tail -n 2)";
      gst = "git status";
      gg = "git grep -n --untracked -I";

      git-untracked-branches = "git fetch -p ; git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}'";

      encore-dev-ls = "git -C ~/projects/encoredev/encore worktree list";
      encore-rel = "nix develop ~/nixos-config#encore-rel -c zsh";

      encore-new = "encore app create --example=ts/hello-world";
      encore-zed-rules-ts = "curl https://raw.githubusercontent.com/encoredev/encore/refs/heads/main/ts_llm_instructions.txt -o .rules";
      encore-zed-rules-go = "curl https://raw.githubusercontent.com/encoredev/encore/refs/heads/main/go_llm_instructions.txt -o .rules";
    };

    initContent = builtins.readFile ./zshrc.zsh;

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
