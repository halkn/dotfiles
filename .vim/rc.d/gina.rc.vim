" status
call gina#custom#command#option(
  \ 'status',
  \ '-s|--short'
  \ )
call gina#custom#command#option(
  \ 'status',
  \ '-b|--branch'
  \ )
call gina#custom#mapping#nmap(
  \ 'status', '<Space>',
  \ ':<C-u>Gina commit<CR>',
  \ {'noremap': 1, 'silent': 1}
  \ )
call gina#custom#mapping#nmap(
  \ 'status',
  \ '<C-m>',
  \ ':<C-u>call gina#action#call(''diff:right'')<CR>',
  \ {'noremap': 1, 'silent': 1}
  \ )

" log
call gina#custom#action#alias(
  \ 'log',
  \ 'vshow',
  \ 'show:commit:vsplit',
  \ )
call gina#custom#mapping#nmap(
  \ 'log',
  \ '<C-m>',
  \ ':<C-u>call gina#action#call(''vshow'')<CR>',
  \ {'noremap': 1, 'silent': 1}
  \ )

call gina#custom#action#alias(
  \ '/\%(blame\|log\|reflog\)',
  \ 'preview',
  \ 'botright show:commit:preview',
  \ )
call gina#custom#mapping#nmap(
  \ '/\%(blame\|log\|reflog\)',
  \ 'p',
  \ ':<C-u>call gina#action#call(''preview'')<CR>',
  \ {'noremap': 1, 'silent': 1}
  \ )
call gina#custom#action#alias(
  \ '/\%(blame\|log\|reflog\)',
  \ 'changes',
  \ 'botright changes:of:preview',
  \ )
call gina#custom#mapping#nmap(
  \ '/\%(blame\|log\|reflog\)',
  \ 'c',
  \ ':<C-u>call gina#action#call(''changes'')<CR>',
  \ {'noremap': 1, 'silent': 1}
  \ )

" blame
call gina#custom#mapping#nmap(
  \ 'blame', 'H',
  \ ':call gina#action#call(''blame:back'')<CR>',
  \ {'noremap': 1, 'silent': 1},
  \ )
call gina#custom#mapping#nmap(
  \ 'blame', 'L',
  \ ':call gina#action#call(''blame:open'')<CR>',
  \ {'noremap': 1, 'silent': 1},
  \ )
call gina#custom#mapping#nmap(
  \ 'blame', '<CR>',
  \ ':call gina#action#call(''show:commit:preview:bottom'')<CR>',
  \ {'noremap': 1, 'silent': 1},
  \ )
call gina#custom#mapping#nmap(
  \ 'blame', 'd',
  \ ':call gina#action#call(''compare'')<CR>',
  \ {'noremap': 1, 'silent': 1},
  \ )

augroup vimrc_gina
  au!
  autocmd FileType git nnoremap <silent> <buffer> q <C-w>c
  autocmd FileType diff nnoremap <silent> <buffer> q <C-w>c
augroup END

" mapping
nmap <silent> [Gina] <Nop>
nmap <silent> <Leader>g [Gina]
nmap <silent> [Gina]s :<C-u>Gina status<CR>
nmap <silent> [Gina]l :<C-u>Gina log<CR>
nmap <silent> [Gina]b :<C-u>Gina blame<CR>
nmap <silent> [Gina]d :<C-u>Gina compare<CR>
