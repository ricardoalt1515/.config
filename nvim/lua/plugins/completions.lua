return {
  "saghen/blink.cmp",
  dependencies = {
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",
    "fang2hou/blink-copilot",
  },
  event = "InsertEnter",
  version = "1.*",
  opts = {
    snippets = { preset = "luasnip" },
    keymap = {
      preset = "enter",
      ["<Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.snippet_forward()
          else
            return cmp.select_next()
          end
        end,
        "fallback",
      },
      ["<S-Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.snippet_backward()
          else
            return cmp.select_prev()
          end
        end,
        "fallback",
      },
    },
    completion = {
      documentation = {
        auto_show = true,
        window = { border = "rounded" },
      },
      ghost_text = { enabled = true },
      menu = {
        border = "rounded",
        max_height = 12,
        draw = { treesitter = { "lsp" } },
      },
      list = { selection = { preselect = true } },
      accept = { auto_brackets = { enabled = true } },
    },
    fuzzy = { implementation = "lua" },
    signature = {
      enabled = true,
      window = {
        show_documentation = true,
        border = "rounded",
      },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "copilot" },
      per_filetype = {
        lua = { inherit_defaults = true, "lazydev" },
      },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
        lsp = {
          score_offset = 90,
        },
        path = {
          score_offset = 10,
        },
        snippets = {
          score_offset = -50,
          max_items = 4,
          min_keyword_length = 2,
        },
        buffer = {
          score_offset = -100,
          min_keyword_length = 3,
        },
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 50,
          async = true,
        },
      },
    },
  },
  config = function(_, opts)
    local ls = require("luasnip")

    ls.config.setup({
      region_check_events = "CursorMoved,CursorHold,InsertEnter",
      delete_check_events = "TextChanged",
      update_events = "TextChanged,TextChangedI",
      history = true,
      enable_autosnippets = true,
    })

    require("luasnip.loaders.from_vscode").lazy_load()
    require("blink.cmp").setup(opts)
    vim.api.nvim_set_hl(0, "BlinkCmpGhostText", { link = "Comment", italic = true })
  end,
}
