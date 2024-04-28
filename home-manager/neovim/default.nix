{ pkgs, ... }: {
  home.packages = with pkgs; [
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
        config = ''
          lua << EOF
          local on_attach = function(_, bufnr)
            local nmap = function(keys, func, desc)
              if desc then
                desc = 'LSP: ' .. desc
              end

              vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
            end

            nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
            nmap('<leader>ca', function()
              vim.lsp.buf.code_action { context = { only = { 'quickfix', 'refactor', 'source' } } }
            end, '[C]ode [A]ction')

            nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
            nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
            nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
            nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
            nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
            nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

            -- See `:help K` for why this keymap
            nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
            nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

            -- Lesser used LSP functionality
            nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
            nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
            nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
            nmap('<leader>wl', function()
              print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, '[W]orkspace [L]ist Folders')

            -- Create a command `:Format` local to the LSP buffer
            vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
              vim.lsp.buf.format()
            end, { desc = 'Format current buffer with LSP' })
          end
          require('lspconfig').rust_analyzer.setup{
            on_attach = on_attach,
          }
          require('lspconfig').lua_ls.setup{
            on_attach = on_attach,
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
          require('lspconfig').nixd.setup{
            on_attach = on_attach,
          }
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

    extraLuaConfig = builtins.readFile (./init.lua);
  };
}
