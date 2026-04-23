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

    initContent = ''
      export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock

      export PATH=$PATH:/home/fredr/go/bin
      export PATH=$PATH:/home/fredr/.cargo/bin
      export PATH=$PATH:/home/fredr/bin

      function encore-dev() {
        if [ -z "$1" ]; then
          nix develop ~/nixos-config#encore-dev -c zsh
          return
        fi

        local name="$1"
        local custom_path="$2"

        if [[ "$name" == */* ]]; then
          echo "Error: name must not contain '/'"
          return 1
        fi

        local encore_main=~/projects/encoredev/encore
        local worktree_base=~/projects/encoredev/encore.worktrees
        local worktree_dir="$worktree_base/$name"

        local new_worktree=0

        if [ -n "$custom_path" ]; then
          local resolved_path="$(realpath "$custom_path" 2>/dev/null)"
          if [ ! -d "$resolved_path" ]; then
            echo "Error: path '$custom_path' does not exist or is not a directory"
            return 1
          fi

          if [ -d "$worktree_dir" ] && [ ! -L "$worktree_dir" ]; then
            echo "Error: '$name' already exists as a worktree, not an external path"
            return 1
          fi

          mkdir -p "$worktree_base"
          ln -sfn "$resolved_path" "$worktree_dir"
        elif [ -L "$worktree_dir" ] && [ ! -d "$worktree_dir" ]; then
          echo "Error: '$name' links to a path that no longer exists: $(readlink "$worktree_dir")"
          return 1
        elif [ ! -d "$worktree_dir" ]; then
          local branch="fredr/$name"
          echo "Creating worktree '$name' (branch '$branch') from main..."
          mkdir -p "$worktree_base"
          git -C "$encore_main" worktree add -b "$branch" "$worktree_dir"
          new_worktree=1
        fi

        ENCORE_WORKTREE_NAME="$name" \
        ENCORE_WORKTREE_DIR="$(realpath "$worktree_dir")" \
        ENCORE_WORKTREE_NEW="$new_worktree" \
          nix develop ~/nixos-config#encore-dev -c zsh
      }

      function encore-dev-rm() {
        if [ -z "$1" ]; then
          echo "Usage: encore-dev-rm <name>"
          return 1
        fi

        local name="$1"
        local encore_main=~/projects/encoredev/encore
        local worktree_dir=~/projects/encoredev/encore.worktrees/$name

        if [ ! -e "$worktree_dir" ] && [ ! -L "$worktree_dir" ]; then
          echo "Entry '$name' does not exist"
          return 1
        fi

        if [ -L "$worktree_dir" ]; then
          rm "$worktree_dir"
          echo "Removed path link '$name'"
        else
          git -C "$encore_main" worktree remove --force "$worktree_dir"
          echo "Removed worktree '$name'"
        fi
      }

      function encore-dir() {
        if [ -z "''${ENCORE_DEV_DIR:-}" ]; then
          echo "encore-dir: not inside an encore-dev shell" >&2
          return 1
        fi
        cd "$ENCORE_DEV_DIR"
      }

      # helper for converting encore protos to json, proto type is the argument
      function encore-buf() {
        (cd ~/projects/encoredev/encore/proto ; buf convert --type $1 | jq)
      }

      # for cross compilation to windows
      export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-L native=${pkgs.pkgsCross.mingwW64.windows.pthreads}/lib -L native=${pkgs.pkgsCross.mingwW64.windows.mcfgthreads}/lib -C link-arg=-lmcfgthread";

      # napi-build requires a real Windows libnode.dll when cross-compiling
      # napi addons to x86_64-pc-windows-gnu. Official Node.js Windows builds
      # don't ship one, so use a prebuilt shared-library Node from
      # github.com/alshdavid/libnode-prebuilt.
      export LIBNODE_PATH="${pkgs.fetchzip {
        url = "https://github.com/alshdavid/libnode-prebuilt/releases/download/v22.18.0/libnode-windows-amd64.tar.gz";
        hash = "sha256-ED8F0HIdLAc2fd9l77Ox9D247bRusvs6+XAfXdglWQU=";
        stripRoot = false;
      }}";

      # for building boring-sys etc
      export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib";

      # bindgen needs mingw headers when cross-compiling to windows
      export BINDGEN_EXTRA_CLANG_ARGS_x86_64_pc_windows_gnu="-isystem ${pkgs.pkgsCross.mingwW64.stdenv.cc.libc.dev}/include";

      # Restore SHELL to zsh — nix develop overrides it to bash via stdenv
      export _ORIG_SHELL="''${_ORIG_SHELL:-$SHELL}"
      export SHELL="$_ORIG_SHELL"

      export BASE_SHLVL=''${BASE_SHLVL:-$SHLVL}

      # Detect new subshells (nix develop, nix shell, etc.)
      if [ "$SHLVL" -gt "$BASE_SHLVL" ] && [ "$SHLVL" != "''${_HANDLED_SHLVL:-0}" ]; then
        if [ "''${SHELL_NAME:-}" = "''${_PARENT_SHELL_NAME:-}" ]; then
          _nix_pkg=""
          if [ -n "''${_PARENT_PATH:-}" ]; then
            _nix_pkg=$(comm -23 \
              <(echo "$PATH" | tr ':' '\n' | grep '/nix/store/' | sort) \
              <(echo "''${_PARENT_PATH}" | tr ':' '\n' | grep '/nix/store/' | sort) \
              | head -1 | sed -E 's|/nix/store/[a-z0-9]{32}-||;s|/bin$||;s|-[0-9].*||')
          fi
          export SHELL_NAME="''${SHELL_NAME:+''${SHELL_NAME}>}''${_nix_pkg:-shell}"
          unset _nix_pkg
        fi
        export _HANDLED_SHLVL=$SHLVL
      fi
      export _PARENT_SHELL_NAME="''${SHELL_NAME:-}"
      export _PARENT_PATH="$PATH"

      function nix_shell() {
        if [ -n "''${SHELL_NAME:-}" ]; then
          echo " %{$fg[cyan]%}''${SHELL_NAME}%{$reset_color%}"
        fi
      }

      ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[green]%}"
      ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
      ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}!"
      ZSH_THEME_GIT_PROMPT_CLEAN=""

      PROMPT='%(?,,%{$fg[red]%}!%{$reset_color%} )%{$fg[blue]%}%~%{$reset_color%}$(git_prompt_info)$(nix_shell)
%{$fg[magenta]%}>%{$reset_color%} '

      RPROMPT=""
    '';

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };
}
