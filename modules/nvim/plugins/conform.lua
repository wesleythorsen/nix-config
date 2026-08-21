-- Conform.nvim configuration for ESLint and Prettier formatting
-- This replaces LSP formatting with the same tools VSCode uses

require("conform").setup({
  formatters_by_ft = {
    -- JavaScript/TypeScript files
    javascript = { "prettier", "eslint" },
    javascriptreact = { "prettier", "eslint" },
    typescript = { "prettier", "eslint" },
    typescriptreact = { "prettier", "eslint" },
    
    -- JSON files
    json = { "prettier" },
    jsonc = { "prettier" },
    
    -- CSS/HTML
    css = { "prettier" },
    html = { "prettier" },
    
    -- Markdown
    markdown = { "prettier" },
    
    -- Lua (using LSP formatter since it works well)
    lua = { "stylua" },
    
    -- Nix
    nix = { "nixfmt" },
  },
  
  -- Format on save (like VSCode)
  format_on_save = {
    timeout_ms = 3000,
    lsp_fallback = true,
  },
  
  -- Formatters configuration
  formatters = {
    eslint = {
      -- Run ESLint fix on the file
      command = "eslint",
      args = { "--fix", "--stdin", "--stdin-filename", "$FILENAME" },
      stdin = true,
      cwd = require("conform.util").root_file({ "package.json", ".eslintrc.js", ".eslintrc.json" }),
    },
    prettier = {
      -- Use project's Prettier config
      command = "prettier",
      args = { "--stdin-filepath", "$FILENAME" },
      stdin = true,
      cwd = require("conform.util").root_file({ "package.json", ".prettierrc", ".prettierrc.json", ".prettierrc.js" }),
    },
  },
  
  -- Notification settings
  notify_on_error = true,
  notify_no_formatters = false,
})

-- Override the LSP format keymap to use conform instead
vim.keymap.set("n", "<leader>f", function()
  require("conform").format({
    async = true,
    lsp_fallback = true,
  })
end, { desc = "Format buffer with conform (prettier/eslint)" })

-- -- Additional keymaps for specific formatters
-- vim.keymap.set("n", "<leader>lf", function()
--   require("conform").format({
--     formatters = { "eslint" },
--     async = true,
--   })
-- end, { desc = "Fix with ESLint only" })

-- vim.keymap.set("n", "<leader>pf", function()
--   require("conform").format({
--     formatters = { "prettier" },
--     async = true,
--   })
-- end, { desc = "Format with Prettier only" })