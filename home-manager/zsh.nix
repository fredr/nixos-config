{ config, ... }: {
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

      theme = "dst";
    };

    shellAliases = {
      ll = "ls -l";
      nixrebuild = "sudo nixos-rebuild switch";
      gst = "git status";
      gg = "git grep -n --untracked -I";
    };

    initExtra = ''
      export PATH=$PATH:/home/fredr/go/bin
      export PATH=$PATH:/home/fredr/.cargo/bin

      export ENCORE_RUNTIMES_PATH=/home/fredr/projects/encoredev/encore/runtimes
      export ENCORE_GOROOT=/home/fredr/projects/encoredev/go/dist/linux_amd64/encore-go

      # disable right prompt (clock in dst)
      unset RPROMPT
    '';

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
