call gina#custom#command#option(
  \ 'status',
  \ '-s|--short'
  \)
call gina#custom#action#alias(
  \ '/\%(blame\|log\|reflog\)',
  \ 'preview',
  \ 'botright show:commit:preview',
  \)
call gina#custom#mapping#nmap(
  \ '/\%(blame\|log\|reflog\)',
  \ 'p',
  \ ':<C-u>call gina#action#call(''preview'')<CR>',
  \ {'noremap': 1, 'silent': 1}
  \)
