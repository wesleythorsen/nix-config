local cmp_nvim_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp.default_capabilities()

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
    -- Format keymap removed - now handled by conform.nvim

  vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts) -- show signatures as you type

  -- Normal mode: comment current line with Ctrl-k then c
  vim.keymap.set("n", "<C-k><C-c>", function()
    require("Comment.api").toggle.linewise.current()
  end, opts)

  -- Visual mode: comment selection with Ctrl-k then c
  vim.keymap.set("v", "<C-k><C-c>", function()
    local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
    vim.api.nvim_feedkeys(esc, "nx", false)
    require("Comment.api").toggle.linewise(vim.fn.visualmode())
  end, opts)
end

-- nvim-lspconfig v3 flow: configure via vim.lsp.config(), then enable.
-- TypeScript / JavaScript
vim.lsp.config("ts_ls", {
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Lua
vim.lsp.config("lua_ls", {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
    },
  },
})

-- Nix
vim.lsp.config("nixd", {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    nixd = {
      nixpkgs = { expr = 'import <nixpkgs> {}' },
      formatting = { command = { "nixfmt" } },
      options = {
        nixos = { expr = '(import <nixpkgs/nixos> { configuration = {}; }).options' },
      },
    },
  },
})

-- Activate the servers for their filetypes
vim.lsp.enable({ "ts_ls", "lua_ls", "nixd" })

-- Diagnostics UI
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Nerd Font v3–safe icons
-- local signs = { Error = "", Warn = "", Hint = "", Info = "" }
local signs = { Error = "", Warn = "", Hint = "", Info = "" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- Handy: open diagnostics on cursor
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { silent = true })
