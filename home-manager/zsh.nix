{ config, pkgs, ... }: {
  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
    "$HOME/bin"
  ];

  home.sessionVariables = {
    DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";

    # for building boring-sys etc
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
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

      windows-cross = "nix develop ~/nixos-config#windows-cross -c zsh";
      project-tools = "nix develop ~/nixos-config#project-tools -c zsh";

      encore-new = "encore app create --example=ts/hello-world";
      encore-zed-rules-ts = "curl https://raw.githubusercontent.com/encoredev/encore/refs/heads/main/ts_llm_instructions.txt -o .rules";
      encore-zed-rules-go = "curl https://raw.githubusercontent.com/encoredev/encore/refs/heads/main/go_llm_instructions.txt -o .rules";
    };

    initContent = builtins.readFile ./zshrc.zsh;

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
