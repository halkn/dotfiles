
" Encoding
set fileencodings=utf-8
set fileformats=unix,dos,mac

" Don't creat swap files
set nobackup
set noswapfile
set noundofile

" Appearance
set wildmenu
set display=lastline
set laststatus=2
set cursorline
" set number
" set relativenumber
set wrap
set list
set listchars=tab:\ \ ,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
set scrolloff=8
set showtabline=0
set synmaxcol=512
set showcmd
set signcolumn=yes

" buffer
set hidden
set switchbuf=useopen

" edit
set smarttab
set expandtab
set autoindent
set shiftwidth=4
set shiftround
set tabstop=4
set virtualedit=block,onemore
set whichwrap=b,s,[,],<,>
set backspace=indent,eol,start

" window
set splitbelow
set splitright
set winwidth=30
set winheight=1
set cmdwinheight=5
set noequalalways

" search
set ignorecase
set smartcase
set incsearch
set hlsearch

" clipborad
set clipboard=unnamedplus

" Completion
set completeopt=preview,menuone,noinsert,noselect

" help
set helplang=ja,en

" grep
if executable('rg')
  let &grepprg = 'rg --vimgrep --hidden'
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

if has('nvim')
  set inccommand=split
endif
