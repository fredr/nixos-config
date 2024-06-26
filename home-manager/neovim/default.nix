{ pkgs, ... }: {
  home.packages = with pkgs; [
    gopls
    nixd
    nixpkgs-fmt
    lua-language-server
    # pick neovim from unstable to get 0.10
    unstable.neovim-unwrapped
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
    ];

    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
