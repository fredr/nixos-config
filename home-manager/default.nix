{ pkgs, inputs, ... }:
let
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
  colorscheme = inputs.nix-colors.colorSchemes.ayu-dark;
in
{
  imports = [
    ./firefox.nix
    ./sway
    ./git.nix
    ./alacritty.nix
    ./neovim
    ./zsh.nix
    ./gcloud.nix
  ];

  home.username = "fredr";
  home.homeDirectory = "/home/fredr";

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  home.packages = with pkgs; [
    ripgrep
    jq
    yq-go
    eza
    fzf

    which
    tree
    btop
    lsof

    slack
    discord
    zulip

    dconf
    grim
    slurp
    dmenu
    kalker

    font-awesome
    powerline-fonts
    powerline-symbols
    nerdfonts

    kubectl
    kubectx
    dive
    websocat
    dig

    openssl
    gnumake
    pkg-config
    protobuf
    cmake
    gcc
    llvm
    rustup
    pkgsCross.mingwW64.windows.pthreads
    pkgsCross.mingwW64.windows.mcfgthreads
    (pkgsCross.mingwW64.stdenv.cc.override
      {
        extraBuildCommands = ''printf '%s ' '-L${pkgsCross.mingwW64.windows.mcfgthreads}/lib' >> $out/nix-support/cc-ldflags'';
      })
    go
    nodejs_22
    nodePackages.pnpm
    nodePackages.yarn
    nodePackages.vercel
    python3
    typescript

    drm_info

    gimp
    obsidian
    pavucontrol
    unstable.zed-editor
    obs-studio
    mplayer
  ];

  home.file.".config/dive/config.yaml".text = ''
    container-engine: podman
    source: podman
  '';

  home.file.".config/zed/settings.json".text = ''
    {
      "ui_font_size": 16,
      "buffer_font_size": 16,
      "vim_mode": true,
      "auto_update": false,
      "relative_line_numbers": true,
      "lsp": {
        "gopls": {
          "binary": {
            "path": "${pkgs.gopls}/bin/gopls"
          },
        },
        "rust-analyzer": {
          "initialization_options": {
            "completion": {
              "snippets": {
                "Arc::new": {
                    "postfix": "arc",
                    "body": ["Arc::new(''${receiver})"],
                    "requires": "std::sync::Arc",
                    "scope": "expr"
                },
                "Some": {
                    "postfix": "some",
                    "body": ["Some(''${receiver})"],
                    "scope": "expr"
                },
                "Ok": {
                    "postfix": "ok",
                    "body": ["Ok(''${receiver})"],
                    "scope": "expr"
                },
              },
            },
            "rust": {
              "analyzerTargetDir": true,
            },
            "check": {
              "command": "clippy"
            }
          },
          "binary": {
            "path": "${pkgs.rust-analyzer}/bin/rust-analyzer"
          }
        }
      }
    }
  '';

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.atuin.enable = true;
  programs.atuin.settings = {
    filter_mode = "session";
    style = "compact";
    show_preview = true;
    enter_accept = false;
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
    settings.editor = "nvim";
  };

  fonts.fontconfig.enable = true;

  gtk = {
    enable = true;

    theme = {
      name = colorscheme.slug;
      package = gtkThemeFromScheme { scheme = colorscheme; };
    };

    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.stateVersion = "24.05";

  # Home manager manages home manager
  programs.home-manager.enable = true;
}
