{ pkgs, ... }: {
  home.packages = with pkgs; [
    nixd
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
          config = ''
              lua << EOF
              require('lspconfig').rust_analyzer.setup{}
              require('lspconfig').lua_ls.setup{
                settings = {
                  Lua = {
                    diagnostics = {
                      globals = { "vim" },
                    },
                    telemetry = {
                      enable = false,
                    },
                  },
                },
              }
              require('lspconfig').nixd.setup{}
              EOF
          '';
      }

      nvim-cmp
      cmp-nvim-lsp
      cmp-path
      luasnip
      cmp_luasnip

      which-key-nvim

      telescope-nvim
      telescope-file-browser-nvim
      plenary-nvim

      nordic-nvim

      vim-nix
    ];

    extraLuaConfig = builtins.readFile(./init.lua);
  };
}
