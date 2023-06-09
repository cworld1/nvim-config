local bufferline = require('bufferline')

bufferline.setup {
  options = {
    style_preset = bufferline.style_preset.no_italic,
    -- 使用 nvim 内置lsp
    diagnostics = "nvim_lsp",
    -- 左侧让出 nvim-tree 的位置
    offsets = {{
      filetype = "NvimTree",
      text = " File Explorer",
      highlight = "Directory",
      text_align = "left",
      separator = true
    }},
    -- 分隔样式
    indicator = {
      icon = ' ', -- this should be omitted if indicator style is not 'icon'
      style = 'icon',
    },
    -- hover 显示关闭按钮
    -- hover = {
    --   enabled = true,
    --   delay = 200,
    --   reveal = {'close'}
    -- },
    show_buffer_icons = true, -- disable filetype icons for buffers
    show_buffer_close_icons = true,
  },

  highlights = {
    fill = {
      fg = "#539BF5",
      bg = "NONE"
    }
  }
}
