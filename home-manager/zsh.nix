{ config, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      nixrebuild = "sudo nixos-rebuild switch";
      gst = "git status";
    };

    initExtra = ''
      export PATH=$PATH:/home/fredr/go/bin
      export PATH=$PATH:/home/fredr/.cargo/bin

      export ENCORE_RUNTIMES_PATH=/home/fredr/projects/encore/runtimes
      export ENCORE_GOROOT=/home/fredr/projects/go/dist/linux_amd64/encore-go
    '';

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
