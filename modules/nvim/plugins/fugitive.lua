-- Git Fugitive configuration and keymaps
-- Fugitive is already loaded by default, this file adds useful keymaps
-- Using <leader>g prefix for git commands (avoiding conflicts with LSP)

-- Git status
vim.keymap.set("n", "<leader>gs", vim.cmd.Git)

-- Git blame
vim.keymap.set("n", "<leader>gb", ":Git blame<CR>")

-- Git log
vim.keymap.set("n", "<leader>gl", ":Git log<CR>")

-- Git diff (using gD instead of gd to avoid LSP conflict)
vim.keymap.set("n", "<leader>gD", ":Gdiffsplit<CR>")

-- Git add current file
vim.keymap.set("n", "<leader>ga", ":Git add %<CR>")

-- Git commit
vim.keymap.set("n", "<leader>gc", ":Git commit<CR>")

-- Git push
vim.keymap.set("n", "<leader>gp", ":Git push<CR>")

-- Git pull  
vim.keymap.set("n", "<leader>gP", ":Git pull<CR>")

-- Git checkout
vim.keymap.set("n", "<leader>go", ":Git checkout<Space>")

-- Git branch
vim.keymap.set("n", "<leader>gB", ":Git branch<Space>")

-- Navigate merge conflicts
vim.keymap.set("n", "<leader>gh", "<cmd>diffget //2<CR>")  -- Get from left (ours)
vim.keymap.set("n", "<leader>gL", "<cmd>diffget //3<CR>")  -- Get from right (theirs)

-- Quick git shortcuts for common workflows
vim.keymap.set("n", "<leader>gw", ":Git add . | Git commit<CR>")  -- Add all and commit