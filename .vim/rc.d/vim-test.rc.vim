let g:test#preserve_screen = 1
let test#strategy = "make_bang"
nnoremap <silent> <Leader>t :<C-u>TestFile<CR>
nnoremap <silent> TN :<C-u>TestNearest<CR>
nnoremap <silent> TF :<C-u>TestFile<CR>
nnoremap <silent> TS :<C-u>TestSuite<CR>
nnoremap <silent> TL :<C-u>TestLast<CR>
nnoremap <silent> TV :<C-u>TestVisit<CR>
