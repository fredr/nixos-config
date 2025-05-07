{ pkgs, ... }: {
  home.packages = with pkgs; [
    gopls
    nixd
    nixpkgs-fmt
    lua-language-server
    # pick neovim from unstable to get 0.10
    unstable.neovim-unwrapped
    prettierd
  ];

  programs.neovim = let
    # see https://github.com/NixOS/nixpkgs/issues/402998
    neovim-unwrapped = pkgs.unstable.neovim-unwrapped.overrideAttrs(old: {
        meta = old.meta // {
            maintainers = old.meta.teams;
        };
    });
  in {
    enable = true;
    defaultEditor = true;

    package = neovim-unwrapped;

    plugins = with pkgs.unstable.vimPlugins; [
      vim-fugitive
      vim-rhubarb
      vim-sleuth
      {
        plugin = fidget-nvim;
        type = "lua";
        config = ''
          require("fidget").setup {}
        '';
      }
      {
        plugin = conform-nvim;
        type = "lua";
        config = ''
          require("conform").setup({
            formatters_by_ft = {
              javascript = { "prettierd" },
              typescript = { "prettierd" },
            },
            format_on_save = {
              timeout_ms = 500,
              lsp_fallback = true,
            },
          })
        '';
      }

      (nvim-treesitter.withPlugins (
        plugins: with plugins; [
          nix
          cpp
          go
          lua
          rust
          tsx
          javascript
          typescript
          bash
          markdown
          toml
          python
        ]
      ))
      nvim-treesitter-textobjects
      nvim-treesitter-context

      rust-vim
      rustaceanvim
      typescript-tools-nvim

      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = builtins.readFile ./lspconfig.lua;
      }

      {
        plugin = nvim-cmp;
        type = "lua";
        config = builtins.readFile ./cmp.lua;
      }
      cmp-nvim-lsp
      cmp-path
      luasnip
      cmp_luasnip
      cmp-vsnip

      {
        plugin = which-key-nvim;
        type = "lua";
        config = builtins.readFile ./which-key.lua;
      }

      {
        plugin = telescope-nvim;
        type = "lua";
        config = builtins.readFile ./telescope.lua;
      }
      telescope-file-browser-nvim
      telescope-fzf-native-nvim
      plenary-nvim

      nordic-nvim

      vim-nix
      {
        plugin = crates-nvim;
        type = "lua";
        config = ''
          require('crates').setup()
        '';
      }

      {
        plugin = copilot-lua;
        type = "lua";
        config = builtins.readFile ./copilot.lua;
      }
      {
        plugin = CopilotChat-nvim;
        type = "lua";
        config = builtins.readFile ./copilot-chat.lua;
      }
      copilot-cmp
      {
        plugin = render-markdown-nvim;
        type = "lua";
        config = ''
          vim.filetype.add({
            extension = { mdx = 'markdown' }
          })

          require('render-markdown').setup({
            file_types = { 'markdown', 'copilot-chat' }
          })
        '';
      }
    ];

    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
