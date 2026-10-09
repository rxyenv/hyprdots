 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#141318',
    base01 = '#201f25',
    base02 = '#2a292f',
    base03 = '#928f99',
    base04 = '#c9c5d0',
    base05 = '#e5e1e9',
    base06 = '#e5e1e9',
    base07 = '#e5e1e9',
    base08 = '#ffb4ab',
    base09 = '#ecb8ce',
    base0A = '#c8c3dc',
    base0B = '#c7bfff',
    base0C = '#ecb8ce',
    base0D = '#c7bfff',
    base0E = '#c8c3dc',
    base0F = '#93000a',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#e5e1e9',          bg = '#141318' })
  hi('TelescopeBorder',         { fg = '#928f99',             bg = '#141318' })
  hi('TelescopePromptNormal',   { fg = '#e5e1e9',          bg = '#141318' })
  hi('TelescopePromptBorder',   { fg = '#928f99',             bg = '#141318' })
  hi('TelescopePromptPrefix',   { fg = '#c7bfff',             bg = '#141318' })
  hi('TelescopePromptCounter',  { fg = '#c9c5d0',  bg = '#141318' })
  hi('TelescopePromptTitle',    { fg = '#141318',             bg = '#c7bfff' })
  hi('TelescopePreviewTitle',   { fg = '#141318',             bg = '#c8c3dc' })
  hi('TelescopeResultsTitle',   { fg = '#141318',             bg = '#ecb8ce' })
  hi('TelescopeSelection',      { fg = '#e5e1e9',          bg = '#2a292f' })
  hi('TelescopeSelectionCaret', { fg = '#c7bfff',             bg = '#2a292f' })
  hi('TelescopeMatching',       { fg = '#c7bfff',             bold = true })
end

-- Keep one watcher across module reloads.
if not _G.zen0x_matugen_signal then
  local signal = vim.uv.new_signal()
  _G.zen0x_matugen_signal = signal
  signal:start('sigusr1', vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end))
  vim.api.nvim_create_autocmd('VimLeavePre', {
    once = true,
    callback = function() signal:stop(); signal:close() end,
  })
end
return M
