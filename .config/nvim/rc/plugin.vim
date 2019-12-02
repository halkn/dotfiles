scriptencoding utf-8

call plug#begin(expand('$XDG_DATA_HOME/nvim/plugged'))
" ----------------------------------------------------------------------------
" Appearance
Plug 'itchyny/lightline.vim'
Plug 'halkn/tender.vim'
" Plug 'morhetz/gruvbox'
Plug 'sainnhe/gruvbox-material'
Plug 'sheerun/vim-polyglot'
" ----------------------------------------------------------------------------
" Edit
Plug 'tpope/vim-commentary'
Plug 'machakann/vim-sandwich'
Plug 'kana/vim-operator-user'
Plug 'kana/vim-operator-replace', { 'on' : '<Plug>(operator-replace)' }
Plug 'junegunn/vim-easy-align', { 'on': '<Plug>(EasyAlign)' }
" ----------------------------------------------------------------------------
" Dev
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'liuchengxu/vista.vim', { 'on': ['Vista', 'Vista!!'] }
" Git
Plug 'mhinz/vim-signify', { 'on': 'SignifyToggle' }
Plug 'tpope/vim-fugitive', {
  \ 'on': ['Git', 'Gcommit', 'Gstatus', 'Gdiff', 'Gblame', 'Glog']
  \ }
" snippets
Plug 'mattn/sonictemplate-vim', { 'on' : 'Template' }
Plug 'honza/vim-snippets'
" markdown
Plug 'dhruvasagar/vim-table-mode', { 'for' : 'markdown' }
Plug 'mattn/vim-maketable', { 'for' : 'markdown' }
Plug 'iamcco/markdown-preview.nvim', {
  \ 'do': { -> mkdp#util#install() },
  \ 'for': 'markdown'
  \ }
" ----------------------------------------------------------------------------
" Util
Plug 'simeji/winresizer', { 'on': 'WinResizerStartResize' }
Plug 'itchyny/calendar.vim', { 'on' : 'Calendar' }
Plug 'glidenote/memolist.vim', { 'on': ['MemoNew','MemoList','MemoGrep'] }
Plug 'Yggdroot/indentLine', { 'on': 'IndentLinesToggle' }
Plug 'voldikss/vim-floaterm'
call plug#end()

let s:script_cwd = expand('<sfile>:p:h')
for s:path in split(glob(s:script_cwd . '/plug-conf/*.rc.vim'), "\n")
  exe 'source ' . s:path
endfor

unlet s:script_cwd
unlet s:path
