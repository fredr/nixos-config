{ pkgs, ... }:
{
  home.packages = with pkgs; [
    unstable.package-version-server
    mypkgs.cargotom
    mypkgs.protobuf-language-server
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "toml"
      "lua"
      "cargo-tom"
      "catppuccin"
      "catppuccin-icons"
      "proto"
      "dockerfile"
    ];

    package = pkgs.unstable.zed-editor;

    userSettings = {
      auto_update = false;

      vim_mode = true;
      load_direnv = "shell_hook";
      relative_line_numbers = true;
      show_whitespaces = "all";
      ui_font_size = 16;
      buffer_font_size = 16;
      hour_format = "hour24";

      telemetry = {
        metrics = false;
      };

      diagnostics = {
        inline = {
          enabled = true;
        };
      };

      preview_tabs = {
        enabled = true;
        enable_preview_from_file_finder = true;
        enable_preview_from_code_navigation = true;
      };

      lsp = {
        nixd = {
          binary = {
            path = "${pkgs.nixd}/bin/nixd";
          };
        };
        rust-analyzer = {
          binary = {
            path = "${pkgs.rustup}/bin/rust-analyzer";
          };

          initialization_options = {
            inlayHints = {
              maxLength = null;
              lifetimeElisionHints = {
                enable = "always";
                useParameterNames = true;
              };
              closureReturnTypeHints = {
                enable = "always";
              };
            };
            rust = {
              analyzerTargetDir = "/home/fredr/rust-analyzer/rust-analyzer-check";
            };
            diagnostics = {
              experimental = {
                enable = false;
              };
            };
            check = {
              command = "clippy";
            };
            cargo = {
              allFeatures = true;
              autoreload = true;
              runBuildScripts = true;
            };
          };
        };
        gopls = {
          binary = {
            path = "${pkgs.gopls}/bin/gopls";
          };
        };
        package-version-server = {
          binary = {
            path = "${pkgs.unstable.package-version-server}/bin/package-version-server";
          };
        };
        cargo-tom = {
          binary = {
            path = "${pkgs.mypkgs.cargotom}/bin/cargotom";
            arguments = [ "--storage" "/home/fredr/.cargo-tom" ];
          };
        };
        protobuf-language-server = {
          binary = {
            path = "${pkgs.mypkgs.protobuf-language-server}/bin/protobuf-language-server";
          };
        };
      };

      languages = {
        Nix = {
          language_servers = [ "nixd" "!nil" ];
          formatter = {
            external = {
              command = "nixpkgs-fmt";
            };
          };
        };
      };

      assistant = {
        enabled = true;
        version = "2";
        default_open_ai_model = null;
        default_model = {
          provider = "anthropic";
          model = "claude-opus-4-latest";
        };
      };

      edit_predictions = {
        mode = "subtle";
      };

      theme = {
        mode = "system";
        dark = "Catppuccin Macchiato";
        light = "Catppuccin Latte";
      };
      icon_theme = {
        mode = "system";
        dark = "Catppuccin Macchiato";
        light = "Catppuccin Latte";
      };
    };
  };
}
