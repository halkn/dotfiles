return {
  src = 'monaqa/dial.nvim',
  config = function()
    local augend = require('dial.augend')
    require('dial.config').augends:register_group({
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.constant.alias.bool,
        augend.date.alias['%Y/%m/%d'],
        augend.date.alias['%Y-%m-%d'],
        augend.date.alias['%H:%M'],
        augend.date.alias['%Y年%-m月%-d日'],
        augend.date.alias['%Y年%-m月%-d日(%ja)'],
        augend.constant.alias.ja_weekday,
        augend.constant.alias.ja_weekday_full,
      },
    })
    vim.keymap.set({ 'n', 'x' }, '<C-a>', '<Plug>(dial-increment)')
    vim.keymap.set({ 'n', 'x' }, '<C-x>', '<Plug>(dial-decrement)')
    vim.keymap.set({ 'n', 'x' }, 'g<C-a>', 'g<Plug>(dial-increment)')
    vim.keymap.set({ 'n', 'x' }, 'g<C-x>', 'g<Plug>(dial-decrement)')
  end,
}
