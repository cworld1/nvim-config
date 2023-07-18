-- ----- 主设置 ----- --
require("core.options")
require("core.keymaps")

-- ----- 插件 ----- --
require("plugins.init")
require("plugins.plugins")

-- 主题
-- github-nvim-theme
require("plugins.github-theme")
-- transparent.nvim
require("plugins.transparent")

-- 模块
-- 底栏：lualine.nvim
require("plugins.lualine")
-- 侧栏：nvim-tree.lua
require("plugins.nvim-tree")
-- 顶栏：bufferline
require("plugins.bufferline")

-- 主窗口
-- 语法高亮：nvim-treesitter
require("plugins.treesitter")
-- LSP 基础：lsp
require("plugins.lsp")
-- LSP 增强：lspsaga
require("plugins.lspsaga")
-- 填充提示：lsp-signature
require("plugins.lsp-signature")
-- 自动补全：cmp
require("plugins.cmp")
-- 快速注释：comment
require("plugins.comment")
-- 自动补全括号：autopairs
require("plugins.autopairs")
-- 颜色识别：nvim-colorizer.lua
require("plugins.colorizer")

-- 辅助工具
-- Git 标记：gitsigns
require("plugins.gitsigns")
-- 文件/内容检索：telescope
require("plugins.telescope")
