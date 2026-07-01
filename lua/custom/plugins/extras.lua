local function gh(repo)
  return 'https://github.com/' .. repo
end

vim.pack.add {
  gh 'stevearc/oil.nvim', -- edit the filesystem like a buffer
  gh 'windwp/nvim-ts-autotag', -- auto close/rename HTML/JSX tags
  gh 'NvChad/nvim-colorizer.lua', -- inline color swatches
}

-- oil.nvim
require('mini.icons').setup()
require('oil').setup {
  view_options = { show_hidden = true },
}
vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

-- HTML/CSS development
require('nvim-ts-autotag').setup()
require('colorizer').setup { user_default_options = { css = true } }
