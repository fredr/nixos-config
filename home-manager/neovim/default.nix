{ pkgs, ... }: {
  home.packages = with pkgs; [
    gopls
    nixd
    nixfmt
    lua-language-server
  ];

  programs.neovim =
    let
      # see https://github.com/NixOS/nixpkgs/issues/402998
      neovim-unwrapped = pkgs.unstable.neovim-unwrapped.overrideAttrs (old: {
        meta = old.meta // {
          maintainers = old.meta.teams;
        };
      });
    in
    {
      enable = true;
      defaultEditor = true;

      package = neovim-unwrapped;

      withRuby = false;

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
          plugin = render-markdown-nvim;
          type = "lua";
          config = ''
            vim.filetype.add({
              extension = { mdx = 'markdown' }
            })

            require('render-markdown').setup({
              file_types = { 'markdown' }
            })
          '';
        }
      ];

      initLua = builtins.readFile ./init.lua;
    };
}
