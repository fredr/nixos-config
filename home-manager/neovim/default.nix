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

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    package = pkgs.unstable.neovim-unwrapped;

    plugins = with pkgs.vimPlugins; [
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
        config = ''
          require('copilot').setup({
            panel = {
              enabled = true,
              auto_refresh = false,
              keymap = {
                jump_prev = "[[",
                jump_next = "]]",
                accept = "<CR>",
                refresh = "gr",
                open = "<M-CR>"
              },
              layout = {
                position = "bottom", -- | top | left | right | horizontal | vertical
                ratio = 0.4
              },
            },
            suggestion = {
              enabled = true,
              auto_trigger = false,
              hide_during_completion = true,
              debounce = 75,
              keymap = {
                accept = "<M-l>",
                accept_word = false,
                accept_line = false,
                next = "<M-]>",
                prev = "<M-[>",
                dismiss = "<C-]>",
              },
            },
            filetypes = {
              yaml = false,
              markdown = false,
              help = false,
              gitcommit = false,
              gitrebase = false,
              hgcommit = false,
              svn = false,
              cvs = false,
              ["."] = false,
            },
            copilot_node_command = 'node', -- Node.js version must be > 18.x
            server_opts_overrides = {},
          })

          -- toggle whitespace
          vim.keymap.set('n', '<leader>tc', function()
            require("copilot.suggestion").toggle_auto_trigger()
          end, { desc = "[T]oggle [C]opilot" })
        '';
      }
      copilot-cmp
    ];

    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
