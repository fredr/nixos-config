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
    };

    shellAliases = {
      ll = "ls -l";
      nixrebuild = "sudo nixos-rebuild switch";
      gst = "git status";
      gg = "git grep -n --untracked -I";

      git-untracked-branches = "git fetch -p ; git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}'";

      encore-dev = "nix develop ~/nixos-config#encore-dev -c $SHELL";
      encore-rel = "nix develop ~/nixos-config#encore-rel -c $SHELL";

      encore-new = "encore app create --example=ts/hello-world";
    };

    initExtra = ''
      export PATH=$PATH:/home/fredr/go/bin
      export PATH=$PATH:/home/fredr/.cargo/bin
      export PATH=$PATH:/home/fredr/bin

      # for cross compilation to windows
      export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-L native=${pkgs.pkgsCross.mingwW64.windows.pthreads}/lib";

      # for building boring-sys etc
      export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib";

      # "theme" based on dst
      function nix_shell() {
        shell_name=''${SHELL_NAME:-shell}
        if [ ! -z ''${IN_NIX_SHELL+x} ];
          then echo "%{$fg[blue]%}  ''${shell_name}%{$reset_color%}";
        fi
      }

      ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[green]%}"
      ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
      ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}!"
      ZSH_THEME_GIT_PROMPT_CLEAN=""

      function prompt_char {
          if [ $UID -eq 0 ]; then echo "%{$fg[red]%}#%{$reset_color%}"; else echo $; fi
      }

      PROMPT='%(?, ,%{$fg[red]%}FAIL%{$reset_color%}
      )
      %{$fg[magenta]%}%n%{$reset_color%}@%{$fg[yellow]%}%m%{$reset_color%}: %{$fg_bold[blue]%}%~%{$reset_color%}$(git_prompt_info)$(nix_shell)
      $(prompt_char) '

      RPROMPT=""
    '';

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}

