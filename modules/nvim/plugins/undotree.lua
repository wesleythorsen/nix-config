-- UndoTree configuration
-- UndoTree provides a visual tree of your undo history

-- Toggle UndoTree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- UndoTree configuration
vim.g.undotree_WindowLayout = 2          -- Layout style
vim.g.undotree_SplitWidth = 35           -- Width of undo tree window
vim.g.undotree_DiffpanelHeight = 10      -- Height of diff panel
vim.g.undotree_SetFocusWhenToggle = 1    -- Focus undo tree when opened
vim.g.undotree_ShortIndicators = 1       -- Use short indicators