{ pkgs, ... }: {
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


      nvim-lspconfig
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
    ];

    extraLuaConfig = builtins.readFile(./init.lua);
  };
}