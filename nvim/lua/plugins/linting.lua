-- Linting configuration using nvim-lint
-- Provides additional linting beyond LSP diagnostics

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      local lint = require("lint")

      -- Register Biome linter (needs explicit definition for nvim-lint)
      lint.linters.biome = {
        cmd = "biome",
        stdin = true,
        args = { "lint", "--stdin-file-path", "$FILENAME" },
        parser = "json",
        stream = "stdout",
        ignore_exitcode = true,
      }

      -- Define linters for each file type
      lint.linters_by_ft = {
        -- JavaScript/TypeScript
        javascript = { "biome" },
        typescript = { "biome" },
        javascriptreact = { "biome" },
        typescriptreact = { "biome" },
        -- Python
        python = { "ruff" },
        -- Lua
        lua = { "luacheck" },
      }

      -- Create autocmd to run linter on save and on change
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })

      -- Optional: Create command to lint manually
      vim.api.nvim_create_user_command("Lint", function()
        lint.try_lint()
      end, { desc = "Run linter for current buffer" })
    end,
  },
}
