" reload vimrc
nnoremap <Space>s :source $MYVIMRC<CR>

" Clear search highlight
nnoremap <Esc><Esc> :nohlsearch<CR><Esc>

" Multi line move
noremap k gk
noremap j gj
noremap gk k
noremap gj j
noremap <Down> gj
noremap <Up> gk

" Move cursor like emacs in Insert Mode
inoremap <C-b> <Left>
inoremap <C-f> <Right>
inoremap <C-a> <C-o>^
inoremap <C-e> <End>
inoremap <C-d> <Del>

" Move cursor like emacs in Insert Mode
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-a> <HOME>
cnoremap <C-e> <END>

" Move cursor the begining and end of line
nnoremap H ^
nnoremap L $
vnoremap H ^
vnoremap L $

" Move between windows
nnoremap <tab>   <c-w>w
nnoremap <S-tab> <c-w>W

" Not yank is delete operation
nnoremap x "_x

" Disable s operation
nnoremap s <Nop>
vnoremap s <Nop>

" Indent in visual and select mode automatically re-selects.
vnoremap > >gv
vnoremap < <gv

" Quit the current window
nnoremap <silent> <C-q> :q<CR>
inoremap <silent> <C-q> <Esc>:q<CR>
tnoremap <silent> <C-q> <C-w>N:q!<CR>

" open termianl in vertial split,new tab,current winddow
nnoremap <silent> <Leader>ts :<C-u>terminal<CR>
nnoremap <silent> <Leader>tv :<C-u>vsplit <BAR> terminal ++curwin<CR>
nnoremap <silent> <Leader>tt :<C-u>tabnew <BAR> terminal ++curwin<CR>
nnoremap <silent> <Leader>tw :<C-u>terminal ++curwin<CR>

" Toggle options
nmap [Toggle] <Nop>
map <Leader>o [Toggle]
nnoremap <silent> [Toggle]n :<C-u>setlocal number! number?<CR>
nnoremap <silent> [Toggle]rn :<C-u>setlocal relativenumber! relativenumber?<CR>
nnoremap <silent> [Toggle]w :<C-u>setlocal wrap! wrap?<CR>
nnoremap <silent> [Toggle]p :<C-u>set paste! paste?<CR>

" Shortening for ++enc=
cnoreabbrev ++u ++enc=utf8
cnoreabbrev ++c ++enc=cp932
cnoreabbrev ++s ++enc=sjis

" quickfix
nnoremap <silent> [q :<C-u>cprev<CR>
nnoremap <silent> ]q :<C-u>cnext<CR>

function! ToggleQuickfix()
    let l:nr = winnr('$')
    cwindow
    let l:nr2 = winnr('$')
    if l:nr == l:nr2
        cclose
    endif
endfunction
nnoremap <script> <silent> Q :call ToggleQuickfix()<CR>
