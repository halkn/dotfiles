local packer = nil
local function init()
  if packer == nil then
    packer = require('packer')
    packer.init({compile_path = vim.fn.stdpath('data') .. '/site/plugin/packer_compiled.vim',})
  end

  local use = packer.use
  packer.reset()

  -- Packer can manage itself as an optional plugin.
  use {
    'wbthomason/packer.nvim',
    opt = true,
    setup = function()
      vim.cmd("command! PackerInstall packadd packer.nvim | lua require('plugins').install()")
      vim.cmd("command! PackerUpdate packadd packer.nvim | lua require('plugins').update()")
      vim.cmd("command! PackerSync packadd packer.nvim | lua require('plugins').sync()")
      vim.cmd("command! PackerClean packadd packer.nvim | lua require('plugins').clean()")
      vim.cmd("command! PackerCompile packadd packer.nvim | lua require('plugins').compile()")
      vim.cmd("augroup vimrc_packer_nvim")
      vim.cmd("autocmd!")
      vim.cmd("autocmd BufWritePost plugins.lua PackerCompile")
      vim.cmd("augroup END")
    end
  }

  -- appearance
  use {
    'sainnhe/sonokai',
    setup = function()
      vim.api.nvim_command("packadd sonokai")
      vim.g.sonokai_transparent_background = 1
      vim.api.nvim_command("colorscheme sonokai")
    end
  }
  use {
    'itchyny/lightline.vim',
    requires = 'itchyny/vim-gitbranch',
    config = function()
      vim.g.lightline = {
        colorscheme = 'sonokai',
        tabline = {
          left = { {'tabs'} },
          right = { {'close'}, {'cwd', 'gitbranch' } }
        },
        active = {
          left = {
            {'mode', 'paste'},
            {'readonly', 'filename', 'modified'}
          },
          right = {
            {'lineinfo'},
            {'percent'},
            {'fileformat', 'fileencoding', 'filetype'}
          }
        },
        component_function = {
          gitbranch = 'gitbranch#name',
          cwd = 'getcwd'
        }
      }
    end
  }

  -- enhance
  use {
    'cohama/lexima.vim',
    config = function()
      vim.g.lexima_ctrlh_as_backspace = 1
    end
  }
  use {
    'kana/vim-operator-replace',
    requires = { 'kana/vim-operator-user' },
    config = function()
      vim.fn.nvim_set_keymap('', 'R', '<Plug>(operator-replace)', {noremap=false, silent=true})
    end
  }
  use { 'machakann/vim-sandwich' }
  use {
    'hrsh7th/vim-eft',
    config = function()
      local maps = {}
      local opt = {noremap=false, silent=true}
      maps[';'] = '<Plug>(eft-repeat)'
      maps['f'] = '<Plug>(eft-f)'
      maps['F'] = '<Plug>(eft-F)'
      maps['t'] = '<Plug>(eft-t)'
      maps['T'] = '<Plug>(eft-T)'
      for k, v in pairs(maps) do
        vim.fn.nvim_set_keymap('n', k, v, opt)
        vim.fn.nvim_set_keymap('x', k, v, opt)
        if k ~= ';' then
          vim.fn.nvim_set_keymap('o',k, v, opt)
        end
      end
    end
  }
  use {
    'tyru/columnskip.vim',
    config = function()
      local maps = {'n', 'o', 'x'}
      local opt = {noremap=false, silent=true}
      for _, v in pairs(maps) do
        vim.fn.nvim_set_keymap(v, 'sj', '<Plug>(columnskip:nonblank:next)', opt)
        vim.fn.nvim_set_keymap(v, 'sk', '<Plug>(columnskip:nonblank:prev)', opt)
      end

    end
  }
  use {
    'tyru/caw.vim',
    keys = {{'n', '<Leader>c'}, {'v', '<Leader>c'}},
    config = function()
      vim.fn.nvim_set_keymap('n', '<Leader>c', '<Plug>(caw:hatpos:toggle)', {noremap=false, silent=true})
      vim.fn.nvim_set_keymap('v', '<Leader>c', '<Plug>(caw:hatpos:toggle)', {noremap=false, silent=true})
    end
  }

  -- fuzzyfinder
  use {
    'nvim-telescope/telescope.nvim',
    requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}},
    cmd = 'Telescope',
    config = function()
      local actions = require('telescope.actions')
      require('telescope').setup {
        defaults = {
          layout_strategy = "flex",
          generic_sorter = require'telescope.sorters'.get_fzy_sorter,
          file_sorter = require'telescope.sorters'.get_fzy_sorter,
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--hidden'
          },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<esc>"] = actions.close,
            },
          },
        }
      }
    end,
    setup = function()
      local nmap = function(key, result)
        vim.fn.nvim_set_keymap('n', key, result, {noremap=true, silent=true})
      end
      nmap('<Leader>f', ':<C-u>Telescope find_files find_command=rg,--ignore,--hidden,--files<CR>')
      nmap('<Leader>b', ':<C-u>Telescope buffers<CR>')
      nmap('<Leader>R', ':<C-u>Telescope live_grep<CR>')
      nmap('<Leader>q', ':<C-u>Telescope quickfix<CR>')
      nmap('<Leader>ml', ':<C-u>Telescope find_files cwd=~/memo<CR>')
    end
  }

  -- git
  use {
    'lewis6991/gitsigns.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    setup = function()
      vim.api.nvim_command("packadd gitsigns.nvim")
      require('gitsigns').setup{
        signs = {
          add          = {hl = 'GitGutterAdd'   , text = '+'},
          change       = {hl = 'GitGutterChange', text = '!'},
          delete       = {hl = 'GitGutterDelete', text = '_'},
          topdelete    = {hl = 'GitGutterDelete', text = '‾'},
          changedelete = {hl = 'GitGutterChangeDelete', text = '~'},
        },
        keymaps = {
          noremap = true,
          buffer = true,
          ['n ]c'] = { expr = true, "&diff ? ']c' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'"},
          ['n [c'] = { expr = true, "&diff ? '[c' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'"},
          ['n <leader>ga'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
          ['n <leader>gr'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
          ['n <leader>gu'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
          ['n <leader>gs'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
        }
      }
    end
  }

  -- extension
  use {
    'skywind3000/asyncrun.vim',
    cmd = 'AsyncRun'
  }
  use {
    'glidenote/memolist.vim',
    cmd = {'MemoNew', 'MemoGrep', 'MemoList'},
    setup = function()
      vim.g.memolist_memo_suffix = 'md'
      vim.g.memolist_template_dir_path = '~/.config/nvim/template/memotemplates'
      vim.fn.nvim_set_keymap('n', '<Leader>mn', ':<C-u>MemoNew<CR>', {noremap=true, silent=true})
      vim.fn.nvim_set_keymap('n', '<Leader>mg', ':<C-u>MemoGrep<CR>', {noremap=true, silent=true})
    end
  }
  use {
    'simeji/winresizer',
    cmd = 'WinResizerStartResize',
    setup = function()
      vim.g.winresizer_start_key = '<C-w>r'
      vim.fn.nvim_set_keymap('n', '<C-w>r', ':<C-u>WinResizerStartResize<CR>', {noremap=true, silent=true})
    end
  }
  use {
    't9md/vim-quickhl',
    keys = {{'x', '<Leader>m'}, {'n', '<Leader>m'}},
    config = function()
      vim.fn.nvim_set_keymap('n', '<Leader>m', '<Plug>(quickhl-manual-this)', {noremap=false, silent=true})
      vim.fn.nvim_set_keymap('x', '<Leader>m', '<Plug>(quickhl-manual-this)', {noremap=false, silent=true})
      vim.fn.nvim_set_keymap('x', '<Leader>M', '<Plug>(quickhl-manual-reset)', {noremap=false, silent=true})
      vim.fn.nvim_set_keymap('x', '<Leader>M', '<Plug>(quickhl-manual-reset)', {noremap=false, silent=true})
    end
  }
  use { 'thinca/vim-qfreplace', cmd = 'Qfreplace' }

  -- go
  use {
    'kana/vim-altr',
    ft = 'go',
    config = function()
      vim.api.nvim_command("augroup vimrc_markdown_preview")
      vim.api.nvim_command("au!")
      vim.api.nvim_command("autocmd FileType go nmap <buffer> <LocalLeader>a <Plug>(altr-forward)")
      vim.api.nvim_command("autocmd FileType go nmap <buffer> <LocalLeader>a <Plug>(altr-back)")
      vim.api.nvim_command("augroup END")
      vim.api.nvim_command("filetype detect")
    end
  }

  -- markdown
  use {
    'iamcco/markdown-preview.nvim',
    cmd = 'MarkdownPreview',
    run = ':call mkdp#util#install()',
    config = function()
      vim.api.nvim_command("augroup vimrc_markdown_preview")
      vim.api.nvim_command("au!")
      vim.api.nvim_command("autocmd FileType markdown nnoremap <buffer> <silent> <LocalLeader>p :<C-u>MarkdownPreview<CR>")
      vim.api.nvim_command("augroup END")
      vim.api.nvim_command("filetype detect")
    end
  }
  use { 'mattn/vim-maketable',cmd = 'MakeTable' }

  -- Other
  use { 'tyru/capture.vim',cmd = 'Capture' }
  use { 'tweekmonster/startuptime.vim',cmd = 'StartupTime' }

  -- LSP & Completion
  use {
    'neovim/nvim-lspconfig',
    opt = true,
    requires = {{'RishabhRD/nvim-lsputils'}, {'RishabhRD/popfix'}},
    setup = function()
      require('lsp_config')
    end
  }
  use {'nvim-lua/completion-nvim',opt = true}
  -- use {'RishabhRD/nvim-lsputils',opt = true, requires = 'RishabhRD/popfix'}
  use {
    'hrsh7th/vim-vsnip',
    requires = 'hrsh7th/vim-vsnip-integ',
    event = 'InsertEnter *',
    config = function()
      vim.g.vsnip_snippet_dir = '~/.config/nvim/snippets'
      vim.fn.nvim_set_keymap('i', '<C-l>', 'vsnip#expandable() ? "<Plug>(vsnip-expand)" : "<C-l>"', {noremap=false, expr=true})
      vim.fn.nvim_set_keymap('s', '<C-l>', 'vsnip#expandable() ? "<Plug>(vsnip-expand)" : "<C-l>"', {noremap=false, expr=true})
      vim.fn.nvim_set_keymap('i', '<Tab>', 'vsnip#jumpable(1) ? "<Plug>(vsnip-jump-next)" : "<Tab>"', {noremap=false, expr=true})
      vim.fn.nvim_set_keymap('s', '<Tab>', 'vsnip#jumpable(1) ? "<Plug>(vsnip-jump-next)" : "<Tab>"', {noremap=false, expr=true})
      vim.fn.nvim_set_keymap('i', '<S-Tab>', 'vsnip#jumpable(-1) ? "<Plug>(vsnip-jump-prev)" : "<S-Tab>"', {noremap=false, expr=true})
      vim.fn.nvim_set_keymap('s', '<S-Tab>', 'vsnip#jumpable(-1) ? "<Plug>(vsnip-jump-prev)" : "<S-Tab>"', {noremap=false, expr=true})
    end
  }

end

local plugins = setmetatable({}, {
  __index = function(_, key)
    init()
    return packer[key]
  end
})

return plugins
