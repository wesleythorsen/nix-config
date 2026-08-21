local cmp = require("cmp")

cmp.setup({
  snippet = {
    expand = function(args) require("luasnip").lsp_expand(args.body) end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    ["<Tab>"]     = cmp.mapping.select_next_item(),
    ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
    ["<C-f>"]     = cmp.mapping.scroll_docs(4),
    ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "nvim_lsp_signature_help" },
    { name = "luasnip" },
    { name = "buffer", keyword_length = 1 },
    { name = "path" },
  }),
  performance = { max_view_entries = 200 },
  experimental = { ghost_text = true },
})

-- auto-trigger completion & signature when you type "("
vim.api.nvim_create_autocmd("TextChangedI", {
  pattern = "*",
  callback = function()
    local col = vim.fn.col('.') - 1
    if col > 0 and vim.fn.getline('.'):sub(col, col) == "(" then
      require("cmp").complete()
    end
  end,
})