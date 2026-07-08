-- LSP Configuration using Neovim 0.11+ native APIs
-- vim.lsp.config() + vim.lsp.enable() instead of deprecated require('lspconfig')
-- Integrates Mason for automatic server/tool installation

return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = { "${3rd}/luv/library" },
    },
  },

  -- Main LSP Configuration
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      { "mason-org/mason-lspconfig.nvim" },
      { "WhoIsSethDaniel/mason-tool-installer.nvim" },
      { "j-hui/fidget.nvim", opts = {} },
      { "saghen/blink.cmp" },
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Diagnostic signs
      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      vim.diagnostic.config({
        severity_sort = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        float = {
          source = "if_many",
          border = "rounded",
        },
        virtual_text = {
          source = "if_many",
          spacing = 2,
        },
      })

      -- Server configurations
      local servers = {
        -- JavaScript/TypeScript
        ts_ls = {},
        -- Angular
        angularls = {
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("angular.json", "project.json")(fname)
          end,
        },
        -- Lua
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              completion = { callSnippet = "Replace" },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
              },
            },
          },
        },
        -- JSON
        jsonls = {
          settings = {
            json = {
              validate = { enable = true },
            },
          },
        },
        -- Python
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
              },
            },
          },
        },
        -- Go
        gopls = {
          settings = {
            gopls = {
              completeUnimported = true,
              usePlaceholders = true,
              analyses = {
                unusedparams = true,
              },
            },
          },
        },
        -- TailwindCSS
        tailwindcss = {},
        -- GraphQL
        graphql = {},
      }

      -- Setup Mason (install LSP servers + tools)
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
      })
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- Formatters
          "biome", -- JavaScript/TypeScript formatter & linter
          "prettier", -- Markdown/GraphQL formatter
          "ruff", -- Python linter/formatter
          "stylua", -- Lua formatter
          "goimports", -- Go imports/format
          "sql-formatter", -- SQL formatter (used by conform)
          -- Linters
          "luacheck", -- Lua linter
        },
        auto_update = false,
        run_on_start = true,
      })

      -- Configure and enable all servers
      for server_name, config in pairs(servers) do
        vim.lsp.config(server_name, vim.tbl_extend("force", { capabilities = capabilities }, config))
        vim.lsp.enable(server_name)
      end

      -- LSP Keybindings and features
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          local fzf = require("fzf-lua")

          -- Navigation (using fzf-lua)
          vim.keymap.set("n", "gd", fzf.lsp_definitions, opts)
          vim.keymap.set("n", "gi", fzf.lsp_implementations, opts)
          vim.keymap.set("n", "gr", fzf.lsp_references, opts)
          vim.keymap.set("n", "<leader>D", fzf.lsp_typedefs, opts)
          vim.keymap.set("n", "<leader>ds", fzf.lsp_document_symbols, opts)
          vim.keymap.set("n", "<leader>ws", fzf.lsp_workspace_symbols, opts)

          -- Hover
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

          -- Rename
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

          -- Diagnostics
          vim.keymap.set("n", "<leader>d", function()
            vim.diagnostic.open_float({ border = "rounded" })
          end, opts)

          -- Code actions
          vim.keymap.set({ "n", "x" }, "<leader>ca", function()
            vim.lsp.buf.code_action()
          end, { noremap = true, silent = true, buffer = ev.buf })

          -- Document Highlight
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, ev.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = ev.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = ev.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- Toggle Inlay Hints
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, ev.buf) then
            vim.keymap.set("n", "<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }))
            end, { buffer = ev.buf, desc = "Toggle Inlay Hints" })
          end
        end,
      })

      -- TypeScript-specific formatting with unused import removal
      vim.keymap.set("n", "<leader>f", function()
        local filetype = vim.bo.filetype
        if filetype == "typescript" or filetype == "typescriptreact" then
          -- Remove unused imports first
          vim.lsp.buf.code_action({
            apply = true,
            context = { only = { "source.removeUnused.ts" }, diagnostics = {} },
          })
          -- Wait 100ms and then format
          vim.defer_fn(function()
            vim.lsp.buf.format({ timeout_ms = 10000 })
          end, 100)
        else
          -- For other filetypes, just format
          vim.lsp.buf.format({ timeout_ms = 10000 })
        end
      end, { noremap = true, silent = true, desc = "Format with cleanup (TS)" })
    end,
  },
}
