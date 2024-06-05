{ pkgs, ... }: {
  home.packages = with pkgs; [
    gopls
    nixd
    nixpkgs-fmt
    lua-language-server
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      vim-fugitive
      vim-rhubarb
      vim-sleuth

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
    ];

    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
