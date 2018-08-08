"##############################################################################
" Setiing
"##############################################################################
" setting
"文字コードをUFT-8に設定
set fenc=utf-8
" バックアップファイルを作らない
set nobackup
" スワップファイルを作らない
set noswapfile
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden
" 入力中のコマンドをステータスに表示する
set showcmd

" View
" 行番号を表示
set number
" 現在の行を強調表示
set cursorline
" 現在の行を強調表示（縦）
"set cursorcolumn
" 行末の1文字先までカーソルを移動できるように
set virtualedit=onemore
" カーソルの回り込み
set whichwrap=b,s,[,],<,>
" インデントはスマートインデント
set smartindent
" ビープ音を可視化
set visualbell
" 括弧入力時の対応する括弧を表示
set showmatch
" ステータスラインを常に表示
set laststatus=2
" コマンドラインの補完
set wildmode=list:longest
" 折り返し時に表示行単位での移動できるようにする
nnoremap j gj
nnoremap k gk
" カーソルの位置をつねに表示
set ruler

" Tab
" 不可視文字を可視化(タブが「▸-」と表示される)
set list listchars=tab:\▸\-
" Tab文字を半角スペースにする
set expandtab
" 行頭以外のTab文字の表示幅（スペースいくつ分）
set tabstop=4
" 行頭でのTab文字の表示幅
set shiftwidth=4

" Search
" 検索文字列が小文字の場合は大文字小文字を区別なく検索する
set ignorecase
" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase
" 検索文字列入力時に順次対象文字列にヒットさせる
set incsearch
" 検索時に最後まで行ったら最初に戻る
set wrapscan
" 検索語をハイライト表示
set hlsearch
" ESC連打でハイライト解除
nmap <Esc><Esc> :nohlsearch<CR><Esc>

" Edit
" バックスペースを、空白、行末、行頭でも使えるようにする
set backspace=indent,eol,start

" Share clipborad with system
set clipboard+=unnamedplus

"##############################################################################
"Dein.vim、プラグイン設定
"##############################################################################
" CACHE define
let $CACHE = expand('~/.cache')
if !isdirectory(expand($CACHE))
  call mkdir(expand($CACHE), 'p')
endif

if &compatible
 set nocompatible
endif
" Add the dein installation directory into runtimepath
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

" Load dein
let s:dein_dir = expand('$CACHE/dein')
if dein#load_state(s:dein_dir)
 call dein#begin(s:dein_dir)
 call dein#load_toml('~/.vim/rc/dein.toml',          {'lazy': 0})
 call dein#load_toml('~/.vim/rc/dein_lazy.toml',     {'lazy': 1})
 call dein#load_toml('~/.vim/rc/dein_neo.toml',      {'lazy': 1})
 call dein#load_toml('~/.vim/rc/dein_python.toml',   {'lazy': 1})

 "call dein#add('$CACHE/dein')
 "call dein#add('Shougo/deoplete.nvim')
 "if !has('nvim')
 "  call dein#add('roxma/nvim-yarp')
 "  call dein#add('roxma/vim-hug-neovim-rpc')
 "endif

 "VIM内でシェル実行
 "call dein#add('Shougo/vimshell')

 "vim-quickrun
 "call dein#add('thinca/vim-quickrun')

 "python
 "call dein#add('davidhalter/jedi-vim')

 "call dein#add('scrooloose/nerdtree')

 call dein#end()
 call dein#save_state()
endif

" 未インストールのplug-inがあれば自動でインストール
if dein#check_install()
  call dein#install()
endif

filetype plugin indent on
syntax enable

" colorscheme 
colorscheme iceberg
