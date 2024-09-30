{ config, pkgs, ... }: {
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

    shellAliases =
      let
        encoreDev = "/home/fredr/projects/encoredev";
      in
      {
        ll = "ls -l";
        nixrebuild = "sudo nixos-rebuild switch";
        gst = "git status";
        gg = "git grep -n --untracked -I";
        encore-dev = "ENCORE_RUNTIMES_PATH=${encoreDev}/runtimes ENCORE_GOROOT=${encoreDev}/go/dist/linux_amd64/encore-go /home/fredr/go/bin/encore";
      };

    initExtra = ''
      export PATH=$PATH:/home/fredr/go/bin
      export PATH=$PATH:/home/fredr/.cargo/bin

      # for cross compilation to windows
      export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-L native=${pkgs.pkgsCross.mingwW64.windows.pthreads}/lib";

      # for building boring-sys etc
      export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib";

      # disable right prompt (clock in dst)
      unset RPROMPT
    '';

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
