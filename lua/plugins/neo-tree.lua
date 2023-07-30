local icons = require("icons")

require("neo-tree").setup({
  auto_clean_after_session_restore = true,
  close_if_last_window = true,                                       -- Close Neo-tree if it is the last window left in the tab
  enable_git_status = true,
  open_files_do_not_replace_types = { "terminal", "trouble", "qf" }, -- when opening files, do not use windows containing these filetypes or buftypes
  sort_case_insensitive = false,                                     -- used when sorting files and directories in the tree
  sources = { "filesystem", "buffers", "git_status" },
  source_selector = {
    winbar = true,
    separator = { left = '│ ', right = '' },
    sources = {
      { source = "filesystem", display_name = " " .. icons.files.File .. " File" },
      { source = "buffers",    display_name = icons.basic.Window .. " Bufs" },
      { source = "git_status", display_name = icons.git.Logo .. " Git" },
    },
  },
  default_component_configs = {
    container = {
      enable_character_fade = true
    },
    indent = { padding = 0 },
    icon = {
      folder_closed = icons.folders.Default,
      folder_open = icons.folders.Open,
      folder_empty = icons.folders.Empty,
      default = icons.files.Default,
    },
    modified = { symbol = "●" },
    name = {
      trailing_slash = false,
      use_git_status_colors = true,
      highlight = "NeoTreeFileName",
    },
    git_status = {
      symbols = {
        -- Change type
        added     = icons.git.Added,
        modified  = icons.git.Modified,
        deleted   = icons.git.Deleted, -- this can only be used in the git_status source
        renamed   = icons.git.Renamed, -- this can only be used in the git_status source
        -- Status type
        untracked = icons.git.Untracked,
        ignored   = icons.git.Ignored,
        unstaged  = icons.git.Unstaged,
        staged    = icons.git.Staged,
        conflict  = icons.git.Conflict,
      }
    },
  },
  -- A list of functions, each representing a global custom command
  -- that will be available in all sources (if not overridden in `opts[source_name].commands`)
  -- see `:h neo-tree-custom-commands-global`
  commands = {},
  window = {
    position = "left",
    width = 28,
    mapping_options = {
      noremap = true,
      nowait = true,
    },
    mappings = {
      ["<tab>"] = "toggle_node",
      ["<space>"] = { "toggle_preview", config = { use_float = true } },
      ["s"] = "open_split",
      ["v"] = "open_vsplit",
    }
  },
  filesystem = {
    filtered_items = {
      visible = false, -- when true, they will just be displayed differently than normal items
      hide_dotfiles = true,
      hide_gitignored = false,
      hide_hidden = true, -- only works on Windows for hidden files/directories
      hide_by_name = {
        ".git",
        "node_modules"
      },
      always_show = { -- remains visible even if other settings would normally hide it
        -- ".gitignore",
      },
      never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
        ".DS_Store",
        "thumbs.db"
      },
    },
    group_empty_dirs = true, -- when true, empty folders will be grouped together
  },
  buffers = {
    group_empty_dirs = true, -- when true, empty folders will be grouped together
  },
  git_status = {
    window = {
      mappings = {
        ["a"]  = "git_add_file",
        ["A"]  = "git_add_all",
        ["u"]  = "git_unstage_file",
        -- ["gr"] = "git_revert_file",
        ["c"]  = "git_commit",
        ["p"]  = "git_push",
        ["cp"] = "git_commit_and_push",
      }
    }
  },
})

-- 配色修改
vim.cmd([[highlight NeoTreeTabInactive ctermbg=0 guibg=0]])
vim.cmd([[highlight NeoTreeTabSeparatorInactive ctermbg=0 guibg=0 guifg=#6D7782]])
vim.cmd([[highlight NeoTreeTabSeparatorActive ctermbg=0 guibg=0 guifg=0]])